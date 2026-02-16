import { NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

/**
 * GET /api/check-ins/[checkInId]
 *
 * Get a specific check-in by ID
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ checkInId: string }> }
) {
  try {
    const { checkInId } = await params;
    const supabase = await createClient();

    const { data: checkIn, error } = await supabase
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
      .eq('id', checkInId)
      .single();

    if (error || !checkIn) {
      return handleError(Errors.resourceNotFound('Check-in'));
    }

    return NextResponse.json({ checkIn });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/check-ins/[checkInId]' });
  }
}

/**
 * PATCH /api/check-ins/[checkInId]
 *
 * Update a check-in (owner only)
 * Body:
 *   - checkOutTime: ISO timestamp (optional)
 *   - tripReport: Trip report text (optional, max 5000 chars)
 *   - rating: Overall rating 1-5 (optional)
 *   - snowQuality: Snow quality rating (optional)
 *   - crowdLevel: Crowd level (optional)
 *   - weatherConditions: Weather object (optional)
 *   - isPublic: Make check-in public (optional)
 */
export const PATCH = withDualAuth(async (request, authUser) => {
  try {
    const url = new URL(request.url);
    const checkInId = url.pathname.split('/').pop()!;
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

    // Fetch existing check-in
    const { data: existingCheckIn, error: fetchError } = await adminClient
      .from('check_ins')
      .select('user_id')
      .eq('id', checkInId)
      .single();

    if (fetchError || !existingCheckIn) {
      return handleError(Errors.resourceNotFound('Check-in'));
    }

    // Verify ownership
    if (existingCheckIn.user_id !== userProfile.id) {
      return handleError(Errors.forbidden('You can only edit your own check-ins'));
    }

    const body = await request.json();
    const {
      checkOutTime,
      tripReport,
      rating,
      snowQuality,
      crowdLevel,
      weatherConditions,
      isPublic,
    } = body;

    // Validate trip report length
    if (tripReport !== undefined && tripReport && tripReport.length > 5000) {
      return handleError(Errors.validationFailed(['Trip report must be less than 5000 characters']));
    }

    // Validate rating
    if (rating !== undefined && rating !== null && (rating < 1 || rating > 5)) {
      return handleError(Errors.validationFailed(['Rating must be between 1 and 5']));
    }

    // Build update object (only include provided fields)
    const updates: any = {};
    if (checkOutTime !== undefined) updates.check_out_time = checkOutTime;
    if (tripReport !== undefined) updates.trip_report = tripReport;
    if (rating !== undefined) updates.rating = rating;
    if (snowQuality !== undefined) updates.snow_quality = snowQuality;
    if (crowdLevel !== undefined) updates.crowd_level = crowdLevel;
    if (weatherConditions !== undefined) updates.weather_conditions = weatherConditions;
    if (isPublic !== undefined) updates.is_public = isPublic;

    // Update check-in
    const { data: updatedCheckIn, error: updateError } = await adminClient
      .from('check_ins')
      .update(updates)
      .eq('id', checkInId)
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

    if (updateError) {
      console.error('Error updating check-in:', updateError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ checkIn: updatedCheckIn });
  } catch (error) {
    return handleError(error, { endpoint: 'PATCH /api/check-ins/[checkInId]' });
  }
});

/**
 * DELETE /api/check-ins/[checkInId]
 *
 * Delete a check-in (owner only)
 */
export const DELETE = withDualAuth(async (request, authUser) => {
  try {
    const url = new URL(request.url);
    const checkInId = url.pathname.split('/').pop()!;
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

    // Fetch existing check-in
    const { data: existingCheckIn, error: fetchError } = await adminClient
      .from('check_ins')
      .select('user_id')
      .eq('id', checkInId)
      .single();

    if (fetchError || !existingCheckIn) {
      return handleError(Errors.resourceNotFound('Check-in'));
    }

    // Verify ownership
    if (existingCheckIn.user_id !== userProfile.id) {
      return handleError(Errors.forbidden('You can only delete your own check-ins'));
    }

    // Delete check-in
    const { error: deleteError } = await adminClient
      .from('check_ins')
      .delete()
      .eq('id', checkInId);

    if (deleteError) {
      console.error('Error deleting check-in:', deleteError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/check-ins/[checkInId]' });
  }
});
