import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { getMountainAllData } from '@/lib/apis/mountain-data';

const MAX_IDS = 10;

/**
 * Batch endpoint that fetches all data for multiple mountains in one request.
 * GET /api/mountains/batch/all?ids=snoqualmie,bachelor,stevens
 */
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const idsParam = searchParams.get('ids');

  if (!idsParam) {
    return NextResponse.json(
      { error: 'Missing required query parameter: ids' },
      { status: 400 }
    );
  }

  // Deduplicate and validate IDs
  const ids = [...new Set(idsParam.split(',').map(id => id.trim()).filter(Boolean))];

  if (ids.length === 0) {
    return NextResponse.json(
      { error: 'No valid mountain IDs provided' },
      { status: 400 }
    );
  }

  if (ids.length > MAX_IDS) {
    return NextResponse.json(
      { error: `Too many IDs. Maximum is ${MAX_IDS}, got ${ids.length}` },
      { status: 400 }
    );
  }

  // Validate all IDs exist
  const invalidIds = ids.filter(id => !getMountain(id));
  if (invalidIds.length > 0) {
    return NextResponse.json(
      { error: `Unknown mountain IDs: ${invalidIds.join(', ')}` },
      { status: 404 }
    );
  }

  try {
    // Fetch all mountains in parallel
    const results = await Promise.allSettled(
      ids.map(id => getMountainAllData(id))
    );

    const mountains: Record<string, any> = {};
    const errors: Record<string, string> = {};

    results.forEach((result, index) => {
      const id = ids[index];
      if (result.status === 'fulfilled' && result.value) {
        mountains[id] = result.value;
      } else {
        const reason = result.status === 'rejected'
          ? (result.reason?.message || 'Unknown error')
          : 'No data returned';
        errors[id] = reason;
      }
    });

    const response: any = {
      mountains,
      cachedAt: new Date().toISOString(),
    };

    if (Object.keys(errors).length > 0) {
      response.errors = errors;
    }

    return NextResponse.json(response);
  } catch (error) {
    console.error('Error fetching batch mountain data:', error);
    return NextResponse.json(
      { error: 'Failed to fetch batch mountain data' },
      { status: 500 }
    );
  }
}
