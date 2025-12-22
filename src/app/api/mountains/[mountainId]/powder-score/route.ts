import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getCurrentConditions } from '@/lib/apis/snotel';
import {
  getForecast,
  getCurrentWeather,
  getExtendedCurrentWeather,
  getHourlyForecast,
  type NOAAGridConfig
} from '@/lib/apis/noaa';
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
  rainRisk?: { score: number; description: string } | null,
  weatherGovData?: {
    windGust: number | null;
    humidity: number | null;
    visibility: number | null;
    skyCover: number | null;
    precipProbability: number | null;
  }
): { score: number; factors: ScoreFactor[] } {
  const factors: ScoreFactor[] = [];

  // Enhanced weights with weather.gov data
  // Fresh 25%, Recent 12%, Temp 10%, Wind 8%, Upcoming 15%, Snow Line 18%, Visibility 7%, Conditions 5%
  const hasRainRisk = rainRisk !== null && rainRisk !== undefined;
  const hasWeatherGov = weatherGovData !== null && weatherGovData !== undefined;

  const weights = hasRainRisk && hasWeatherGov
    ? { fresh: 0.25, recent: 0.12, temp: 0.10, wind: 0.08, upcoming: 0.15, snowLine: 0.18, visibility: 0.07, conditions: 0.05 }
    : hasRainRisk
    ? { fresh: 0.30, recent: 0.15, temp: 0.10, wind: 0.10, upcoming: 0.15, snowLine: 0.20, visibility: 0, conditions: 0 }
    : { fresh: 0.35, recent: 0.20, temp: 0.15, wind: 0.15, upcoming: 0.15, snowLine: 0, visibility: 0, conditions: 0 };

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

  // Wind factor (0-10) - lower is better for powder, consider gusts
  const effectiveWind = weatherGovData?.windGust
    ? Math.max(windSpeed, weatherGovData.windGust * 0.8) // Gusts matter more
    : windSpeed;
  const windScore = Math.max(0, 10 - effectiveWind / 5);
  const windDesc = weatherGovData?.windGust
    ? `${windSpeed} mph (gusts ${weatherGovData.windGust}) - ${effectiveWind < 15 ? 'light' : effectiveWind < 30 ? 'moderate' : 'strong'} winds`
    : `${windSpeed} mph - ${windSpeed < 15 ? 'light winds' : windSpeed < 30 ? 'moderate winds' : 'strong winds'}`;

  factors.push({
    name: 'Wind',
    value: Math.round(effectiveWind),
    weight: weights.wind,
    contribution: windScore * weights.wind,
    description: windDesc,
    isPositive: effectiveWind < 20,
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

  // Visibility factor (0-10) - from weather.gov gridded data
  if (hasWeatherGov && weatherGovData && weatherGovData.visibility !== null && weights.visibility > 0) {
    const visibilityMiles = weatherGovData.visibility;
    let visibilityScore = 10;
    let visibilityDesc = '';

    if (visibilityMiles >= 5) {
      visibilityScore = 10;
      visibilityDesc = `Excellent (${visibilityMiles.toFixed(1)} mi)`;
    } else if (visibilityMiles >= 2) {
      visibilityScore = 7;
      visibilityDesc = `Good (${visibilityMiles.toFixed(1)} mi)`;
    } else if (visibilityMiles >= 0.5) {
      visibilityScore = 4;
      visibilityDesc = `Limited (${visibilityMiles.toFixed(1)} mi) - fog/snow`;
    } else {
      visibilityScore = 2;
      visibilityDesc = `Poor (${visibilityMiles.toFixed(1)} mi) - whiteout risk`;
    }

    factors.push({
      name: 'Visibility',
      value: Math.round(visibilityMiles * 10) / 10,
      weight: weights.visibility,
      contribution: visibilityScore * weights.visibility,
      description: visibilityDesc,
      isPositive: visibilityMiles >= 2,
    });
  }

  // Weather Conditions factor (0-10) - from weather.gov
  if (hasWeatherGov && weatherGovData && weights.conditions > 0) {
    const { skyCover, humidity, precipProbability } = weatherGovData;
    let conditionsScore = 7; // Default neutral
    let conditionsDesc = 'Conditions monitoring';

    // Perfect powder conditions: clear/partly cloudy, low humidity, low precip probability
    if (skyCover !== null && humidity !== null && precipProbability !== null) {
      // Sky cover: less is better unless we want snow
      const skyScore = upcomingSnow > 2 ? Math.min(10, skyCover / 10) : Math.max(0, 10 - skyCover / 10);

      // Humidity: moderate is best (too low = ice, too high = wet)
      const humidityScore = humidity >= 60 && humidity <= 80 ? 10 : Math.max(0, 10 - Math.abs(70 - humidity) / 10);

      // Precip probability: align with upcoming snow forecast
      const precipScore = upcomingSnow > 2 ? Math.min(10, precipProbability / 10) : Math.max(0, 10 - precipProbability / 10);

      conditionsScore = (skyScore + humidityScore + precipScore) / 3;

      if (upcomingSnow > 4) {
        conditionsDesc = `Active weather - ${precipProbability}% precip chance`;
      } else if (skyCover < 50 && precipProbability < 30) {
        conditionsDesc = `Bluebird - ${skyCover}% clouds, ${precipProbability}% precip`;
      } else {
        conditionsDesc = `Mixed - ${skyCover}% clouds, ${humidity}% humidity`;
      }
    }

    factors.push({
      name: 'Conditions',
      value: Math.round(conditionsScore * 10) / 10,
      weight: weights.conditions,
      contribution: conditionsScore * weights.conditions,
      description: conditionsDesc,
      isPositive: conditionsScore >= 6,
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

    // Get NOAA data (enhanced with gridded data)
    const noaaConfig: NOAAGridConfig = mountain.noaa;
    let weatherData = null;
    let extendedWeatherData = null;
    let forecast = null;
    let hourlyForecast = null;

    try {
      [weatherData, extendedWeatherData, forecast, hourlyForecast] = await Promise.all([
        getCurrentWeather(noaaConfig),
        getExtendedCurrentWeather(noaaConfig),
        getForecast(noaaConfig),
        getHourlyForecast(noaaConfig, 24),
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

    // Calculate upcoming snow from forecast (enhanced with hourly data)
    const upcomingSnow = forecast
      ? forecast
          .slice(0, 2)
          .reduce((sum: number, day) => sum + (day.snowfall || 0), 0)
      : 0;

    // Get detailed upcoming snow from hourly forecast
    let upcomingSnow24h = 0;
    if (hourlyForecast && hourlyForecast.length > 0) {
      // Estimate snowfall from hourly precip probability and temperature
      upcomingSnow24h = hourlyForecast
        .slice(0, 24)
        .filter(h => h.temperature <= 35 && (h.precipProbability ?? 0) > 30)
        .length * 0.5; // Rough estimate: 0.5" per hour with snow conditions
    }

    // Use the higher of the two estimates
    const bestUpcomingSnow = Math.max(upcomingSnow, upcomingSnow24h);

    // Prepare weather.gov data for powder score
    const weatherGovData = extendedWeatherData ? {
      windGust: extendedWeatherData.windGust,
      humidity: extendedWeatherData.humidity,
      visibility: extendedWeatherData.visibility,
      skyCover: extendedWeatherData.skyCover,
      precipProbability: extendedWeatherData.precipProbability,
    } : undefined;

    // Calculate powder score
    const snowfall24h = snotelData?.snowfall24h ?? 0;
    const snowfall48h = snotelData?.snowfall48h ?? 0;
    const temperature = extendedWeatherData?.temperature ?? weatherData?.temperature ?? snotelData?.temperature ?? 32;
    const windSpeed = extendedWeatherData?.windSpeed ?? weatherData?.windSpeed ?? 0;

    const { score, factors } = calculatePowderScore(
      snowfall24h,
      snowfall48h,
      temperature,
      windSpeed,
      bestUpcomingSnow,
      rainRisk,
      weatherGovData
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
        upcomingSnow: bestUpcomingSnow,
        // Enhanced weather.gov data
        windGust: extendedWeatherData?.windGust ?? null,
        humidity: extendedWeatherData?.humidity ?? null,
        visibility: extendedWeatherData?.visibility ?? null,
        visibilityCategory: extendedWeatherData?.visibilityCategory ?? null,
        skyCover: extendedWeatherData?.skyCover ?? null,
        precipProbability: extendedWeatherData?.precipProbability ?? null,
      },
      // Freezing level from Open-Meteo
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
        noaaExtended: !!extendedWeatherData,
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
