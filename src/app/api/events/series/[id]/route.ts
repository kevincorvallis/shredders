import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import type { AuthenticatedUser } from '@/lib/auth';
import { getMountain } from '@shredders/shared';
import { Errors, handleError } from '@/lib/errors';
import { sendEventCancellationNotification } from '@/lib/push/event-notifications';
import type { EventSeries, RecurrencePattern } from '../route';

/**
 * GET /api/events/series/[id]
 *
 * Get details of a specific event series including upcoming events
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: seriesId } = await params;
    const supabase = await createClient();

    const { data: series, error } = await supabase
      .from('event_series')
      .select('*')
      .eq('id', seriesId)
      .single();

    if (error || !series) {
      return handleError(Errors.resourceNotFound('Series'));
    }

    // Fetch upcoming events for this series
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
    const { data: events } = await supabase
      .from('events')
      .select(`
        id,
        title,
        event_date,
        status,
        going_count,
        maybe_count,
        is_series_exception
      `)
      .eq('series_id', seriesId)
      .gte('event_date', today)
      .order('event_date', { ascending: true })
      .limit(10);

    const mountain = getMountain(series.mountain_id);

    const transformedSeries: EventSeries = {
      id: series.id,
      creatorId: series.user_id,
      mountainId: series.mountain_id,
      mountainName: mountain?.name,
      title: series.title,
      notes: series.notes,
      departureTime: series.departure_time,
      departureLocation: series.departure_location,
      skillLevel: series.skill_level,
      carpoolAvailable: series.carpool_available,
      carpoolSeats: series.carpool_seats,
      maxAttendees: series.max_attendees,
      recurrencePattern: series.recurrence_pattern,
      dayOfWeek: series.day_of_week,
      dayOfMonth: series.day_of_month,
      weekOfMonth: series.week_of_month,
      startDate: series.start_date,
      endDate: series.end_date,
      status: series.status,
      createdAt: series.created_at,
      updatedAt: series.updated_at,
    };

    return NextResponse.json({
      series: transformedSeries,
      upcomingEvents: events || [],
    });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/events/series/[id]' });
  }
}

/**
 * PATCH /api/events/series/[id]
 *
 * Update a series. Updates apply to future events only.
 * Set updateFutureEvents=true to update all future non-exception events.
 */
export const PATCH = withDualAuth(async (
  request: NextRequest,
  authUser: AuthenticatedUser,
  { params }: { params: Promise<{ id: string }> }
) => {
  try {
    const { id: seriesId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.resourceNotFound('User profile'));
    }

    // Verify series exists and user owns it
    const { data: series, error: seriesError } = await supabase
      .from('event_series')
      .select('*')
      .eq('id', seriesId)
      .single();

    if (seriesError || !series) {
      return handleError(Errors.resourceNotFound('Series'));
    }

    if (series.user_id !== userProfile.id) {
      return handleError(Errors.forbidden('Only the series creator can update it'));
    }

    const body = await request.json();
    const {
      title,
      notes,
      departureTime,
      departureLocation,
      skillLevel,
      carpoolAvailable,
      carpoolSeats,
      maxAttendees,
      endDate,
      status,
      updateFutureEvents = false,
    } = body;

    // Build update object
    const updateData: Record<string, unknown> = {};

    if (title !== undefined) updateData.title = title.trim();
    if (notes !== undefined) updateData.notes = notes?.trim() || null;
    if (departureTime !== undefined) updateData.departure_time = departureTime ? `${departureTime}:00` : null;
    if (departureLocation !== undefined) updateData.departure_location = departureLocation?.trim() || null;
    if (skillLevel !== undefined) updateData.skill_level = skillLevel || null;
    if (carpoolAvailable !== undefined) updateData.carpool_available = carpoolAvailable;
    if (carpoolSeats !== undefined) updateData.carpool_seats = carpoolSeats || null;
    if (maxAttendees !== undefined) updateData.max_attendees = maxAttendees || null;
    if (endDate !== undefined) updateData.end_date = endDate || null;
    if (status !== undefined) {
      const validSeriesStatuses = ['active', 'paused', 'ended'];
      if (!validSeriesStatuses.includes(status)) {
        return NextResponse.json(
          { error: 'Invalid series status. Must be active, paused, or ended.' },
          { status: 400 }
        );
      }
      updateData.status = status;
    }

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json(
        { error: 'No fields to update' },
        { status: 400 }
      );
    }

    // Update series
    const { data: updatedSeries, error: updateError } = await adminClient
      .from('event_series')
      .update(updateData)
      .eq('id', seriesId)
      .select()
      .single();

    if (updateError) {
      console.error('Error updating series:', updateError);
      return handleError(Errors.databaseError());
    }

    // Optionally update future events
    let updatedEventsCount = 0;
    if (updateFutureEvents) {
      const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });

      // Build event update (only fields that apply to events)
      const eventUpdateData: Record<string, unknown> = {};
      if (title !== undefined) eventUpdateData.title = title.trim();
      if (notes !== undefined) eventUpdateData.notes = notes?.trim() || null;
      if (departureTime !== undefined) eventUpdateData.departure_time = departureTime ? `${departureTime}:00` : null;
      if (departureLocation !== undefined) eventUpdateData.departure_location = departureLocation?.trim() || null;
      if (skillLevel !== undefined) eventUpdateData.skill_level = skillLevel || null;
      if (carpoolAvailable !== undefined) eventUpdateData.carpool_available = carpoolAvailable;
      if (carpoolSeats !== undefined) eventUpdateData.carpool_seats = carpoolSeats || null;
      if (maxAttendees !== undefined) eventUpdateData.max_attendees = maxAttendees || null;

      if (Object.keys(eventUpdateData).length > 0) {
        const { data: updatedEvents, error: eventsError } = await adminClient
          .from('events')
          .update(eventUpdateData)
          .eq('series_id', seriesId)
          .eq('is_series_exception', false)
          .gte('event_date', today)
          .eq('status', 'active')
          .select('id');

        if (eventsError) {
          console.error('Error updating future events:', eventsError);
        } else {
          updatedEventsCount = updatedEvents?.length || 0;
        }
      }
    }

    const mountain = getMountain(updatedSeries.mountain_id);

    const transformedSeries: EventSeries = {
      id: updatedSeries.id,
      creatorId: updatedSeries.user_id,
      mountainId: updatedSeries.mountain_id,
      mountainName: mountain?.name,
      title: updatedSeries.title,
      notes: updatedSeries.notes,
      departureTime: updatedSeries.departure_time,
      departureLocation: updatedSeries.departure_location,
      skillLevel: updatedSeries.skill_level,
      carpoolAvailable: updatedSeries.carpool_available,
      carpoolSeats: updatedSeries.carpool_seats,
      maxAttendees: updatedSeries.max_attendees,
      recurrencePattern: updatedSeries.recurrence_pattern,
      dayOfWeek: updatedSeries.day_of_week,
      dayOfMonth: updatedSeries.day_of_month,
      weekOfMonth: updatedSeries.week_of_month,
      startDate: updatedSeries.start_date,
      endDate: updatedSeries.end_date,
      status: updatedSeries.status,
      createdAt: updatedSeries.created_at,
      updatedAt: updatedSeries.updated_at,
    };

    return NextResponse.json({
      series: transformedSeries,
      updatedEventsCount,
    });
  } catch (error) {
    return handleError(error, { endpoint: 'PATCH /api/events/series/[id]' });
  }
});

/**
 * DELETE /api/events/series/[id]
 *
 * Cancel/end a series. Cancels all future events.
 */
export const DELETE = withDualAuth(async (
  request: NextRequest,
  authUser: AuthenticatedUser,
  { params }: { params: Promise<{ id: string }> }
) => {
  try {
    const { id: seriesId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.resourceNotFound('User profile'));
    }

    // Verify series exists and user owns it
    const { data: series, error: seriesError } = await supabase
      .from('event_series')
      .select('*')
      .eq('id', seriesId)
      .single();

    if (seriesError || !series) {
      return handleError(Errors.resourceNotFound('Series'));
    }

    if (series.user_id !== userProfile.id) {
      return handleError(Errors.forbidden('Only the series creator can cancel it'));
    }

    // Prevent cancelling an already-cancelled series
    if (series.status === 'ended' || series.status === 'paused') {
      return NextResponse.json(
        { error: 'Series is already cancelled' },
        { status: 400 }
      );
    }

    // Fetch future active events BEFORE cancelling so we can notify their attendees
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
    const { data: futureEvents } = await adminClient
      .from('events')
      .select('id, title, mountain_id, event_date')
      .eq('series_id', seriesId)
      .eq('status', 'active')
      .gte('event_date', today);

    // Use the cancel_series function
    const { data: cancelledCount, error: cancelError } = await adminClient
      .rpc('cancel_series', {
        p_series_id: seriesId,
      });

    if (cancelError) {
      console.error('Error cancelling series:', cancelError);
      return handleError(Errors.databaseError());
    }

    // Send cancellation notifications for each affected event (async, don't block response)
    if (futureEvents && futureEvents.length > 0) {
      const mountain = getMountain(series.mountain_id);
      for (const event of futureEvents) {
        sendEventCancellationNotification({
          eventId: event.id,
          eventTitle: event.title,
          mountainName: mountain?.name || event.mountain_id,
          eventDate: event.event_date,
          cancelledByUserId: userProfile.id,
        }).catch((err) => console.error(`Failed to send cancellation notification for series event ${event.id}:`, err));
      }
    }

    return NextResponse.json({
      message: 'Series cancelled successfully',
      cancelledEventsCount: cancelledCount || 0,
    });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/events/series/[id]' });
  }
});
