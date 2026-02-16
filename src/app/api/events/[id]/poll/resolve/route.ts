import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';
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
export const POST = withDualAuth(async (
  request: NextRequest,
  authUser,
  { params }: { params: Promise<{ id: string }> }
) => {
  try {
    const { id: eventId } = await params;
    const adminClient = createAdminClient();

    // Look up user profile
    let userProfileId = authUser.profileId;
    if (!userProfileId) {
      const { data: userProfile } = await adminClient
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.userId)
        .single();

      if (!userProfile) {
        return handleError(Errors.resourceNotFound('User profile'));
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
      return handleError(Errors.resourceNotFound('Event'));
    }

    if (event.user_id !== userProfileId) {
      return handleError(Errors.forbidden('Only the event creator can resolve the poll'));
    }

    // Validate request body
    const body: ResolveDatePollRequest = await request.json();
    const { optionId } = body;

    if (!optionId) {
      return handleError(Errors.missingField('optionId'));
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
      return handleError(Errors.resourceNotFound('Date option'));
    }

    const poll = Array.isArray(option.poll) ? option.poll[0] : option.poll;

    if (poll.event_id !== eventId) {
      return handleError(Errors.validationFailed(['Option does not belong to this event']));
    }

    if (poll.status !== 'open') {
      return handleError(Errors.validationFailed(['Poll is already closed']));
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
      return handleError(Errors.databaseError());
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
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({
      message: 'Poll resolved successfully',
      selectedDate: option.proposed_date,
      eventId,
    });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/events/[id]/poll/resolve' });
  }
});
