import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';

const STORAGE_BUCKET = 'event-photos';
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/heif', 'image/webp'];

/**
 * Helper: Check if user has RSVP'd to an event (going or maybe)
 */
async function checkUserRSVP(
  supabase: any,
  eventId: string,
  userProfileId: string
): Promise<boolean> {
  const { data: attendee } = await supabase
    .from('event_attendees')
    .select('status')
    .eq('event_id', eventId)
    .eq('user_id', userProfileId)
    .in('status', ['going', 'maybe'])
    .single();

  return !!attendee;
}

/**
 * Helper: Check if user is the event creator
 */
async function checkIsCreator(
  supabase: any,
  eventId: string,
  userProfileId: string
): Promise<boolean> {
  const { data: event } = await supabase
    .from('events')
    .select('user_id')
    .eq('id', eventId)
    .single();

  return event?.user_id === userProfileId;
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
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
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

    // Look up user's internal profile ID
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return NextResponse.json({
        photos: [],
        photoCount,
        gated: true,
        message: 'RSVP to see photos',
      });
    }

    // Check if user is creator or has RSVP'd
    // Use adminClient for RSVP check to bypass RLS (RSVP records are inserted via admin client)
    const isCreator = await checkIsCreator(adminClient, eventId, userProfile.id);
    const hasRSVP = await checkUserRSVP(adminClient, eventId, userProfile.id);

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
      return NextResponse.json(
        { error: 'Failed to fetch photos' },
        { status: 500 }
      );
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
    console.error('Error in GET /api/events/[id]/photos:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
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
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
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
    // Use adminClient for RSVP check to bypass RLS (RSVP records are inserted via admin client)
    const isCreator = await checkIsCreator(adminClient, eventId, userProfile.id);
    const hasRSVP = await checkUserRSVP(adminClient, eventId, userProfile.id);

    if (!isCreator && !hasRSVP) {
      return NextResponse.json(
        { error: 'You must RSVP to upload photos to this event' },
        { status: 403 }
      );
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
      return NextResponse.json(
        { error: 'Failed to upload photo' },
        { status: 500 }
      );
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
      return NextResponse.json(
        { error: 'Failed to create photo record' },
        { status: 500 }
      );
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
    console.error('Error in POST /api/events/[id]/photos:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
