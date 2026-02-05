import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import type { RSVPRequest, RSVPResponse, RSVPStatus } from '@/types/event';
import { sendNewRSVPNotification, sendRSVPChangeNotification } from '@/lib/push/event-notifications';

/**
 * POST /api/events/[id]/rsvp
 *
 * RSVP to an event
 *
 * Body:
 *   - status: 'going' | 'maybe' | 'declined' (required)
 *   - isDriver: Whether user can drive others (optional)
 *   - needsRide: Whether user needs a ride (optional)
 *   - pickupLocation: Pickup location if needs ride (optional)
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

    // Check authentication
    const authUser = await getDualAuthUser(request);
    if (!authUser) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Rate limiting: 20 RSVPs per hour per user
    const rateLimitKey = createRateLimitKey(authUser.userId, 'rsvpEvent');
    const rateLimit = rateLimitEnhanced(rateLimitKey, 'rsvpEvent');

    if (!rateLimit.success) {
      return NextResponse.json(
        {
          error: 'Rate limit exceeded. Please try again later.',
          retryAfter: rateLimit.retryAfter,
        },
        {
          status: 429,
          headers: { 'Retry-After': String(rateLimit.retryAfter || 3600) },
        }
      );
    }

    // Verify event exists and is active
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('id, status, event_date, user_id, title, max_attendees, going_count')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    if (event.status !== 'active') {
      return NextResponse.json(
        { error: 'Cannot RSVP to a cancelled or completed event' },
        { status: 400 }
      );
    }

    // Check if event date has passed
    const today = new Date().toISOString().split('T')[0];
    if (event.event_date < today) {
      return NextResponse.json(
        { error: 'Cannot RSVP to a past event' },
        { status: 400 }
      );
    }

    // OPTIMIZATION: Use cached profileId from auth when available
    let userProfileId = authUser.profileId;

    // Fallback to database lookup only if profileId not in cache
    if (!userProfileId) {
      const { data: userProfile, error: userError } = await adminClient
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.userId)
        .single();

      if (userError || !userProfile) {
        console.error('Error finding user profile:', userError);
        return NextResponse.json(
          { error: 'User profile not found. Please try signing out and back in.' },
          { status: 404 }
        );
      }
      userProfileId = userProfile.id;
    }

    // Create a compatible object for the rest of the code
    const userProfile = { id: userProfileId };

    const body: RSVPRequest = await request.json();
    const { status, isDriver, needsRide, pickupLocation } = body;

    // Validate status
    const validStatuses: RSVPStatus[] = ['going', 'maybe', 'declined'];
    if (!status || !validStatuses.includes(status)) {
      return NextResponse.json(
        { error: 'Invalid RSVP status. Must be: going, maybe, or declined' },
        { status: 400 }
      );
    }

    // OPTIMIZATION: Fetch existing RSVP once and reuse throughout the function
    const { data: existingRSVP } = await supabase
      .from('event_attendees')
      .select('id, status')
      .eq('event_id', eventId)
      .eq('user_id', userProfile.id)
      .single();

    const oldStatus = existingRSVP?.status || null;

    // Check capacity and determine if user should be waitlisted
    let effectiveStatus: RSVPStatus = status;
    let waitlistPosition: number | null = null;
    const isAtCapacity = event.max_attendees !== null && event.going_count >= event.max_attendees;

    if (status === 'going' && isAtCapacity) {
      // If user is not already going, put them on waitlist
      if (!existingRSVP || existingRSVP.status !== 'going') {
        effectiveStatus = 'waitlist';
        // Get next waitlist position
        const { data: maxPosition } = await adminClient
          .from('event_attendees')
          .select('waitlist_position')
          .eq('event_id', eventId)
          .eq('status', 'waitlist')
          .order('waitlist_position', { ascending: false })
          .limit(1)
          .single();

        waitlistPosition = (maxPosition?.waitlist_position || 0) + 1;
      }
    }
    const isNewRSVP = !existingRSVP;

    let attendeeData;

    if (existingRSVP) {
      // Update existing RSVP
      // If changing from waitlist to something else, clear waitlist_position
      const updateData: Record<string, unknown> = {
        status: effectiveStatus,
        is_driver: isDriver ?? false,
        needs_ride: needsRide ?? false,
        pickup_location: pickupLocation?.trim() || null,
        responded_at: new Date().toISOString(),
      };

      // Set or clear waitlist_position based on effective status
      if (effectiveStatus === 'waitlist') {
        updateData.waitlist_position = waitlistPosition;
      } else {
        updateData.waitlist_position = null;
      }

      const { data, error: updateError } = await adminClient
        .from('event_attendees')
        .update(updateData)
        .eq('id', existingRSVP.id)
        .select(`
          *,
          user:user_id (
            id,
            username,
            display_name,
            avatar_url,
            riding_style
          )
        `)
        .single();

      if (updateError) {
        console.error('Error updating RSVP:', updateError);
        return NextResponse.json(
          { error: 'Failed to update RSVP' },
          { status: 500 }
        );
      }

      attendeeData = data;
    } else {
      // Create new RSVP
      const { data, error: insertError } = await adminClient
        .from('event_attendees')
        .insert({
          event_id: eventId,
          user_id: userProfile.id,
          status: effectiveStatus,
          is_driver: isDriver ?? false,
          needs_ride: needsRide ?? false,
          pickup_location: pickupLocation?.trim() || null,
          waitlist_position: effectiveStatus === 'waitlist' ? waitlistPosition : null,
          responded_at: new Date().toISOString(),
        })
        .select(`
          *,
          user:user_id (
            id,
            username,
            display_name,
            avatar_url,
            riding_style
          )
        `)
        .single();

      if (insertError) {
        console.error('Error creating RSVP:', insertError);
        console.error('Insert details - eventId:', eventId, 'userId:', userProfile.id, 'status:', effectiveStatus);
        return NextResponse.json(
          { error: `Failed to create RSVP: ${insertError.message || 'Database error'}` },
          { status: 500 }
        );
      }

      attendeeData = data;
    }

    // Fetch updated event counts
    const { data: updatedEvent, error: countError } = await supabase
      .from('events')
      .select('going_count, maybe_count, attendee_count, waitlist_count, max_attendees')
      .eq('id', eventId)
      .single();

    if (countError) {
      console.error('Error fetching updated counts:', countError);
    }

    // Send notification to event creator (async, don't block response)
    // Only notify if user is not the event creator
    if (event.user_id !== userProfile.id && (status === 'going' || status === 'maybe')) {
      const attendeeName = attendeeData.user?.display_name || attendeeData.user?.username || 'Someone';

      if (isNewRSVP) {
        // New RSVP notification
        sendNewRSVPNotification({
          eventId,
          eventTitle: event.title,
          creatorUserId: event.user_id,
          attendeeName,
          rsvpStatus: status as 'going' | 'maybe',
        }).catch((err) => console.error('Failed to send RSVP notification:', err));
      } else if (oldStatus && oldStatus !== status) {
        // RSVP status changed notification
        sendRSVPChangeNotification({
          eventId,
          eventTitle: event.title,
          creatorUserId: event.user_id,
          attendeeName,
          oldStatus,
          newStatus: status,
        }).catch((err) => console.error('Failed to send RSVP change notification:', err));
      }
    }

    const response: RSVPResponse = {
      attendee: {
        id: attendeeData.id,
        userId: attendeeData.user_id,
        status: attendeeData.status,
        isDriver: attendeeData.is_driver,
        needsRide: attendeeData.needs_ride,
        pickupLocation: attendeeData.pickup_location,
        waitlistPosition: attendeeData.waitlist_position,
        respondedAt: attendeeData.responded_at,
        user: attendeeData.user,
      },
      event: {
        id: eventId,
        goingCount: updatedEvent?.going_count ?? 0,
        maybeCount: updatedEvent?.maybe_count ?? 0,
        attendeeCount: updatedEvent?.attendee_count ?? 0,
        waitlistCount: updatedEvent?.waitlist_count ?? 0,
        maxAttendees: updatedEvent?.max_attendees ?? null,
      },
    };

    // If user was waitlisted, add a message
    if (effectiveStatus === 'waitlist' && status === 'going') {
      return NextResponse.json({
        ...response,
        message: `Event is at capacity. You've been added to the waitlist at position ${waitlistPosition}.`,
        wasWaitlisted: true,
      });
    }

    return NextResponse.json(response);
  } catch (error) {
    console.error('Error in POST /api/events/[id]/rsvp:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/events/[id]/rsvp
 *
 * Remove RSVP from an event
 */
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

    // Check authentication
    const authUser = await getDualAuthUser(request);
    if (!authUser) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Verify event exists
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('id, user_id')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // OPTIMIZATION: Use cached profileId from auth when available
    let userProfileId = authUser.profileId;

    if (!userProfileId) {
      const { data: profile, error: userError } = await adminClient
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.userId)
        .single();

      if (userError || !profile) {
        console.error('Error finding user profile:', userError);
        return NextResponse.json(
          { error: 'User profile not found' },
          { status: 404 }
        );
      }
      userProfileId = profile.id;
    }

    const userProfile = { id: userProfileId };

    // Event creator cannot remove their RSVP
    if (event.user_id === userProfile.id) {
      return NextResponse.json(
        { error: 'Event creator cannot remove their RSVP' },
        { status: 400 }
      );
    }

    // Delete RSVP
    const { error: deleteError } = await adminClient
      .from('event_attendees')
      .delete()
      .eq('event_id', eventId)
      .eq('user_id', userProfile.id);

    if (deleteError) {
      console.error('Error deleting RSVP:', deleteError);
      return NextResponse.json(
        { error: 'Failed to remove RSVP' },
        { status: 500 }
      );
    }

    // Fetch updated event counts
    const { data: updatedEvent } = await supabase
      .from('events')
      .select('going_count, maybe_count, attendee_count')
      .eq('id', eventId)
      .single();

    return NextResponse.json({
      message: 'RSVP removed successfully',
      event: {
        id: eventId,
        goingCount: updatedEvent?.going_count ?? 0,
        maybeCount: updatedEvent?.maybe_count ?? 0,
        attendeeCount: updatedEvent?.attendee_count ?? 0,
      },
    });
  } catch (error) {
    console.error('Error in DELETE /api/events/[id]/rsvp:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
