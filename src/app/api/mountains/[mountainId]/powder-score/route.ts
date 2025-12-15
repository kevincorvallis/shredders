import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getForecast, getCurrentWeather, type NOAAGridConfig } from '@/lib/apis/noaa';
import { getCurrentFreezingLevelFeet, calculateRainRiskScore } from '@/lib/apis/open-meteo';

interface ScoreFactor {
  name: string;
  value: number;
  weight: number;
  contribution: number;
  description: string;
  isPositive?: boolean;
}

function calculatePowderScore(
  snowfall24h: number,
  snowfall48h: number,
  temperature: number,
  windSpeed: number,
  upcomingSnow: number,
  rainRisk?: { score: number; description: string } | null
): { score: number; factors: ScoreFactor[] } {
  const factors: ScoreFactor[] = [];

  // Weights adjusted to include rain risk factor
  // With rain risk: Fresh 30%, Recent 15%, Temp 10%, Wind 10%, Upcoming 15%, Snow Line 20%
  // Without rain risk (fallback): Fresh 35%, Recent 20%, Temp 15%, Wind 15%, Upcoming 15%
  const hasRainRisk = rainRisk !== null && rainRisk !== undefined;
  const weights = hasRainRisk
    ? { fresh: 0.30, recent: 0.15, temp: 0.10, wind: 0.10, upcoming: 0.15, snowLine: 0.20 }
    : { fresh: 0.35, recent: 0.20, temp: 0.15, wind: 0.15, upcoming: 0.15, snowLine: 0 };

  // Fresh snow factor (0-10) - most important
  const freshSnowScore = Math.min(10, snowfall24h / 2);
  factors.push({
    name: 'Fresh Snow (24h)',
    value: snowfall24h,
    weight: weights.fresh,
    contribution: freshSnowScore * weights.fresh,
    description: `${snowfall24h}" in last 24 hours`,
    isPositive: snowfall24h >= 4,
  });

  // Recent snow factor (0-10)
  const recentSnowScore = Math.min(10, snowfall48h / 3);
  factors.push({
    name: 'Recent Snow (48h)',
    value: snowfall48h,
    weight: weights.recent,
    contribution: recentSnowScore * weights.recent,
    description: `${snowfall48h}" in last 48 hours`,
    isPositive: snowfall48h >= 6,
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
    weight: weights.temp,
    contribution: tempScore * weights.temp,
    description: `${temperature}°F - ${temperature <= 32 ? 'good for snow preservation' : 'warm, watch for wet conditions'}`,
    isPositive: temperature <= 32 && temperature >= 20,
  });

  // Wind factor (0-10) - lower is better for powder
  const windScore = Math.max(0, 10 - windSpeed / 5);
  factors.push({
    name: 'Wind',
    value: windSpeed,
    weight: weights.wind,
    contribution: windScore * weights.wind,
    description: `${windSpeed} mph - ${windSpeed < 15 ? 'light winds' : windSpeed < 30 ? 'moderate winds' : 'strong winds'}`,
    isPositive: windSpeed < 20,
  });

  // Forecast factor (0-10) - upcoming snow
  const forecastScore = Math.min(10, upcomingSnow / 2);
  factors.push({
    name: 'Upcoming Snow',
    value: upcomingSnow,
    weight: weights.upcoming,
    contribution: forecastScore * weights.upcoming,
    description: `${upcomingSnow}" expected in next 48 hours`,
    isPositive: upcomingSnow >= 4,
  });

  // Snow Line factor (0-10) - from Open-Meteo freezing level
  if (hasRainRisk && rainRisk) {
    factors.push({
      name: 'Snow Line',
      value: rainRisk.score,
      weight: weights.snowLine,
      contribution: rainRisk.score * weights.snowLine,
      description: rainRisk.description,
      isPositive: rainRisk.score >= 7,
    });
  }

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

    // Get freezing level from Open-Meteo
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
      upcomingSnow,
      rainRisk
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
      // New: Freezing level from Open-Meteo
      freezingLevel,
      rainRisk: rainRisk
        ? {
            score: rainRisk.score,
            description: rainRisk.description,
            level: rainRisk.score >= 7 ? 'low' : rainRisk.score >= 4 ? 'moderate' : 'high',
          }
        : null,
      elevation: mountain.elevation,
      dataAvailable: {
        snotel: !!snotelData,
        noaa: !!weatherData,
        openMeteo: !!freezingLevel,
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
