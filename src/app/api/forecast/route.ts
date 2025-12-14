import { NextResponse } from 'next/server';
import { getForecast } from '@/lib/apis/noaa';

export async function GET() {
  try {
    const forecast = await getForecast();

    return NextResponse.json({
      generated: new Date().toISOString(),
      location: {
        name: 'Mt. Baker',
        lat: 48.857,
        lng: -121.669,
      },
      source: 'NOAA National Weather Service',
      forecast: forecast.map(day => ({
        ...day,
        // Ensure snowfall is shown as integer inches
        snowfall: Math.round(day.snowfall),
      })),
    }, {
      headers: {
        'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=7200',
      },
    });
  } catch (error) {
    console.error('Error fetching forecast:', error);

    // Return fallback with empty forecast
    return NextResponse.json({
      generated: new Date().toISOString(),
      location: {
        name: 'Mt. Baker',
        lat: 48.857,
        lng: -121.669,
      },
      error: 'Forecast temporarily unavailable',
      forecast: generateFallbackForecast(),
    }, {
      status: 200,
      headers: {
        'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
      },
    });
  }
}

function generateFallbackForecast() {
  const today = new Date();
  const forecast = [];

  for (let i = 0; i < 7; i++) {
    const date = new Date(today.getTime() + i * 86400000);
    forecast.push({
      date: date.toISOString().split('T')[0],
      dayOfWeek: date.toLocaleDateString('en-US', { weekday: 'short' }),
      high: 32,
      low: 25,
      snowfall: 0,
      precipProbability: 0,
      precipType: 'none',
      wind: { speed: 10, gust: 15 },
      conditions: 'Data unavailable',
      icon: 'cloud',
    });
  }

  return forecast;
}
