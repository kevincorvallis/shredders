import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { getExtendedConditions, getExtendedHistory } from '@/lib/apis/snotel';
import { getExtendedCurrentWeather, getRecentWindData } from '@/lib/apis/noaa';
import {
  calculateWindLoading,
  detectTemperatureInversion,
  assessSnowStability,
  classifySnowType,
  calculateWindChill,
  estimateFreezingLevel,
  generateHazardMatrix,
  generateSafetyAlerts,
} from '@/lib/calculations/safety-metrics';

export const dynamic = 'force-dynamic';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ mountainId: string }> }
) {
  const { mountainId } = await params;
  const mountain = getMountain(mountainId);

  if (!mountain) {
    return NextResponse.json(
      { error: 'Mountain not found' },
      { status: 404 }
    );
  }

  try {
    // Fetch data in parallel
    const [snotelData, weatherData, windHistory, snowHistory] = await Promise.all([
      mountain.snotel
        ? getExtendedConditions(mountain.snotel.stationId).catch(() => null)
        : Promise.resolve(null),
      getExtendedCurrentWeather(mountain.noaa).catch(() => null),
      getRecentWindData(mountain.noaa, 6).catch(() => []),
      mountain.snotel
        ? getExtendedHistory(mountain.snotel.stationId, 7).catch(() => [])
        : Promise.resolve([]),
    ]);

    // Use SNOTEL data if available, otherwise use NOAA
    const temperature = snotelData?.temperature ?? weatherData?.temperature ?? 32;
    const humidity = snotelData?.humidity ?? weatherData?.humidity ?? null;
    const windSpeed = weatherData?.windSpeed ?? snotelData?.windSpeed ?? 0;
    const windGust = weatherData?.windGust ?? null;
    const windDirection = weatherData?.windDirectionDegrees ?? snotelData?.windDirection ?? 0;
    const visibility = weatherData?.visibility ?? null;

    // Calculate safety metrics
    const windLoading = calculateWindLoading(windSpeed, windDirection, windGust);

    const inversionRisk = detectTemperatureInversion(
      temperature, // base temp (approximation - ideally would have base station)
      temperature - 5, // summit temp (approximation - cooler at top)
      mountain.elevation.base,
      mountain.elevation.summit
    );

    const stabilityAssessment = assessSnowStability(
      temperature,
      snotelData?.tempMax24hr ?? null,
      snotelData?.tempMin24hr ?? null,
      humidity,
      windSpeed,
      snotelData?.snowfall24h ?? 0,
      snotelData?.snowDensity ?? null,
      snotelData?.settlingRate ?? null
    );

    const snowType = classifySnowType(
      temperature,
      humidity,
      windSpeed
    );

    const windChill = calculateWindChill(temperature, windSpeed);

    const freezingLevel = estimateFreezingLevel(
      mountain.elevation.base,
      temperature,
      mountain.elevation.summit,
      temperature - 8 // Approximate summit temp using lapse rate
    );

    const hazardMatrix = generateHazardMatrix(
      windLoading,
      snotelData?.snowfall24h ?? 0,
      snotelData?.tempMax24hr ?? null,
      snotelData?.tempMin24hr ?? null
    );

    const alerts = generateSafetyAlerts(
      windLoading,
      snotelData?.snowfall24h ?? 0,
      temperature,
      snotelData?.tempMax24hr ?? null,
      windChill,
      visibility
    );

    // Build response
    const response = {
      timestamp: new Date().toISOString(),
      mountain: mountainId,
      dataQuality: {
        hasSnotel: !!snotelData,
        hasWeather: !!weatherData,
        hasWindHistory: windHistory.length > 0,
      },
      alerts,
      metrics: {
        windLoading: {
          index: windLoading.index,
          severity: windLoading.severity,
          loadedAspects: windLoading.loadedAspects,
          crossLoadedAspects: windLoading.crossLoadedAspects,
          message: windLoading.message,
        },
        inversionRisk: {
          detected: inversionRisk.detected,
          confidence: inversionRisk.confidence,
          type: inversionRisk.type,
          message: inversionRisk.message,
        },
        snowStability: {
          rating: stabilityAssessment.rating,
          trend: stabilityAssessment.trend,
          factors: stabilityAssessment.factors,
          message: stabilityAssessment.overallMessage,
        },
        snowType,
        windChill,
        freezingLevel: Math.round(freezingLevel),
        hazardMatrix,
      },
      conditions: {
        temperature,
        tempMax24hr: snotelData?.tempMax24hr ?? null,
        tempMin24hr: snotelData?.tempMin24hr ?? null,
        diurnalRange: snotelData?.diurnalRange ?? null,
        humidity,
        windSpeed,
        windGust,
        windDirection,
        windDirectionCardinal: weatherData?.windDirection ?? 'N',
        visibility,
        visibilityCategory: weatherData?.visibilityCategory ?? 'good',
        skyCover: weatherData?.skyCover ?? null,
        precipProbability: weatherData?.precipProbability ?? null,
      },
      snowpack: snotelData ? {
        depth: snotelData.snowDepth,
        swe: snotelData.snowWaterEquivalent,
        density: snotelData.snowDensity,
        snowfall24h: snotelData.snowfall24h,
        snowfall48h: snotelData.snowfall48h,
        snowfall7d: snotelData.snowfall7d,
        settlingRate: snotelData.settlingRate,
      } : null,
      windHistory,
      snowHistory: snowHistory.slice(-7), // Last 7 days
    };

    return NextResponse.json(response, {
      headers: {
        'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
      },
    });
  } catch (error) {
    console.error('Safety API error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch safety data' },
      { status: 500 }
    );
  }
}
