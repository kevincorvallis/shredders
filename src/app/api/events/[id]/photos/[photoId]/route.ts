import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

const STORAGE_BUCKET = 'event-photos';

/**
 * DELETE /api/events/[id]/photos/[photoId]
 *
 * Delete a photo (soft delete).
 * Users can only delete their own photos.
 * Event creators can delete any photo on their event.
 */
export const DELETE = withDualAuth(async (
  request,
  authUser,
  { params }: { params: Promise<{ id: string; photoId: string }> }
) => {
  try {
    const { id: eventId, photoId } = await params;
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

    // Check if photo exists and belongs to this event
    const { data: photo, error: photoError } = await adminClient
      .from('event_photos')
      .select('id, event_id, user_id, storage_path')
      .eq('id', photoId)
      .eq('event_id', eventId)
      .eq('is_deleted', false)
      .single();

    if (photoError || !photo) {
      return handleError(Errors.resourceNotFound('Photo'));
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
      return handleError(Errors.forbidden('You can only delete your own photos'));
    }

    // Soft delete the photo
    const { error: deleteError } = await adminClient
      .from('event_photos')
      .update({ is_deleted: true })
      .eq('id', photoId);

    if (deleteError) {
      console.error('Error deleting photo:', deleteError);
      return handleError(Errors.databaseError());
    }

    // Optionally: Delete from storage (hard delete)
    // Uncomment if you want to actually remove the file
    // await adminClient.storage.from(STORAGE_BUCKET).remove([photo.storage_path]);

    return NextResponse.json({ message: 'Photo deleted successfully' });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/events/[id]/photos/[photoId]' });
  }
});

/**
 * GET /api/events/[id]/photos/[photoId]
 *
 * Get a single photo by ID.
 * Requires RSVP.
 */
export const GET = withDualAuth(async (
  request,
  authUser,
  { params }: { params: Promise<{ id: string; photoId: string }> }
) => {
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
      return handleError(Errors.resourceNotFound('Event'));
    }

    // Look up user's internal profile ID
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.resourceNotFound('User profile'));
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
      return handleError(Errors.forbidden('RSVP required to view photos'));
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
      return handleError(Errors.resourceNotFound('Photo'));
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
    return handleError(error, { endpoint: 'GET /api/events/[id]/photos/[photoId]' });
  }
});
