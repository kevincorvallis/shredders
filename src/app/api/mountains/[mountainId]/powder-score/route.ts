import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getForecast, getCurrentWeather, type NOAAGridConfig } from '@/lib/apis/noaa';

interface ScoreFactor {
  name: string;
  value: number;
  weight: number;
  contribution: number;
  description: string;
}

function calculatePowderScore(
  snowfall24h: number,
  snowfall48h: number,
  temperature: number,
  windSpeed: number,
  upcomingSnow: number
): { score: number; factors: ScoreFactor[] } {
  const factors: ScoreFactor[] = [];

  // Fresh snow factor (0-10) - most important
  const freshSnowScore = Math.min(10, snowfall24h / 2);
  factors.push({
    name: 'Fresh Snow (24h)',
    value: snowfall24h,
    weight: 0.35,
    contribution: freshSnowScore * 0.35,
    description: `${snowfall24h}" in last 24 hours`,
  });

  // Recent snow factor (0-10)
  const recentSnowScore = Math.min(10, snowfall48h / 3);
  factors.push({
    name: 'Recent Snow (48h)',
    value: snowfall48h,
    weight: 0.2,
    contribution: recentSnowScore * 0.2,
    description: `${snowfall48h}" in last 48 hours`,
  });

  // Temperature factor (0-10) - ideal is 28-32F
  let tempScore = 0;
  if (temperature <= 32 && temperature >= 20) {
    tempScore = 10 - Math.abs(30 - temperature) / 2;
  } else if (temperature < 20) {
    tempScore = 6; // Very cold, snow might be too dry
  } else {
    tempScore = Math.max(0, 10 - (temperature - 32)); // Above freezing, risk of rain
  }
  factors.push({
    name: 'Temperature',
    value: temperature,
    weight: 0.15,
    contribution: tempScore * 0.15,
    description: `${temperature}°F - ${temperature <= 32 ? 'good for snow preservation' : 'warm, watch for wet conditions'}`,
  });

  // Wind factor (0-10) - lower is better for powder
  const windScore = Math.max(0, 10 - windSpeed / 5);
  factors.push({
    name: 'Wind',
    value: windSpeed,
    weight: 0.15,
    contribution: windScore * 0.15,
    description: `${windSpeed} mph - ${windSpeed < 15 ? 'light winds' : windSpeed < 30 ? 'moderate winds' : 'strong winds'}`,
  });

  // Forecast factor (0-10) - upcoming snow
  const forecastScore = Math.min(10, upcomingSnow / 2);
  factors.push({
    name: 'Upcoming Snow',
    value: upcomingSnow,
    weight: 0.15,
    contribution: forecastScore * 0.15,
    description: `${upcomingSnow}" expected in next 48 hours`,
  });

  // Calculate final score
  const totalScore = factors.reduce((sum, f) => sum + f.contribution, 0);
  const score = Math.round(totalScore * 10) / 10;

  return { score: Math.min(10, Math.max(1, score)), factors };
}

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
    // Get SNOTEL data
    let snotelData = null;
    if (mountain.snotel) {
      try {
        snotelData = await getCurrentConditions(mountain.snotel.stationId);
      } catch (error) {
        console.error(`SNOTEL error for ${mountain.name}:`, error);
      }
    }

    // Get NOAA data
    const noaaConfig: NOAAGridConfig = mountain.noaa;
    let weatherData = null;
    let forecast = null;
    try {
      [weatherData, forecast] = await Promise.all([
        getCurrentWeather(noaaConfig),
        getForecast(noaaConfig),
      ]);
    } catch (error) {
      console.error(`NOAA error for ${mountain.name}:`, error);
    }

    // Calculate upcoming snow from forecast
    const upcomingSnow = forecast
      ? forecast
          .slice(0, 2)
          .reduce((sum: number, day) => sum + (day.snowfall || 0), 0)
      : 0;

    // Calculate powder score
    const snowfall24h = snotelData?.snowfall24h ?? 0;
    const snowfall48h = snotelData?.snowfall48h ?? 0;
    const temperature = weatherData?.temperature ?? snotelData?.temperature ?? 32;
    const windSpeed = weatherData?.windSpeed ?? 0;

    const { score, factors } = calculatePowderScore(
      snowfall24h,
      snowfall48h,
      temperature,
      windSpeed,
      upcomingSnow
    );

    // Generate verdict
    let verdict: string;
    if (score >= 8) {
      verdict = 'SEND IT! Epic powder conditions!';
    } else if (score >= 6) {
      verdict = 'Great day for skiing - fresh snow awaits!';
    } else if (score >= 4) {
      verdict = 'Decent conditions - groomed runs will be good.';
    } else {
      verdict = 'Consider waiting for better conditions.';
    }

    return NextResponse.json({
      mountain: {
        id: mountain.id,
        name: mountain.name,
        shortName: mountain.shortName,
      },
      score,
      factors,
      verdict,
      conditions: {
        snowfall24h,
        snowfall48h,
        temperature,
        windSpeed,
        upcomingSnow,
      },
      dataAvailable: {
        snotel: !!snotelData,
        noaa: !!weatherData,
      },
    });
  } catch (error) {
    console.error('Error calculating powder score:', error);
    return NextResponse.json(
      { error: 'Failed to calculate powder score' },
      { status: 500 }
    );
  }
}
