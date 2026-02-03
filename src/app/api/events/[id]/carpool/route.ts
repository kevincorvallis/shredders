import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';

interface CarpoolDriver {
  userId: string;
  displayName: string;
  avatarUrl: string | null;
  seatsOffered: number;
  seatsTaken: number;
  seatsAvailable: number;
  departureLocation: string | null;
  pickupLocation: string | null;
}

interface CarpoolRider {
  userId: string;
  displayName: string;
  avatarUrl: string | null;
  pickupLocation: string | null;
  hasDriver: boolean;
}

interface CarpoolResponse {
  eventId: string;
  drivers: CarpoolDriver[];
  riders: CarpoolRider[];
  summary: {
    totalSeatsOffered: number;
    totalSeatsTaken: number;
    totalSeatsAvailable: number;
    ridersNeedingRides: number;
  };
}

/**
 * GET /api/events/[id]/carpool
 *
 * Get carpool information for an event
 * Returns drivers with available seats and riders who need rides
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
    const supabase = await createClient();

    // Verify event exists
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('id, carpool_available, carpool_seats')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // Fetch all attendees with their carpool info
    const { data: attendees, error: attendeesError } = await supabase
      .from('event_attendees')
      .select(`
        user_id,
        status,
        is_driver,
        needs_ride,
        pickup_location,
        user:user_id (
          id,
          display_name,
          avatar_url
        )
      `)
      .eq('event_id', eventId)
      .in('status', ['going', 'maybe']);

    if (attendeesError) {
      console.error('Error fetching attendees:', attendeesError);
      return NextResponse.json(
        { error: 'Failed to fetch carpool data' },
        { status: 500 }
      );
    }

    // Get event creator's carpool info
    const { data: eventWithCreator } = await supabase
      .from('events')
      .select(`
        user_id,
        carpool_available,
        carpool_seats,
        departure_location,
        creator:user_id (
          id,
          display_name,
          avatar_url
        )
      `)
      .eq('id', eventId)
      .single();

    // Build drivers list
    const drivers: CarpoolDriver[] = [];
    const riders: CarpoolRider[] = [];

    // Add event creator as driver if they're offering carpool
    if (eventWithCreator?.carpool_available && eventWithCreator.carpool_seats > 0) {
      // Count how many riders this driver has (attendees who need_ride and have this user as implied driver)
      // For now, we'll set seatsTaken to 0 - proper matching would need a driver_id field on attendees
      drivers.push({
        userId: eventWithCreator.user_id,
        displayName: (eventWithCreator.creator as any)?.display_name || 'Event Creator',
        avatarUrl: (eventWithCreator.creator as any)?.avatar_url || null,
        seatsOffered: eventWithCreator.carpool_seats,
        seatsTaken: 0, // Would need driver assignment tracking for accurate count
        seatsAvailable: eventWithCreator.carpool_seats,
        departureLocation: eventWithCreator.departure_location,
        pickupLocation: null,
      });
    }

    // Process attendees
    for (const attendee of attendees || []) {
      const user = attendee.user as any;

      if (attendee.is_driver) {
        // This attendee is offering to drive
        // Note: Currently we don't track individual driver seat counts in event_attendees
        // This would need schema enhancement for per-attendee seat offerings
        drivers.push({
          userId: attendee.user_id,
          displayName: user?.display_name || 'Unknown',
          avatarUrl: user?.avatar_url || null,
          seatsOffered: 4, // Default - would need schema change for actual value
          seatsTaken: 0,
          seatsAvailable: 4,
          departureLocation: null,
          pickupLocation: attendee.pickup_location,
        });
      }

      if (attendee.needs_ride) {
        riders.push({
          userId: attendee.user_id,
          displayName: user?.display_name || 'Unknown',
          avatarUrl: user?.avatar_url || null,
          pickupLocation: attendee.pickup_location,
          hasDriver: false, // Would need driver assignment tracking
        });
      }
    }

    // Calculate summary
    const totalSeatsOffered = drivers.reduce((sum, d) => sum + d.seatsOffered, 0);
    const totalSeatsTaken = drivers.reduce((sum, d) => sum + d.seatsTaken, 0);
    const totalSeatsAvailable = drivers.reduce((sum, d) => sum + d.seatsAvailable, 0);
    const ridersNeedingRides = riders.filter(r => !r.hasDriver).length;

    const response: CarpoolResponse = {
      eventId,
      drivers,
      riders,
      summary: {
        totalSeatsOffered,
        totalSeatsTaken,
        totalSeatsAvailable,
        ridersNeedingRides,
      },
    };

    return NextResponse.json(response);
  } catch (error) {
    console.error('Error in GET /api/events/[id]/carpool:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
