/**
 * GET /api/photos/[photoId]
 * Get a specific photo
 *
 * DELETE /api/photos/[photoId]
 * Delete a photo (must be owner)
 */

import { createClient, createAdminClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ photoId: string }> }
) {
  try {
    const { photoId } = await params;
    const supabase = await createClient();

    const { data: photo, error } = await supabase
      .from('user_photos')
      .select(
        `
        *,
        users:user_id (
          username,
          display_name,
          avatar_url
        )
      `
      )
      .eq('id', photoId)
      .single();

    if (error) {
      console.error('Error fetching photo:', error);
      return handleError(Errors.resourceNotFound('Photo'));
    }

    return NextResponse.json({ photo });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/photos/[photoId]' });
  }
}

export const DELETE = withDualAuth(async (request, authUser) => {
  try {
    const url = new URL(request.url);
    const segments = url.pathname.split('/');
    const photoId = segments[segments.length - 1];
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

    // Get photo to verify ownership and get storage path
    const { data: photo, error: fetchError } = await adminClient
      .from('user_photos')
      .select('user_id, storage_path')
      .eq('id', photoId)
      .single();

    if (fetchError || !photo) {
      return handleError(Errors.resourceNotFound('Photo'));
    }

    // Verify ownership
    if (photo.user_id !== userProfile.id) {
      return handleError(Errors.forbidden('You can only delete your own photos'));
    }

    // Delete from storage
    const supabase = await createClient();
    const { error: storageError } = await supabase.storage
      .from('user-photos')
      .remove([photo.storage_path]);

    if (storageError) {
      console.error('Storage delete error:', storageError);
      // Continue anyway - database record will be deleted
    }

    // Delete from database
    const { error: deleteError } = await adminClient
      .from('user_photos')
      .delete()
      .eq('id', photoId);

    if (deleteError) {
      console.error('Database delete error:', deleteError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ message: 'Photo deleted successfully' });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/photos/[photoId]' });
  }
});
