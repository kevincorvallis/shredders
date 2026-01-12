import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { getForecast, type NOAAGridConfig } from '@/lib/apis/noaa';

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
    if (!mountain.noaa) {
      // For international mountains without NOAA, return empty forecast
      return NextResponse.json({
        mountain: {
          id: mountain.id,
          name: mountain.name,
          shortName: mountain.shortName,
        },
        forecast: [],
        source: {
          provider: 'Open-Meteo',
          gridOffice: 'N/A',
        },
      });
    }

    const forecast = await getForecast(mountain.noaa);

    return NextResponse.json({
      mountain: {
        id: mountain.id,
        name: mountain.name,
        shortName: mountain.shortName,
      },
      forecast,
      source: {
        provider: 'NOAA Weather.gov',
        gridOffice: mountain.noaa.gridOffice,
      },
    });
  } catch (error) {
    console.error('Error fetching forecast:', error);
    return NextResponse.json(
      { error: 'Failed to fetch forecast' },
      { status: 500 }
    );
  }
}
