import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';

/**
 * Helper: Check if user has RSVP'd to an event (going or maybe)
 */
async function checkUserRSVP(
  supabase: any,
  eventId: string,
  userProfileId: string
): Promise<boolean> {
  const { data: attendee } = await supabase
    .from('event_attendees')
    .select('status')
    .eq('event_id', eventId)
    .eq('user_id', userProfileId)
    .in('status', ['going', 'maybe'])
    .single();

  return !!attendee;
}

/**
 * Helper: Check if user is the event creator
 */
async function checkIsCreator(
  supabase: any,
  eventId: string,
  userProfileId: string
): Promise<boolean> {
  const { data: event } = await supabase
    .from('events')
    .select('user_id')
    .eq('id', eventId)
    .single();

  return event?.user_id === userProfileId;
}

// Activity type definitions
type ActivityType =
  | 'rsvp_going'
  | 'rsvp_maybe'
  | 'rsvp_declined'
  | 'comment_posted'
  | 'milestone_reached'
  | 'event_created'
  | 'event_updated';

interface ActivityMetadata {
  milestone?: number;
  label?: string;
  comment_id?: string;
  preview?: string;
  is_reply?: boolean;
  previous_status?: string;
}

interface EventActivity {
  id: string;
  eventId: string;
  userId: string | null;
  activityType: ActivityType;
  metadata: ActivityMetadata;
  createdAt: string;
  user?: {
    id: string;
    username: string;
    displayName: string | null;
    avatarUrl: string | null;
  } | null;
}

/**
 * GET /api/events/[id]/activity
 *
 * Fetch activity timeline for an event.
 * - RSVP'd users (going/maybe) or event creator: Full access
 * - Non-RSVP'd users: Return 403 with activity count only
 *
 * Query params:
 *   - limit: Number of results (default: 20, max: 50)
 *   - offset: Pagination offset (default: 0)
 *   - type: Filter by activity type (optional)
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params;
    const supabase = await createClient();
    const adminClient = createAdminClient();
    const { searchParams } = new URL(request.url);

    const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 50);
    const offset = parseInt(searchParams.get('offset') || '0');
    const typeFilter = searchParams.get('type');

    // Check if event exists
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('id, user_id')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // Get activity count (always returned)
    const { count: activityCount } = await adminClient
      .from('event_activity')
      .select('*', { count: 'exact', head: true })
      .eq('event_id', eventId);

    // Check authentication
    const authUser = await getDualAuthUser(request);

    if (!authUser) {
      // Return count only for unauthenticated users
      return NextResponse.json({
        activities: [],
        activityCount: activityCount || 0,
        gated: true,
        message: 'RSVP to see activity',
      });
    }

    // Look up user's internal profile ID
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return NextResponse.json({
        activities: [],
        activityCount: activityCount || 0,
        gated: true,
        message: 'RSVP to see activity',
      });
    }

    // Check if user is creator or has RSVP'd
    const isCreator = await checkIsCreator(supabase, eventId, userProfile.id);
    const hasRSVP = await checkUserRSVP(supabase, eventId, userProfile.id);

    if (!isCreator && !hasRSVP) {
      return NextResponse.json({
        activities: [],
        activityCount: activityCount || 0,
        gated: true,
        message: 'RSVP to see activity',
      });
    }

    // Build query
    let query = adminClient
      .from('event_activity')
      .select(`
        id,
        event_id,
        user_id,
        activity_type,
        metadata,
        created_at
      `)
      .eq('event_id', eventId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // Apply type filter if provided
    if (typeFilter) {
      query = query.eq('activity_type', typeFilter);
    }

    const { data: activities, error: activitiesError } = await query;

    if (activitiesError) {
      console.error('Error fetching event activities:', activitiesError);
      return NextResponse.json(
        { error: 'Failed to fetch activities' },
        { status: 500 }
      );
    }

    // Fetch user info for activities that have user_id
    const userIds = [...new Set((activities || [])
      .map((a: any) => a.user_id)
      .filter((id: string | null) => id !== null))];

    let usersMap: Record<string, any> = {};

    if (userIds.length > 0) {
      const { data: users } = await adminClient
        .from('users')
        .select('id, username, display_name, avatar_url')
        .in('id', userIds);

      if (users) {
        usersMap = users.reduce((acc: Record<string, any>, user: any) => {
          acc[user.id] = user;
          return acc;
        }, {});
      }
    }

    // Transform activities
    const transformedActivities: EventActivity[] = (activities || []).map((activity: any) => ({
      id: activity.id,
      eventId: activity.event_id,
      userId: activity.user_id,
      activityType: activity.activity_type,
      metadata: activity.metadata || {},
      createdAt: activity.created_at,
      user: activity.user_id ? usersMap[activity.user_id] ? {
        id: usersMap[activity.user_id].id,
        username: usersMap[activity.user_id].username,
        displayName: usersMap[activity.user_id].display_name,
        avatarUrl: usersMap[activity.user_id].avatar_url,
      } : null : null,
    }));

    return NextResponse.json({
      activities: transformedActivities,
      activityCount: activityCount || 0,
      gated: false,
      pagination: {
        limit,
        offset,
        hasMore: (activityCount || 0) > offset + limit,
      },
    });
  } catch (error) {
    console.error('Error in GET /api/events/[id]/activity:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
