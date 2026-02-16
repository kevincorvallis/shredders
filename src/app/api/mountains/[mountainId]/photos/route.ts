/**
 * GET /api/mountains/[mountainId]/photos
 *
 * Get all photos for a specific mountain
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { handleError } from '@/lib/errors';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  try {
    const { mountainId } = await params;
    const { searchParams } = new URL(request.url);
    const webcamId = searchParams.get('webcamId');
    const limit = parseInt(searchParams.get('limit') || '20');
    const offset = parseInt(searchParams.get('offset') || '0');

    const supabase = await createClient();

    let query = supabase
      .from('user_photos')
      .select(
        `
        *,
        users:user_id (
          username,
          display_name,
          avatar_url
        )
      `
      )
      .eq('mountain_id', mountainId)
      .eq('is_approved', true)
      .order('taken_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // Filter by webcam if specified
    if (webcamId) {
      query = query.eq('webcam_id', webcamId);
    }

    const { data: photos, error } = await query;

    if (error) {
      console.error('Error fetching photos:', error);
      return handleError(error, { endpoint: 'GET /api/mountains/[mountainId]/photos' });
    }

    return NextResponse.json({
      photos: photos || [],
      total: photos?.length || 0,
    });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/mountains/[mountainId]/photos' });
  }
}
