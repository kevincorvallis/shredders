import { NextResponse } from 'next/server';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getCurrentWeather } from '@/lib/apis/noaa';

export async function GET() {
  try {
    // Fetch real data from SNOTEL and NOAA in parallel
    const [snotelData, noaaData] = await Promise.all([
      getCurrentConditions(),
      getCurrentWeather().catch(() => null), // NOAA can be flaky, don't fail if it's down
    ]);

    // Estimate freezing level based on temperature
    // Rough calculation: freezing level rises ~1000ft per 3.5°F above 32
    const freezingLevel = snotelData.temperature > 32
      ? Math.round(4000 + (snotelData.temperature - 32) * 285)
      : Math.round(4000 - (32 - snotelData.temperature) * 285);

    const conditions = {
      timestamp: new Date().toISOString(),
      mountain: {
        id: 'mt-baker',
        name: 'Mt. Baker',
        elevation: { base: 3500, summit: 5089 },
      },
      temperature: {
        base: noaaData?.temperature || snotelData.temperature,
        summit: Math.round((noaaData?.temperature || snotelData.temperature) - 15), // Summit typically ~15°F colder
      },
      snowDepth: snotelData.snowDepth,
      snowfall24h: snotelData.snowfall24h,
      snowfall48h: snotelData.snowfall48h,
      snowfall7d: snotelData.snowfall7d,
      snowWaterEquivalent: snotelData.snowWaterEquivalent,
      freezingLevel: Math.max(0, Math.min(10000, freezingLevel)),
      wind: {
        speed: noaaData?.windSpeed || 10,
        direction: noaaData?.windDirection || 'W',
        gust: Math.round((noaaData?.windSpeed || 10) * 1.5),
      },
      visibility: getVisibility(noaaData?.conditions || ''),
      source: {
        snotel: 'Wells Creek (910:WA:SNTL)',
        weather: 'NOAA NWS',
        lastUpdated: snotelData.lastUpdated,
      },
    };

    return NextResponse.json(conditions, {
      headers: {
        'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
      },
    });
  } catch (error) {
    console.error('Error fetching conditions:', error);

    // Return fallback data if APIs fail
    return NextResponse.json({
      timestamp: new Date().toISOString(),
      mountain: {
        id: 'mt-baker',
        name: 'Mt. Baker',
        elevation: { base: 3500, summit: 5089 },
      },
      temperature: { base: 32, summit: 20 },
      snowDepth: 0,
      snowfall24h: 0,
      snowfall48h: 0,
      snowfall7d: 0,
      snowWaterEquivalent: 0,
      freezingLevel: 4000,
      wind: { speed: 10, direction: 'W', gust: 15 },
      visibility: 'cloudy',
      error: 'Data temporarily unavailable',
    }, {
      status: 200, // Return 200 with error flag so app doesn't break
      headers: {
        'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=120',
      },
    });
  }
}

function getVisibility(conditions: string): string {
  const lower = conditions.toLowerCase();
  if (lower.includes('snow')) return 'snowing';
  if (lower.includes('fog') || lower.includes('mist')) return 'fog';
  if (lower.includes('rain')) return 'cloudy';
  if (lower.includes('cloud') || lower.includes('overcast')) return 'cloudy';
  if (lower.includes('partly')) return 'partly-cloudy';
  if (lower.includes('sun') || lower.includes('clear')) return 'clear';
  return 'cloudy';
}
