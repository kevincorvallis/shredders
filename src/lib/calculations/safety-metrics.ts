import type { Severity, Aspect, StabilityRating, SnowType, Trend, ElevationBand } from '@/lib/design-tokens';
import { ASPECTS, degreesToAspect } from '@/lib/design-tokens';

// Wind Loading Index (1-5 scale)
// Based on wind speed and whether the wind is loading a given aspect
export interface WindLoadingResult {
  index: number; // 1-5 scale
  severity: Severity;
  loadedAspects: Aspect[];
  crossLoadedAspects: Aspect[];
  message: string;
}

export function calculateWindLoading(
  windSpeed: number,
  windDirection: number, // degrees
  windGust: number | null
): WindLoadingResult {
  // Effective wind speed considers gusts
  const effectiveWind = windGust ? Math.max(windSpeed, windGust * 0.7) : windSpeed;

  // Calculate wind loading index (1-5)
  let index: number;
  if (effectiveWind < 10) index = 1;
  else if (effectiveWind < 20) index = 2;
  else if (effectiveWind < 30) index = 3;
  else if (effectiveWind < 45) index = 4;
  else index = 5;

  // Determine loaded aspects (leeward of wind direction)
  const windAspect = degreesToAspect(windDirection);
  const windIndex = ASPECTS.indexOf(windAspect);

  // Primary loaded aspects are opposite to wind direction (+/- 1)
  const loadedIndices = [
    (windIndex + 4) % 8, // Directly opposite
    (windIndex + 3) % 8, // Adjacent left
    (windIndex + 5) % 8, // Adjacent right
  ];
  const loadedAspects = loadedIndices.map(i => ASPECTS[i]);

  // Cross-loaded aspects (perpendicular)
  const crossIndices = [
    (windIndex + 2) % 8,
    (windIndex + 6) % 8,
  ];
  const crossLoadedAspects = crossIndices.map(i => ASPECTS[i]);

  // Determine severity
  let severity: Severity;
  if (index <= 1) severity = 'low';
  else if (index === 2) severity = 'moderate';
  else if (index === 3) severity = 'considerable';
  else if (index === 4) severity = 'high';
  else severity = 'extreme';

  // Generate message
  const messages: Record<number, string> = {
    1: 'Light winds. Minimal wind loading expected.',
    2: 'Moderate winds. Some wind loading on lee slopes.',
    3: 'Strong winds. Significant wind slab formation likely on lee slopes.',
    4: 'Very strong winds. Dangerous wind loading. Avoid steep lee terrain.',
    5: 'Extreme winds. Extensive wind slab formation. High avalanche danger.',
  };

  return {
    index,
    severity,
    loadedAspects,
    crossLoadedAspects,
    message: messages[index],
  };
}

// Temperature Inversion Detection
export interface InversionRisk {
  detected: boolean;
  confidence: number; // 0-1
  type: 'surface' | 'elevated' | 'none';
  message: string;
}

export function detectTemperatureInversion(
  baseTemp: number,
  summitTemp: number,
  baseElevation: number,
  summitElevation: number
): InversionRisk {
  // Normal lapse rate is about -3.5°F per 1000ft
  const elevationDiff = (summitElevation - baseElevation) / 1000;
  const expectedTempDiff = elevationDiff * -3.5;
  const actualTempDiff = summitTemp - baseTemp;

  // If summit is warmer than expected (or warmer than base), inversion detected
  const deviation = actualTempDiff - expectedTempDiff;

  if (actualTempDiff > 0) {
    // Clear inversion: summit is warmer than base
    return {
      detected: true,
      confidence: Math.min(1, actualTempDiff / 10),
      type: 'surface',
      message: `Temperature inversion detected. Summit ${Math.abs(actualTempDiff).toFixed(0)}°F warmer than base.`,
    };
  } else if (deviation > 5) {
    // Elevated inversion: temps don't decrease as expected
    return {
      detected: true,
      confidence: Math.min(1, deviation / 15),
      type: 'elevated',
      message: 'Elevated temperature inversion suspected. Temps not decreasing normally with elevation.',
    };
  }

  return {
    detected: false,
    confidence: 0,
    type: 'none',
    message: 'Normal temperature gradient. No inversion detected.',
  };
}

// Snow Stability Assessment
export interface StabilityAssessment {
  rating: StabilityRating;
  trend: Trend;
  factors: {
    name: string;
    status: 'positive' | 'negative' | 'neutral';
    description: string;
  }[];
  overallMessage: string;
}

export function assessSnowStability(
  temperature: number,
  tempMax: number | null,
  tempMin: number | null,
  humidity: number | null,
  windSpeed: number,
  snowfall24h: number,
  density: number | null,
  settlingRate: number | null
): StabilityAssessment {
  const factors: StabilityAssessment['factors'] = [];
  let positiveCount = 0;
  let negativeCount = 0;

  // Factor 1: Recent snowfall loading
  if (snowfall24h > 12) {
    factors.push({
      name: 'New Snow',
      status: 'negative',
      description: `Heavy new snow (${snowfall24h}") adds significant load`,
    });
    negativeCount += 2;
  } else if (snowfall24h > 6) {
    factors.push({
      name: 'New Snow',
      status: 'negative',
      description: `Moderate new snow (${snowfall24h}") adds load`,
    });
    negativeCount++;
  } else if (snowfall24h > 0) {
    factors.push({
      name: 'New Snow',
      status: 'neutral',
      description: `Light new snow (${snowfall24h}")`,
    });
  } else {
    factors.push({
      name: 'New Snow',
      status: 'positive',
      description: 'No new snow - snowpack can consolidate',
    });
    positiveCount++;
  }

  // Factor 2: Temperature (freeze-thaw cycles)
  if (tempMax !== null && tempMin !== null) {
    const range = tempMax - tempMin;
    if (tempMax > 32 && tempMin < 32) {
      factors.push({
        name: 'Freeze-Thaw',
        status: 'negative',
        description: `Temperature cycling through freezing (${tempMin.toFixed(0)}°F to ${tempMax.toFixed(0)}°F)`,
      });
      negativeCount++;
    } else if (tempMax > 35) {
      factors.push({
        name: 'Warm Temps',
        status: 'negative',
        description: `Warm temps (${tempMax.toFixed(0)}°F) may weaken snow bonds`,
      });
      negativeCount++;
    } else if (temperature < 20) {
      factors.push({
        name: 'Cold Temps',
        status: 'positive',
        description: 'Cold temps preserve snow structure',
      });
      positiveCount++;
    }
  }

  // Factor 3: Wind
  if (windSpeed > 25) {
    factors.push({
      name: 'Wind',
      status: 'negative',
      description: `Strong winds (${windSpeed} mph) creating wind slabs`,
    });
    negativeCount += 2;
  } else if (windSpeed > 15) {
    factors.push({
      name: 'Wind',
      status: 'negative',
      description: `Moderate winds (${windSpeed} mph) may create wind loading`,
    });
    negativeCount++;
  } else {
    factors.push({
      name: 'Wind',
      status: 'positive',
      description: 'Light winds minimize wind loading',
    });
    positiveCount++;
  }

  // Factor 4: Snow density (if available)
  if (density !== null) {
    if (density < 20) {
      factors.push({
        name: 'Density',
        status: 'negative',
        description: `Low density snow (${density}%) - weak cohesion`,
      });
      negativeCount++;
    } else if (density > 40) {
      factors.push({
        name: 'Density',
        status: 'positive',
        description: `Dense snow (${density}%) - good cohesion`,
      });
      positiveCount++;
    }
  }

  // Factor 5: Settling (if available)
  if (settlingRate !== null && settlingRate > 0) {
    factors.push({
      name: 'Settlement',
      status: 'positive',
      description: `Active settlement (${settlingRate.toFixed(1)}"/day) indicates bonding`,
    });
    positiveCount++;
  }

  // Determine overall rating
  let rating: StabilityRating;
  const score = positiveCount - negativeCount;
  if (score >= 2) rating = 'good';
  else if (score >= 0) rating = 'fair';
  else rating = 'poor';

  // Determine trend (simplified - would need historical data)
  let trend: Trend = 'stable';
  if (settlingRate && settlingRate > 1 && snowfall24h === 0) {
    trend = 'improving';
  } else if (snowfall24h > 6 || windSpeed > 20) {
    trend = 'declining';
  }

  // Generate message
  const messages: Record<StabilityRating, string> = {
    good: 'Snowpack appears well-bonded. Continue monitoring conditions.',
    fair: 'Snowpack stability is moderate. Exercise caution on steep terrain.',
    poor: 'Snowpack stability is questionable. Avoid steep terrain and cornices.',
    unknown: 'Insufficient data to assess snowpack stability.',
  };

  return {
    rating,
    trend,
    factors,
    overallMessage: messages[rating],
  };
}

// Snow Type Classification
export function classifySnowType(
  temperature: number,
  humidity: number | null,
  windSpeed: number
): SnowType {
  // Dry powder: cold temps, low humidity, light wind
  if (temperature < 28) {
    if ((humidity === null || humidity < 60) && windSpeed < 15) {
      return 'dry-powder';
    }
  }

  // Wet/heavy: temps near or above freezing, high humidity
  if (temperature > 32 || (humidity !== null && humidity > 85)) {
    return 'wet-heavy';
  }

  // Mixed: everything else
  return 'mixed';
}

// Wind Chill Calculation (NWS formula)
export function calculateWindChill(tempF: number, windMph: number): number {
  // Wind chill only applies when temp <= 50°F and wind >= 3 mph
  if (tempF > 50 || windMph < 3) {
    return tempF;
  }

  const windChill = 35.74 + (0.6215 * tempF) - (35.75 * Math.pow(windMph, 0.16)) + (0.4275 * tempF * Math.pow(windMph, 0.16));
  return Math.round(windChill);
}

// Freezing Level Estimation
export function estimateFreezingLevel(
  baseElevation: number,
  baseTemp: number,
  summitElevation: number,
  summitTemp: number
): number {
  // If both temps are above or below freezing, extrapolate
  if (baseTemp <= 32 && summitTemp <= 32) {
    // Freezing level is below base
    const lapseRate = (summitTemp - baseTemp) / (summitElevation - baseElevation);
    return baseElevation + (32 - baseTemp) / lapseRate;
  }

  if (baseTemp >= 32 && summitTemp >= 32) {
    // Freezing level is above summit
    const lapseRate = (summitTemp - baseTemp) / (summitElevation - baseElevation);
    return summitElevation + (32 - summitTemp) / lapseRate;
  }

  // Linear interpolation between base and summit
  const ratio = (32 - baseTemp) / (summitTemp - baseTemp);
  return baseElevation + ratio * (summitElevation - baseElevation);
}

// Generate Hazard Matrix (aspect x elevation risk levels)
export interface HazardMatrixEntry {
  aspect: Aspect;
  elevation: ElevationBand;
  risk: 1 | 2 | 3 | 4 | 5;
  factors: string[];
}

export function generateHazardMatrix(
  windLoading: WindLoadingResult,
  snowfall24h: number,
  tempMax: number | null,
  tempMin: number | null
): HazardMatrixEntry[] {
  const matrix: HazardMatrixEntry[] = [];
  const elevationBands: ElevationBand[] = ['Alpine', 'Treeline', 'Below Treeline'];

  for (const aspect of ASPECTS) {
    for (const elevation of elevationBands) {
      let risk: 1 | 2 | 3 | 4 | 5 = 1;
      const factors: string[] = [];

      // Base risk from wind loading
      if (windLoading.loadedAspects.includes(aspect)) {
        risk = Math.min(5, risk + windLoading.index - 1) as 1 | 2 | 3 | 4 | 5;
        factors.push('Wind-loaded slope');
      } else if (windLoading.crossLoadedAspects.includes(aspect)) {
        risk = Math.min(5, risk + Math.floor((windLoading.index - 1) / 2)) as 1 | 2 | 3 | 4 | 5;
        factors.push('Cross-loaded slope');
      }

      // Elevation adjustments
      if (elevation === 'Alpine') {
        risk = Math.min(5, risk + 1) as 1 | 2 | 3 | 4 | 5;
        factors.push('Exposed alpine terrain');
      } else if (elevation === 'Below Treeline') {
        risk = Math.max(1, risk - 1) as 1 | 2 | 3 | 4 | 5;
      }

      // New snow loading
      if (snowfall24h > 12) {
        risk = Math.min(5, risk + 2) as 1 | 2 | 3 | 4 | 5;
        factors.push('Heavy new snow');
      } else if (snowfall24h > 6) {
        risk = Math.min(5, risk + 1) as 1 | 2 | 3 | 4 | 5;
        factors.push('Moderate new snow');
      }

      // Aspect-specific solar effects (south-facing + warm temps)
      if (['S', 'SE', 'SW'].includes(aspect) && tempMax !== null && tempMax > 35) {
        risk = Math.min(5, risk + 1) as 1 | 2 | 3 | 4 | 5;
        factors.push('Solar warming on south aspects');
      }

      matrix.push({ aspect, elevation, risk, factors });
    }
  }

  return matrix;
}

// Generate safety alerts based on conditions
export interface SafetyAlert {
  type: 'wind_loading' | 'new_snow' | 'warm_temps' | 'poor_visibility' | 'wind_chill';
  severity: Severity;
  title: string;
  message: string;
  aspect?: Aspect;
}

export function generateSafetyAlerts(
  windLoading: WindLoadingResult,
  snowfall24h: number,
  temperature: number,
  tempMax: number | null,
  windChill: number,
  visibility: number | null
): SafetyAlert[] {
  const alerts: SafetyAlert[] = [];

  // Wind loading alert
  if (windLoading.severity !== 'low') {
    alerts.push({
      type: 'wind_loading',
      severity: windLoading.severity,
      title: 'Wind Loading',
      message: windLoading.message,
    });
  }

  // New snow alert
  if (snowfall24h > 12) {
    alerts.push({
      type: 'new_snow',
      severity: 'high',
      title: 'Heavy Snowfall',
      message: `${snowfall24h}" of new snow in 24 hours. Significant avalanche danger.`,
    });
  } else if (snowfall24h > 6) {
    alerts.push({
      type: 'new_snow',
      severity: 'considerable',
      title: 'Moderate Snowfall',
      message: `${snowfall24h}" of new snow. Monitor for instability.`,
    });
  }

  // Warm temperature alert
  if (tempMax !== null && tempMax > 40) {
    alerts.push({
      type: 'warm_temps',
      severity: 'considerable',
      title: 'Warming Trend',
      message: `High of ${tempMax}°F may cause wet avalanche conditions.`,
    });
  }

  // Visibility alert
  if (visibility !== null && visibility < 0.5) {
    alerts.push({
      type: 'poor_visibility',
      severity: 'considerable',
      title: 'Poor Visibility',
      message: `Visibility under 1/2 mile. Navigation hazards.`,
    });
  } else if (visibility !== null && visibility < 1) {
    alerts.push({
      type: 'poor_visibility',
      severity: 'moderate',
      title: 'Reduced Visibility',
      message: `Visibility ${visibility} miles. Use caution.`,
    });
  }

  // Wind chill alert
  if (windChill < -10) {
    alerts.push({
      type: 'wind_chill',
      severity: 'high',
      title: 'Dangerous Wind Chill',
      message: `Wind chill ${windChill}°F. Frostbite risk in minutes.`,
    });
  } else if (windChill < 10) {
    alerts.push({
      type: 'wind_chill',
      severity: 'moderate',
      title: 'Cold Wind Chill',
      message: `Wind chill ${windChill}°F. Dress warmly.`,
    });
  }

  return alerts.sort((a, b) => {
    const severityOrder: Severity[] = ['extreme', 'high', 'considerable', 'moderate', 'low'];
    return severityOrder.indexOf(a.severity) - severityOrder.indexOf(b.severity);
  });
}
