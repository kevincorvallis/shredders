import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';

/**
 * GET /api/comments
 *
 * Fetch comments for a specific target (mountain, webcam, or photo)
 * Query params:
 *   - mountainId: Filter by mountain
 *   - webcamId: Filter by webcam
 *   - photoId: Filter by photo
 *   - parentCommentId: Filter by parent comment (for nested replies)
 *   - limit: Number of results (default: 50, max: 100)
 *   - offset: Pagination offset (default: 0)
 */
export async function GET(request: Request) {
  try {
    const supabase = await createClient();
    const { searchParams } = new URL(request.url);

    const mountainId = searchParams.get('mountainId');
    const webcamId = searchParams.get('webcamId');
    const photoId = searchParams.get('photoId');
    const parentCommentId = searchParams.get('parentCommentId');
    const limit = Math.min(parseInt(searchParams.get('limit') || '50'), 100);
    const offset = parseInt(searchParams.get('offset') || '0');

    // Build query with user join
    let query = supabase
      .from('comments')
      .select(`
        *,
        user:user_id (
          id,
          username,
          display_name,
          avatar_url
        )
      `)
      .eq('is_deleted', false)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // Apply filters
    if (mountainId) {
      query = query.eq('mountain_id', mountainId);
    }
    if (webcamId) {
      query = query.eq('webcam_id', webcamId);
    }
    if (photoId) {
      query = query.eq('photo_id', photoId);
    }
    if (parentCommentId) {
      query = query.eq('parent_comment_id', parentCommentId);
    }

    const { data: comments, error } = await query;

    if (error) {
      console.error('Error fetching comments:', error);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ comments: comments || [] }, {
      headers: {
        'Cache-Control': 'public, max-age=30, stale-while-revalidate=60',
      },
    });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/comments' });
  }
}

/**
 * POST /api/comments
 *
 * Create a new comment
 * Supports both JWT bearer tokens and Supabase session authentication
 *
 * Body:
 *   - content: Comment text (required, max 2000 chars)
 *   - mountainId: Mountain ID (optional)
 *   - webcamId: Webcam ID (optional)
 *   - photoId: Photo ID (optional)
 *   - parentCommentId: Parent comment ID for nested replies (optional)
 */
export const POST = withDualAuth(async (request, authUser) => {
  try {
    const supabase = await createClient();
    const adminClient = createAdminClient();

    // Look up internal user profile ID
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.unauthorized('User profile not found'));
    }

    // Rate limit comment creation
    const rateLimitResult = await rateLimitEnhanced(
      createRateLimitKey('comment', authUser.userId),
      'postComment'
    );
    if (!rateLimitResult.success) {
      return handleError(Errors.rateLimitExceeded(rateLimitResult.retryAfter ?? 60, 'comment'));
    }

    const body = await request.json();
    const { content, mountainId, webcamId, photoId, parentCommentId } = body;

    // Validate content
    if (!content || typeof content !== 'string') {
      return handleError(Errors.missingField('content'));
    }

    if (content.length > 2000) {
      return handleError(Errors.validationFailed(['Content must be less than 2000 characters']));
    }

    // At least one target must be specified
    if (!mountainId && !webcamId && !photoId) {
      return handleError(Errors.validationFailed(['At least one target (mountainId, webcamId, or photoId) is required']));
    }

    // If parent comment specified, verify it exists
    if (parentCommentId) {
      const { data: parentComment, error: parentError } = await supabase
        .from('comments')
        .select('id')
        .eq('id', parentCommentId)
        .single();

      if (parentError || !parentComment) {
        return handleError(Errors.resourceNotFound('Parent comment'));
      }
    }

    // Create comment
    const { data: comment, error: insertError } = await adminClient
      .from('comments')
      .insert({
        user_id: userProfile.id,
        content: content.trim(),
        mountain_id: mountainId || null,
        webcam_id: webcamId || null,
        photo_id: photoId || null,
        parent_comment_id: parentCommentId || null,
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
      console.error('Error creating comment:', insertError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ comment }, { status: 201 });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/comments' });
  }
});
