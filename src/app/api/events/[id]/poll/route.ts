import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';
import type {
  CreateDatePollRequest,
  DatePoll,
  DatePollOption,
  DatePollResponse,
  DatePollVote,
} from '@/types/event';

/**
 * GET /api/events/[id]/poll
 *
 * Fetch the date poll for an event, including options and votes.
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
    const adminClient = createAdminClient();

    // Fetch poll
    const { data: poll, error: pollError } = await adminClient
      .from('event_date_polls')
      .select('id, event_id, status, created_at, closed_at')
      .eq('event_id', eventId)
      .single();

    if (pollError || !poll) {
      return handleError(Errors.resourceNotFound('Date poll'));
    }

    // Fetch options
    const { data: options } = await adminClient
      .from('event_date_options')
      .select('id, proposed_date, proposed_by')
      .eq('poll_id', poll.id)
      .order('proposed_date', { ascending: true });

    // Fetch all votes for these options
    const optionIds = (options || []).map((o) => o.id);
    const { data: votes } = optionIds.length > 0
      ? await adminClient
          .from('event_date_votes')
          .select(`
            id,
            option_id,
            user_id,
            vote,
            user:user_id (
              id,
              username,
              display_name,
              avatar_url
            )
          `)
          .in('option_id', optionIds)
      : { data: [] };

    // Build response
    const pollOptions: DatePollOption[] = (options || []).map((opt) => {
      const optVotes = (votes || []).filter((v) => v.option_id === opt.id);
      return {
        id: opt.id,
        proposedDate: opt.proposed_date,
        proposedBy: opt.proposed_by,
        votes: optVotes.map((v): DatePollVote => ({
          userId: v.user_id,
          vote: v.vote,
          user: Array.isArray(v.user) ? v.user[0] : v.user,
        })),
        availableCount: optVotes.filter((v) => v.vote === 'available').length,
        maybeCount: optVotes.filter((v) => v.vote === 'maybe').length,
        unavailableCount: optVotes.filter((v) => v.vote === 'unavailable').length,
      };
    });

    const response: DatePollResponse = {
      poll: {
        id: poll.id,
        eventId: poll.event_id,
        status: poll.status,
        createdAt: poll.created_at,
        closedAt: poll.closed_at,
        options: pollOptions,
      },
    };

    return NextResponse.json(response);
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/events/[id]/poll' });
  }
}

/**
 * POST /api/events/[id]/poll
 *
 * Create a date poll for an event. Only the event creator can do this.
 *
 * Body:
 *   - dates: string[] (2-5 date strings in YYYY-MM-DD format)
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
      return handleError(Errors.forbidden('Only the event creator can create a date poll'));
    }

    if (event.status !== 'active') {
      return handleError(Errors.validationFailed(['Cannot create poll for inactive event']));
    }

    // Check if poll already exists
    const { data: existingPoll } = await adminClient
      .from('event_date_polls')
      .select('id')
      .eq('event_id', eventId)
      .single();

    if (existingPoll) {
      return handleError(Errors.validationFailed(['A date poll already exists for this event']));
    }

    // Validate request body
    const body: CreateDatePollRequest = await request.json();
    const { dates } = body;

    if (!dates || !Array.isArray(dates) || dates.length < 2 || dates.length > 5) {
      return handleError(Errors.validationFailed(['Must provide 2-5 dates']));
    }

    // Validate date format
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    for (const d of dates) {
      if (!dateRegex.test(d)) {
        return handleError(Errors.validationFailed([`Invalid date format: ${d}. Use YYYY-MM-DD`]));
      }
    }

    // Create poll
    const { data: poll, error: pollError } = await adminClient
      .from('event_date_polls')
      .insert({ event_id: eventId })
      .select('id, event_id, status, created_at, closed_at')
      .single();

    if (pollError || !poll) {
      return handleError(Errors.databaseError());
    }

    // Create date options
    const optionInserts = dates.map((date) => ({
      poll_id: poll.id,
      proposed_date: date,
      proposed_by: userProfileId,
    }));

    const { data: options, error: optionsError } = await adminClient
      .from('event_date_options')
      .insert(optionInserts)
      .select('id, proposed_date, proposed_by');

    if (optionsError) {
      return handleError(Errors.databaseError());
    }

    const pollOptions: DatePollOption[] = (options || []).map((opt) => ({
      id: opt.id,
      proposedDate: opt.proposed_date,
      proposedBy: opt.proposed_by,
      votes: [],
      availableCount: 0,
      maybeCount: 0,
      unavailableCount: 0,
    }));

    const response: DatePollResponse = {
      poll: {
        id: poll.id,
        eventId: poll.event_id,
        status: poll.status,
        createdAt: poll.created_at,
        closedAt: poll.closed_at,
        options: pollOptions,
      },
    };

    return NextResponse.json(response, { status: 201 });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/events/[id]/poll' });
  }
});
