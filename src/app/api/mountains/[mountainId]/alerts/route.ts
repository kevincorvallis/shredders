import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getWeatherAlerts } from '@/lib/apis/noaa';

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
    const alerts = await getWeatherAlerts(
      mountain.location.lat,
      mountain.location.lng
    );

    return NextResponse.json({
      mountain: {
        id: mountain.id,
        name: mountain.name,
        shortName: mountain.shortName,
      },
      alerts,
      count: alerts.length,
      source: 'NOAA Weather.gov',
    });
  } catch (error) {
    console.error('Error fetching alerts:', error);
    return NextResponse.json(
      { error: 'Failed to fetch weather alerts' },
      { status: 500 }
    );
  }
}
