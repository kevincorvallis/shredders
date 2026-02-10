import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import {
  sendNewCommentNotification,
  sendCommentReplyNotification,
} from '@/lib/push/event-notifications';

/**
 * OPTIMIZATION: Combined helper to check both creator status and RSVP in a single query
 * Returns { isCreator: boolean, hasRSVP: boolean }
 */
async function checkUserEventAccess(
  supabase: any,
  eventId: string,
  userProfileId: string
): Promise<{ isCreator: boolean; hasRSVP: boolean }> {
  // Run both checks in parallel for better performance
  const [eventResult, rsvpResult] = await Promise.all([
    supabase
      .from('events')
      .select('user_id')
      .eq('id', eventId)
      .single(),
    supabase
      .from('event_attendees')
      .select('status')
      .eq('event_id', eventId)
      .eq('user_id', userProfileId)
      .in('status', ['going', 'maybe'])
      .maybeSingle(),
  ]);

  return {
    isCreator: eventResult.data?.user_id === userProfileId,
    hasRSVP: !!rsvpResult.data,
  };
}

/**
 * GET /api/events/[id]/comments
 *
 * Fetch comments for an event.
 * - RSVP'd users (going/maybe) or event creator: Full access
 * - Non-RSVP'd users: Return 403 with comment count only
 *
 * Query params:
 *   - limit: Number of results (default: 50, max: 100)
 *   - offset: Pagination offset (default: 0)
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();
    const { searchParams } = new URL(request.url);

    const limit = Math.min(parseInt(searchParams.get('limit') || '50'), 100);
    const offset = parseInt(searchParams.get('offset') || '0');

    // Check if event exists
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

    // Get comment count (always returned)
    const { count: commentCount } = await supabase
      .from('event_comments')
      .select('*', { count: 'exact', head: true })
      .eq('event_id', eventId)
      .eq('is_deleted', false);

    // Check authentication
    const authUser = await getDualAuthUser(request);

    if (!authUser) {
      // Return count only for unauthenticated users
      return NextResponse.json({
        comments: [],
        commentCount: commentCount || 0,
        gated: true,
        message: 'RSVP to view comments',
      });
    }

    // OPTIMIZATION: Use cached profileId from auth when available
    let userProfileId = authUser.profileId;

    if (!userProfileId) {
      const { data: profile } = await adminClient
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.userId)
        .single();
      userProfileId = profile?.id;
    }

    if (!userProfileId) {
      return NextResponse.json({
        comments: [],
        commentCount: commentCount || 0,
        gated: true,
        message: 'RSVP to view comments',
      });
    }

    const userProfile = { id: userProfileId };

    // OPTIMIZATION: Check creator + RSVP in parallel (combined query)
    const { isCreator, hasRSVP } = await checkUserEventAccess(adminClient, eventId, userProfile.id);

    // Debug logging
    console.log('[Comments] Access check:', {
      eventId,
      userProfileId: userProfile.id,
      eventCreatorId: event.user_id,
      isCreator,
      hasRSVP,
      idsMatch: event.user_id === userProfile.id,
    });

    if (!isCreator && !hasRSVP) {
      return NextResponse.json({
        comments: [],
        commentCount: commentCount || 0,
        gated: true,
        message: 'RSVP to view comments',
      });
    }

    // Fetch comments with user info
    const { data: comments, error: commentsError } = await supabase
      .from('event_comments')
      .select(`
        id,
        event_id,
        user_id,
        content,
        parent_id,
        created_at,
        updated_at,
        user:user_id (
          id,
          username,
          display_name,
          avatar_url
        )
      `)
      .eq('event_id', eventId)
      .eq('is_deleted', false)
      .order('created_at', { ascending: true })
      .range(offset, offset + limit - 1);

    if (commentsError) {
      console.error('Error fetching event comments:', commentsError);
      return NextResponse.json(
        { error: 'Failed to fetch comments' },
        { status: 500 }
      );
    }

    // Organize into threads (top-level and replies)
    const topLevel = (comments || []).filter((c: any) => !c.parent_id);
    const replies = (comments || []).filter((c: any) => c.parent_id);

    // Attach replies to their parents
    const threaded = topLevel.map((comment: any) => ({
      ...comment,
      replies: replies.filter((r: any) => r.parent_id === comment.id),
    }));

    return NextResponse.json({
      comments: threaded,
      commentCount: commentCount || 0,
      gated: false,
    });
  } catch (error) {
    console.error('Error in GET /api/events/[id]/comments:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/events/[id]/comments
 *
 * Create a comment on an event.
 * Requires user to be RSVP'd (going/maybe) or event creator.
 *
 * Body:
 *   - content: Comment text (required, max 2000 chars)
 *   - parentId: Parent comment ID for replies (optional)
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

    // Rate limiting: 30 comments per hour per user
    const rateLimitKey = createRateLimitKey(authUser.userId, 'postComment');
    const rateLimit = await rateLimitEnhanced(rateLimitKey, 'postComment');

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

    // Check if event exists
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('id, user_id, title, status')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // Block comments on cancelled or completed events
    if (event.status !== 'active') {
      return NextResponse.json(
        { error: 'Cannot comment on a cancelled or completed event' },
        { status: 400 }
      );
    }

    // OPTIMIZATION: Use cached profileId, but still need display_name for notifications
    let userProfile: { id: string; display_name?: string; username?: string } | null = null;

    if (authUser.profileId) {
      // We have the ID cached, but need display_name for notifications
      // Fetch only if we need those fields (which we do for posting comments)
      const { data: profile } = await adminClient
        .from('users')
        .select('id, display_name, username')
        .eq('id', authUser.profileId)
        .single();
      userProfile = profile;
    } else {
      // Fallback: full lookup
      const { data: profile } = await adminClient
        .from('users')
        .select('id, display_name, username')
        .eq('auth_user_id', authUser.userId)
        .single();
      userProfile = profile;
    }

    if (!userProfile) {
      return NextResponse.json(
        { error: 'User profile not found' },
        { status: 404 }
      );
    }

    // OPTIMIZATION: Check creator + RSVP in parallel (combined query)
    const { isCreator, hasRSVP } = await checkUserEventAccess(adminClient, eventId, userProfile.id);

    if (!isCreator && !hasRSVP) {
      return NextResponse.json(
        { error: 'You must RSVP to comment on this event' },
        { status: 403 }
      );
    }

    const body = await request.json();
    const { content, parentId } = body;

    // Validate content
    if (!content || typeof content !== 'string') {
      return NextResponse.json(
        { error: 'Content is required' },
        { status: 400 }
      );
    }

    if (content.trim().length === 0) {
      return NextResponse.json(
        { error: 'Content cannot be empty' },
        { status: 400 }
      );
    }

    if (content.length > 2000) {
      return NextResponse.json(
        { error: 'Content must be less than 2000 characters' },
        { status: 400 }
      );
    }

    // If parent comment specified, verify it exists, belongs to this event, and check nesting depth
    if (parentId) {
      const { data: parentComment, error: parentError } = await supabase
        .from('event_comments')
        .select('id, event_id, parent_id')
        .eq('id', parentId)
        .eq('event_id', eventId)
        .single();

      if (parentError || !parentComment) {
        return NextResponse.json(
          { error: 'Parent comment not found' },
          { status: 404 }
        );
      }

      // Limit nesting depth to 2 levels (top-level and one reply level)
      // If parent already has a parent, we're at max depth
      if (parentComment.parent_id) {
        return NextResponse.json(
          { error: 'Cannot reply to a reply. Maximum comment depth is 2 levels.' },
          { status: 400 }
        );
      }
    }

    // Create comment using admin client to bypass RLS
    const { data: comment, error: insertError } = await adminClient
      .from('event_comments')
      .insert({
        event_id: eventId,
        user_id: userProfile.id,
        content: content.trim(),
        parent_id: parentId || null,
      })
      .select(`
        id,
        event_id,
        user_id,
        content,
        parent_id,
        created_at,
        updated_at
      `)
      .single();

    if (insertError) {
      console.error('Error creating event comment:', insertError);
      return NextResponse.json(
        { error: 'Failed to create comment' },
        { status: 500 }
      );
    }

    // Fetch user info for the response
    const { data: user } = await adminClient
      .from('users')
      .select('id, username, display_name, avatar_url')
      .eq('id', userProfile.id)
      .single();

    // Send notifications (async, don't block response)
    const commenterName = userProfile.display_name || userProfile.username || 'Someone';
    const commentPreview = content.trim().substring(0, 50) + (content.length > 50 ? '...' : '');

    if (parentId) {
      // This is a reply - notify the parent comment author
      const { data: parentComment } = await adminClient
        .from('event_comments')
        .select('user_id')
        .eq('id', parentId)
        .single();

      if (parentComment) {
        sendCommentReplyNotification({
          eventId,
          eventTitle: event.title,
          parentCommentAuthorId: parentComment.user_id,
          replierUserId: userProfile.id,
          replierName: commenterName,
          replyPreview: commentPreview,
        }).catch((err) => console.error('Failed to send reply notification:', err));
      }
    } else {
      // Top-level comment - notify the event creator
      sendNewCommentNotification({
        eventId,
        eventTitle: event.title,
        creatorUserId: event.user_id,
        commenterUserId: userProfile.id,
        commenterName,
        commentPreview,
      }).catch((err) => console.error('Failed to send comment notification:', err));
    }

    return NextResponse.json({
      comment: {
        ...comment,
        user,
        replies: [],
      },
    }, { status: 201 });
  } catch (error) {
    console.error('Error in POST /api/events/[id]/comments:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
