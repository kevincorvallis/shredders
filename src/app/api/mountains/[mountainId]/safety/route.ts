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

    // Determine overall safety level
    const safetyLevel = alerts.length === 0 ? 'low' :
                       alerts.some(a => a.severity === 'high' || a.severity === 'extreme') ? 'high' :
                       alerts.some(a => a.severity === 'moderate') ? 'moderate' : 'low';

    // Build safety recommendations
    const recommendations = alerts.length > 0
      ? alerts.slice(0, 3).map(a => a.message)
      : [
          'Check avalanche forecast before heading into the backcountry',
          'Always ski with a partner and carry proper safety equipment',
          'Monitor changing conditions throughout the day'
        ];

    // Simplified hazard assessment from safety metrics
    const getHazardLevel = (riskLevel: number): string => {
      if (riskLevel >= 4) return 'high';
      if (riskLevel >= 3) return 'considerable';
      if (riskLevel >= 2) return 'moderate';
      return 'low';
    };

    // Calculate average risk from hazard matrix
    const avgRisk = hazardMatrix.length > 0
      ? hazardMatrix.reduce((sum, entry) => sum + entry.risk, 0) / hazardMatrix.length
      : 1;

    // Determine specific hazard levels
    const avalancheLevel = getHazardLevel(avgRisk);
    const treeWellsLevel = snotelData?.snowDepth && snotelData.snowDepth > 36 ? 'moderate' : 'low';
    const icyLevel = temperature > 32 && snotelData?.snowfall24h === 0 ? 'moderate' : 'low';
    const crowdedLevel = 'low'; // Could be enhanced with day-of-week logic

    // Build response matching iOS SafetyResponse structure
    const response = {
      mountain: {
        id: mountain.id,
        name: mountain.name,
        shortName: mountain.shortName,
        elevation: mountain.elevation,
      },
      assessment: {
        level: safetyLevel,
        description: stabilityAssessment.overallMessage,
        recommendations: recommendations,
      },
      weather: {
        temperature: Math.round(temperature),
        feelsLike: Math.round(windChill),
        humidity: humidity ? Math.round(humidity) : null,
        visibility: visibility,
        pressure: null, // Not available from current weather sources
        uvIndex: null,  // Not available from current weather sources
        wind: {
          speed: Math.round(windSpeed),
          gust: windGust ? Math.round(windGust) : null,
          direction: weatherData?.windDirection ?? 'N',
        },
      },
      hazards: {
        avalanche: {
          level: avalancheLevel,
          description: windLoading.message || `General avalanche danger is ${avalancheLevel}`,
        },
        treeWells: {
          level: treeWellsLevel,
          description: snotelData?.snowDepth && snotelData.snowDepth > 36
            ? `Deep snow (${Math.round(snotelData.snowDepth)}") creates tree well hazards`
            : 'Tree well risk is low with current snow depth',
        },
        icy: {
          level: icyLevel,
          description: temperature > 32 && snotelData?.snowfall24h === 0
            ? 'Warm temperatures may create icy conditions'
            : 'Icy conditions are minimal',
        },
        crowded: {
          level: crowdedLevel,
          description: 'Typical crowd levels expected',
        },
      },
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
