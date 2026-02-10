import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { getMountain } from '@shredders/shared';
import type {
  UpdateEventRequest,
  EventWithDetails,
  EventResponse,
  EventAttendee,
  EventConditions,
} from '@/types/event';
import {
  sendEventCancellationNotification,
  sendEventUpdateNotification,
} from '@/lib/push/event-notifications';

/**
 * GET /api/events/[id]
 *
 * Get event details with attendees and conditions
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const supabase = await createClient();
    const authUser = await getDualAuthUser(request);

    // Fetch event with creator info
    const { data: event, error } = await supabase
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
      `)
      .eq('id', id)
      .single();

    if (error || !event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    const mountain = getMountain(event.mountain_id);

    // OPTIMIZATION: Use cached profileId from auth when available
    let userProfileId: string | null = null;
    if (authUser) {
      userProfileId = authUser.profileId || null;

      // Fallback to database lookup only if profileId not in cache
      if (!userProfileId) {
        const adminClient = createAdminClient();
        const { data: userProfile } = await adminClient
          .from('users')
          .select('id')
          .eq('auth_user_id', authUser.userId)
          .single();
        userProfileId = userProfile?.id || null;
      }
    }

    // Build conditions URL
    const baseUrl = process.env.VERCEL_URL
      ? `https://${process.env.VERCEL_URL}`
      : process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000';

    // OPTIMIZATION: Run all independent queries in parallel using Promise.allSettled
    const [
      attendeesResult,
      userRSVPResult,
      inviteTokenResult,
      conditionsResult,
      commentCountResult,
      photoCountResult,
    ] = await Promise.allSettled([
      // 1. Fetch attendees - OPTIMIZATION: Select only needed columns
      supabase
        .from('event_attendees')
        .select(`
          id,
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
            avatar_url,
            riding_style
          )
        `)
        .eq('event_id', id)
        .in('status', ['going', 'maybe'])
        .order('responded_at', { ascending: true }),

      // 2. Get user's RSVP status (if authenticated)
      // NOTE: Use adminClient to bypass RLS - regular client may not see user's own RSVP
      userProfileId
        ? createAdminClient()
            .from('event_attendees')
            .select('status')
            .eq('event_id', id)
            .eq('user_id', userProfileId)
            .single()
        : Promise.resolve({ data: null }),

      // 3. Get invite token (if user is the creator)
      userProfileId && event.user_id === userProfileId
        ? supabase
            .from('event_invite_tokens')
            .select('token')
            .eq('event_id', id)
            .single()
        : Promise.resolve({ data: null }),

      // 4. Fetch mountain conditions
      mountain
        ? fetch(`${baseUrl}/api/mountains/${event.mountain_id}/all`, {
            headers: { 'Accept': 'application/json' },
            next: { revalidate: 600 },
          })
        : Promise.resolve(null),

      // 5. Comment count
      supabase
        .from('event_comments')
        .select('*', { count: 'exact', head: true })
        .eq('event_id', id)
        .eq('is_deleted', false),

      // 6. Photo count
      supabase
        .from('event_photos')
        .select('*', { count: 'exact', head: true })
        .eq('event_id', id),
    ]);

    // Extract results from Promise.allSettled
    const attendees = attendeesResult.status === 'fulfilled'
      ? attendeesResult.value.data
      : null;

    if (attendeesResult.status === 'rejected' || (attendeesResult.status === 'fulfilled' && attendeesResult.value.error)) {
      console.error('Error fetching attendees:', attendeesResult.status === 'rejected' ? attendeesResult.reason : attendeesResult.value.error);
    }

    const userRSVPStatus = userRSVPResult.status === 'fulfilled'
      ? userRSVPResult.value?.data?.status || null
      : null;

    const inviteToken = inviteTokenResult.status === 'fulfilled'
      ? inviteTokenResult.value?.data?.token || null
      : null;

    // Parse conditions response
    let conditions: EventConditions | undefined;
    if (conditionsResult.status === 'fulfilled' && conditionsResult.value) {
      try {
        const conditionsRes = conditionsResult.value as Response;
        if (conditionsRes.ok) {
          const data = await conditionsRes.json();
          conditions = {
            temperature: data.conditions?.temperature,
            snowfall24h: data.conditions?.snowfall24h,
            snowDepth: data.conditions?.snowDepth,
            powderScore: data.powderScore?.score,
            forecast: data.forecast?.[0] ? {
              high: data.forecast[0].high,
              low: data.forecast[0].low,
              snowfall: data.forecast[0].snowfall || 0,
              conditions: data.forecast[0].conditions,
            } : undefined,
          };
        }
      } catch (conditionsError) {
        console.error('Error parsing conditions:', conditionsError);
      }
    }

    const commentCount = commentCountResult.status === 'fulfilled'
      ? commentCountResult.value.count
      : 0;

    const photoCount = photoCountResult.status === 'fulfilled'
      ? photoCountResult.value.count
      : 0;

    // Transform attendees
    const transformedAttendees: EventAttendee[] = (attendees || []).map((a: any) => ({
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

    // Transform to API response
    const eventWithDetails: EventWithDetails = {
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
      commentCount: commentCount ?? 0,
      photoCount: photoCount ?? 0,
      creator: event.creator,
      userRSVPStatus,
      isCreator: userProfileId ? event.user_id === userProfileId : false,
      attendees: transformedAttendees,
      conditions,
      inviteToken: inviteToken || undefined,
    };

    const response: EventResponse = {
      event: eventWithDetails,
    };

    // Add cache headers - event details can be cached for 5 minutes
    // with stale-while-revalidate for better UX during updates
    return NextResponse.json(response, {
      headers: {
        'Cache-Control': 'public, max-age=300, stale-while-revalidate=600',
      },
    });
  } catch (error) {
    console.error('Error in GET /api/events/[id]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * PATCH /api/events/[id]
 *
 * Update an event (creator only)
 */
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
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

    // Check if event exists and user is the creator
    // Fetch additional fields needed for change detection and validation
    const { data: existingEvent, error: fetchError } = await supabase
      .from('events')
      .select('user_id, title, mountain_id, event_date, departure_time, departure_location, going_count, max_attendees, status')
      .eq('id', id)
      .single();

    if (fetchError || !existingEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // Block editing cancelled or completed events
    if (existingEvent.status === 'cancelled') {
      return NextResponse.json(
        { error: 'Cannot edit a cancelled event. Reactivate it first or clone it.' },
        { status: 400 }
      );
    }

    if (existingEvent.status === 'completed') {
      return NextResponse.json(
        { error: 'Cannot edit a completed event' },
        { status: 400 }
      );
    }

    // Look up the internal users.id from auth_user_id
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

    if (existingEvent.user_id !== userProfile.id) {
      return NextResponse.json(
        { error: 'You can only edit your own events' },
        { status: 403 }
      );
    }

    const body: UpdateEventRequest = await request.json();
    const updates: Record<string, any> = {};

    // Only update provided fields
    if (body.title !== undefined) {
      if (body.title.trim().length < 3) {
        return NextResponse.json(
          { error: 'Title must be at least 3 characters' },
          { status: 400 }
        );
      }
      if (body.title.length > 100) {
        return NextResponse.json(
          { error: 'Title must be less than 100 characters' },
          { status: 400 }
        );
      }
      updates.title = body.title.trim();
    }

    if (body.notes !== undefined) {
      if (body.notes && body.notes.length > 2000) {
        return NextResponse.json(
          { error: 'Notes must be less than 2000 characters' },
          { status: 400 }
        );
      }
      updates.notes = body.notes?.trim() || null;
    }

    if (body.eventDate !== undefined) {
      const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
      if (body.eventDate < today) {
        return NextResponse.json(
          { error: 'Event date cannot be in the past' },
          { status: 400 }
        );
      }
      updates.event_date = body.eventDate;
    }

    if (body.departureTime !== undefined) {
      if (body.departureTime && !/^\d{2}:\d{2}$/.test(body.departureTime)) {
        return NextResponse.json(
          { error: 'Departure time must be in HH:MM format' },
          { status: 400 }
        );
      }
      updates.departure_time = body.departureTime ? `${body.departureTime}:00` : null;
    }

    if (body.departureLocation !== undefined) {
      updates.departure_location = body.departureLocation?.trim() || null;
    }

    if (body.skillLevel !== undefined) {
      const validSkillLevels = ['beginner', 'intermediate', 'advanced', 'expert', 'all'];
      if (body.skillLevel && !validSkillLevels.includes(body.skillLevel)) {
        return NextResponse.json(
          { error: 'Invalid skill level' },
          { status: 400 }
        );
      }
      updates.skill_level = body.skillLevel;
    }

    if (body.carpoolAvailable !== undefined) {
      updates.carpool_available = body.carpoolAvailable;
    }

    if (body.carpoolSeats !== undefined) {
      if (body.carpoolSeats !== null && (body.carpoolSeats < 0 || body.carpoolSeats > 8)) {
        return NextResponse.json(
          { error: 'Carpool seats must be between 0 and 8' },
          { status: 400 }
        );
      }
      updates.carpool_seats = body.carpoolSeats;
    }

    if (body.maxAttendees !== undefined) {
      // Validate range
      if (body.maxAttendees !== null && (body.maxAttendees < 1 || body.maxAttendees > 1000)) {
        return NextResponse.json(
          { error: 'Max attendees must be between 1 and 1000' },
          { status: 400 }
        );
      }
      // Prevent setting below current going count (would strand existing attendees)
      if (body.maxAttendees !== null && existingEvent.going_count > body.maxAttendees) {
        return NextResponse.json(
          { error: `Cannot set capacity below current attendees (${existingEvent.going_count} going)` },
          { status: 400 }
        );
      }
      updates.max_attendees = body.maxAttendees;
    }

    if (Object.keys(updates).length === 0) {
      return NextResponse.json(
        { error: 'No valid fields to update' },
        { status: 400 }
      );
    }

    // Update event
    const { data: updatedEvent, error: updateError } = await adminClient
      .from('events')
      .update(updates)
      .eq('id', id)
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

    if (updateError) {
      console.error('Error updating event:', updateError);
      return NextResponse.json(
        { error: 'Failed to update event' },
        { status: 500 }
      );
    }

    const mountain = getMountain(updatedEvent.mountain_id);

    // Send update notifications for important changes (async, don't block response)
    const dateChanged = existingEvent.event_date !== updatedEvent.event_date;
    const timeChanged = existingEvent.departure_time !== updatedEvent.departure_time;
    const locationChanged = existingEvent.departure_location !== updatedEvent.departure_location;

    if (dateChanged || timeChanged || locationChanged) {
      // Build a human-readable change description
      const changes: string[] = [];
      if (dateChanged) {
        const dateFormatter = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric' });
        const newDate = new Date(updatedEvent.event_date + 'T12:00:00');
        changes.push(`Date changed to ${dateFormatter.format(newDate)}`);
      }
      if (timeChanged && updatedEvent.departure_time) {
        const [hours, minutes] = updatedEvent.departure_time.split(':');
        const hour = parseInt(hours, 10);
        const ampm = hour >= 12 ? 'PM' : 'AM';
        const hour12 = hour % 12 || 12;
        changes.push(`Time updated to ${hour12}:${minutes} ${ampm}`);
      }
      if (locationChanged && updatedEvent.departure_location) {
        changes.push(`Location changed to ${updatedEvent.departure_location}`);
      }

      sendEventUpdateNotification({
        eventId: id,
        eventTitle: updatedEvent.title,
        mountainName: mountain?.name || updatedEvent.mountain_id,
        changeDescription: changes.join(', '),
        updatedByUserId: userProfile.id,
      }).catch((err) => console.error('Failed to send update notifications:', err));
    }

    return NextResponse.json({
      event: {
        id: updatedEvent.id,
        creatorId: updatedEvent.user_id,
        mountainId: updatedEvent.mountain_id,
        mountainName: mountain?.name,
        title: updatedEvent.title,
        notes: updatedEvent.notes,
        eventDate: updatedEvent.event_date,
        departureTime: updatedEvent.departure_time,
        departureLocation: updatedEvent.departure_location,
        skillLevel: updatedEvent.skill_level,
        carpoolAvailable: updatedEvent.carpool_available,
        carpoolSeats: updatedEvent.carpool_seats,
        maxAttendees: updatedEvent.max_attendees,
        status: updatedEvent.status,
        createdAt: updatedEvent.created_at,
        updatedAt: updatedEvent.updated_at,
        attendeeCount: updatedEvent.attendee_count,
        goingCount: updatedEvent.going_count,
        maybeCount: updatedEvent.maybe_count,
        waitlistCount: updatedEvent.waitlist_count ?? 0,
        creator: updatedEvent.creator,
        isCreator: true,
      },
    });
  } catch (error) {
    console.error('Error in PATCH /api/events/[id]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/events/[id]
 *
 * Cancel an event (creator only)
 * Note: Uses soft delete by setting status to 'cancelled'
 */
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
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

    // Check if event exists and user is the creator
    const { data: existingEvent, error: fetchError } = await supabase
      .from('events')
      .select('user_id, title, mountain_id, event_date, status')
      .eq('id', id)
      .single();

    if (fetchError || !existingEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // Prevent double-cancellation (would send duplicate notifications)
    if (existingEvent.status === 'cancelled') {
      return NextResponse.json(
        { error: 'Event is already cancelled' },
        { status: 400 }
      );
    }

    // Prevent cancelling completed events
    if (existingEvent.status === 'completed') {
      return NextResponse.json(
        { error: 'Cannot cancel a completed event' },
        { status: 400 }
      );
    }

    // Prevent cancelling past events
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
    if (existingEvent.event_date < today) {
      return NextResponse.json(
        { error: 'Cannot cancel a past event' },
        { status: 400 }
      );
    }

    // Look up the internal users.id from auth_user_id
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

    if (existingEvent.user_id !== userProfile.id) {
      return NextResponse.json(
        { error: 'You can only cancel your own events' },
        { status: 403 }
      );
    }

    // Soft delete by setting status to cancelled
    const { error: updateError } = await adminClient
      .from('events')
      .update({ status: 'cancelled' })
      .eq('id', id);

    if (updateError) {
      console.error('Error cancelling event:', updateError);
      return NextResponse.json(
        { error: 'Failed to cancel event' },
        { status: 500 }
      );
    }

    // Send cancellation notifications to attendees (async, don't block response)
    const mountain = getMountain(existingEvent.mountain_id);
    sendEventCancellationNotification({
      eventId: id,
      eventTitle: existingEvent.title,
      mountainName: mountain?.name || existingEvent.mountain_id,
      eventDate: existingEvent.event_date,
      cancelledByUserId: userProfile.id,
    }).catch((err) => console.error('Failed to send cancellation notifications:', err));

    return NextResponse.json({ message: 'Event cancelled successfully' });
  } catch (error) {
    console.error('Error in DELETE /api/events/[id]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
