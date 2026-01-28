import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import type { RSVPRequest, RSVPResponse, RSVPStatus } from '@/types/event';

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

    // Verify event exists and is active
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('id, status, event_date, user_id')
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

    // Look up the internal users.id from auth_user_id
    // The event_attendees.user_id foreign key references users.id, not users.auth_user_id
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

    // Check if user already has an RSVP
    const { data: existingRSVP } = await supabase
      .from('event_attendees')
      .select('id')
      .eq('event_id', eventId)
      .eq('user_id', userProfile.id)
      .single();

    let attendeeData;

    if (existingRSVP) {
      // Update existing RSVP
      const { data, error: updateError } = await adminClient
        .from('event_attendees')
        .update({
          status,
          is_driver: isDriver ?? false,
          needs_ride: needsRide ?? false,
          pickup_location: pickupLocation?.trim() || null,
          responded_at: new Date().toISOString(),
        })
        .eq('id', existingRSVP.id)
        .select(`
          *,
          user:user_id (
            id,
            username,
            display_name,
            avatar_url
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
          status,
          is_driver: isDriver ?? false,
          needs_ride: needsRide ?? false,
          pickup_location: pickupLocation?.trim() || null,
          responded_at: new Date().toISOString(),
        })
        .select(`
          *,
          user:user_id (
            id,
            username,
            display_name,
            avatar_url
          )
        `)
        .single();

      if (insertError) {
        console.error('Error creating RSVP:', insertError);
        return NextResponse.json(
          { error: 'Failed to create RSVP' },
          { status: 500 }
        );
      }

      attendeeData = data;
    }

    // Fetch updated event counts
    const { data: updatedEvent, error: countError } = await supabase
      .from('events')
      .select('going_count, maybe_count, attendee_count')
      .eq('id', eventId)
      .single();

    if (countError) {
      console.error('Error fetching updated counts:', countError);
    }

    const response: RSVPResponse = {
      attendee: {
        id: attendeeData.id,
        userId: attendeeData.user_id,
        status: attendeeData.status,
        isDriver: attendeeData.is_driver,
        needsRide: attendeeData.needs_ride,
        pickupLocation: attendeeData.pickup_location,
        respondedAt: attendeeData.responded_at,
        user: attendeeData.user,
      },
      event: {
        id: eventId,
        goingCount: updatedEvent?.going_count ?? 0,
        maybeCount: updatedEvent?.maybe_count ?? 0,
        attendeeCount: updatedEvent?.attendee_count ?? 0,
      },
    };

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

    // Look up the internal users.id from auth_user_id
    const { data: userProfile, error: userError } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (userError || !userProfile) {
      console.error('Error finding user profile:', userError);
      return NextResponse.json(
        { error: 'User profile not found' },
        { status: 404 }
      );
    }

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
