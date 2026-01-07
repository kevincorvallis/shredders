import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

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
      return NextResponse.json(
        { error: 'Check-in not found' },
        { status: 404 }
      );
    }

    // Check if check-in is public or belongs to current user
    const { data: { user } } = await supabase.auth.getUser();
    if (!checkIn.is_public && (!user || checkIn.user_id !== user.id)) {
      return NextResponse.json(
        { error: 'Check-in not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ checkIn });
  } catch (error) {
    console.error('Error in GET /api/check-ins/[checkInId]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
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
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ checkInId: string }> }
) {
  try {
    const { checkInId } = await params;
    const supabase = await createClient();

    // Check authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Fetch existing check-in
    const { data: existingCheckIn, error: fetchError } = await supabase
      .from('check_ins')
      .select('user_id')
      .eq('id', checkInId)
      .single();

    if (fetchError || !existingCheckIn) {
      return NextResponse.json(
        { error: 'Check-in not found' },
        { status: 404 }
      );
    }

    // Verify ownership
    if (existingCheckIn.user_id !== user.id) {
      return NextResponse.json(
        { error: 'You can only edit your own check-ins' },
        { status: 403 }
      );
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
      return NextResponse.json(
        { error: 'Trip report must be less than 5000 characters' },
        { status: 400 }
      );
    }

    // Validate rating
    if (rating !== undefined && rating !== null && (rating < 1 || rating > 5)) {
      return NextResponse.json(
        { error: 'Rating must be between 1 and 5' },
        { status: 400 }
      );
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
    const { data: updatedCheckIn, error: updateError } = await supabase
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
      return NextResponse.json(
        { error: 'Failed to update check-in' },
        { status: 500 }
      );
    }

    return NextResponse.json({ checkIn: updatedCheckIn });
  } catch (error) {
    console.error('Error in PATCH /api/check-ins/[checkInId]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/check-ins/[checkInId]
 *
 * Delete a check-in (owner only)
 */
export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ checkInId: string }> }
) {
  try {
    const { checkInId } = await params;
    const supabase = await createClient();

    // Check authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Fetch existing check-in
    const { data: existingCheckIn, error: fetchError } = await supabase
      .from('check_ins')
      .select('user_id')
      .eq('id', checkInId)
      .single();

    if (fetchError || !existingCheckIn) {
      return NextResponse.json(
        { error: 'Check-in not found' },
        { status: 404 }
      );
    }

    // Verify ownership
    if (existingCheckIn.user_id !== user.id) {
      return NextResponse.json(
        { error: 'You can only delete your own check-ins' },
        { status: 403 }
      );
    }

    // Delete check-in (hard delete)
    const { error: deleteError } = await supabase
      .from('check_ins')
      .delete()
      .eq('id', checkInId);

    if (deleteError) {
      console.error('Error deleting check-in:', deleteError);
      return NextResponse.json(
        { error: 'Failed to delete check-in' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error in DELETE /api/check-ins/[checkInId]:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
