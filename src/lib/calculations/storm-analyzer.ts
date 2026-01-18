/**
 * Storm Analyzer
 * Tracks incoming storms and calculates which mountains are favored
 * based on wind direction, elevation, and geographic position.
 */

import type { MountainConfig } from '@shredders/shared';
import type { ExtendedDailyForecast } from '../apis/open-meteo';

// ============================================================
// Types
// ============================================================

export interface StormEvent {
  id: string;
  name: string;
  startDate: string;
  endDate: string;
  peakDate: string;
  windDirection: number; // degrees (0-360)
  windDirectionCardinal: string; // NW, SW, etc.
  intensity: 'light' | 'moderate' | 'significant' | 'major';
  totalPrecip: number; // inches of precipitation
  expectedSnow: number; // inches at typical mid-elevation
}

export interface MountainStormImpact {
  mountainId: string;
  mountainName: string;
  expectedSnow: number; // inches
  impactScore: number; // 1-10
  confidence: 'high' | 'medium' | 'low';
  favoredReason: string;
  ranking: number;
}

export interface StormAnalysis {
  storm: StormEvent;
  impacts: MountainStormImpact[];
  summary: string;
  favorsText: string; // "Favors Baker > Stevens > Crystal"
  generatedAt: string;
}

export interface RegionalForecast {
  region: string;
  regionName: string;
  activeStorms: StormAnalysis[];
  nextSevenDays: {
    date: string;
    totalRegionSnow: number;
    bestMountain: string;
    bestMountainSnow: number;
  }[];
  summary: string;
  generatedAt: string;
}

// ============================================================
// Wind Direction Favor Matrix
// ============================================================

/**
 * Each mountain has wind directions that favor it.
 * This is based on orographic lift and mountain positioning.
 */
const WIND_FAVOR_MATRIX: Record<string, { favored: number[]; neutral: number[]; unfavored: number[] }> = {
  // Washington - West
  baker: {
    favored: [270, 285, 300, 315], // W to NW flow (direct Pacific, exposed to west)
    neutral: [240, 255, 330, 345],
    unfavored: [0, 15, 30, 45, 60, 75, 90, 180, 195, 210], // E winds, S winds
  },
  stevens: {
    favored: [255, 270, 285, 300], // W to WNW flow
    neutral: [240, 315, 330],
    unfavored: [0, 15, 30, 45, 60, 75, 90, 180], // E/SE winds
  },
  crystal: {
    favored: [195, 210, 225, 240, 255], // SW to W flow (sheltered from direct NW)
    neutral: [180, 270, 285],
    unfavored: [0, 15, 30, 45, 60, 315, 330, 345], // NW/N/E winds
  },
  snoqualmie: {
    favored: [240, 255, 270, 285], // W to WSW flow
    neutral: [225, 300],
    unfavored: [0, 15, 30, 45, 60, 90, 120], // E winds
  },
  whitepass: {
    favored: [195, 210, 225, 240], // S to SW flow
    neutral: [180, 255, 270],
    unfavored: [0, 15, 30, 315, 330, 345], // N/NW winds
  },

  // Washington - East
  missionridge: {
    favored: [255, 270, 285, 300], // W to NW flow (gets spillover)
    neutral: [240, 315],
    unfavored: [0, 45, 90, 135, 180], // E/SE winds (rain shadow)
  },
  fortynine: {
    favored: [240, 255, 270, 285, 300], // W to NW flow
    neutral: [225, 315],
    unfavored: [0, 45, 90, 135], // E winds
  },

  // Oregon
  meadows: {
    favored: [210, 225, 240, 255, 270], // SW to W flow
    neutral: [195, 285],
    unfavored: [0, 45, 90, 315, 330, 345], // N/E winds
  },
  timberline: {
    favored: [210, 225, 240, 255, 270], // SW to W flow
    neutral: [195, 285],
    unfavored: [0, 45, 90, 315, 330, 345], // N/E winds
  },
  bachelor: {
    favored: [225, 240, 255, 270], // SW to W flow
    neutral: [210, 285, 300],
    unfavored: [0, 45, 90, 135], // E winds (high desert effect)
  },
  hoodoo: {
    favored: [210, 225, 240, 255], // SW flow
    neutral: [195, 270],
    unfavored: [0, 45, 90, 315, 330], // N/E winds
  },
  willamette: {
    favored: [210, 225, 240, 255], // SW flow
    neutral: [195, 270],
    unfavored: [0, 45, 90, 315, 330], // N/E winds
  },
  ashland: {
    favored: [195, 210, 225, 240], // S to SW flow
    neutral: [180, 255],
    unfavored: [0, 45, 315, 330, 345], // N/NE winds
  },

  // Idaho
  schweitzer: {
    favored: [240, 255, 270, 285, 300], // W to NW flow
    neutral: [225, 315],
    unfavored: [0, 45, 90, 135, 180], // E/SE winds
  },
  lookout: {
    favored: [255, 270, 285, 300], // W to NW flow
    neutral: [240, 315],
    unfavored: [0, 45, 90, 135], // E winds
  },
  sunvalley: {
    favored: [240, 255, 270, 285], // W to WNW flow
    neutral: [225, 300],
    unfavored: [0, 45, 90, 135, 180], // E/SE winds (high desert)
  },
  brundage: {
    favored: [240, 255, 270, 285], // W to WNW flow
    neutral: [225, 300],
    unfavored: [0, 45, 90, 135], // E winds
  },

  // Canada
  whistler: {
    favored: [195, 210, 225, 240, 255], // SW to W flow
    neutral: [180, 270, 285],
    unfavored: [0, 45, 90, 315, 330, 345], // N/E winds
  },
  revelstoke: {
    favored: [225, 240, 255, 270, 285], // SW to W flow
    neutral: [210, 300],
    unfavored: [0, 45, 90, 135], // E winds
  },
  cypress: {
    favored: [195, 210, 225, 240], // SW flow (coastal)
    neutral: [180, 255, 270],
    unfavored: [0, 45, 90, 315, 330, 345], // N/E winds
  },
  bigwhite: {
    favored: [240, 255, 270, 285], // W to WNW flow
    neutral: [225, 300],
    unfavored: [0, 45, 90, 135, 180], // E/SE winds
  },
  sunpeaks: {
    favored: [225, 240, 255, 270], // SW to W flow
    neutral: [210, 285],
    unfavored: [0, 45, 90, 135], // E winds
  },
  silverstar: {
    favored: [240, 255, 270, 285], // W to WNW flow
    neutral: [225, 300],
    unfavored: [0, 45, 90, 135], // E winds
  },
  apex: {
    favored: [225, 240, 255, 270], // SW to W flow
    neutral: [210, 285],
    unfavored: [0, 45, 90, 135, 180], // E/SE winds
  },
  red: {
    favored: [225, 240, 255, 270, 285], // SW to W flow
    neutral: [210, 300],
    unfavored: [0, 45, 90, 135], // E winds
  },
  panorama: {
    favored: [225, 240, 255, 270], // SW to W flow
    neutral: [210, 285],
    unfavored: [0, 45, 90, 135], // E winds
  },
};

// ============================================================
// Helper Functions
// ============================================================

/**
 * Convert degrees to cardinal direction
 */
function degreesToCardinal(degrees: number): string {
  const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  const index = Math.round(degrees / 22.5) % 16;
  return directions[index];
}

/**
 * Calculate how favored a mountain is for a given wind direction
 * Returns a score from 0-10
 */
function calculateWindFavor(mountainId: string, windDirection: number): number {
  const favor = WIND_FAVOR_MATRIX[mountainId];
  if (!favor) return 5; // Default neutral score

  // Normalize wind direction to 0-360
  const normalizedWind = ((windDirection % 360) + 360) % 360;

  // Check if wind direction is within any favored range (allowing 15-degree tolerance)
  for (const favoredDir of favor.favored) {
    const diff = Math.abs(normalizedWind - favoredDir);
    const wrappedDiff = Math.min(diff, 360 - diff);
    if (wrappedDiff <= 22.5) {
      return 9 - (wrappedDiff / 22.5) * 2; // 7-9 score
    }
  }

  // Check neutral
  for (const neutralDir of favor.neutral) {
    const diff = Math.abs(normalizedWind - neutralDir);
    const wrappedDiff = Math.min(diff, 360 - diff);
    if (wrappedDiff <= 22.5) {
      return 5 + (1 - wrappedDiff / 22.5); // 5-6 score
    }
  }

  // Check unfavored
  for (const unfavoredDir of favor.unfavored) {
    const diff = Math.abs(normalizedWind - unfavoredDir);
    const wrappedDiff = Math.min(diff, 360 - diff);
    if (wrappedDiff <= 22.5) {
      return 2 + (wrappedDiff / 22.5) * 2; // 2-4 score
    }
  }

  return 5; // Default neutral
}

/**
 * Calculate elevation factor for snow amounts
 * Higher elevations generally get more snow
 */
function calculateElevationFactor(mountain: MountainConfig): number {
  const avgElevation = (mountain.elevation.base + mountain.elevation.summit) / 2;

  // Base factor on elevation (4000' = 1.0, 6000' = 1.2, 8000' = 1.4)
  return 0.8 + (avgElevation / 10000);
}

/**
 * Determine storm intensity from expected precipitation
 */
function determineIntensity(precipInches: number): 'light' | 'moderate' | 'significant' | 'major' {
  if (precipInches >= 3) return 'major';
  if (precipInches >= 1.5) return 'significant';
  if (precipInches >= 0.5) return 'moderate';
  return 'light';
}

/**
 * Generate a unique storm ID
 */
function generateStormId(startDate: string, windDir: number): string {
  const dateHash = startDate.replace(/-/g, '');
  const dirHash = Math.round(windDir / 45);
  return `storm-${dateHash}-${dirHash}`;
}

/**
 * Generate a storm name based on characteristics
 */
function generateStormName(windDir: number, intensity: string): string {
  const cardinal = degreesToCardinal(windDir);
  const prefix = intensity === 'major' ? 'Major' : intensity === 'significant' ? 'Strong' : '';
  return `${prefix} ${cardinal} Flow`.trim();
}

// ============================================================
// Main Functions
// ============================================================

/**
 * Detect storms from forecast data
 */
export function detectStorms(forecast: ExtendedDailyForecast[]): StormEvent[] {
  const storms: StormEvent[] = [];
  let currentStorm: Partial<StormEvent> | null = null;
  let stormPrecip = 0;
  let stormSnow = 0;
  let peakPrecipDay = 0;
  let peakPrecipAmount = 0;
  let stormDays: ExtendedDailyForecast[] = [];

  for (let i = 0; i < forecast.length; i++) {
    const day = forecast[i];
    const hasPrecip = day.precipProbability >= 40 && day.precipitationSum >= 0.1;

    if (hasPrecip) {
      if (!currentStorm) {
        // Start new storm
        currentStorm = {
          startDate: day.date,
          windDirection: day.windDirection,
        };
        stormPrecip = day.precipitationSum;
        stormSnow = day.snowfallSum;
        stormDays = [day];

        if (day.precipitationSum > peakPrecipAmount) {
          peakPrecipAmount = day.precipitationSum;
          peakPrecipDay = i;
        }
      } else {
        // Continue storm
        stormPrecip += day.precipitationSum;
        stormSnow += day.snowfallSum;
        stormDays.push(day);

        if (day.precipitationSum > peakPrecipAmount) {
          peakPrecipAmount = day.precipitationSum;
          peakPrecipDay = stormDays.length - 1;
        }
      }
    } else if (currentStorm) {
      // Storm ended - check if it's significant enough to track
      if (stormPrecip >= 0.3 || stormSnow >= 2) {
        // Calculate average wind direction during storm
        const avgWindDir = stormDays.reduce((sum, d) => sum + d.windDirection, 0) / stormDays.length;
        const intensity = determineIntensity(stormPrecip);

        storms.push({
          id: generateStormId(currentStorm.startDate!, avgWindDir),
          name: generateStormName(avgWindDir, intensity),
          startDate: currentStorm.startDate!,
          endDate: stormDays[stormDays.length - 1].date,
          peakDate: stormDays[Math.min(peakPrecipDay, stormDays.length - 1)].date,
          windDirection: Math.round(avgWindDir),
          windDirectionCardinal: degreesToCardinal(avgWindDir),
          intensity,
          totalPrecip: Math.round(stormPrecip * 10) / 10,
          expectedSnow: Math.round(stormSnow * 10) / 10,
        });
      }

      // Reset
      currentStorm = null;
      stormPrecip = 0;
      stormSnow = 0;
      peakPrecipAmount = 0;
      stormDays = [];
    }
  }

  // Handle storm that continues to end of forecast
  if (currentStorm && (stormPrecip >= 0.3 || stormSnow >= 2)) {
    const avgWindDir = stormDays.reduce((sum, d) => sum + d.windDirection, 0) / stormDays.length;
    const intensity = determineIntensity(stormPrecip);

    storms.push({
      id: generateStormId(currentStorm.startDate!, avgWindDir),
      name: generateStormName(avgWindDir, intensity),
      startDate: currentStorm.startDate!,
      endDate: stormDays[stormDays.length - 1].date,
      peakDate: stormDays[Math.min(peakPrecipDay, stormDays.length - 1)].date,
      windDirection: Math.round(avgWindDir),
      windDirectionCardinal: degreesToCardinal(avgWindDir),
      intensity,
      totalPrecip: Math.round(stormPrecip * 10) / 10,
      expectedSnow: Math.round(stormSnow * 10) / 10,
    });
  }

  return storms;
}

/**
 * Calculate storm impact for each mountain
 */
export function calculateStormImpact(
  storm: StormEvent,
  mountains: MountainConfig[]
): MountainStormImpact[] {
  const impacts: MountainStormImpact[] = [];

  for (const mountain of mountains) {
    // Calculate wind favor score
    const windFavor = calculateWindFavor(mountain.id, storm.windDirection);

    // Calculate elevation factor
    const elevationFactor = calculateElevationFactor(mountain);

    // Calculate expected snow (base amount * wind favor * elevation)
    const expectedSnow = Math.round(storm.expectedSnow * (windFavor / 5) * elevationFactor * 10) / 10;

    // Calculate overall impact score (1-10)
    const impactScore = Math.round(Math.min(10, (windFavor * 0.6 + (expectedSnow / storm.expectedSnow) * 4)));

    // Determine confidence
    const confidence: 'high' | 'medium' | 'low' =
      storm.intensity === 'major' || storm.intensity === 'significant' ? 'high' :
      storm.intensity === 'moderate' ? 'medium' : 'low';

    // Generate reason
    let favoredReason: string;
    if (windFavor >= 7) {
      favoredReason = `${storm.windDirectionCardinal} flow directly favors this location`;
    } else if (windFavor >= 5) {
      favoredReason = `Neutral positioning for ${storm.windDirectionCardinal} flow`;
    } else {
      favoredReason = `Less favored for ${storm.windDirectionCardinal} flow`;
    }

    impacts.push({
      mountainId: mountain.id,
      mountainName: mountain.name,
      expectedSnow,
      impactScore,
      confidence,
      favoredReason,
      ranking: 0, // Will be set after sorting
    });
  }

  // Sort by impact score and assign rankings
  impacts.sort((a, b) => b.impactScore - a.impactScore);
  impacts.forEach((impact, index) => {
    impact.ranking = index + 1;
  });

  return impacts;
}

/**
 * Analyze a storm and generate complete analysis
 */
export function analyzeStorm(
  storm: StormEvent,
  mountains: MountainConfig[]
): StormAnalysis {
  const impacts = calculateStormImpact(storm, mountains);

  // Generate "favors" text (top 3 mountains)
  const top3 = impacts.slice(0, 3);
  const favorsText = `Favors ${top3.map(i => i.mountainName.replace(/Mt\.|Mountain| Pass| Resort/g, '').trim()).join(' > ')}`;

  // Generate summary
  const topMountain = impacts[0];
  const summary = `${storm.name} (${storm.startDate} to ${storm.endDate}): ${storm.intensity} storm with ${storm.windDirectionCardinal} flow. ${topMountain.mountainName} most favored with ${topMountain.expectedSnow}" expected.`;

  return {
    storm,
    impacts,
    summary,
    favorsText,
    generatedAt: new Date().toISOString(),
  };
}

/**
 * Get all active/upcoming storms for a region
 */
export function getActiveStorms(
  forecasts: Map<string, ExtendedDailyForecast[]>,
  mountains: MountainConfig[]
): StormAnalysis[] {
  // Use the first mountain's forecast to detect storms
  // (assumes storms affect the whole region similarly)
  const firstForecast = Array.from(forecasts.values())[0];
  if (!firstForecast) return [];

  const storms = detectStorms(firstForecast);

  return storms.map(storm => analyzeStorm(storm, mountains));
}

/**
 * Generate regional forecast with storm rankings
 */
export function generateRegionalForecast(
  region: string,
  regionName: string,
  forecasts: Map<string, ExtendedDailyForecast[]>,
  mountains: MountainConfig[]
): RegionalForecast {
  // Get active storms
  const activeStorms = getActiveStorms(forecasts, mountains);

  // Calculate next 7 days summary
  const firstForecast = Array.from(forecasts.values())[0] || [];
  const nextSevenDays = firstForecast.slice(0, 7).map(day => {
    // Find best mountain for this day
    let bestMountain = '';
    let bestSnow = 0;
    let totalSnow = 0;

    for (const [mountainId, forecast] of forecasts.entries()) {
      const dayForecast = forecast.find(f => f.date === day.date);
      if (dayForecast) {
        totalSnow += dayForecast.snowfallSum;
        if (dayForecast.snowfallSum > bestSnow) {
          bestSnow = dayForecast.snowfallSum;
          bestMountain = mountains.find(m => m.id === mountainId)?.shortName || mountainId;
        }
      }
    }

    return {
      date: day.date,
      totalRegionSnow: Math.round(totalSnow * 10) / 10,
      bestMountain,
      bestMountainSnow: bestSnow,
    };
  });

  // Generate summary
  const totalRegionSnow = nextSevenDays.reduce((sum, d) => sum + d.totalRegionSnow, 0);
  const stormCount = activeStorms.length;

  let summary: string;
  if (stormCount === 0) {
    summary = `Quiet pattern for ${regionName} over the next 7 days with ${Math.round(totalRegionSnow)}" total expected across the region.`;
  } else if (stormCount === 1) {
    summary = `One storm system affecting ${regionName}: ${activeStorms[0].favorsText}. Total regional snow: ${Math.round(totalRegionSnow)}".`;
  } else {
    summary = `${stormCount} storm systems affecting ${regionName} over the next 7 days. ${Math.round(totalRegionSnow)}" total expected.`;
  }

  return {
    region,
    regionName,
    activeStorms,
    nextSevenDays,
    summary,
    generatedAt: new Date().toISOString(),
  };
}
