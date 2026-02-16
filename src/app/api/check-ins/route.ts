import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

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
    const limit = Math.max(1, Math.min(parseInt(searchParams.get('limit') || '20') || 20, 100));
    const offset = Math.max(0, parseInt(searchParams.get('offset') || '0') || 0);
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
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ checkIns: checkIns || [] });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/check-ins' });
  }
}

/**
 * POST /api/check-ins
 *
 * Create a new check-in
 * Supports both JWT bearer tokens and Supabase session authentication
 *
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
export const POST = withDualAuth(async (request, authUser) => {
  try {
    const adminClient = createAdminClient();

    // Look up internal user profile ID
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.unauthorized('User profile not found'));
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
      return handleError(Errors.missingField('mountainId'));
    }

    // Validate trip report length
    if (tripReport && tripReport.length > 5000) {
      return handleError(Errors.validationFailed(['Trip report must be less than 5000 characters']));
    }

    // Validate rating
    if (rating !== undefined && (rating < 1 || rating > 5)) {
      return handleError(Errors.validationFailed(['Rating must be between 1 and 5']));
    }

    // Create check-in
    const { data: checkIn, error: insertError } = await adminClient
      .from('check_ins')
      .insert({
        user_id: userProfile.id,
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
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ checkIn }, { status: 201 });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/check-ins' });
  }
});
