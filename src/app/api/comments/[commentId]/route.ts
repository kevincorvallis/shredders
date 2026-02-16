import { NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth, getDualAuthUser } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

/**
 * GET /api/comments/[commentId]
 *
 * Get a specific comment by ID
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ commentId: string }> }
) {
  try {
    const { commentId } = await params;
    const supabase = await createClient();

    const { data: comment, error } = await supabase
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
      .eq('id', commentId)
      .eq('is_deleted', false)
      .single();

    if (error || !comment) {
      return handleError(Errors.resourceNotFound('Comment'));
    }

    return NextResponse.json({ comment });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/comments/[commentId]' });
  }
}

/**
 * PATCH /api/comments/[commentId]
 *
 * Update a comment (owner only)
 * Body:
 *   - content: Updated comment text (required, max 2000 chars)
 */
export const PATCH = withDualAuth(async (request, authUser) => {
  try {
    const url = new URL(request.url);
    const commentId = url.pathname.split('/').pop()!;
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

    // Fetch existing comment
    const { data: existingComment, error: fetchError } = await adminClient
      .from('comments')
      .select('user_id, is_deleted')
      .eq('id', commentId)
      .single();

    if (fetchError || !existingComment) {
      return handleError(Errors.resourceNotFound('Comment'));
    }

    // Verify ownership
    if (existingComment.user_id !== userProfile.id) {
      return handleError(Errors.forbidden('You can only edit your own comments'));
    }

    // Cannot edit deleted comments
    if (existingComment.is_deleted) {
      return handleError(Errors.validationFailed(['Cannot edit deleted comment']));
    }

    const body = await request.json();
    const { content } = body;

    // Validate content
    if (!content || typeof content !== 'string') {
      return handleError(Errors.missingField('content'));
    }

    if (content.length > 2000) {
      return handleError(Errors.validationFailed(['Content must be less than 2000 characters']));
    }

    // Update comment
    const { data: updatedComment, error: updateError } = await adminClient
      .from('comments')
      .update({
        content: content.trim(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', commentId)
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
      console.error('Error updating comment:', updateError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ comment: updatedComment });
  } catch (error) {
    return handleError(error, { endpoint: 'PATCH /api/comments/[commentId]' });
  }
});

/**
 * DELETE /api/comments/[commentId]
 *
 * Delete a comment (owner only)
 * This performs a soft delete by setting is_deleted=true
 */
export const DELETE = withDualAuth(async (request, authUser) => {
  try {
    const url = new URL(request.url);
    const commentId = url.pathname.split('/').pop()!;
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

    // Fetch existing comment
    const { data: existingComment, error: fetchError } = await adminClient
      .from('comments')
      .select('user_id, is_deleted')
      .eq('id', commentId)
      .single();

    if (fetchError || !existingComment) {
      return handleError(Errors.resourceNotFound('Comment'));
    }

    // Verify ownership
    if (existingComment.user_id !== userProfile.id) {
      return handleError(Errors.forbidden('You can only delete your own comments'));
    }

    // Already deleted
    if (existingComment.is_deleted) {
      return handleError(Errors.validationFailed(['Comment already deleted']));
    }

    // Soft delete
    const { error: deleteError } = await adminClient
      .from('comments')
      .update({
        is_deleted: true,
        content: '[deleted]',
        updated_at: new Date().toISOString(),
      })
      .eq('id', commentId);

    if (deleteError) {
      console.error('Error deleting comment:', deleteError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/comments/[commentId]' });
  }
});
