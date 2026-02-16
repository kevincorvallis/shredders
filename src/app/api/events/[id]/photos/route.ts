import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth, getDualAuthUser } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

const STORAGE_BUCKET = 'event-photos';
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/heif', 'image/webp'];

/**
 * OPTIMIZATION: Combined helper to check both creator status and RSVP in parallel
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

interface EventPhoto {
  id: string;
  eventId: string;
  userId: string;
  url: string;
  thumbnailUrl: string | null;
  caption: string | null;
  width: number | null;
  height: number | null;
  createdAt: string;
  user: {
    id: string;
    username: string;
    displayName: string | null;
    avatarUrl: string | null;
  } | null;
}

/**
 * GET /api/events/[id]/photos
 *
 * Fetch photos for an event.
 * - RSVP'd users (going/maybe) or event creator: Full access
 * - Non-RSVP'd users: Return 403 with photo count only
 *
 * Query params:
 *   - limit: Number of results (default: 20, max: 50)
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

    const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 50);
    const offset = parseInt(searchParams.get('offset') || '0');

    // Check if event exists
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('id, user_id, photo_count')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return handleError(Errors.resourceNotFound('Event'));
    }

    const photoCount = event.photo_count || 0;

    // Check authentication
    const authUser = await getDualAuthUser(request);

    if (!authUser) {
      return NextResponse.json({
        photos: [],
        photoCount,
        gated: true,
        message: 'RSVP to see photos',
      });
    }

    // Look up user's profile ID from auth_user_id
    const { data: profile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();
    const userProfileId = profile?.id;

    if (!userProfileId) {
      return NextResponse.json({
        photos: [],
        photoCount,
        gated: true,
        message: 'RSVP to see photos',
      });
    }

    const userProfile = { id: userProfileId };

    // OPTIMIZATION: Check creator + RSVP in parallel (combined query)
    const { isCreator, hasRSVP } = await checkUserEventAccess(adminClient, eventId, userProfile.id);

    if (!isCreator && !hasRSVP) {
      return NextResponse.json({
        photos: [],
        photoCount,
        gated: true,
        message: 'RSVP to see photos',
      });
    }

    // Fetch photos
    const { data: photos, error: photosError } = await adminClient
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
      .eq('event_id', eventId)
      .eq('is_deleted', false)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (photosError) {
      console.error('Error fetching event photos:', photosError);
      return handleError(Errors.databaseError());
    }

    // Fetch user info for photos
    const userIds = [...new Set((photos || []).map((p: any) => p.user_id))];
    let usersMap: Record<string, any> = {};

    if (userIds.length > 0) {
      const { data: users } = await adminClient
        .from('users')
        .select('id, username, display_name, avatar_url')
        .in('id', userIds);

      if (users) {
        usersMap = users.reduce((acc: Record<string, any>, user: any) => {
          acc[user.id] = user;
          return acc;
        }, {});
      }
    }

    // Transform photos
    const transformedPhotos: EventPhoto[] = (photos || []).map((photo: any) => ({
      id: photo.id,
      eventId: photo.event_id,
      userId: photo.user_id,
      url: photo.url,
      thumbnailUrl: photo.thumbnail_url,
      caption: photo.caption,
      width: photo.width,
      height: photo.height,
      createdAt: photo.created_at,
      user: usersMap[photo.user_id] ? {
        id: usersMap[photo.user_id].id,
        username: usersMap[photo.user_id].username,
        displayName: usersMap[photo.user_id].display_name,
        avatarUrl: usersMap[photo.user_id].avatar_url,
      } : null,
    }));

    return NextResponse.json({
      photos: transformedPhotos,
      photoCount,
      gated: false,
      pagination: {
        limit,
        offset,
        hasMore: photoCount > offset + limit,
      },
    });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/events/[id]/photos' });
  }
}

/**
 * POST /api/events/[id]/photos
 *
 * Upload a photo to an event.
 * Requires user to be RSVP'd (going/maybe) or event creator.
 *
 * Body: multipart/form-data
 *   - photo: File (required, max 5MB, jpeg/png/heif/webp)
 *   - caption: string (optional, max 500 chars)
 */
export const POST = withDualAuth(async (
  request,
  authUser,
  { params }: { params: Promise<{ id: string }> }
) => {
  try {
    const { id: eventId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

    // Check if event exists
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('id, user_id, status')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return handleError(Errors.resourceNotFound('Event'));
    }

    // Block uploads on cancelled or completed events
    if (event.status !== 'active') {
      return NextResponse.json(
        { error: 'Cannot upload photos to a cancelled or completed event' },
        { status: 400 }
      );
    }

    // Look up user's profile ID from auth_user_id
    const { data: profile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!profile) {
      return handleError(Errors.resourceNotFound('User profile'));
    }
    const userProfileId = profile.id;

    // TypeScript narrowing: at this point userProfileId is guaranteed to be a string
    const userProfile = { id: userProfileId as string };

    // OPTIMIZATION: Check creator + RSVP in parallel (combined query)
    const { isCreator, hasRSVP } = await checkUserEventAccess(adminClient, eventId, userProfile.id);

    if (!isCreator && !hasRSVP) {
      return handleError(Errors.forbidden('You must RSVP to upload photos to this event'));
    }

    // Parse multipart form data
    const formData = await request.formData();
    const photoFile = formData.get('photo') as File | null;
    const caption = formData.get('caption') as string | null;

    if (!photoFile) {
      return NextResponse.json(
        { error: 'Photo file is required' },
        { status: 400 }
      );
    }

    // Validate file type
    if (!ALLOWED_TYPES.includes(photoFile.type)) {
      return NextResponse.json(
        { error: 'Invalid file type. Allowed: JPEG, PNG, HEIF, WebP' },
        { status: 400 }
      );
    }

    // Validate file size
    if (photoFile.size > MAX_FILE_SIZE) {
      return NextResponse.json(
        { error: 'File too large. Maximum size is 5MB' },
        { status: 400 }
      );
    }

    // Validate caption
    if (caption && caption.length > 500) {
      return NextResponse.json(
        { error: 'Caption must be less than 500 characters' },
        { status: 400 }
      );
    }

    // Generate unique filename
    const timestamp = Date.now();
    const extension = photoFile.type.split('/')[1].replace('jpeg', 'jpg');
    const storagePath = `${eventId}/${userProfile.id}/${timestamp}.${extension}`;

    // Upload to Supabase Storage
    const fileBuffer = await photoFile.arrayBuffer();
    const { error: uploadError } = await adminClient.storage
      .from(STORAGE_BUCKET)
      .upload(storagePath, fileBuffer, {
        contentType: photoFile.type,
        cacheControl: '3600',
        upsert: false,
      });

    if (uploadError) {
      console.error('Error uploading photo:', uploadError);
      return handleError(Errors.databaseError());
    }

    // Get public URL
    const { data: urlData } = adminClient.storage
      .from(STORAGE_BUCKET)
      .getPublicUrl(storagePath);

    const publicUrl = urlData.publicUrl;

    // Create photo record
    const { data: photo, error: insertError } = await adminClient
      .from('event_photos')
      .insert({
        event_id: eventId,
        user_id: userProfile.id,
        storage_path: storagePath,
        url: publicUrl,
        caption: caption?.trim() || null,
        file_size: photoFile.size,
        mime_type: photoFile.type,
      })
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
      .single();

    if (insertError) {
      console.error('Error creating photo record:', insertError);
      // Try to clean up uploaded file
      await adminClient.storage.from(STORAGE_BUCKET).remove([storagePath]);
      return handleError(Errors.databaseError());
    }

    // Fetch user info for response
    const { data: user } = await adminClient
      .from('users')
      .select('id, username, display_name, avatar_url')
      .eq('id', userProfile.id)
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
    }, { status: 201 });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/events/[id]/photos' });
  }
});
