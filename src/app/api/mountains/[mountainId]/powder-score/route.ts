import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { getCurrentConditions } from '@/lib/apis/snotel';
import {
  getForecast,
  getCurrentWeather,
  getExtendedCurrentWeather,
  getHourlyForecast,
  getWeatherAlerts,
  analyzeStormFromAlerts,
  type NOAAGridConfig,
  type StormInfo
} from '@/lib/apis/noaa';
import { getCurrentFreezingLevelFeet, calculateRainRiskScore } from '@/lib/apis/open-meteo';
import { withCache } from '@/lib/cache';

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
  },
  baseDepth?: number,
  snowfall72h?: number,
  stormInfo?: StormInfo | null
): { score: number; factors: ScoreFactor[]; stormBoost: number } {
  const factors: ScoreFactor[] = [];

  // ===== PRIMARY FACTORS (60% of total) =====

  // 24h Snowfall (40% of Primary = 24% of total)
  let snowfallScore = 0;
  if (snowfall24h === 0) snowfallScore = 0;
  else if (snowfall24h <= 3) snowfallScore = 4;
  else if (snowfall24h <= 6) snowfallScore = 6;
  else if (snowfall24h <= 12) snowfallScore = 8;
  else snowfallScore = 10;

  // Snow Density (30% of Primary = 18% of total)
  // Estimate from temperature and humidity - ideal is <10% water content (light powder)
  const humidity = weatherGovData?.humidity ?? 70;
  let densityScore = 8; // Default good
  if (temperature > 32 || humidity > 85) {
    densityScore = 2; // Heavy, wet snow
  } else if (temperature >= 28 && humidity >= 70 && humidity <= 80) {
    densityScore = 5; // Medium density
  } else if (temperature >= 25 && temperature <= 32 && humidity < 70) {
    densityScore = 8; // Light powder
  } else if (temperature < 25 && humidity < 60) {
    densityScore = 10; // Champagne powder
  }

  // Freshness (30% of Primary = 18% of total)
  // Estimate when snow fell based on 24h vs 48h accumulation
  const recentSnow = snowfall24h;
  const olderSnow = Math.max(0, snowfall48h - snowfall24h);
  let freshnessScore = 0;
  if (recentSnow >= olderSnow * 2) {
    freshnessScore = 10; // Most snow fell recently (0-6hrs)
  } else if (recentSnow >= olderSnow) {
    freshnessScore = 8; // Decent fresh snow (6-12hrs)
  } else if (recentSnow > 0) {
    freshnessScore = 6; // Some fresh snow (12-24hrs)
  } else if (olderSnow > 0) {
    freshnessScore = 4; // Snow 24-48hrs old
  } else if (snowfall72h && snowfall72h > 0) {
    freshnessScore = 2; // Snow 48-72hrs old
  } else {
    freshnessScore = 0; // 72h+ old
  }

  const primaryScore = (snowfallScore * 0.40) + (densityScore * 0.30) + (freshnessScore * 0.30);

  factors.push({
    name: '24h Snowfall',
    value: snowfall24h,
    weight: 0.24, // 40% of 60%
    contribution: snowfallScore * 0.24,
    description: `${snowfall24h}" fresh snow`,
    isPositive: snowfall24h >= 6,
  });

  factors.push({
    name: 'Snow Density',
    value: densityScore,
    weight: 0.18, // 30% of 60%
    contribution: densityScore * 0.18,
    description: densityScore >= 8 ? 'Light powder' : densityScore >= 5 ? 'Medium density' : 'Heavy/wet',
    isPositive: densityScore >= 8,
  });

  factors.push({
    name: 'Freshness',
    value: freshnessScore,
    weight: 0.18, // 30% of 60%
    contribution: freshnessScore * 0.18,
    description: freshnessScore >= 8 ? 'Just fell' : freshnessScore >= 6 ? 'Recent' : freshnessScore >= 4 ? '1-2 days' : 'Older snow',
    isPositive: freshnessScore >= 8,
  });

  // ===== SECONDARY FACTORS (25% of total) =====

  // Wind Speed (40% of Secondary = 10% of total)
  const effectiveWind = weatherGovData?.windGust
    ? Math.max(windSpeed, weatherGovData.windGust * 0.8)
    : windSpeed;
  let windScore = 0;
  if (effectiveWind <= 5) windScore = 10;
  else if (effectiveWind <= 15) windScore = 7;
  else if (effectiveWind <= 25) windScore = 4;
  else windScore = 1;

  // Temperature (35% of Secondary = 8.75% of total)
  let tempScore = 0;
  if (temperature < 15) tempScore = 10;
  else if (temperature <= 25) tempScore = 8;
  else if (temperature <= 32) tempScore = 5;
  else tempScore = 2;

  // Aspect (25% of Secondary = 6.25% of total)
  // Since we don't have real-time aspect data, use a neutral score of 7
  // In a full implementation, this would vary based on sun exposure and wind direction
  const aspectScore = 7; // Neutral - could be enhanced with wind direction data

  const secondaryScore = (windScore * 0.40) + (tempScore * 0.35) + (aspectScore * 0.25);

  factors.push({
    name: 'Wind',
    value: Math.round(effectiveWind),
    weight: 0.10, // 40% of 25%
    contribution: windScore * 0.10,
    description: `${Math.round(effectiveWind)} mph${weatherGovData?.windGust ? ` (gusts ${weatherGovData.windGust})` : ''} - ${effectiveWind <= 15 ? 'calm' : effectiveWind <= 25 ? 'moderate' : 'strong'}`,
    isPositive: effectiveWind <= 15,
  });

  factors.push({
    name: 'Temperature',
    value: temperature,
    weight: 0.0875, // 35% of 25%
    contribution: tempScore * 0.0875,
    description: `${temperature}°F - ${temperature < 15 ? 'cold & dry' : temperature <= 25 ? 'ideal' : temperature <= 32 ? 'good' : 'warm'}`,
    isPositive: temperature <= 25,
  });

  // ===== TERTIARY FACTORS (15% of total) =====

  // Base Depth (30% of Tertiary = 4.5% of total)
  const depth = baseDepth ?? 0;
  let baseScore = 3;
  if (depth >= 72) baseScore = 10;
  else if (depth >= 48) baseScore = 8;
  else if (depth >= 24) baseScore = 6;
  else baseScore = 3;

  // Sky Conditions (35% of Tertiary = 5.25% of total)
  const skyCover = weatherGovData?.skyCover ?? 50;
  let skyScore = 6;
  if (skyCover >= 70 || snowfall24h > 0) skyScore = 10; // Overcast/snowing
  else if (skyCover >= 40) skyScore = 6; // Partly cloudy
  else skyScore = 3; // Clear/sunny

  // Crowd Factor (35% of Tertiary = 5.25% of total)
  const now = new Date();
  const dayOfWeek = now.getDay(); // 0 = Sunday, 6 = Saturday
  const hour = now.getHours();
  let crowdScore = 7;
  if (dayOfWeek >= 1 && dayOfWeek <= 5) {
    // Weekday
    crowdScore = hour < 9 ? 10 : 7;
  } else {
    // Weekend
    crowdScore = hour < 8 ? 5 : 2;
  }

  const tertiaryScore = (baseScore * 0.30) + (skyScore * 0.35) + (crowdScore * 0.35);

  factors.push({
    name: 'Base Depth',
    value: depth,
    weight: 0.045, // 30% of 15%
    contribution: baseScore * 0.045,
    description: depth >= 48 ? 'Deep base' : depth >= 24 ? 'Good coverage' : 'Limited base',
    isPositive: depth >= 48,
  });

  factors.push({
    name: 'Sky Conditions',
    value: skyCover,
    weight: 0.0525, // 35% of 15%
    contribution: skyScore * 0.0525,
    description: skyCover >= 70 ? 'Overcast/snowing' : skyCover >= 40 ? 'Partly cloudy' : 'Bluebird',
    isPositive: skyCover >= 70 || snowfall24h > 0,
  });

  factors.push({
    name: 'Crowd Level',
    value: crowdScore,
    weight: 0.0525, // 35% of 15%
    contribution: crowdScore * 0.0525,
    description: crowdScore >= 9 ? 'Weekday early' : crowdScore >= 6 ? 'Weekday' : crowdScore >= 4 ? 'Weekend early' : 'Peak crowds',
    isPositive: crowdScore >= 7,
  });

  // Calculate base score
  let baseScoreTotal = (primaryScore * 0.60) + (secondaryScore * 0.25) + (tertiaryScore * 0.15);

  // ===== MODIFIERS =====
  const modifiers: string[] = [];

  // No new snow in 72h+ - cap at 3
  if (snowfall24h === 0 && snowfall48h === 0) {
    baseScoreTotal = Math.min(baseScoreTotal, 3);
    modifiers.push('No recent snow (capped at 3)');
  }

  // Wind > 30mph sustained - penalty
  if (effectiveWind > 30) {
    baseScoreTotal = Math.max(1, baseScoreTotal - 2);
    modifiers.push('High winds (−2)');
  }

  // Rain event - cap at 2
  if (rainRisk && rainRisk.score < 4) {
    baseScoreTotal = Math.min(baseScoreTotal, 2);
    modifiers.push('Rain risk (capped at 2)');
  }

  // 48h snowfall > 24" - bonus
  if (snowfall48h > 24) {
    baseScoreTotal = Math.min(10, baseScoreTotal + 1);
    modifiers.push('Storm cycling (+1)');
  }

  // Storm boost - active winter storm warning boosts score
  let stormBoost = 0;
  if (stormInfo?.isPowderBoost && stormInfo.isActive) {
    // Calculate boost based on expected snowfall (0.5-1.5 points)
    const expectedSnow = stormInfo.expectedSnowfall ?? 6; // Default to 6" if unknown
    stormBoost = Math.min(expectedSnow / 12, 1.5); // Max 1.5 point boost
    stormBoost = Math.round(stormBoost * 10) / 10; // Round to 1 decimal

    baseScoreTotal = Math.min(10, baseScoreTotal + stormBoost);
    modifiers.push(`Storm incoming (+${stormBoost}): ${stormInfo.eventType}`);
  }

  // Add modifiers to description if any
  if (modifiers.length > 0) {
    factors.push({
      name: 'Modifiers',
      value: 0,
      weight: 0,
      contribution: 0,
      description: modifiers.join(', '),
      isPositive: modifiers.some(m => m.includes('+')),
    });
  }

  const finalScore = Math.round(Math.max(1, Math.min(10, baseScoreTotal)) * 10) / 10;

  return { score: finalScore, factors, stormBoost };
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
    const result = await withCache(`powder-score:${mountainId}`, async () => {
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
    let weatherData = null;
    let extendedWeatherData = null;
    let forecast = null;
    let hourlyForecast = null;

    if (mountain.noaa) {
      try {
        [weatherData, extendedWeatherData, forecast, hourlyForecast] = await Promise.all([
          getCurrentWeather(mountain.noaa),
          getExtendedCurrentWeather(mountain.noaa),
          getForecast(mountain.noaa),
          getHourlyForecast(mountain.noaa, 24),
        ]);
      } catch (error) {
        console.error(`NOAA error for ${mountain.name}:`, error);
      }
    }

    // Get weather alerts and analyze for storms
    let stormInfo: StormInfo | null = null;
    try {
      const alerts = await getWeatherAlerts(mountain.location.lat, mountain.location.lng);
      stormInfo = analyzeStormFromAlerts(alerts);
    } catch (error) {
      console.error(`Alerts error for ${mountain.name}:`, error);
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
    const snowfall72h = snotelData?.snowfall7d ?? 0; // Use 7-day as proxy for 72h
    const baseDepth = snotelData?.snowDepth ?? 0;
    const temperature = extendedWeatherData?.temperature ?? weatherData?.temperature ?? snotelData?.temperature ?? 32;
    const windSpeed = extendedWeatherData?.windSpeed ?? weatherData?.windSpeed ?? 0;

    const { score, factors, stormBoost } = calculatePowderScore(
      snowfall24h,
      snowfall48h,
      temperature,
      windSpeed,
      bestUpcomingSnow,
      rainRisk,
      weatherGovData,
      baseDepth,
      snowfall72h,
      stormInfo
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

    return {
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
        windGust: extendedWeatherData?.windGust ?? null,
        humidity: extendedWeatherData?.humidity ?? null,
        visibility: extendedWeatherData?.visibility ?? null,
        visibilityCategory: extendedWeatherData?.visibilityCategory ?? null,
        skyCover: extendedWeatherData?.skyCover ?? null,
        precipProbability: extendedWeatherData?.precipProbability ?? null,
      },
      freezingLevel,
      rainRisk: rainRisk
        ? {
            score: rainRisk.score,
            description: rainRisk.description,
            level: rainRisk.score >= 7 ? 'low' : rainRisk.score >= 4 ? 'moderate' : 'high',
          }
        : null,
      stormInfo: stormInfo?.isActive ? {
        isActive: stormInfo.isActive,
        isPowderBoost: stormInfo.isPowderBoost,
        eventType: stormInfo.eventType,
        hoursRemaining: stormInfo.hoursRemaining,
        expectedSnowfall: stormInfo.expectedSnowfall,
        severity: stormInfo.severity,
        scoreBoost: stormBoost,
      } : null,
      elevation: mountain.elevation,
      dataAvailable: {
        snotel: !!snotelData,
        noaa: !!weatherData,
        noaaExtended: !!extendedWeatherData,
        openMeteo: !!freezingLevel,
        alerts: stormInfo !== null,
      },
    };
    }, 600); // 10min cache

    return NextResponse.json(result);
  } catch (error) {
    console.error('Error calculating powder score:', error);
    return NextResponse.json(
      { error: 'Failed to calculate powder score' },
      { status: 500 }
    );
  }
}
