import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';

const STORAGE_BUCKET = 'event-photos';

/**
 * DELETE /api/events/[id]/photos/[photoId]
 *
 * Delete a photo (soft delete).
 * Users can only delete their own photos.
 * Event creators can delete any photo on their event.
 */
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; photoId: string }> }
) {
  try {
    const { id: eventId, photoId } = await params;
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

    // Look up user's internal profile ID
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

    // Check if photo exists and belongs to this event
    const { data: photo, error: photoError } = await adminClient
      .from('event_photos')
      .select('id, event_id, user_id, storage_path')
      .eq('id', photoId)
      .eq('event_id', eventId)
      .eq('is_deleted', false)
      .single();

    if (photoError || !photo) {
      return NextResponse.json(
        { error: 'Photo not found' },
        { status: 404 }
      );
    }

    // Check if user is the event creator
    const { data: event } = await supabase
      .from('events')
      .select('user_id')
      .eq('id', eventId)
      .single();

    const isEventCreator = event?.user_id === userProfile.id;
    const isPhotoOwner = photo.user_id === userProfile.id;

    // User must be photo owner or event creator to delete
    if (!isPhotoOwner && !isEventCreator) {
      return NextResponse.json(
        { error: 'You can only delete your own photos' },
        { status: 403 }
      );
    }

    // Soft delete the photo
    const { error: deleteError } = await adminClient
      .from('event_photos')
      .update({ is_deleted: true })
      .eq('id', photoId);

    if (deleteError) {
      console.error('Error deleting photo:', deleteError);
      return NextResponse.json(
        { error: 'Failed to delete photo' },
        { status: 500 }
      );
    }

    // Optionally: Delete from storage (hard delete)
    // Uncomment if you want to actually remove the file
    // await adminClient.storage.from(STORAGE_BUCKET).remove([photo.storage_path]);

    return NextResponse.json({ message: 'Photo deleted successfully' });
  } catch (error) {
    console.error('Error in DELETE /api/events/[id]/photos/[photoId]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * GET /api/events/[id]/photos/[photoId]
 *
 * Get a single photo by ID.
 * Requires RSVP.
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; photoId: string }> }
) {
  try {
    const { id: eventId, photoId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

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

    // Check authentication
    const authUser = await getDualAuthUser(request);
    if (!authUser) {
      return NextResponse.json(
        { error: 'Authentication required' },
        { status: 401 }
      );
    }

    // Look up user's internal profile ID
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

    // Check if user is creator or has RSVP'd
    const isCreator = event.user_id === userProfile.id;

    let hasRSVP = false;
    if (!isCreator) {
      const { data: attendee } = await supabase
        .from('event_attendees')
        .select('status')
        .eq('event_id', eventId)
        .eq('user_id', userProfile.id)
        .in('status', ['going', 'maybe'])
        .single();
      hasRSVP = !!attendee;
    }

    if (!isCreator && !hasRSVP) {
      return NextResponse.json(
        { error: 'RSVP required to view photos' },
        { status: 403 }
      );
    }

    // Fetch photo
    const { data: photo, error: photoError } = await adminClient
      .from('event_photos')
      .select(`
        id,
        event_id,
        user_id,
        url,
        thumbnail_url,
        caption,
        width,
        height,
        created_at
      `)
      .eq('id', photoId)
      .eq('event_id', eventId)
      .eq('is_deleted', false)
      .single();

    if (photoError || !photo) {
      return NextResponse.json(
        { error: 'Photo not found' },
        { status: 404 }
      );
    }

    // Fetch user info
    const { data: user } = await adminClient
      .from('users')
      .select('id, username, display_name, avatar_url')
      .eq('id', photo.user_id)
      .single();

    return NextResponse.json({
      photo: {
        id: photo.id,
        eventId: photo.event_id,
        userId: photo.user_id,
        url: photo.url,
        thumbnailUrl: photo.thumbnail_url,
        caption: photo.caption,
        width: photo.width,
        height: photo.height,
        createdAt: photo.created_at,
        user: user ? {
          id: user.id,
          username: user.username,
          displayName: user.display_name,
          avatarUrl: user.avatar_url,
        } : null,
      },
    });
  } catch (error) {
    console.error('Error in GET /api/events/[id]/photos/[photoId]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
