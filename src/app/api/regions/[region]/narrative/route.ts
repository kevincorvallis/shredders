import { NextResponse } from 'next/server';
import { getMountainsByRegion, getAllMountains, type MountainConfig } from '@shredders/shared';
import { getExtendedForecast, getMultiModelForecast, type ExtendedDailyForecast } from '@/lib/apis/open-meteo';
import { detectStorms } from '@/lib/calculations/storm-analyzer';
import {
  generateRegionalNarrative,
  type RegionalNarrativeInput,
  type RegionalNarrative,
} from '@/lib/apis/claude';

const REGION_NAMES: Record<string, string> = {
  washington: 'Washington',
  oregon: 'Oregon',
  idaho: 'Idaho',
  canada: 'British Columbia',
  utah: 'Utah',
  colorado: 'Colorado',
  california: 'California',
  wyoming: 'Wyoming',
  montana: 'Montana',
  vermont: 'Vermont',
  newmexico: 'New Mexico',
  'pnw-north': 'PNW North',
  'pnw-central': 'PNW Central',
  'pnw-south': 'PNW South',
};

// Subregion definitions
const SUBREGIONS: Record<string, string[]> = {
  'pnw-north': ['baker', 'stevens', 'whistler', 'fortynine'],
  'pnw-central': ['crystal', 'snoqualmie', 'whitepass', 'missionridge'],
  'pnw-south': ['meadows', 'timberline', 'bachelor', 'hoodoo', 'willamette'],
};

type ValidRegion = 'washington' | 'oregon' | 'idaho' | 'canada' | 'utah' | 'colorado' | 'california' | 'wyoming' | 'montana' | 'vermont' | 'newmexico';

export interface RegionalNarrativeResponse {
  region: string;
  regionName: string;
  narrative: RegionalNarrative;
  mountains: Array<{
    id: string;
    name: string;
    expectedSnow3Day: number;
  }>;
  stormInfo: {
    activeStorms: number;
    primaryWindDirection: string | null;
    favoredMountains: string[];
  };
  confidence: {
    level: 'high' | 'medium' | 'low';
    snowSpread: number;
  };
  generatedAt: string;
}

export async function GET(
  request: Request,
  { params }: { params: Promise<{ region: string }> }
) {
  const { region } = await params;

  // Validate region
  const isValidRegion = ['washington', 'oregon', 'idaho', 'canada', 'utah', 'colorado', 'california', 'wyoming', 'montana', 'vermont', 'newmexico'].includes(region);
  const isValidSubregion = region in SUBREGIONS;

  if (!isValidRegion && !isValidSubregion) {
    return NextResponse.json(
      {
        error: `Invalid region '${region}'`,
        validRegions: Object.keys(REGION_NAMES),
      },
      { status: 404 }
    );
  }

  const regionName = REGION_NAMES[region] || region;

  try {
    // Get mountains for this region
    let mountains: MountainConfig[];

    if (isValidSubregion) {
      const allMountains = getAllMountains();
      mountains = allMountains.filter(m => SUBREGIONS[region].includes(m.id));
    } else {
      mountains = getMountainsByRegion(region as ValidRegion);
    }

    if (mountains.length === 0) {
      return NextResponse.json(
        { error: `No mountains found for region '${region}'` },
        { status: 404 }
      );
    }

    // Fetch forecasts for all mountains (limit to first 5 for API efficiency)
    const mountainsToFetch = mountains.slice(0, 5);

    const forecastPromises = mountainsToFetch.map(async mountain => {
      try {
        const forecast = await getExtendedForecast(
          mountain.location.lat,
          mountain.location.lng,
          7
        );
        return { mountain, forecast };
      } catch (err) {
        console.warn(`Failed to fetch forecast for ${mountain.id}:`, err);
        return { mountain, forecast: [] as ExtendedDailyForecast[] };
      }
    });

    const forecastResults = await Promise.all(forecastPromises);

    // Get multi-model data for confidence assessment from first mountain
    let modelConfidence: 'high' | 'medium' | 'low' = 'medium';
    let snowSpread = 0;

    try {
      const firstMountain = mountainsToFetch[0];
      const modelData = await getMultiModelForecast(
        firstMountain.location.lat,
        firstMountain.location.lng,
        3
      );

      if (modelData.agreement.length > 0) {
        const avgConfidence = modelData.agreement.reduce(
          (sum, a) => sum + a.confidencePercent, 0
        ) / modelData.agreement.length;

        modelConfidence = avgConfidence >= 70 ? 'high' : avgConfidence >= 45 ? 'medium' : 'low';
        snowSpread = Math.max(...modelData.agreement.map(a => a.snowfallRange.spread));
      }
    } catch (err) {
      console.warn('Failed to fetch model data:', err);
    }

    // Detect storms from first mountain's forecast
    let activeStorms = 0;
    let primaryWindDirection: string | null = null;
    const favoredMountains: string[] = [];

    const firstForecast = forecastResults[0]?.forecast;
    if (firstForecast && firstForecast.length > 0) {
      const storms = detectStorms(firstForecast);
      activeStorms = storms.length;

      if (storms.length > 0) {
        primaryWindDirection = storms[0].windDirectionCardinal;

        // Simple favoring logic based on wind direction
        const windDir = storms[0].windDirection;
        if (windDir >= 270 && windDir <= 330) {
          // NW flow
          favoredMountains.push('Baker', 'Stevens');
        } else if (windDir >= 210 && windDir < 270) {
          // SW flow
          favoredMountains.push('Crystal', 'Hood');
        } else if (windDir >= 180 && windDir < 210) {
          // S flow
          favoredMountains.push('White Pass', 'Bachelor');
        }
      }
    }

    // Prepare input for narrative generation
    const narrativeInput: RegionalNarrativeInput = {
      region,
      regionName,
      mountains: forecastResults.map(({ mountain, forecast }) => ({
        id: mountain.id,
        name: mountain.name,
        forecast: forecast.map(f => ({
          date: f.date,
          dayOfWeek: new Date(f.date).toLocaleDateString('en-US', { weekday: 'short' }),
          snowfall: f.snowfallSum,
          high: f.highTemp,
          low: f.lowTemp,
          precipProbability: f.precipProbability,
          windDirection: f.windDirection,
        })),
      })),
      stormData: activeStorms > 0 ? {
        activeStorms,
        primaryWindDirection: primaryWindDirection || 'Variable',
        favoredMountains,
      } : undefined,
      modelAgreement: {
        confidence: modelConfidence,
        snowSpread,
      },
    };

    // Generate AI narrative
    const narrative = await generateRegionalNarrative(narrativeInput);

    // Calculate 3-day snow totals for each mountain
    const mountainSnowTotals = forecastResults.map(({ mountain, forecast }) => ({
      id: mountain.id,
      name: mountain.name,
      expectedSnow3Day: Math.round(
        forecast.slice(0, 3).reduce((sum, f) => sum + f.snowfallSum, 0) * 10
      ) / 10,
    }));

    // Sort by snow totals
    mountainSnowTotals.sort((a, b) => b.expectedSnow3Day - a.expectedSnow3Day);

    const response: RegionalNarrativeResponse = {
      region,
      regionName,
      narrative,
      mountains: mountainSnowTotals,
      stormInfo: {
        activeStorms,
        primaryWindDirection,
        favoredMountains,
      },
      confidence: {
        level: modelConfidence,
        snowSpread: Math.round(snowSpread * 10) / 10,
      },
      generatedAt: new Date().toISOString(),
    };

    return NextResponse.json(response, {
      headers: {
        'Cache-Control': 'public, max-age=3600', // 1 hour cache (narratives are expensive to generate)
      },
    });
  } catch (error) {
    console.error('Error generating regional narrative:', error);
    return NextResponse.json(
      { error: 'Failed to generate regional narrative' },
      { status: 500 }
    );
  }
}
