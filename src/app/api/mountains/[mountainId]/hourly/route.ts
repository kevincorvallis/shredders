import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { getHourlyForecast, type NOAAGridConfig } from '@/lib/apis/noaa';
import { withCache } from '@/lib/cache';

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
    const { searchParams } = new URL(request.url);
    const hours = parseInt(searchParams.get('hours') || '48');

    if (!mountain.noaa) {
      return NextResponse.json({
        mountain: {
          id: mountain.id,
          name: mountain.name,
          shortName: mountain.shortName,
        },
        hourly: [],
        source: {
          provider: 'Open-Meteo',
          gridOffice: 'N/A',
        },
      });
    }

    const data = await withCache(`hourly:${mountainId}`, async () => {
      const hourly = await getHourlyForecast(mountain.noaa!);
      return {
        mountain: {
          id: mountain.id,
          name: mountain.name,
          shortName: mountain.shortName,
        },
        hourly,
        source: {
          provider: 'NOAA Weather.gov',
          gridOffice: mountain.noaa!.gridOffice,
        },
      };
    }, 300); // 5min cache for hourly data

    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching hourly forecast:', error);
    return NextResponse.json(
      { error: 'Failed to fetch hourly forecast' },
      { status: 500 }
    );
  }
}
