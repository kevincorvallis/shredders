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
          avatar_url
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

    // Fetch attendees
    const { data: attendees, error: attendeesError } = await supabase
      .from('event_attendees')
      .select(`
        *,
        user:user_id (
          id,
          username,
          display_name,
          avatar_url
        )
      `)
      .eq('event_id', id)
      .in('status', ['going', 'maybe'])
      .order('responded_at', { ascending: true });

    if (attendeesError) {
      console.error('Error fetching attendees:', attendeesError);
    }

    // Get user's RSVP status if authenticated
    let userRSVPStatus = null;
    let userProfileId: string | null = null;

    if (authUser) {
      // Look up the internal users.id from auth_user_id
      const adminClient = createAdminClient();
      const { data: userProfile } = await adminClient
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.userId)
        .single();

      userProfileId = userProfile?.id || null;

      if (userProfileId) {
        const { data: userAttendee } = await supabase
          .from('event_attendees')
          .select('status')
          .eq('event_id', id)
          .eq('user_id', userProfileId)
          .single();

        userRSVPStatus = userAttendee?.status || null;
      }
    }

    // Get invite token if user is the creator
    let inviteToken = null;
    if (authUser && userProfileId && event.user_id === userProfileId) {
      const { data: tokenData } = await supabase
        .from('event_invite_tokens')
        .select('token')
        .eq('event_id', id)
        .single();

      inviteToken = tokenData?.token || null;
    }

    // Fetch mountain conditions
    let conditions: EventConditions | undefined;
    const mountain = getMountain(event.mountain_id);

    if (mountain) {
      try {
        // Fetch conditions from the internal API
        const baseUrl = process.env.VERCEL_URL
          ? `https://${process.env.VERCEL_URL}`
          : process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000';

        const conditionsRes = await fetch(`${baseUrl}/api/mountains/${event.mountain_id}/all`, {
          headers: { 'Accept': 'application/json' },
          next: { revalidate: 600 }, // Cache for 10 minutes
        });

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
        console.error('Error fetching conditions:', conditionsError);
        // Continue without conditions data
      }
    }

    // Transform attendees
    const transformedAttendees: EventAttendee[] = (attendees || []).map((a: any) => ({
      id: a.id,
      userId: a.user_id,
      status: a.status,
      isDriver: a.is_driver,
      needsRide: a.needs_ride,
      pickupLocation: a.pickup_location,
      respondedAt: a.responded_at,
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
      status: event.status,
      createdAt: event.created_at,
      updatedAt: event.updated_at,
      attendeeCount: event.attendee_count,
      goingCount: event.going_count,
      maybeCount: event.maybe_count,
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

    return NextResponse.json(response);
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
    const { data: existingEvent, error: fetchError } = await supabase
      .from('events')
      .select('user_id')
      .eq('id', id)
      .single();

    if (fetchError || !existingEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
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
      const today = new Date().toISOString().split('T')[0];
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
          avatar_url
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
        status: updatedEvent.status,
        createdAt: updatedEvent.created_at,
        updatedAt: updatedEvent.updated_at,
        attendeeCount: updatedEvent.attendee_count,
        goingCount: updatedEvent.going_count,
        maybeCount: updatedEvent.maybe_count,
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
      .select('user_id')
      .eq('id', id)
      .single();

    if (fetchError || !existingEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
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

    return NextResponse.json({ message: 'Event cancelled successfully' });
  } catch (error) {
    console.error('Error in DELETE /api/events/[id]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
