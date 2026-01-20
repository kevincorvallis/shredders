import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { getMountain } from '@shredders/shared';
import { randomBytes } from 'crypto';
import type {
  CreateEventRequest,
  Event,
  EventRow,
  EventsListResponse,
  CreateEventResponse,
  SkillLevel,
} from '@/types/event';

/**
 * GET /api/events
 *
 * Fetch events with optional filters
 * Query params:
 *   - mountainId: Filter by mountain (optional)
 *   - status: Filter by status (default: 'active')
 *   - upcoming: Only show future events (default: true)
 *   - createdByMe: Only show events I created (requires auth)
 *   - attendingOnly: Only show events I'm attending (requires auth)
 *   - limit: Number of results (default: 20, max: 100)
 *   - offset: Pagination offset (default: 0)
 */
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient();
    const { searchParams } = new URL(request.url);

    const mountainId = searchParams.get('mountainId');
    const status = searchParams.get('status') || 'active';
    const upcoming = searchParams.get('upcoming') !== 'false';
    const createdByMe = searchParams.get('createdByMe') === 'true';
    const attendingOnly = searchParams.get('attendingOnly') === 'true';
    const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 100);
    const offset = parseInt(searchParams.get('offset') || '0');

    // Check auth for user-specific queries
    const authUser = await getDualAuthUser(request);

    if ((createdByMe || attendingOnly) && !authUser) {
      return NextResponse.json(
        { error: 'Authentication required for this filter' },
        { status: 401 }
      );
    }

    // Build base query
    let query = supabase
      .from('events')
      .select(`
        *,
        creator:user_id (
          id,
          username,
          display_name,
          avatar_url
        )
      `, { count: 'exact' })
      .eq('status', status)
      .order('event_date', { ascending: true })
      .range(offset, offset + limit - 1);

    // Apply filters
    if (mountainId) {
      query = query.eq('mountain_id', mountainId);
    }

    if (upcoming) {
      const today = new Date().toISOString().split('T')[0];
      query = query.gte('event_date', today);
    }

    if (createdByMe && authUser) {
      query = query.eq('user_id', authUser.userId);
    }

    const { data: events, error, count } = await query;

    if (error) {
      console.error('Error fetching events:', error);
      return NextResponse.json(
        { error: 'Failed to fetch events' },
        { status: 500 }
      );
    }

    // If filtering by attending, we need a different query
    let filteredEvents = events || [];

    if (attendingOnly && authUser && !createdByMe) {
      // Fetch events where user is an attendee
      const { data: attendeeEvents, error: attendeeError } = await supabase
        .from('event_attendees')
        .select(`
          status,
          event:event_id (
            *,
            creator:user_id (
              id,
              username,
              display_name,
              avatar_url
            )
          )
        `)
        .eq('user_id', authUser.userId)
        .in('status', ['going', 'maybe']);

      if (attendeeError) {
        console.error('Error fetching attending events:', attendeeError);
        return NextResponse.json(
          { error: 'Failed to fetch attending events' },
          { status: 500 }
        );
      }

      filteredEvents = (attendeeEvents || [])
        .filter((a: any) => a.event && a.event.status === 'active')
        .map((a: any) => ({
          ...a.event,
          userRSVPStatus: a.status,
        }));
    }

    // Transform to API response format
    const transformedEvents: Event[] = filteredEvents.map((event: any) => {
      const mountain = getMountain(event.mountain_id);
      return {
        id: event.id,
        creatorId: event.user_id,
        mountainId: event.mountain_id,
        mountainName: mountain?.name,
        title: event.title,
        notes: event.notes,
        eventDate: event.event_date,
        departureTime: event.departure_time,
        departureLocation: event.departure_location,
        skillLevel: event.skill_level,
        carpoolAvailable: event.carpool_available,
        carpoolSeats: event.carpool_seats,
        status: event.status,
        createdAt: event.created_at,
        updatedAt: event.updated_at,
        attendeeCount: event.attendee_count,
        goingCount: event.going_count,
        maybeCount: event.maybe_count,
        creator: event.creator,
        userRSVPStatus: event.userRSVPStatus || null,
        isCreator: authUser ? event.user_id === authUser.userId : false,
      };
    });

    const response: EventsListResponse = {
      events: transformedEvents,
      pagination: {
        total: count || 0,
        limit,
        offset,
        hasMore: (count || 0) > offset + limit,
      },
    };

    return NextResponse.json(response);
  } catch (error) {
    console.error('Error in GET /api/events:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/events
 *
 * Create a new ski event
 *
 * Body:
 *   - mountainId: Mountain ID (required)
 *   - title: Event title (required, 3-100 chars)
 *   - notes: Additional notes (optional, max 2000 chars)
 *   - eventDate: ISO date string YYYY-MM-DD (required, must be future)
 *   - departureTime: HH:MM format (optional)
 *   - departureLocation: Meetup location (optional)
 *   - skillLevel: beginner/intermediate/advanced/expert/all (optional)
 *   - carpoolAvailable: Whether driver can offer rides (default: false)
 *   - carpoolSeats: Number of available seats (optional, 0-8)
 */
export async function POST(request: NextRequest) {
  try {
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

    const body: CreateEventRequest = await request.json();
    const {
      mountainId,
      title,
      notes,
      eventDate,
      departureTime,
      departureLocation,
      skillLevel,
      carpoolAvailable = false,
      carpoolSeats,
    } = body;

    // Validate required fields
    if (!mountainId) {
      return NextResponse.json(
        { error: 'Mountain ID is required' },
        { status: 400 }
      );
    }

    // Validate mountain exists
    const mountain = getMountain(mountainId);
    if (!mountain) {
      return NextResponse.json(
        { error: `Mountain '${mountainId}' not found` },
        { status: 404 }
      );
    }

    if (!title || title.trim().length < 3) {
      return NextResponse.json(
        { error: 'Title must be at least 3 characters' },
        { status: 400 }
      );
    }

    if (title.length > 100) {
      return NextResponse.json(
        { error: 'Title must be less than 100 characters' },
        { status: 400 }
      );
    }

    if (notes && notes.length > 2000) {
      return NextResponse.json(
        { error: 'Notes must be less than 2000 characters' },
        { status: 400 }
      );
    }

    if (!eventDate) {
      return NextResponse.json(
        { error: 'Event date is required' },
        { status: 400 }
      );
    }

    // Validate date is not in the past
    const today = new Date().toISOString().split('T')[0];
    if (eventDate < today) {
      return NextResponse.json(
        { error: 'Event date cannot be in the past' },
        { status: 400 }
      );
    }

    // Validate skill level
    const validSkillLevels: SkillLevel[] = ['beginner', 'intermediate', 'advanced', 'expert', 'all'];
    if (skillLevel && !validSkillLevels.includes(skillLevel)) {
      return NextResponse.json(
        { error: 'Invalid skill level' },
        { status: 400 }
      );
    }

    // Validate carpool seats
    if (carpoolSeats !== undefined && (carpoolSeats < 0 || carpoolSeats > 8)) {
      return NextResponse.json(
        { error: 'Carpool seats must be between 0 and 8' },
        { status: 400 }
      );
    }

    // Validate departure time format (HH:MM)
    if (departureTime && !/^\d{2}:\d{2}$/.test(departureTime)) {
      return NextResponse.json(
        { error: 'Departure time must be in HH:MM format' },
        { status: 400 }
      );
    }

    // Create event using admin client to bypass RLS for initial insert
    const { data: event, error: insertError } = await adminClient
      .from('events')
      .insert({
        user_id: authUser.userId,
        mountain_id: mountainId,
        title: title.trim(),
        notes: notes?.trim() || null,
        event_date: eventDate,
        departure_time: departureTime ? `${departureTime}:00` : null,
        departure_location: departureLocation?.trim() || null,
        skill_level: skillLevel || null,
        carpool_available: carpoolAvailable,
        carpool_seats: carpoolSeats || null,
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

    if (insertError) {
      console.error('Error creating event:', insertError);
      return NextResponse.json(
        { error: 'Failed to create event' },
        { status: 500 }
      );
    }

    // Generate invite token
    const token = randomBytes(16).toString('hex');

    const { error: tokenError } = await adminClient
      .from('event_invite_tokens')
      .insert({
        event_id: event.id,
        token,
        created_by: authUser.userId,
        expires_at: null, // No expiration by default
        max_uses: null, // Unlimited uses by default
      });

    if (tokenError) {
      console.error('Error creating invite token:', tokenError);
      // Don't fail the whole request, event was created successfully
    }

    // Transform to API response
    const transformedEvent: Event = {
      id: event.id,
      creatorId: event.user_id,
      mountainId: event.mountain_id,
      mountainName: mountain.name,
      title: event.title,
      notes: event.notes,
      eventDate: event.event_date,
      departureTime: event.departure_time,
      departureLocation: event.departure_location,
      skillLevel: event.skill_level,
      carpoolAvailable: event.carpool_available,
      carpoolSeats: event.carpool_seats,
      status: event.status,
      createdAt: event.created_at,
      updatedAt: event.updated_at,
      attendeeCount: event.attendee_count,
      goingCount: event.going_count,
      maybeCount: event.maybe_count,
      creator: event.creator,
      isCreator: true,
    };

    // Build invite URL
    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 'https://shredders-bay.vercel.app';
    const inviteUrl = `${baseUrl}/events/invite/${token}`;

    const response: CreateEventResponse = {
      event: transformedEvent,
      inviteToken: token,
      inviteUrl,
    };

    return NextResponse.json(response, { status: 201 });
  } catch (error) {
    console.error('Error in POST /api/events:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
