import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
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

    // Validate request body
    const body: CastDateVoteRequest = await request.json();
    const { optionId, vote } = body;

    const validVotes: DateVoteChoice[] = ['available', 'maybe', 'unavailable'];
    if (!optionId || !vote || !validVotes.includes(vote)) {
      return NextResponse.json(
        { error: 'Invalid vote. Must provide optionId and vote (available/maybe/unavailable)' },
        { status: 400 }
      );
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
        { error: 'Poll is closed' },
        { status: 400 }
      );
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
      console.error('Error casting vote:', voteError);
      return NextResponse.json(
        { error: 'Failed to cast vote' },
        { status: 500 }
      );
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
    console.error('Error in POST /api/events/[id]/poll/vote:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
