import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getCurrentWeather, type NOAAGridConfig } from '@/lib/apis/noaa';
import { getCurrentFreezingLevelFeet, calculateRainRiskScore } from '@/lib/apis/open-meteo';

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

    // Fetch NOAA weather data (if available for this region)
    let weatherData = null;
    if (mountain.noaa) {
      const noaaConfig: NOAAGridConfig = mountain.noaa;
      try {
        weatherData = await getCurrentWeather(noaaConfig);
      } catch (error) {
        console.error(`NOAA error for ${mountain.name}:`, error);
      }
    }

    // Fetch freezing level from Open-Meteo
    let freezingLevel: number | null = null;
    let rainRisk: { score: number; description: string } | null = null;
    try {
      freezingLevel = await getCurrentFreezingLevelFeet(
        mountain.location.lat,
        mountain.location.lng
      );
      rainRisk = calculateRainRiskScore(
        freezingLevel,
        mountain.elevation.base,
        mountain.elevation.summit
      );
    } catch (error) {
      console.error(`Open-Meteo error for ${mountain.name}:`, error);
      // Fallback to simple temperature-based estimate
      const temp = weatherData?.temperature ?? snotelData?.temperature ?? 32;
      freezingLevel = Math.round(4000 + (temp - 32) * 285);
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
      // New: Freezing level from Open-Meteo
      freezingLevel,
      rainRisk: rainRisk
        ? {
            score: rainRisk.score,
            description: rainRisk.description,
          }
        : null,
      elevation: mountain.elevation,
      dataSources: {
        snotel: mountain.snotel
          ? {
              available: !!snotelData,
              stationName: mountain.snotel.stationName,
            }
          : null,
        noaa: mountain.noaa
          ? {
              available: !!weatherData,
              gridOffice: mountain.noaa.gridOffice,
            }
          : {
              available: false,
              gridOffice: 'N/A',
            },
        openMeteo: {
          available: freezingLevel !== null,
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
