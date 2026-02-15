import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import type { ResolveDatePollRequest } from '@/types/event';

/**
 * POST /api/events/[id]/poll/resolve
 *
 * Resolve a date poll by picking the winning date.
 * Updates the event's event_date and closes the poll.
 * Only the event creator can resolve.
 *
 * Body:
 *   - optionId: string (the winning date option ID)
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
    const adminClient = createAdminClient();

    // Check authentication
    const authUser = await getDualAuthUser(request);
    if (!authUser) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Look up user profile
    let userProfileId = authUser.profileId;
    if (!userProfileId) {
      const { data: userProfile } = await adminClient
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.userId)
        .single();

      if (!userProfile) {
        return NextResponse.json(
          { error: 'User profile not found' },
          { status: 404 }
        );
      }
      userProfileId = userProfile.id;
    }

    // Verify event exists and user is the creator
    const { data: event } = await adminClient
      .from('events')
      .select('id, user_id, status')
      .eq('id', eventId)
      .single();

    if (!event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    if (event.user_id !== userProfileId) {
      return NextResponse.json(
        { error: 'Only the event creator can resolve the poll' },
        { status: 403 }
      );
    }

    // Validate request body
    const body: ResolveDatePollRequest = await request.json();
    const { optionId } = body;

    if (!optionId) {
      return NextResponse.json(
        { error: 'Must provide optionId' },
        { status: 400 }
      );
    }

    // Verify the option belongs to a poll for this event and poll is open
    const { data: option } = await adminClient
      .from('event_date_options')
      .select(`
        id,
        proposed_date,
        poll:poll_id (
          id,
          event_id,
          status
        )
      `)
      .eq('id', optionId)
      .single();

    if (!option || !option.poll) {
      return NextResponse.json(
        { error: 'Date option not found' },
        { status: 404 }
      );
    }

    const poll = Array.isArray(option.poll) ? option.poll[0] : option.poll;

    if (poll.event_id !== eventId) {
      return NextResponse.json(
        { error: 'Option does not belong to this event' },
        { status: 400 }
      );
    }

    if (poll.status !== 'open') {
      return NextResponse.json(
        { error: 'Poll is already closed' },
        { status: 400 }
      );
    }

    // Update event date to winning date
    const { error: eventUpdateError } = await adminClient
      .from('events')
      .update({
        event_date: option.proposed_date,
        updated_at: new Date().toISOString(),
      })
      .eq('id', eventId);

    if (eventUpdateError) {
      console.error('Error updating event date:', eventUpdateError);
      return NextResponse.json(
        { error: 'Failed to update event date' },
        { status: 500 }
      );
    }

    // Close the poll
    const { error: pollUpdateError } = await adminClient
      .from('event_date_polls')
      .update({
        status: 'closed',
        closed_at: new Date().toISOString(),
      })
      .eq('id', poll.id);

    if (pollUpdateError) {
      console.error('Error closing poll:', pollUpdateError);
      return NextResponse.json(
        { error: 'Failed to close poll' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      message: 'Poll resolved successfully',
      selectedDate: option.proposed_date,
      eventId,
    });
  } catch (error) {
    console.error('Error in POST /api/events/[id]/poll/resolve:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
