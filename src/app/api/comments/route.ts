import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';

/**
 * GET /api/comments
 *
 * Fetch comments for a specific target (mountain, webcam, photo, or check-in)
 * Query params:
 *   - mountainId: Filter by mountain
 *   - webcamId: Filter by webcam
 *   - photoId: Filter by photo
 *   - checkInId: Filter by check-in
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
    const checkInId = searchParams.get('checkInId');
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
    if (checkInId) {
      query = query.eq('check_in_id', checkInId);
    }
    if (parentCommentId) {
      query = query.eq('parent_comment_id', parentCommentId);
    }

    const { data: comments, error } = await query;

    if (error) {
      console.error('Error fetching comments:', error);
      return NextResponse.json(
        { error: 'Failed to fetch comments' },
        { status: 500 }
      );
    }

    return NextResponse.json({ comments: comments || [] }, {
      headers: {
        'Cache-Control': 'public, max-age=30, stale-while-revalidate=60',
      },
    });
  } catch (error) {
    console.error('Error in GET /api/comments:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
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
 *   - checkInId: Check-in ID (optional)
 *   - parentCommentId: Parent comment ID for nested replies (optional)
 */
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Check authentication (supports both JWT and Supabase session)
    const authUser = await getDualAuthUser(request);
    if (!authUser) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Rate limit comment creation
    const rateLimitResult = await rateLimitEnhanced(
      createRateLimitKey('comment', authUser.userId),
      'postComment'
    );
    if (!rateLimitResult.success) {
      return NextResponse.json(
        { error: 'Too many comments. Please try again later.' },
        { status: 429, headers: { 'Retry-After': String(rateLimitResult.retryAfter ?? 60) } }
      );
    }

    const body = await request.json();
    const { content, mountainId, webcamId, photoId, checkInId, parentCommentId } = body;

    // Validate content
    if (!content || typeof content !== 'string') {
      return NextResponse.json(
        { error: 'Content is required' },
        { status: 400 }
      );
    }

    if (content.length > 2000) {
      return NextResponse.json(
        { error: 'Content must be less than 2000 characters' },
        { status: 400 }
      );
    }

    // At least one target must be specified
    if (!mountainId && !webcamId && !photoId && !checkInId) {
      return NextResponse.json(
        { error: 'At least one target (mountainId, webcamId, photoId, or checkInId) is required' },
        { status: 400 }
      );
    }

    // If parent comment specified, verify it exists
    if (parentCommentId) {
      const { data: parentComment, error: parentError } = await supabase
        .from('comments')
        .select('id')
        .eq('id', parentCommentId)
        .single();

      if (parentError || !parentComment) {
        return NextResponse.json(
          { error: 'Parent comment not found' },
          { status: 404 }
        );
      }
    }

    // Create comment
    const { data: comment, error: insertError } = await supabase
      .from('comments')
      .insert({
        user_id: authUser.userId,
        content: content.trim(),
        mountain_id: mountainId || null,
        webcam_id: webcamId || null,
        photo_id: photoId || null,
        check_in_id: checkInId || null,
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
      return NextResponse.json(
        { error: 'Failed to create comment' },
        { status: 500 }
      );
    }

    return NextResponse.json({ comment }, { status: 201 });
  } catch (error) {
    console.error('Error in POST /api/comments:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
