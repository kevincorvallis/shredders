import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getMountain } from '@shredders/shared';
import type { InviteInfo, InviteResponse, EventConditions } from '@/types/event';

/**
 * GET /api/events/invite/[token]
 *
 * Get event details from an invite token (public endpoint)
 * This is used for link previews and the public invite page
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ token: string }> }
) {
  try {
    const { token } = await params;
    const adminClient = createAdminClient();

    // Fetch invite token and associated event
    const { data: inviteData, error: inviteError } = await adminClient
      .from('event_invite_tokens')
      .select(`
        *,
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
      .eq('token', token)
      .single();

    if (inviteError || !inviteData) {
      return NextResponse.json(
        {
          error: 'Invalid or expired invite link',
          invite: {
            isValid: false,
            isExpired: true,
            requiresAuth: false,
            event: null,
          }
        },
        { status: 404 }
      );
    }

    const event = inviteData.event;

    // Check if token is expired
    const isExpired = inviteData.expires_at && new Date(inviteData.expires_at) < new Date();

    // Check if max uses exceeded
    const isMaxUsesExceeded = inviteData.max_uses && inviteData.uses_count >= inviteData.max_uses;

    // Check if event is still active
    const isEventInactive = event.status !== 'active';

    // Check if event date has passed
    const today = new Date().toISOString().split('T')[0];
    const isEventPast = event.event_date < today;

    const isValid = !isExpired && !isMaxUsesExceeded && !isEventInactive && !isEventPast;

    // Get mountain info
    const mountain = getMountain(event.mountain_id);

    // Fetch conditions for the event
    let conditions: EventConditions | undefined;
    if (mountain && isValid) {
      try {
        const baseUrl = process.env.VERCEL_URL
          ? `https://${process.env.VERCEL_URL}`
          : process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000';

        const conditionsRes = await fetch(`${baseUrl}/api/mountains/${event.mountain_id}/all`, {
          headers: { 'Accept': 'application/json' },
          next: { revalidate: 600 },
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
        console.error('Error fetching conditions for invite:', conditionsError);
      }
    }

    const inviteInfo: InviteInfo = {
      event: {
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
        creator: event.creator,
      },
      conditions,
      isValid,
      isExpired: isExpired || isEventPast,
      requiresAuth: true, // RSVP always requires auth
    };

    const response: InviteResponse = {
      invite: inviteInfo,
    };

    // Add cache headers for link previews
    return NextResponse.json(response, {
      headers: {
        'Cache-Control': 'public, max-age=300, s-maxage=300', // 5 minute cache
      },
    });
  } catch (error) {
    console.error('Error in GET /api/events/invite/[token]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/events/invite/[token]
 *
 * Use an invite token to RSVP (redirects to RSVP endpoint)
 * This increments the usage count and validates the token
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ token: string }> }
) {
  try {
    const { token } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();

    // Fetch invite token
    const { data: inviteData, error: inviteError } = await adminClient
      .from('event_invite_tokens')
      .select('*, event:event_id (id, status, event_date)')
      .eq('token', token)
      .single();

    if (inviteError || !inviteData) {
      return NextResponse.json(
        { error: 'Invalid or expired invite link' },
        { status: 404 }
      );
    }

    // Validate token
    const isExpired = inviteData.expires_at && new Date(inviteData.expires_at) < new Date();
    const isMaxUsesExceeded = inviteData.max_uses && inviteData.uses_count >= inviteData.max_uses;
    const event = inviteData.event;
    const isEventInactive = event.status !== 'active';
    const today = new Date().toISOString().split('T')[0];
    const isEventPast = event.event_date < today;

    if (isExpired || isMaxUsesExceeded || isEventInactive || isEventPast) {
      return NextResponse.json(
        { error: 'This invite link is no longer valid' },
        { status: 400 }
      );
    }

    // Increment usage count atomically using raw SQL to prevent race conditions
    // This ensures concurrent requests don't exceed max_uses
    const { error: incrementError } = await adminClient.rpc('increment_invite_usage', {
      token_id: inviteData.id,
      max_allowed: inviteData.max_uses || 999999,
    });

    // If the RPC doesn't exist, fall back to regular update with error handling
    if (incrementError?.code === '42883') { // function does not exist
      const { error: updateError } = await adminClient
        .from('event_invite_tokens')
        .update({ uses_count: inviteData.uses_count + 1 })
        .eq('id', inviteData.id);

      if (updateError) {
        console.error('Error incrementing invite usage:', updateError);
        return NextResponse.json(
          { error: 'Failed to process invite' },
          { status: 500 }
        );
      }
    } else if (incrementError) {
      // Check if it was a max_uses exceeded error from the RPC
      if (incrementError.message?.includes('max_uses')) {
        return NextResponse.json(
          { error: 'This invite link has reached its usage limit' },
          { status: 400 }
        );
      }
      console.error('Error incrementing invite usage:', incrementError);
      return NextResponse.json(
        { error: 'Failed to process invite' },
        { status: 500 }
      );
    }

    // Return event ID for client to use with RSVP endpoint
    return NextResponse.json({
      eventId: inviteData.event_id,
      message: 'Invite validated successfully. Use /api/events/{eventId}/rsvp to complete RSVP.',
    });
  } catch (error) {
    console.error('Error in POST /api/events/invite/[token]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
