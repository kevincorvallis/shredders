/**
 * Weather Pattern Analyzer
 * Detects meteorological patterns like "active storm cycle", "high pressure ridge", etc.
 * for long-range outlook narratives.
 */

import type { ExtendedDailyForecast, WeatherPattern } from '../apis/open-meteo';

export type PatternType =
  | 'storm_cycle'
  | 'high_pressure'
  | 'cold_pattern'
  | 'warm_pattern'
  | 'transition'
  | 'neutral';

export interface PatternAnalysis {
  patterns: WeatherPattern[];
  overallTrend: 'active' | 'quiet' | 'mixed';
  temperatureRegime: 'cold' | 'mild' | 'warm' | 'variable';
  totalExpectedSnow: number;
  bestPowderWindow: { start: string; end: string } | null;
  narrative: string;
}

interface DayMetrics {
  date: string;
  hasSnow: boolean;
  hasPrecip: boolean;
  isCold: boolean;
  isWarm: boolean;
  isWindy: boolean;
  snowAmount: number;
  precipAmount: number;
  avgTemp: number;
}

/**
 * Convert extended forecast data to day metrics for pattern analysis
 */
function forecastToDayMetrics(forecast: ExtendedDailyForecast): DayMetrics {
  const avgTemp = (forecast.highTemp + forecast.lowTemp) / 2;

  return {
    date: forecast.date,
    hasSnow: forecast.snowfallSum > 0.5,
    hasPrecip: forecast.precipitationSum > 0.1,
    isCold: avgTemp < 28,
    isWarm: forecast.highTemp > 38,
    isWindy: forecast.windSpeedMax > 25,
    snowAmount: forecast.snowfallSum,
    precipAmount: forecast.precipitationSum,
    avgTemp,
  };
}

/**
 * Detect consecutive storm patterns
 */
function detectStormCycles(metrics: DayMetrics[]): WeatherPattern[] {
  const patterns: WeatherPattern[] = [];
  let stormStart: number | null = null;
  let consecutiveSnowDays = 0;
  let totalStormSnow = 0;

  for (let i = 0; i < metrics.length; i++) {
    const day = metrics[i];

    if (day.hasSnow || (day.hasPrecip && day.isCold)) {
      if (stormStart === null) {
        stormStart = i;
        consecutiveSnowDays = 1;
        totalStormSnow = day.snowAmount;
      } else {
        consecutiveSnowDays++;
        totalStormSnow += day.snowAmount;
      }
    } else if (stormStart !== null) {
      // Storm ended
      if (consecutiveSnowDays >= 2 || totalStormSnow >= 6) {
        const startDate = metrics[stormStart].date;
        const endDate = metrics[i - 1].date;

        patterns.push({
          type: 'storm_cycle',
          startDate,
          endDate,
          description: generateStormDescription(consecutiveSnowDays, totalStormSnow),
          confidence: consecutiveSnowDays >= 3 ? 'high' : 'medium',
        });
      }
      stormStart = null;
      consecutiveSnowDays = 0;
      totalStormSnow = 0;
    }
  }

  // Check if storm continues to end of forecast
  if (stormStart !== null && (consecutiveSnowDays >= 2 || totalStormSnow >= 6)) {
    patterns.push({
      type: 'storm_cycle',
      startDate: metrics[stormStart].date,
      endDate: metrics[metrics.length - 1].date,
      description: generateStormDescription(consecutiveSnowDays, totalStormSnow),
      confidence: consecutiveSnowDays >= 3 ? 'high' : 'medium',
    });
  }

  return patterns;
}

/**
 * Generate descriptive text for storm patterns
 */
function generateStormDescription(days: number, totalSnow: number): string {
  const intensity = totalSnow >= 18 ? 'significant' : totalSnow >= 10 ? 'moderate' : 'light';
  const duration = days >= 5 ? 'extended' : days >= 3 ? 'multi-day' : 'brief';

  return `${duration.charAt(0).toUpperCase() + duration.slice(1)} storm cycle bringing ${intensity} snowfall (${Math.round(totalSnow)}" expected)`;
}

/**
 * Detect high pressure / dry patterns
 */
function detectHighPressure(metrics: DayMetrics[]): WeatherPattern[] {
  const patterns: WeatherPattern[] = [];
  let dryStart: number | null = null;
  let consecutiveDryDays = 0;

  for (let i = 0; i < metrics.length; i++) {
    const day = metrics[i];

    if (!day.hasSnow && !day.hasPrecip && day.precipAmount < 0.05) {
      if (dryStart === null) {
        dryStart = i;
        consecutiveDryDays = 1;
      } else {
        consecutiveDryDays++;
      }
    } else if (dryStart !== null) {
      if (consecutiveDryDays >= 3) {
        patterns.push({
          type: 'high_pressure',
          startDate: metrics[dryStart].date,
          endDate: metrics[i - 1].date,
          description: `${consecutiveDryDays}-day dry spell with stable conditions`,
          confidence: consecutiveDryDays >= 5 ? 'high' : 'medium',
        });
      }
      dryStart = null;
      consecutiveDryDays = 0;
    }
  }

  // Check if dry spell continues to end
  if (dryStart !== null && consecutiveDryDays >= 3) {
    patterns.push({
      type: 'high_pressure',
      startDate: metrics[dryStart].date,
      endDate: metrics[metrics.length - 1].date,
      description: `${consecutiveDryDays}-day dry spell with stable conditions`,
      confidence: consecutiveDryDays >= 5 ? 'high' : 'medium',
    });
  }

  return patterns;
}

/**
 * Detect temperature patterns (cold/warm)
 */
function detectTemperaturePatterns(metrics: DayMetrics[]): WeatherPattern[] {
  const patterns: WeatherPattern[] = [];

  // Calculate average temps for the period
  const avgTemps = metrics.map(m => m.avgTemp);
  const overallAvg = avgTemps.reduce((a, b) => a + b, 0) / avgTemps.length;

  // Detect cold snaps
  let coldStart: number | null = null;
  let consecutiveColdDays = 0;

  for (let i = 0; i < metrics.length; i++) {
    const day = metrics[i];

    if (day.isCold) {
      if (coldStart === null) {
        coldStart = i;
        consecutiveColdDays = 1;
      } else {
        consecutiveColdDays++;
      }
    } else if (coldStart !== null) {
      if (consecutiveColdDays >= 3) {
        const avgColdTemp = metrics
          .slice(coldStart, i)
          .reduce((sum, m) => sum + m.avgTemp, 0) / (i - coldStart);

        patterns.push({
          type: 'cold_pattern',
          startDate: metrics[coldStart].date,
          endDate: metrics[i - 1].date,
          description: `Cold pattern with temps averaging ${Math.round(avgColdTemp)}°F`,
          confidence: consecutiveColdDays >= 5 ? 'high' : 'medium',
        });
      }
      coldStart = null;
      consecutiveColdDays = 0;
    }
  }

  // Detect warm spells (potential rain risk)
  let warmStart: number | null = null;
  let consecutiveWarmDays = 0;

  for (let i = 0; i < metrics.length; i++) {
    const day = metrics[i];

    if (day.isWarm) {
      if (warmStart === null) {
        warmStart = i;
        consecutiveWarmDays = 1;
      } else {
        consecutiveWarmDays++;
      }
    } else if (warmStart !== null) {
      if (consecutiveWarmDays >= 2) {
        patterns.push({
          type: 'warm_pattern',
          startDate: metrics[warmStart].date,
          endDate: metrics[i - 1].date,
          description: `Warm spell - watch for rain/mixed precip at lower elevations`,
          confidence: consecutiveWarmDays >= 4 ? 'high' : 'medium',
        });
      }
      warmStart = null;
      consecutiveWarmDays = 0;
    }
  }

  return patterns;
}

/**
 * Determine overall temperature regime
 */
function determineTemperatureRegime(metrics: DayMetrics[]): 'cold' | 'mild' | 'warm' | 'variable' {
  const avgTemps = metrics.map(m => m.avgTemp);
  const overall = avgTemps.reduce((a, b) => a + b, 0) / avgTemps.length;
  const variance = Math.sqrt(
    avgTemps.reduce((sum, t) => sum + Math.pow(t - overall, 2), 0) / avgTemps.length
  );

  if (variance > 10) return 'variable';
  if (overall < 25) return 'cold';
  if (overall > 35) return 'warm';
  return 'mild';
}

/**
 * Find the best powder window in the forecast
 */
function findBestPowderWindow(metrics: DayMetrics[]): { start: string; end: string } | null {
  let bestStart = -1;
  let bestEnd = -1;
  let bestScore = 0;

  for (let i = 0; i < metrics.length; i++) {
    // Look for days with significant snow
    if (metrics[i].snowAmount >= 4 && metrics[i].isCold) {
      // Score this potential window
      let windowScore = metrics[i].snowAmount;
      let endIdx = i;

      // Extend window if next days also have snow
      for (let j = i + 1; j < Math.min(i + 4, metrics.length); j++) {
        if (metrics[j].snowAmount > 0 && metrics[j].isCold) {
          windowScore += metrics[j].snowAmount;
          endIdx = j;
        } else {
          break;
        }
      }

      if (windowScore > bestScore) {
        bestScore = windowScore;
        bestStart = i;
        bestEnd = endIdx;
      }
    }
  }

  if (bestStart >= 0) {
    return {
      start: metrics[bestStart].date,
      end: metrics[bestEnd].date,
    };
  }

  return null;
}

/**
 * Generate narrative text for the overall pattern
 */
function generateNarrative(
  patterns: WeatherPattern[],
  overallTrend: 'active' | 'quiet' | 'mixed',
  tempRegime: 'cold' | 'mild' | 'warm' | 'variable',
  totalSnow: number,
  bestWindow: { start: string; end: string } | null
): string {
  const parts: string[] = [];

  // Overall trend
  if (overallTrend === 'active') {
    parts.push('An active pattern continues');
  } else if (overallTrend === 'quiet') {
    parts.push('A quiet, stable pattern dominates');
  } else {
    parts.push('A transitional pattern is expected');
  }

  // Temperature context
  if (tempRegime === 'cold') {
    parts.push('with cold temperatures favoring snow at all elevations');
  } else if (tempRegime === 'warm') {
    parts.push('but warm temps may bring mixed precip to lower elevations');
  } else if (tempRegime === 'variable') {
    parts.push('with variable temps - check freezing levels closely');
  }

  // Snow totals
  if (totalSnow >= 24) {
    parts.push(`Significant accumulations expected (${Math.round(totalSnow)}" total)`);
  } else if (totalSnow >= 12) {
    parts.push(`Moderate snowfall expected (${Math.round(totalSnow)}" total)`);
  } else if (totalSnow > 0) {
    parts.push(`Light snow chances (${Math.round(totalSnow)}" total)`);
  } else {
    parts.push('Little to no snowfall expected');
  }

  // Best window
  if (bestWindow) {
    const startDate = new Date(bestWindow.start);
    const endDate = new Date(bestWindow.end);
    const startDay = startDate.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    const endDay = endDate.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });

    if (bestWindow.start === bestWindow.end) {
      parts.push(`Best powder opportunity: ${startDay}`);
    } else {
      parts.push(`Best powder window: ${startDay} - ${endDay}`);
    }
  }

  return parts.join('. ') + '.';
}

/**
 * Main pattern analysis function
 */
export function analyzePatterns(forecast: ExtendedDailyForecast[]): PatternAnalysis {
  if (forecast.length === 0) {
    return {
      patterns: [],
      overallTrend: 'quiet',
      temperatureRegime: 'mild',
      totalExpectedSnow: 0,
      bestPowderWindow: null,
      narrative: 'No forecast data available.',
    };
  }

  const metrics = forecast.map(forecastToDayMetrics);

  // Detect all patterns
  const stormPatterns = detectStormCycles(metrics);
  const highPressurePatterns = detectHighPressure(metrics);
  const tempPatterns = detectTemperaturePatterns(metrics);

  const allPatterns = [...stormPatterns, ...highPressurePatterns, ...tempPatterns]
    .sort((a, b) => a.startDate.localeCompare(b.startDate));

  // Calculate overall metrics
  const totalSnow = metrics.reduce((sum, m) => sum + m.snowAmount, 0);
  const snowDays = metrics.filter(m => m.hasSnow).length;
  const precipDays = metrics.filter(m => m.hasPrecip).length;

  // Determine overall trend
  let overallTrend: 'active' | 'quiet' | 'mixed';
  if (snowDays >= metrics.length * 0.5 || totalSnow >= 18) {
    overallTrend = 'active';
  } else if (precipDays <= metrics.length * 0.2) {
    overallTrend = 'quiet';
  } else {
    overallTrend = 'mixed';
  }

  const tempRegime = determineTemperatureRegime(metrics);
  const bestWindow = findBestPowderWindow(metrics);

  const narrative = generateNarrative(
    allPatterns,
    overallTrend,
    tempRegime,
    totalSnow,
    bestWindow
  );

  return {
    patterns: allPatterns,
    overallTrend,
    temperatureRegime: tempRegime,
    totalExpectedSnow: Math.round(totalSnow * 10) / 10,
    bestPowderWindow: bestWindow,
    narrative,
  };
}

/**
 * Get a human-readable pattern type name
 */
export function getPatternTypeName(type: PatternType): string {
  const names: Record<PatternType, string> = {
    storm_cycle: 'Storm Cycle',
    high_pressure: 'High Pressure Ridge',
    cold_pattern: 'Cold Pattern',
    warm_pattern: 'Warm Spell',
    transition: 'Transition Period',
    neutral: 'Neutral Pattern',
  };
  return names[type];
}
