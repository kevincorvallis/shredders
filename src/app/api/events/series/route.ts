import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';
import { getMountain } from '@shredders/shared';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import type { SkillLevel } from '@/types/event';

// ============================================
// Types
// ============================================

export type RecurrencePattern = 'weekly' | 'biweekly' | 'monthly_day' | 'monthly_weekday';

export interface CreateSeriesRequest {
  mountainId: string;
  title: string;
  notes?: string;
  departureTime?: string; // HH:MM
  departureLocation?: string;
  skillLevel?: SkillLevel;
  carpoolAvailable?: boolean;
  carpoolSeats?: number;
  maxAttendees?: number;
  recurrencePattern: RecurrencePattern;
  dayOfWeek?: number; // 0-6 for weekly/biweekly
  dayOfMonth?: number; // 1-31 for monthly_day
  weekOfMonth?: number; // 1-4 or -1 for last, for monthly_weekday
  startDate: string; // YYYY-MM-DD
  endDate?: string; // YYYY-MM-DD, optional
}

export interface EventSeries {
  id: string;
  creatorId: string;
  mountainId: string;
  mountainName?: string;
  title: string;
  notes: string | null;
  departureTime: string | null;
  departureLocation: string | null;
  skillLevel: SkillLevel | null;
  carpoolAvailable: boolean;
  carpoolSeats: number | null;
  maxAttendees: number | null;
  recurrencePattern: RecurrencePattern;
  dayOfWeek: number | null;
  dayOfMonth: number | null;
  weekOfMonth: number | null;
  startDate: string;
  endDate: string | null;
  status: 'active' | 'paused' | 'ended';
  createdAt: string;
  updatedAt: string;
}

/**
 * GET /api/events/series
 *
 * List event series created by the current user
 */
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient();
    const adminClient = createAdminClient();

    const authUser = await getDualAuthUser(request);
    if (!authUser) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return NextResponse.json(
        { error: 'User profile not found' },
        { status: 404 }
      );
    }

    const { data: series, error } = await supabase
      .from('event_series')
      .select('*')
      .eq('user_id', userProfile.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching series:', error);
      return NextResponse.json(
        { error: 'Failed to fetch series' },
        { status: 500 }
      );
    }

    const transformedSeries: EventSeries[] = (series || []).map((s: any) => {
      const mountain = getMountain(s.mountain_id);
      return {
        id: s.id,
        creatorId: s.user_id,
        mountainId: s.mountain_id,
        mountainName: mountain?.name,
        title: s.title,
        notes: s.notes,
        departureTime: s.departure_time,
        departureLocation: s.departure_location,
        skillLevel: s.skill_level,
        carpoolAvailable: s.carpool_available,
        carpoolSeats: s.carpool_seats,
        maxAttendees: s.max_attendees,
        recurrencePattern: s.recurrence_pattern,
        dayOfWeek: s.day_of_week,
        dayOfMonth: s.day_of_month,
        weekOfMonth: s.week_of_month,
        startDate: s.start_date,
        endDate: s.end_date,
        status: s.status,
        createdAt: s.created_at,
        updatedAt: s.updated_at,
      };
    });

    return NextResponse.json({ series: transformedSeries });
  } catch (error) {
    console.error('Error in GET /api/events/series:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/events/series
 *
 * Create a new recurring event series
 */
export async function POST(request: NextRequest) {
  try {
    const adminClient = createAdminClient();

    const authUser = await getDualAuthUser(request);
    if (!authUser) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Rate limiting
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

    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return NextResponse.json(
        { error: 'User profile not found' },
        { status: 404 }
      );
    }

    const body: CreateSeriesRequest = await request.json();
    const {
      mountainId,
      title,
      notes,
      departureTime,
      departureLocation,
      skillLevel,
      carpoolAvailable = false,
      carpoolSeats,
      maxAttendees,
      recurrencePattern,
      dayOfWeek,
      dayOfMonth,
      weekOfMonth,
      startDate,
      endDate,
    } = body;

    // Validate required fields
    if (!mountainId) {
      return NextResponse.json(
        { error: 'Mountain ID is required' },
        { status: 400 }
      );
    }

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

    if (!recurrencePattern) {
      return NextResponse.json(
        { error: 'Recurrence pattern is required' },
        { status: 400 }
      );
    }

    const validPatterns: RecurrencePattern[] = ['weekly', 'biweekly', 'monthly_day', 'monthly_weekday'];
    if (!validPatterns.includes(recurrencePattern)) {
      return NextResponse.json(
        { error: 'Invalid recurrence pattern' },
        { status: 400 }
      );
    }

    // Validate pattern-specific fields
    if ((recurrencePattern === 'weekly' || recurrencePattern === 'biweekly') && (dayOfWeek === undefined || dayOfWeek < 0 || dayOfWeek > 6)) {
      return NextResponse.json(
        { error: 'Day of week (0-6) is required for weekly/biweekly patterns' },
        { status: 400 }
      );
    }

    if (recurrencePattern === 'monthly_day' && (dayOfMonth === undefined || dayOfMonth < 1 || dayOfMonth > 31)) {
      return NextResponse.json(
        { error: 'Day of month (1-31) is required for monthly_day pattern' },
        { status: 400 }
      );
    }

    if (recurrencePattern === 'monthly_weekday') {
      if (dayOfWeek === undefined || dayOfWeek < 0 || dayOfWeek > 6) {
        return NextResponse.json(
          { error: 'Day of week (0-6) is required for monthly_weekday pattern' },
          { status: 400 }
        );
      }
      if (weekOfMonth === undefined || (weekOfMonth < -1 || weekOfMonth > 4 || weekOfMonth === 0)) {
        return NextResponse.json(
          { error: 'Week of month (1-4 or -1 for last) is required for monthly_weekday pattern' },
          { status: 400 }
        );
      }
    }

    if (!startDate) {
      return NextResponse.json(
        { error: 'Start date is required' },
        { status: 400 }
      );
    }

    const today = new Date().toISOString().split('T')[0];
    if (startDate < today) {
      return NextResponse.json(
        { error: 'Start date cannot be in the past' },
        { status: 400 }
      );
    }

    // Create series
    const { data: series, error: insertError } = await adminClient
      .from('event_series')
      .insert({
        user_id: userProfile.id,
        mountain_id: mountainId,
        title: title.trim(),
        notes: notes?.trim() || null,
        departure_time: departureTime ? `${departureTime}:00` : null,
        departure_location: departureLocation?.trim() || null,
        skill_level: skillLevel || null,
        carpool_available: carpoolAvailable,
        carpool_seats: carpoolSeats || null,
        max_attendees: maxAttendees || null,
        recurrence_pattern: recurrencePattern,
        day_of_week: dayOfWeek ?? null,
        day_of_month: dayOfMonth ?? null,
        week_of_month: weekOfMonth ?? null,
        start_date: startDate,
        end_date: endDate || null,
      })
      .select()
      .single();

    if (insertError) {
      console.error('Error creating series:', insertError);
      return NextResponse.json(
        { error: 'Failed to create series' },
        { status: 500 }
      );
    }

    // Generate initial event instances (next 3 months)
    const { data: generatedCount, error: genError } = await adminClient
      .rpc('generate_series_instances', {
        p_series_id: series.id,
        p_months_ahead: 3,
      });

    if (genError) {
      console.error('Error generating series instances:', genError);
      // Don't fail the request, series was created
    }

    const transformedSeries: EventSeries = {
      id: series.id,
      creatorId: series.user_id,
      mountainId: series.mountain_id,
      mountainName: mountain.name,
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
      generatedEvents: generatedCount || 0,
    }, { status: 201 });
  } catch (error) {
    console.error('Error in POST /api/events/series:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
