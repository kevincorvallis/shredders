import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getHistoricalData } from '@/lib/apis/snotel';

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

  if (!mountain.snotel) {
    return NextResponse.json(
      { error: `No SNOTEL data available for ${mountain.name}` },
      { status: 404 }
    );
  }

  const { searchParams } = new URL(request.url);
  const days = parseInt(searchParams.get('days') || '30', 10);

  try {
    const history = await getHistoricalData(mountain.snotel.stationId, days);

    return NextResponse.json({
      mountain: {
        id: mountain.id,
        name: mountain.name,
        shortName: mountain.shortName,
      },
      history,
      days,
      source: {
        provider: 'SNOTEL',
        stationName: mountain.snotel.stationName,
        stationId: mountain.snotel.stationId,
      },
    });
  } catch (error) {
    console.error('Error fetching history:', error);
    return NextResponse.json(
      { error: 'Failed to fetch historical data' },
      { status: 500 }
    );
  }
}
