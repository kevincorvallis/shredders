import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { getMountain } from '@shredders/shared';
import { randomBytes } from 'crypto';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
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
 *   - dateFrom: Filter events on or after this date (YYYY-MM-DD)
 *   - dateTo: Filter events on or before this date (YYYY-MM-DD)
 *   - skillLevel: Filter by skill level (beginner, intermediate, advanced, expert, all)
 *   - carpoolAvailable: Filter events with carpool offered (true/false)
 *   - hasAvailableSeats: Filter events with available carpool seats (true/false)
 *   - search: Text search on event title and notes
 *   - sortBy: Sort order (date, popularity) - default: date
 *   - thisWeekend: Shortcut filter for this weekend's events (true/false)
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

    // Phase 3: Enhanced Search & Discovery filters
    const dateFrom = searchParams.get('dateFrom');
    const dateTo = searchParams.get('dateTo');
    const skillLevel = searchParams.get('skillLevel');
    const carpoolAvailable = searchParams.get('carpoolAvailable');
    const hasAvailableSeats = searchParams.get('hasAvailableSeats') === 'true';
    const search = searchParams.get('search')?.trim();
    const sortBy = searchParams.get('sortBy') || 'date';
    const thisWeekend = searchParams.get('thisWeekend') === 'true';

    // Check auth for user-specific queries
    const authUser = await getDualAuthUser(request);

    if ((createdByMe || attendingOnly) && !authUser) {
      return NextResponse.json(
        { error: 'Authentication required for this filter' },
        { status: 401 }
      );
    }

    // OPTIMIZATION: Use cached profileId from auth when available
    let userProfileId: string | null = null;
    if (authUser) {
      // profileId is now cached in getDualAuthUser, avoiding repeated lookups
      userProfileId = authUser.profileId || null;

      // Fallback to database lookup only if profileId not in cache (shouldn't happen for valid users)
      if (!userProfileId) {
        const adminClient = createAdminClient();
        const { data: userProfile } = await adminClient
          .from('users')
          .select('id')
          .eq('auth_user_id', authUser.userId)
          .single();
        userProfileId = userProfile?.id || null;
      }

      // Only require profile for filters that need it
      if (!userProfileId && (createdByMe || attendingOnly)) {
        return NextResponse.json(
          { error: 'User profile not found' },
          { status: 404 }
        );
      }
    }

    // OPTIMIZATION: Skip base query when attendingOnly=true (it's not needed)
    let filteredEvents: any[] = [];
    let count: number | null = null;

    if (attendingOnly && userProfileId && !createdByMe) {
      // OPTIMIZATION: Query events directly with inner join on attendees
      // This allows database-side filtering instead of fetching all events
      const today = new Date().toISOString().split('T')[0];

      // Calculate weekend dates if needed
      let weekendStart = '';
      let weekendEnd = '';
      if (thisWeekend) {
        const now = new Date();
        const dayOfWeek = now.getDay();
        const daysUntilSaturday = (6 - dayOfWeek + 7) % 7 || 7;
        const saturday = new Date(now);
        saturday.setDate(now.getDate() + (dayOfWeek === 6 ? 0 : daysUntilSaturday));
        const sunday = new Date(saturday);
        sunday.setDate(saturday.getDate() + 1);
        weekendStart = saturday.toISOString().split('T')[0];
        weekendEnd = sunday.toISOString().split('T')[0];
      }

      // Build query with database-side filters
      let attendeeQuery = supabase
        .from('event_attendees')
        .select(`
          status,
          event:event_id!inner (
            id,
            user_id,
            mountain_id,
            title,
            notes,
            event_date,
            departure_time,
            departure_location,
            skill_level,
            carpool_available,
            carpool_seats,
            max_attendees,
            status,
            created_at,
            updated_at,
            attendee_count,
            going_count,
            maybe_count,
            waitlist_count,
            creator:user_id (
              id,
              username,
              display_name,
              avatar_url,
              riding_style
            )
          )
        `, { count: 'exact' })
        .eq('user_id', userProfileId)
        .in('status', ['going', 'maybe']);

      // Push filters to the database query using the !inner join
      // Note: Supabase allows filtering on joined tables with dot notation
      attendeeQuery = attendeeQuery.eq('event.status', status);

      if (mountainId) {
        attendeeQuery = attendeeQuery.eq('event.mountain_id', mountainId);
      }

      if (skillLevel) {
        attendeeQuery = attendeeQuery.eq('event.skill_level', skillLevel);
      }

      if (carpoolAvailable === 'true') {
        attendeeQuery = attendeeQuery.eq('event.carpool_available', true);
      }

      if (hasAvailableSeats) {
        attendeeQuery = attendeeQuery
          .eq('event.carpool_available', true)
          .gt('event.carpool_seats', 0);
      }

      // Date filters
      if (thisWeekend) {
        attendeeQuery = attendeeQuery
          .gte('event.event_date', weekendStart)
          .lte('event.event_date', weekendEnd);
      } else {
        if (dateFrom) {
          attendeeQuery = attendeeQuery.gte('event.event_date', dateFrom);
        } else if (upcoming) {
          attendeeQuery = attendeeQuery.gte('event.event_date', today);
        }
        if (dateTo) {
          attendeeQuery = attendeeQuery.lte('event.event_date', dateTo);
        }
      }

      // Text search (can be done at DB level with ilike)
      if (search) {
        attendeeQuery = attendeeQuery.or(
          `event.title.ilike.%${search}%,event.notes.ilike.%${search}%`
        );
      }

      // Apply sorting
      if (sortBy === 'popularity') {
        attendeeQuery = attendeeQuery.order('event(going_count)', { ascending: false });
      } else {
        attendeeQuery = attendeeQuery.order('event(event_date)', { ascending: true });
      }

      // Apply pagination
      attendeeQuery = attendeeQuery.range(offset, offset + limit - 1);

      const { data: attendeeEvents, error: attendeeError, count: attendeeCount } = await attendeeQuery;

      if (attendeeError) {
        console.error('Error fetching attending events:', attendeeError);
        return NextResponse.json(
          { error: 'Failed to fetch attending events' },
          { status: 500 }
        );
      }

      filteredEvents = (attendeeEvents || [])
        .filter((a: any) => a.event) // Safety filter for null events
        .map((a: any) => ({
          ...a.event,
          userRSVPStatus: a.status,
        }));

      count = attendeeCount;
    } else {
      // Build base query for non-attendingOnly requests
      let query = supabase
        .from('events')
        .select(`
          *,
          creator:user_id (
            id,
            username,
            display_name,
            avatar_url,
            riding_style
          )
        `, { count: 'exact' })
        .eq('status', status)
        .range(offset, offset + limit - 1);

      // Apply filters
      if (mountainId) {
        query = query.eq('mountain_id', mountainId);
      }

      // Date filters
      if (thisWeekend) {
        // Calculate this weekend's date range (Saturday-Sunday)
        const now = new Date();
        const dayOfWeek = now.getDay();
        const daysUntilSaturday = (6 - dayOfWeek + 7) % 7 || 7; // If today is Saturday, show this weekend
        const saturday = new Date(now);
        saturday.setDate(now.getDate() + (dayOfWeek === 6 ? 0 : daysUntilSaturday));
        const sunday = new Date(saturday);
        sunday.setDate(saturday.getDate() + 1);

        const saturdayStr = saturday.toISOString().split('T')[0];
        const sundayStr = sunday.toISOString().split('T')[0];
        query = query.gte('event_date', saturdayStr).lte('event_date', sundayStr);
      } else {
        if (dateFrom) {
          query = query.gte('event_date', dateFrom);
        } else if (upcoming) {
          const today = new Date().toISOString().split('T')[0];
          query = query.gte('event_date', today);
        }

        if (dateTo) {
          query = query.lte('event_date', dateTo);
        }
      }

      // Skill level filter
      if (skillLevel) {
        query = query.eq('skill_level', skillLevel);
      }

      // Carpool filters
      if (carpoolAvailable === 'true') {
        query = query.eq('carpool_available', true);
      }

      if (hasAvailableSeats) {
        // Filter events with available carpool seats
        query = query.eq('carpool_available', true).gt('carpool_seats', 0);
      }

      // Text search on title and notes
      if (search) {
        // Use ilike for case-insensitive partial match
        query = query.or(`title.ilike.%${search}%,notes.ilike.%${search}%`);
      }

      if (createdByMe && userProfileId) {
        query = query.eq('user_id', userProfileId);
      }

      // Apply sorting
      if (sortBy === 'popularity') {
        query = query.order('going_count', { ascending: false });
      } else {
        // Default: sort by date
        query = query.order('event_date', { ascending: true });
      }

      const { data: events, error, count: queryCount } = await query;

      if (error) {
        console.error('Error fetching events:', error);
        return NextResponse.json(
          { error: 'Failed to fetch events' },
          { status: 500 }
        );
      }

      filteredEvents = events || [];
      count = queryCount;
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
        maxAttendees: event.max_attendees ?? null,
        status: event.status,
        createdAt: event.created_at,
        updatedAt: event.updated_at,
        attendeeCount: event.attendee_count,
        goingCount: event.going_count,
        maybeCount: event.maybe_count,
        waitlistCount: event.waitlist_count ?? 0,
        creator: event.creator,
        userRSVPStatus: event.userRSVPStatus || null,
        isCreator: userProfileId ? event.user_id === userProfileId : false,
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

    // Add cache headers for better performance
    // Events list can be cached for 60 seconds with stale-while-revalidate
    return NextResponse.json(response, {
      headers: {
        'Cache-Control': 'public, max-age=60, stale-while-revalidate=120',
      },
    });
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
 *   - maxAttendees: Maximum capacity for the event (optional, 1-1000)
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

    // Rate limiting: 10 events per hour per user
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
      maxAttendees,
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

    // Validate max attendees
    if (maxAttendees !== undefined && maxAttendees !== null && (maxAttendees < 1 || maxAttendees > 1000)) {
      return NextResponse.json(
        { error: 'Max attendees must be between 1 and 1000' },
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

    // Look up the internal users.id from auth_user_id
    // The events.user_id foreign key references users.id, not users.auth_user_id
    const { data: userProfile, error: userError } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (userError || !userProfile) {
      console.error('Error finding user profile:', userError);
      return NextResponse.json(
        { error: 'User profile not found. Please try signing out and back in.' },
        { status: 404 }
      );
    }

    // Create event using admin client to bypass RLS for initial insert
    const { data: event, error: insertError } = await adminClient
      .from('events')
      .insert({
        user_id: userProfile.id,  // Use users.id, not auth_user_id
        mountain_id: mountainId,
        title: title.trim(),
        notes: notes?.trim() || null,
        event_date: eventDate,
        departure_time: departureTime ? `${departureTime}:00` : null,
        departure_location: departureLocation?.trim() || null,
        skill_level: skillLevel || null,
        carpool_available: carpoolAvailable,
        carpool_seats: carpoolSeats || null,
        max_attendees: maxAttendees || null,
      })
      .select(`
        *,
        creator:user_id (
          id,
          username,
          display_name,
          avatar_url,
          riding_style
        )
      `)
      .single();

    if (insertError) {
      console.error('Error creating event:', JSON.stringify(insertError, null, 2));
      console.error('Insert payload:', JSON.stringify({
        user_id: userProfile.id,
        mountain_id: mountainId,
        title: title.trim(),
        event_date: eventDate,
      }));
      return NextResponse.json(
        { error: `Failed to create event: ${insertError.message || 'Unknown error'}` },
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
        created_by: userProfile.id,  // Use users.id, not auth_user_id
        expires_at: null, // No expiration by default
        max_uses: null, // Unlimited uses by default
      });

    if (tokenError) {
      console.error('Error creating invite token:', tokenError);
      // Don't fail the whole request, event was created successfully
    }

    // Auto-RSVP creator as 'going' so they appear in attendee list
    const { error: rsvpError } = await adminClient
      .from('event_attendees')
      .insert({
        event_id: event.id,
        user_id: userProfile.id,
        status: 'going',
        is_driver: carpoolAvailable,
        needs_ride: false,
        responded_at: new Date().toISOString(),
      });

    if (rsvpError) {
      console.error('Error auto-RSVPing creator:', rsvpError);
      // Don't fail the whole request, event was created successfully
    }

    // Fetch updated counts after auto-RSVP
    const { data: updatedEvent } = await adminClient
      .from('events')
      .select('attendee_count, going_count, maybe_count')
      .eq('id', event.id)
      .single();

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
      maxAttendees: event.max_attendees,
      status: event.status,
      createdAt: event.created_at,
      updatedAt: event.updated_at,
      attendeeCount: updatedEvent?.attendee_count ?? event.attendee_count,
      goingCount: updatedEvent?.going_count ?? event.going_count,
      maybeCount: updatedEvent?.maybe_count ?? event.maybe_count,
      waitlistCount: event.waitlist_count ?? 0,
      creator: event.creator,
      userRSVPStatus: 'going',  // Creator is auto-RSVP'd as going
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
