import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { getMountain } from '@shredders/shared';
import type { EventWithDetails, EventAttendee, EventConditions, RSVPStatus } from '@/types/event';

/**
 * GET /api/events/batch
 *
 * Fetch multiple events in a single request for better performance.
 * This reduces N+1 requests when loading multiple event details.
 *
 * Query params:
 *   - ids: Comma-separated list of event IDs (required, max 20)
 */
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient();
    const authUser = await getDualAuthUser(request);
    const { searchParams } = new URL(request.url);

    const idsParam = searchParams.get('ids');
    if (!idsParam) {
      return NextResponse.json(
        { error: 'ids parameter is required' },
        { status: 400 }
      );
    }

    const ids = idsParam.split(',').map(id => id.trim()).filter(Boolean);
    if (ids.length === 0) {
      return NextResponse.json(
        { error: 'At least one event ID is required' },
        { status: 400 }
      );
    }

    if (ids.length > 20) {
      return NextResponse.json(
        { error: 'Maximum 20 event IDs allowed per request' },
        { status: 400 }
      );
    }

    // Get user profile ID if authenticated
    let userProfileId: string | null = null;
    if (authUser) {
      const adminClient = createAdminClient();
      const { data: userProfile } = await adminClient
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.userId)
        .single();
      userProfileId = userProfile?.id || null;
    }

    // Support optional status filter (defaults to active only)
    const includeStatus = searchParams.get('includeStatus');

    // Fetch all events with their creators in a single query
    let eventsQuery = supabase
      .from('events')
      .select(`
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
          avatar_url
        )
      `)
      .in('id', ids);

    // Filter out cancelled events by default
    if (!includeStatus) {
      eventsQuery = eventsQuery.neq('status', 'cancelled');
    }

    const { data: events, error: eventsError } = await eventsQuery;

    if (eventsError) {
      console.error('Error fetching batch events:', eventsError);
      return NextResponse.json(
        { error: 'Failed to fetch events' },
        { status: 500 }
      );
    }

    if (!events || events.length === 0) {
      return NextResponse.json({
        events: [],
        count: 0,
      });
    }

    const eventIds = events.map(e => e.id);

    // Batch fetch all related data in parallel
    const [
      attendeesResult,
      userRSVPsResult,
      commentCountsResult,
      photoCountsResult,
    ] = await Promise.allSettled([
      // All attendees for all events
      supabase
        .from('event_attendees')
        .select(`
          id,
          event_id,
          user_id,
          status,
          is_driver,
          needs_ride,
          pickup_location,
          responded_at,
          waitlist_position,
          user:user_id (
            id,
            username,
            display_name,
            avatar_url
          )
        `)
        .in('event_id', eventIds)
        .in('status', ['going', 'maybe'])
        .order('responded_at', { ascending: true }),

      // User's RSVPs for all events
      userProfileId
        ? supabase
            .from('event_attendees')
            .select('event_id, status')
            .in('event_id', eventIds)
            .eq('user_id', userProfileId)
        : Promise.resolve({ data: [] }),

      // Comment event_ids for per-event counting
      supabase
        .from('event_comments')
        .select('event_id')
        .in('event_id', eventIds)
        .eq('is_deleted', false),

      // Photo event_ids for per-event counting
      supabase
        .from('event_photos')
        .select('event_id')
        .in('event_id', eventIds),
    ]);

    // Extract results
    const allAttendees = attendeesResult.status === 'fulfilled'
      ? (attendeesResult.value.data || [])
      : [];

    const userRSVPs = userRSVPsResult.status === 'fulfilled'
      ? (userRSVPsResult.value.data || [])
      : [];

    // Build lookup maps for efficient access
    const attendeesByEvent = new Map<string, any[]>();
    for (const attendee of allAttendees) {
      const eventId = attendee.event_id;
      if (!attendeesByEvent.has(eventId)) {
        attendeesByEvent.set(eventId, []);
      }
      attendeesByEvent.get(eventId)!.push(attendee);
    }

    const userRSVPByEvent = new Map<string, string>();
    for (const rsvp of userRSVPs) {
      userRSVPByEvent.set(rsvp.event_id, rsvp.status);
    }

    // Build per-event comment and photo count maps
    const commentCountByEvent = new Map<string, number>();
    const allComments = commentCountsResult.status === 'fulfilled'
      ? (commentCountsResult.value.data || [])
      : [];
    for (const row of allComments) {
      commentCountByEvent.set(row.event_id, (commentCountByEvent.get(row.event_id) || 0) + 1);
    }

    const photoCountByEvent = new Map<string, number>();
    const allPhotos = photoCountsResult.status === 'fulfilled'
      ? (photoCountsResult.value.data || [])
      : [];
    for (const row of allPhotos) {
      photoCountByEvent.set(row.event_id, (photoCountByEvent.get(row.event_id) || 0) + 1);
    }

    // Transform events to response format
    const transformedEvents: EventWithDetails[] = events.map((event: any) => {
      const mountain = getMountain(event.mountain_id);
      const eventAttendees = attendeesByEvent.get(event.id) || [];

      const transformedAttendees: EventAttendee[] = eventAttendees.map((a: any) => ({
        id: a.id,
        userId: a.user_id,
        status: a.status,
        isDriver: a.is_driver,
        needsRide: a.needs_ride,
        pickupLocation: a.pickup_location,
        respondedAt: a.responded_at,
        waitlistPosition: a.waitlist_position,
        user: a.user,
      }));

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
        maxAttendees: event.max_attendees,
        status: event.status,
        createdAt: event.created_at,
        updatedAt: event.updated_at,
        attendeeCount: event.attendee_count,
        goingCount: event.going_count,
        maybeCount: event.maybe_count,
        waitlistCount: event.waitlist_count ?? 0,
        commentCount: commentCountByEvent.get(event.id) || 0,
        photoCount: photoCountByEvent.get(event.id) || 0,
        creator: event.creator,
        userRSVPStatus: (userRSVPByEvent.get(event.id) as RSVPStatus | undefined) || null,
        isCreator: userProfileId ? event.user_id === userProfileId : false,
        attendees: transformedAttendees,
      };
    });

    return NextResponse.json({
      events: transformedEvents,
      count: transformedEvents.length,
    }, {
      headers: {
        // Batch endpoint can be cached briefly
        'Cache-Control': 'public, max-age=30, stale-while-revalidate=60',
      },
    });
  } catch (error) {
    console.error('Error in GET /api/events/batch:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
