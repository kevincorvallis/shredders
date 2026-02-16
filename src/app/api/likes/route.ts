import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

/**
 * GET /api/likes
 *
 * Check if user has liked a specific target
 * Supports both JWT bearer tokens and Supabase session authentication
 *
 * Query params:
 *   - photoId: Photo ID
 *   - commentId: Comment ID
 *   - checkInId: Check-in ID
 *   - webcamId: Webcam ID
 */
export const GET = withDualAuth(async (request, authUser) => {
  try {
    const supabase = await createClient();
    const { searchParams } = new URL(request.url);

    const photoId = searchParams.get('photoId');
    const commentId = searchParams.get('commentId');
    const checkInId = searchParams.get('checkInId');
    const webcamId = searchParams.get('webcamId');

    // At least one target must be specified
    if (!photoId && !commentId && !checkInId && !webcamId) {
      return handleError(Errors.validationFailed(['At least one target (photoId, commentId, checkInId, or webcamId) is required']));
    }

    // Build query
    let query = supabase
      .from('likes')
      .select('id')
      .eq('user_id', authUser.userId);

    if (photoId) query = query.eq('photo_id', photoId);
    if (commentId) query = query.eq('comment_id', commentId);
    if (checkInId) query = query.eq('check_in_id', checkInId);
    if (webcamId) query = query.eq('webcam_id', webcamId);

    const { data: like, error } = await query.maybeSingle();

    if (error) {
      console.error('Error checking like:', error);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ liked: !!like });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/likes' });
  }
});

/**
 * POST /api/likes
 *
 * Toggle a like on a target (photo, comment, check-in, or webcam)
 * If like exists, it will be removed. If not, it will be created.
 * Supports both JWT bearer tokens and Supabase session authentication
 *
 * Body:
 *   - photoId: Photo ID (optional)
 *   - commentId: Comment ID (optional)
 *   - checkInId: Check-in ID (optional)
 *   - webcamId: Webcam ID (optional)
 */
export const POST = withDualAuth(async (request, authUser) => {
  try {
    const supabase = await createClient();

    const body = await request.json();
    const { photoId, commentId, checkInId, webcamId } = body;

    // At least one target must be specified
    if (!photoId && !commentId && !checkInId && !webcamId) {
      return handleError(Errors.validationFailed(['At least one target (photoId, commentId, checkInId, or webcamId) is required']));
    }

    // Build query to check existing like
    let checkQuery = supabase
      .from('likes')
      .select('id')
      .eq('user_id', authUser.userId);

    if (photoId) checkQuery = checkQuery.eq('photo_id', photoId);
    if (commentId) checkQuery = checkQuery.eq('comment_id', commentId);
    if (checkInId) checkQuery = checkQuery.eq('check_in_id', checkInId);
    if (webcamId) checkQuery = checkQuery.eq('webcam_id', webcamId);

    const { data: existingLike, error: checkError } = await checkQuery.maybeSingle();

    if (checkError) {
      console.error('Error checking existing like:', checkError);
      return handleError(Errors.databaseError());
    }

    // If like exists, remove it (unlike)
    if (existingLike) {
      const { error: deleteError } = await supabase
        .from('likes')
        .delete()
        .eq('id', existingLike.id);

      if (deleteError) {
        console.error('Error removing like:', deleteError);
        return handleError(Errors.databaseError());
      }

      return NextResponse.json({
        liked: false,
        message: 'Like removed successfully',
      });
    }

    // Otherwise, create new like
    const { data: newLike, error: insertError } = await supabase
      .from('likes')
      .insert({
        user_id: authUser.userId,
        photo_id: photoId || null,
        comment_id: commentId || null,
        check_in_id: checkInId || null,
        webcam_id: webcamId || null,
      })
      .select()
      .single();

    if (insertError) {
      console.error('Error creating like:', insertError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({
      liked: true,
      message: 'Like added successfully',
      like: newLike,
    }, { status: 201 });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/likes' });
  }
});

/**
 * DELETE /api/likes
 *
 * Remove a like from a target
 * Supports both JWT bearer tokens and Supabase session authentication
 *
 * Query params:
 *   - photoId: Photo ID
 *   - commentId: Comment ID
 *   - checkInId: Check-in ID
 *   - webcamId: Webcam ID
 */
export const DELETE = withDualAuth(async (request, authUser) => {
  try {
    const supabase = await createClient();
    const { searchParams } = new URL(request.url);

    const photoId = searchParams.get('photoId');
    const commentId = searchParams.get('commentId');
    const checkInId = searchParams.get('checkInId');
    const webcamId = searchParams.get('webcamId');

    // At least one target must be specified
    if (!photoId && !commentId && !checkInId && !webcamId) {
      return handleError(Errors.validationFailed(['At least one target (photoId, commentId, checkInId, or webcamId) is required']));
    }

    // Build delete query
    let deleteQuery = supabase
      .from('likes')
      .delete()
      .eq('user_id', authUser.userId);

    if (photoId) deleteQuery = deleteQuery.eq('photo_id', photoId);
    if (commentId) deleteQuery = deleteQuery.eq('comment_id', commentId);
    if (checkInId) deleteQuery = deleteQuery.eq('check_in_id', checkInId);
    if (webcamId) deleteQuery = deleteQuery.eq('webcam_id', webcamId);

    const { error } = await deleteQuery;

    if (error) {
      console.error('Error deleting like:', error);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/likes' });
  }
});
