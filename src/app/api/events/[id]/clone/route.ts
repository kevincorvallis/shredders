import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { getMountain } from '@shredders/shared';
import { randomBytes } from 'crypto';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import type { Event, CreateEventResponse } from '@/types/event';

/**
 * POST /api/events/[id]/clone
 *
 * Clone an existing event with a new date
 *
 * Body:
 *   - eventDate: New event date (required, YYYY-MM-DD, must be future)
 *   - title: Override title (optional, defaults to original)
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

    // Rate limiting: 10 events per hour (same as create)
    const rateLimitKey = createRateLimitKey(authUser.userId, 'createEvent');
    const rateLimit = rateLimitEnhanced(rateLimitKey, 'createEvent');

    if (!rateLimit.success) {
      return NextResponse.json(
        {
          error: 'Rate limit exceeded. Please try again later.',
          retryAfter: rateLimit.retryAfter,
        },
        {
          status: 429,
          headers: { 'Retry-After': String(rateLimit.retryAfter || 3600) },
        }
      );
    }

    // Look up user profile
    const { data: userProfile, error: userError } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (userError || !userProfile) {
      return NextResponse.json(
        { error: 'User profile not found' },
        { status: 404 }
      );
    }

    // Fetch original event
    const { data: originalEvent, error: eventError } = await supabase
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single();

    if (eventError || !originalEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // Parse request body
    const body = await request.json();
    const { eventDate, title } = body;

    // Validate new event date
    if (!eventDate) {
      return NextResponse.json(
        { error: 'New event date is required' },
        { status: 400 }
      );
    }

    const today = new Date().toISOString().split('T')[0];
    if (eventDate < today) {
      return NextResponse.json(
        { error: 'Event date cannot be in the past' },
        { status: 400 }
      );
    }

    // Create cloned event
    const { data: clonedEvent, error: cloneError } = await adminClient
      .from('events')
      .insert({
        user_id: userProfile.id,
        mountain_id: originalEvent.mountain_id,
        title: title?.trim() || originalEvent.title,
        notes: originalEvent.notes,
        event_date: eventDate,
        departure_time: originalEvent.departure_time,
        departure_location: originalEvent.departure_location,
        skill_level: originalEvent.skill_level,
        carpool_available: originalEvent.carpool_available,
        carpool_seats: originalEvent.carpool_seats,
      })
      .select(`
        *,
        creator:user_id (
          id,
          username,
          display_name,
          avatar_url
        )
      `)
      .single();

    if (cloneError) {
      console.error('Error cloning event:', cloneError);
      return NextResponse.json(
        { error: 'Failed to clone event' },
        { status: 500 }
      );
    }

    // Generate new invite token
    const token = randomBytes(16).toString('hex');
    await adminClient
      .from('event_invite_tokens')
      .insert({
        event_id: clonedEvent.id,
        token,
        created_by: userProfile.id,
        expires_at: null,
        max_uses: null,
      });

    const mountain = getMountain(clonedEvent.mountain_id);

    const transformedEvent: Event = {
      id: clonedEvent.id,
      creatorId: clonedEvent.user_id,
      mountainId: clonedEvent.mountain_id,
      mountainName: mountain?.name,
      title: clonedEvent.title,
      notes: clonedEvent.notes,
      eventDate: clonedEvent.event_date,
      departureTime: clonedEvent.departure_time,
      departureLocation: clonedEvent.departure_location,
      skillLevel: clonedEvent.skill_level,
      carpoolAvailable: clonedEvent.carpool_available,
      carpoolSeats: clonedEvent.carpool_seats,
      status: clonedEvent.status,
      createdAt: clonedEvent.created_at,
      updatedAt: clonedEvent.updated_at,
      attendeeCount: 0,
      goingCount: 0,
      maybeCount: 0,
      creator: clonedEvent.creator,
      isCreator: true,
    };

    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app';
    const inviteUrl = `${baseUrl}/events/invite/${token}`;

    const response: CreateEventResponse = {
      event: transformedEvent,
      inviteToken: token,
      inviteUrl,
    };

    return NextResponse.json(response, { status: 201 });
  } catch (error) {
    console.error('Error in POST /api/events/[id]/clone:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
