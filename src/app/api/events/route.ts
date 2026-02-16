import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser, withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';
import { getMountain } from '@shredders/shared';
import { randomBytes } from 'crypto';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import { getUserProfileId } from '@/lib/auth/get-user-id';
import { parseEventFilterParams, applyEventFilters } from '@/lib/events/event-query-builder';
import {
  validateTitle,
  validateNotes,
  validateEventDate,
  validateSkillLevel,
  validateCarpoolSeats,
  validateMaxAttendees,
  validateDepartureTime,
} from '@/lib/events/event-validators';
import type {
  CreateEventRequest,
  Event,
  EventsListResponse,
  CreateEventResponse,
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
    const filters = parseEventFilterParams(searchParams);

    // Check auth for user-specific queries
    const authUser = await getDualAuthUser(request);

    if ((filters.createdByMe || filters.attendingOnly) && !authUser) {
      return handleError(Errors.unauthorized('Authentication required for this filter'));
    }

    // Resolve internal user profile ID when authenticated
    let userProfileId: string | null = null;
    if (authUser) {
      try {
        userProfileId = await getUserProfileId(authUser);
      } catch {
        if (filters.createdByMe || filters.attendingOnly) {
          return handleError(Errors.resourceNotFound('User profile'));
        }
      }
    }

    // OPTIMIZATION: Skip base query when attendingOnly=true (it's not needed)
    let filteredEvents: any[] = [];
    let count: number | null = null;

    if (filters.attendingOnly && userProfileId && !filters.createdByMe) {
      // Query events via inner join on attendees for database-side filtering
      let attendeeQuery = supabase
        .from('event_attendees')
        .select(`
          status,
          event:event_id!inner (
            id, user_id, mountain_id, title, notes, event_date,
            departure_time, departure_location, skill_level,
            carpool_available, carpool_seats, max_attendees, status,
            created_at, updated_at, attendee_count, going_count,
            maybe_count, waitlist_count,
            creator:user_id (
              id, username, display_name, avatar_url, experience_level
            )
          )
        `, { count: 'exact' })
        .eq('user_id', userProfileId)
        .in('status', ['going', 'maybe']);

      attendeeQuery = attendeeQuery.eq('event.status', filters.status);
      attendeeQuery = applyEventFilters(attendeeQuery, filters, 'event.');
      attendeeQuery = attendeeQuery.range(filters.offset, filters.offset + filters.limit - 1);

      const { data: attendeeEvents, error: attendeeError, count: attendeeCount } = await attendeeQuery;

      if (attendeeError) {
        console.error('Error fetching attending events:', attendeeError);
        return handleError(Errors.databaseError());
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
            id, username, display_name, avatar_url, experience_level
          )
        `, { count: 'exact' })
        .eq('status', filters.status)
        .range(filters.offset, filters.offset + filters.limit - 1);

      query = applyEventFilters(query, filters);

      if (filters.createdByMe && userProfileId) {
        query = query.eq('user_id', userProfileId);
      }

      const { data: events, error, count: queryCount } = await query;

      if (error) {
        console.error('Error fetching events:', error);
        return handleError(Errors.databaseError());
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
        limit: filters.limit,
        offset: filters.offset,
        hasMore: (count || 0) > filters.offset + filters.limit,
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
    return handleError(error, { endpoint: 'GET /api/events' });
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
export const POST = withDualAuth(async (request, authUser) => {
  try {
    const adminClient = createAdminClient();

    // Rate limiting: 10 events per hour per user
    const rateLimitKey = createRateLimitKey(authUser.userId, 'createEvent');
    const rateLimit = await rateLimitEnhanced(rateLimitKey, 'createEvent');

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

    // Validate mountain
    if (!mountainId) {
      return NextResponse.json({ error: 'Mountain ID is required' }, { status: 400 });
    }
    const mountain = getMountain(mountainId);
    if (!mountain) {
      return handleError(Errors.resourceNotFound('Mountain'));
    }

    // Validate other fields
    const titleError = validateTitle(title);
    if (titleError) return titleError;

    const notesError = validateNotes(notes);
    if (notesError) return notesError;

    const dateError = validateEventDate(eventDate);
    if (dateError) return dateError;

    const skillError = validateSkillLevel(skillLevel);
    if (skillError) return skillError;

    const seatsError = validateCarpoolSeats(carpoolSeats);
    if (seatsError) return seatsError;

    const attendeesError = validateMaxAttendees(maxAttendees);
    if (attendeesError) return attendeesError;

    const timeError = validateDepartureTime(departureTime);
    if (timeError) return timeError;

    // Resolve internal users.id (foreign keys reference users.id, not auth_user_id)
    const userProfileId = await getUserProfileId(authUser);

    // Create event using admin client to bypass RLS for initial insert
    const { data: event, error: insertError } = await adminClient
      .from('events')
      .insert({
        user_id: userProfileId,
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
          experience_level
        )
      `)
      .single();

    if (insertError) {
      console.error('Error creating event:', JSON.stringify(insertError, null, 2));
      console.error('Insert payload:', JSON.stringify({
        user_id: userProfileId,
        mountain_id: mountainId,
        title: title.trim(),
        event_date: eventDate,
      }));
      return handleError(Errors.databaseError());
    }

    // Generate invite token
    const token = randomBytes(16).toString('hex');

    const { error: tokenError } = await adminClient
      .from('event_invite_tokens')
      .insert({
        event_id: event.id,
        token,
        created_by: userProfileId,
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
        user_id: userProfileId,
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
    return handleError(error, { endpoint: 'POST /api/events' });
  }
});
