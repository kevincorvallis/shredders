import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

/**
 * DELETE /api/events/[id]/comments/[commentId]
 *
 * Delete a comment (soft delete).
 * Users can only delete their own comments.
 * Event creators can delete any comment on their event.
 */
export const DELETE = withDualAuth(async (
  request,
  authUser,
  { params }: { params: Promise<{ id: string; commentId: string }> }
) => {
  try {
    const { id: eventId, commentId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

    // Look up user's internal profile ID
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.resourceNotFound('User profile'));
    }

    // Check if comment exists and belongs to this event
    const { data: comment, error: commentError } = await supabase
      .from('event_comments')
      .select('id, event_id, user_id')
      .eq('id', commentId)
      .eq('event_id', eventId)
      .eq('is_deleted', false)
      .single();

    if (commentError || !comment) {
      return handleError(Errors.resourceNotFound('Comment'));
    }

    // Check if user is the event creator
    const { data: event } = await supabase
      .from('events')
      .select('user_id')
      .eq('id', eventId)
      .single();

    const isEventCreator = event?.user_id === userProfile.id;
    const isCommentAuthor = comment.user_id === userProfile.id;

    // User must be comment author or event creator to delete
    if (!isCommentAuthor && !isEventCreator) {
      return handleError(Errors.forbidden('You can only delete your own comments'));
    }

    // Soft delete the comment
    const { error: deleteError } = await adminClient
      .from('event_comments')
      .update({ is_deleted: true })
      .eq('id', commentId);

    if (deleteError) {
      console.error('Error deleting comment:', deleteError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ message: 'Comment deleted successfully' });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/events/[id]/comments/[commentId]' });
  }
});
