import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getCurrentWeather, type NOAAGridConfig } from '@/lib/apis/noaa';

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
    // Fetch SNOTEL data if available
    let snotelData = null;
    if (mountain.snotel) {
      try {
        snotelData = await getCurrentConditions(mountain.snotel.stationId);
      } catch (error) {
        console.error(`SNOTEL error for ${mountain.name}:`, error);
      }
    }

    // Fetch NOAA weather data
    const noaaConfig: NOAAGridConfig = mountain.noaa;
    let weatherData = null;
    try {
      weatherData = await getCurrentWeather(noaaConfig);
    } catch (error) {
      console.error(`NOAA error for ${mountain.name}:`, error);
    }

    // Combine data
    const conditions = {
      mountain: {
        id: mountain.id,
        name: mountain.name,
        shortName: mountain.shortName,
      },
      snowDepth: snotelData?.snowDepth ?? null,
      snowWaterEquivalent: snotelData?.snowWaterEquivalent ?? null,
      snowfall24h: snotelData?.snowfall24h ?? 0,
      snowfall48h: snotelData?.snowfall48h ?? 0,
      snowfall7d: snotelData?.snowfall7d ?? 0,
      temperature: weatherData?.temperature ?? snotelData?.temperature ?? null,
      conditions: weatherData?.conditions ?? 'Unknown',
      wind: weatherData
        ? {
            speed: weatherData.windSpeed,
            direction: weatherData.windDirection,
          }
        : null,
      lastUpdated: snotelData?.lastUpdated ?? new Date().toISOString(),
      dataSources: {
        snotel: mountain.snotel
          ? {
              available: !!snotelData,
              stationName: mountain.snotel.stationName,
            }
          : null,
        noaa: {
          available: !!weatherData,
          gridOffice: mountain.noaa.gridOffice,
        },
      },
    };

    return NextResponse.json(conditions);
  } catch (error) {
    console.error('Error fetching conditions:', error);
    return NextResponse.json(
      { error: 'Failed to fetch conditions' },
      { status: 500 }
    );
  }
}
