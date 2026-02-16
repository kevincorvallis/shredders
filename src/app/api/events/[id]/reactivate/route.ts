import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';
import { getMountain } from '@shredders/shared';
import type { Event } from '@/types/event';
import { sendEventUpdateNotification, sendEventReactivationNotification } from '@/lib/push/event-notifications';

/**
 * POST /api/events/[id]/reactivate
 *
 * Reactivate a cancelled event (creator only)
 * Only allowed if event date is in the future
 */
export const POST = withDualAuth(async (
  request, authUser, { params }: { params: Promise<{ id: string }> }
) => {
  try {
    const { id: eventId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

    // Look up user profile
    const { data: userProfile, error: userError } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (userError || !userProfile) {
      return handleError(Errors.resourceNotFound('User profile'));
    }

    // Fetch event
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return handleError(Errors.resourceNotFound('Event'));
    }

    // Check if user is the creator
    if (event.user_id !== userProfile.id) {
      return handleError(Errors.forbidden('Only the event creator can reactivate it'));
    }

    // Check if event is cancelled
    if (event.status !== 'cancelled') {
      return NextResponse.json(
        { error: 'Only cancelled events can be reactivated' },
        { status: 400 }
      );
    }

    // Check if event date is in the future
    const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
    if (event.event_date < today) {
      return NextResponse.json(
        { error: 'Cannot reactivate a past event. Consider cloning it instead.' },
        { status: 400 }
      );
    }

    // Reactivate the event
    const { data: updatedEvent, error: updateError } = await adminClient
      .from('events')
      .update({ status: 'active' })
      .eq('id', eventId)
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
      console.error('Error reactivating event:', updateError);
      return handleError(Errors.databaseError());
    }

    const mountain = getMountain(updatedEvent.mountain_id);

    // Notify ALL previous attendees (including waitlisted) that the event is back on
    sendEventReactivationNotification({
      eventId,
      eventTitle: updatedEvent.title,
      mountainName: mountain?.name || updatedEvent.mountain_id,
      reactivatedByUserId: userProfile.id,
    }).catch((err) => console.error('Failed to send reactivation notifications:', err));

    const transformedEvent: Event = {
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
    };

    return NextResponse.json({
      message: 'Event reactivated successfully',
      event: transformedEvent,
    });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/events/[id]/reactivate' });
  }
});
