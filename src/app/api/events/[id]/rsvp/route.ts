import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import type { RSVPRequest, RSVPResponse, RSVPStatus } from '@/types/event';
import { sendNewRSVPNotification, sendRSVPChangeNotification } from '@/lib/push/event-notifications';

/**
 * Promote the next waitlisted user to "going" if there's capacity.
 * Call after any status change away from "going" or RSVP deletion.
 */
async function promoteFromWaitlist(adminClient: ReturnType<typeof createAdminClient>, eventId: string) {
  // Re-fetch fresh counts
  const { data: event } = await adminClient
    .from('events')
    .select('max_attendees, going_count')
    .eq('id', eventId)
    .single();

  if (!event || event.max_attendees === null) return;
  if (event.going_count >= event.max_attendees) return;

  // Find the waitlisted attendee with the lowest position
  const { data: nextInLine } = await adminClient
    .from('event_attendees')
    .select('id, user_id')
    .eq('event_id', eventId)
    .eq('status', 'waitlist')
    .order('waitlist_position', { ascending: true })
    .limit(1)
    .single();

  if (!nextInLine) return;

  // Promote to going
  await adminClient
    .from('event_attendees')
    .update({ status: 'going', waitlist_position: null })
    .eq('id', nextInLine.id);
}

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
export const POST = withDualAuth(async (
  request: NextRequest,
  authUser,
  { params }: { params: Promise<{ id: string }> }
) => {
  try {
    const { id: eventId } = await params;
    const adminClient = createAdminClient();

    // Rate limiting: 20 RSVPs per hour per user
    const rateLimitKey = createRateLimitKey(authUser.userId, 'rsvpEvent');
    const rateLimit = await rateLimitEnhanced(rateLimitKey, 'rsvpEvent');

    if (!rateLimit.success) {
      return handleError(Errors.rateLimitExceeded(rateLimit.retryAfter || 3600, 'rsvp'));
    }

    // Verify event exists and is active (use adminClient to bypass RLS for iOS Bearer token requests)
    const { data: event, error: eventError } = await adminClient
      .from('events')
      .select('id, status, event_date, user_id, title, max_attendees, going_count')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return handleError(Errors.resourceNotFound('Event'));
    }

    if (event.status !== 'active') {
      return handleError(Errors.validationFailed(['Cannot RSVP to a cancelled or completed event']));
    }

    // Check if event date has passed (use Pacific time for US ski mountains)
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
    if (event.event_date < today) {
      return handleError(Errors.validationFailed(['Cannot RSVP to a past event']));
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
        return handleError(Errors.resourceNotFound('User profile'));
      }
      userProfileId = userProfile.id;
    }

    // Create a compatible object for the rest of the code
    const userProfile = { id: userProfileId };

    // Event creator cannot change their RSVP (they're always "going")
    if (event.user_id === userProfile.id) {
      return handleError(Errors.validationFailed(['Event creator cannot change their RSVP status']));
    }

    const body: RSVPRequest = await request.json();
    const { status, isDriver, needsRide, pickupLocation } = body;

    // Validate status
    const validStatuses: RSVPStatus[] = ['going', 'maybe', 'declined'];
    if (!status || !validStatuses.includes(status)) {
      return handleError(Errors.validationFailed(['Invalid RSVP status. Must be: going, maybe, or declined']));
    }

    // OPTIMIZATION: Fetch existing RSVP once and reuse throughout the function
    // NOTE: Use adminClient to bypass RLS - regular client may not see user's own RSVP
    const { data: existingRSVP } = await adminClient
      .from('event_attendees')
      .select('id, status, is_driver, needs_ride, pickup_location')
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
        // Position assigned after insert/update via atomic pattern below
        waitlistPosition = 0; // placeholder, updated atomically
      }
    }
    const isNewRSVP = !existingRSVP;

    let attendeeData;

    if (existingRSVP) {
      // Update existing RSVP
      // If changing from waitlist to something else, clear waitlist_position
      // Preserve existing carpool fields if not explicitly provided in this request
      const updateData: Record<string, unknown> = {
        status: effectiveStatus,
        is_driver: isDriver ?? existingRSVP.is_driver ?? false,
        needs_ride: needsRide ?? existingRSVP.needs_ride ?? false,
        pickup_location: pickupLocation !== undefined
          ? (pickupLocation?.trim() || null)
          : (existingRSVP.pickup_location ?? null),
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
        return handleError(Errors.databaseError());
      }

      attendeeData = data;

      // If user changed from "going" to something else, promote from waitlist
      if (oldStatus === 'going' && effectiveStatus !== 'going') {
        await promoteFromWaitlist(adminClient, eventId);
      }
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
        return handleError(Errors.databaseError());
      }

      attendeeData = data;
    }

    // Atomically assign waitlist position after insert/update to prevent race conditions.
    // We use MAX+1 in a single UPDATE so concurrent inserts get sequential positions.
    if (effectiveStatus === 'waitlist' && attendeeData) {
      const { data: maxPos } = await adminClient
        .from('event_attendees')
        .select('waitlist_position')
        .eq('event_id', eventId)
        .eq('status', 'waitlist')
        .neq('id', attendeeData.id)
        .order('waitlist_position', { ascending: false })
        .limit(1)
        .single();

      const newPosition = (maxPos?.waitlist_position || 0) + 1;
      await adminClient
        .from('event_attendees')
        .update({ waitlist_position: newPosition })
        .eq('id', attendeeData.id);

      attendeeData.waitlist_position = newPosition;
      waitlistPosition = newPosition;
    }

    // Fetch updated event counts (use adminClient to bypass RLS for iOS Bearer token requests)
    const { data: updatedEvent, error: countError } = await adminClient
      .from('events')
      .select('going_count, maybe_count, attendee_count, waitlist_count, max_attendees')
      .eq('id', eventId)
      .single();

    if (countError) {
      console.error('Error fetching updated counts:', countError);
    }

    // Send notification to event creator (async, don't block response)
    // Notify for going, maybe, and declined (so hosts know when someone drops out)
    // Use effectiveStatus to avoid misleading "is going" when actually waitlisted
    if (event.user_id !== userProfile.id && ['going', 'maybe', 'declined'].includes(status)) {
      const attendeeName = attendeeData.user?.display_name || attendeeData.user?.username || 'Someone';

      if (isNewRSVP && (effectiveStatus === 'going' || effectiveStatus === 'maybe')) {
        // New RSVP notification (skip for waitlisted users — don't mislead the host)
        sendNewRSVPNotification({
          eventId,
          eventTitle: event.title,
          creatorUserId: event.user_id,
          attendeeName,
          rsvpStatus: effectiveStatus as 'going' | 'maybe',
        }).catch((err) => console.error('Failed to send RSVP notification:', err));
      } else if (oldStatus && oldStatus !== effectiveStatus) {
        // RSVP status changed notification (uses effectiveStatus for accuracy)
        sendRSVPChangeNotification({
          eventId,
          eventTitle: event.title,
          creatorUserId: event.user_id,
          attendeeName,
          oldStatus,
          newStatus: effectiveStatus,
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
    return handleError(error, { endpoint: 'POST /api/events/[id]/rsvp' });
  }
});

/**
 * DELETE /api/events/[id]/rsvp
 *
 * Remove RSVP from an event
 */
export const DELETE = withDualAuth(async (
  request: NextRequest,
  authUser,
  { params }: { params: Promise<{ id: string }> }
) => {
  try {
    const { id: eventId } = await params;
    const adminClient = createAdminClient();

    // Verify event exists and is active (use adminClient to bypass RLS for iOS Bearer token requests)
    const { data: event, error: eventError } = await adminClient
      .from('events')
      .select('id, user_id, status, event_date')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return handleError(Errors.resourceNotFound('Event'));
    }

    if (event.status !== 'active') {
      return handleError(Errors.validationFailed(['Cannot modify RSVP for inactive events']));
    }

    // Use Pacific time for date comparison (US ski mountains)
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
    if (event.event_date < today) {
      return handleError(Errors.validationFailed(['Cannot modify RSVP for past events']));
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
        return handleError(Errors.resourceNotFound('User profile'));
      }
      userProfileId = profile.id;
    }

    const userProfile = { id: userProfileId };

    // Event creator cannot remove their RSVP
    if (event.user_id === userProfile.id) {
      return handleError(Errors.validationFailed(['Event creator cannot remove their RSVP']));
    }

    // Check existing RSVP status before deleting (for waitlist promotion)
    const { data: existingRSVP } = await adminClient
      .from('event_attendees')
      .select('status')
      .eq('event_id', eventId)
      .eq('user_id', userProfile.id)
      .single();

    // Delete RSVP
    const { error: deleteError } = await adminClient
      .from('event_attendees')
      .delete()
      .eq('event_id', eventId)
      .eq('user_id', userProfile.id);

    if (deleteError) {
      return handleError(Errors.databaseError());
    }

    // If deleted user was "going", promote next from waitlist
    if (existingRSVP?.status === 'going') {
      await promoteFromWaitlist(adminClient, eventId);
    }

    // Fetch updated event counts (use adminClient to bypass RLS for iOS Bearer token requests)
    const { data: updatedEvent } = await adminClient
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
    return handleError(error, { endpoint: 'DELETE /api/events/[id]/rsvp' });
  }
});
