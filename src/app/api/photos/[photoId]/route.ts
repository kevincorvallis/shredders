/**
 * GET /api/photos/[photoId]
 * Get a specific photo
 *
 * DELETE /api/photos/[photoId]
 * Delete a photo (must be owner)
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

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
      return NextResponse.json({ error: 'Photo not found' }, { status: 404 });
    }

    return NextResponse.json({ photo });
  } catch (error: any) {
    console.error('Get photo error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ photoId: string }> }
) {
  try {
    const { photoId } = await params;
    const supabase = await createClient();

    // Check authentication
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    // Get photo to verify ownership and get storage path
    const { data: photo, error: fetchError } = await supabase
      .from('user_photos')
      .select('user_id, s3_key, s3_bucket')
      .eq('id', photoId)
      .single();

    if (fetchError || !photo) {
      return NextResponse.json({ error: 'Photo not found' }, { status: 404 });
    }

    // Verify ownership
    if (photo.user_id !== user.id) {
      return NextResponse.json(
        { error: 'You can only delete your own photos' },
        { status: 403 }
      );
    }

    // Delete from storage
    const { error: storageError } = await supabase.storage
      .from(photo.s3_bucket)
      .remove([photo.s3_key]);

    if (storageError) {
      console.error('Storage delete error:', storageError);
      // Continue anyway - database record will be deleted
    }

    // Delete from database
    const { error: deleteError } = await supabase
      .from('user_photos')
      .delete()
      .eq('id', photoId);

    if (deleteError) {
      console.error('Database delete error:', deleteError);
      return NextResponse.json({ error: deleteError.message }, { status: 500 });
    }

    return NextResponse.json({ message: 'Photo deleted successfully' });
  } catch (error: any) {
    console.error('Delete photo error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}
