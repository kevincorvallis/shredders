import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';
import type { CastDateVoteRequest, DateVoteChoice } from '@/types/event';

/**
 * POST /api/events/[id]/poll/vote
 *
 * Cast or update a vote on a date option.
 *
 * Body:
 *   - optionId: string (required)
 *   - vote: 'available' | 'maybe' | 'unavailable' (required)
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

    // Validate request body
    const body: CastDateVoteRequest = await request.json();
    const { optionId, vote } = body;

    const validVotes: DateVoteChoice[] = ['available', 'maybe', 'unavailable'];
    if (!optionId || !vote || !validVotes.includes(vote)) {
      return handleError(Errors.validationFailed(['Invalid vote. Must provide optionId and vote (available/maybe/unavailable)']));
    }

    // Verify the option belongs to a poll for this event
    const { data: option } = await adminClient
      .from('event_date_options')
      .select(`
        id,
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
      return handleError(Errors.validationFailed(['Poll is closed']));
    }

    // Upsert the vote
    const { data: voteData, error: voteError } = await adminClient
      .from('event_date_votes')
      .upsert(
        {
          option_id: optionId,
          user_id: userProfileId,
          vote,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'option_id,user_id' }
      )
      .select('id, option_id, user_id, vote')
      .single();

    if (voteError) {
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({
      vote: {
        id: voteData.id,
        optionId: voteData.option_id,
        userId: voteData.user_id,
        vote: voteData.vote,
      },
    });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/events/[id]/poll/vote' });
  }
});
