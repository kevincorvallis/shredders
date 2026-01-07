import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

/**
 * GET /api/mountains/[mountainId]/check-ins
 *
 * Fetch check-ins for a specific mountain
 * Query params:
 *   - limit: Number of results (default: 20, max: 100)
 *   - offset: Pagination offset (default: 0)
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  try {
    const { mountainId } = await params;
    const supabase = await createClient();
    const { searchParams } = new URL(request.url);

    const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 100);
    const offset = parseInt(searchParams.get('offset') || '0');

    // Fetch public check-ins for this mountain
    const { data: checkIns, error } = await supabase
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
      .eq('mountain_id', mountainId)
      .eq('is_public', true)
      .order('check_in_time', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('Error fetching check-ins:', error);
      return NextResponse.json(
        { error: 'Failed to fetch check-ins' },
        { status: 500 }
      );
    }

    return NextResponse.json({ checkIns: checkIns || [] });
  } catch (error) {
    console.error('Error in GET /api/mountains/[mountainId]/check-ins:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
