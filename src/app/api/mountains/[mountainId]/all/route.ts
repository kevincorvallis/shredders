import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { getMountainAllData } from '@/lib/apis/mountain-data';

/**
 * Batched API endpoint that fetches all mountain data in one request.
 * Delegates to the shared getMountainAllData() function.
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  const { mountainId } = await params;
  const mountain = getMountain(mountainId);

  if (!mountain) {
    return NextResponse.json(
      { error: `Mountain '${mountainId}' not found` },
      { status: 404 }
    );
  }

  try {
    const data = await getMountainAllData(mountainId);

    if (!data) {
      return NextResponse.json(
        { error: `Mountain '${mountainId}' not found` },
        { status: 404 }
      );
    }

    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching mountain data:', error);
    return NextResponse.json(
      { error: 'Failed to fetch mountain data' },
      { status: 500 }
    );
  }
}
