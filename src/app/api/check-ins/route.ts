import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

/**
 * GET /api/check-ins
 *
 * Fetch check-ins with optional filters
 * Query params:
 *   - mountainId: Filter by mountain (optional)
 *   - userId: Filter by user (optional)
 *   - limit: Number of results (default: 20, max: 100)
 *   - offset: Pagination offset (default: 0)
 *   - publicOnly: Only show public check-ins (default: true)
 */
export async function GET(request: Request) {
  try {
    const supabase = await createClient();
    const { searchParams } = new URL(request.url);

    const mountainId = searchParams.get('mountainId');
    const userId = searchParams.get('userId');
    const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 100);
    const offset = parseInt(searchParams.get('offset') || '0');
    const publicOnly = searchParams.get('publicOnly') !== 'false';

    // Build query with user join
    let query = supabase
      .from('check_ins')
      .select(`
        *,
        user:user_id (
          id,
          username,
          display_name,
          avatar_url
        )
      `)
      .order('check_in_time', { ascending: false })
      .range(offset, offset + limit - 1);

    // Apply filters
    if (mountainId) {
      query = query.eq('mountain_id', mountainId);
    }
    if (userId) {
      query = query.eq('user_id', userId);
    }
    if (publicOnly) {
      query = query.eq('is_public', true);
    }

    const { data: checkIns, error } = await query;

    if (error) {
      console.error('Error fetching check-ins:', error);
      return NextResponse.json(
        { error: 'Failed to fetch check-ins' },
        { status: 500 }
      );
    }

    return NextResponse.json({ checkIns: checkIns || [] });
  } catch (error) {
    console.error('Error in GET /api/check-ins:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/check-ins
 *
 * Create a new check-in
 * Body:
 *   - mountainId: Mountain ID (required)
 *   - checkInTime: ISO timestamp (default: now)
 *   - checkOutTime: ISO timestamp (optional)
 *   - tripReport: Trip report text (optional, max 5000 chars)
 *   - rating: Overall rating 1-5 (optional)
 *   - snowQuality: Snow quality rating (optional)
 *   - crowdLevel: Crowd level (optional)
 *   - weatherConditions: Weather object (optional)
 *   - isPublic: Make check-in public (default: true)
 */
export async function POST(request: Request) {
  try {
    const supabase = await createClient();

    // Check authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    const body = await request.json();
    const {
      mountainId,
      checkInTime,
      checkOutTime,
      tripReport,
      rating,
      snowQuality,
      crowdLevel,
      weatherConditions,
      isPublic = true,
    } = body;

    // Validate required fields
    if (!mountainId) {
      return NextResponse.json(
        { error: 'Mountain ID is required' },
        { status: 400 }
      );
    }

    // Validate trip report length
    if (tripReport && tripReport.length > 5000) {
      return NextResponse.json(
        { error: 'Trip report must be less than 5000 characters' },
        { status: 400 }
      );
    }

    // Validate rating
    if (rating !== undefined && (rating < 1 || rating > 5)) {
      return NextResponse.json(
        { error: 'Rating must be between 1 and 5' },
        { status: 400 }
      );
    }

    // Create check-in
    const { data: checkIn, error: insertError } = await supabase
      .from('check_ins')
      .insert({
        user_id: user.id,
        mountain_id: mountainId,
        check_in_time: checkInTime || new Date().toISOString(),
        check_out_time: checkOutTime || null,
        trip_report: tripReport || null,
        rating: rating || null,
        snow_quality: snowQuality || null,
        crowd_level: crowdLevel || null,
        weather_conditions: weatherConditions || null,
        is_public: isPublic,
      })
      .select(`
        *,
        user:user_id (
          id,
          username,
          display_name,
          avatar_url
        )
      `)
      .single();

    if (insertError) {
      console.error('Error creating check-in:', insertError);
      return NextResponse.json(
        { error: 'Failed to create check-in' },
        { status: 500 }
      );
    }

    return NextResponse.json({ checkIn }, { status: 201 });
  } catch (error) {
    console.error('Error in POST /api/check-ins:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
