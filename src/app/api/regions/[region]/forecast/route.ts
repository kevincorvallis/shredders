import { NextResponse } from 'next/server';
import { getMountainsByRegion, type MountainConfig } from '@shredders/shared';
import { getExtendedForecast, type ExtendedDailyForecast } from '@/lib/apis/open-meteo';
import { generateRegionalForecast, type RegionalForecast } from '@/lib/calculations/storm-analyzer';

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
  'pnw-north': 'PNW North (Baker, Stevens, Whistler)',
  'pnw-central': 'PNW Central (Crystal, Snoqualmie, White Pass)',
  'pnw-south': 'PNW South (Hood, Bachelor)',
};

// Subregion definitions for more granular forecasts
const SUBREGIONS: Record<string, string[]> = {
  'pnw-north': ['baker', 'stevens', 'whistler', 'fortynine'],
  'pnw-central': ['crystal', 'snoqualmie', 'whitepass', 'missionridge'],
  'pnw-south': ['meadows', 'timberline', 'bachelor', 'hoodoo', 'willamette'],
};

type ValidRegion = 'washington' | 'oregon' | 'idaho' | 'canada' | 'utah' | 'colorado' | 'california' | 'wyoming' | 'montana' | 'vermont' | 'newmexico';

export async function GET(
  request: Request,
  { params }: { params: Promise<{ region: string }> }
) {
  const { region } = await params;

  // Check if it's a valid region
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
      // Get mountains from subregion list
      const allMountains = [
        ...getMountainsByRegion('washington'),
        ...getMountainsByRegion('oregon'),
        ...getMountainsByRegion('idaho'),
        ...getMountainsByRegion('canada'),
        ...getMountainsByRegion('utah'),
        ...getMountainsByRegion('colorado'),
        ...getMountainsByRegion('california'),
        ...getMountainsByRegion('wyoming'),
        ...getMountainsByRegion('montana'),
        ...getMountainsByRegion('vermont'),
        ...getMountainsByRegion('newmexico'),
      ];
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

    // Fetch forecasts for all mountains in parallel
    const forecastPromises = mountains.map(async mountain => {
      try {
        const forecast = await getExtendedForecast(
          mountain.location.lat,
          mountain.location.lng,
          7
        );
        return { mountainId: mountain.id, forecast };
      } catch (err) {
        console.warn(`Failed to fetch forecast for ${mountain.id}:`, err);
        return { mountainId: mountain.id, forecast: [] };
      }
    });

    const forecastResults = await Promise.all(forecastPromises);

    // Build forecast map
    const forecastMap = new Map<string, ExtendedDailyForecast[]>();
    for (const result of forecastResults) {
      forecastMap.set(result.mountainId, result.forecast);
    }

    // Generate regional forecast with storm analysis
    const regionalForecast = generateRegionalForecast(
      region,
      regionName,
      forecastMap,
      mountains
    );

    return NextResponse.json(regionalForecast, {
      headers: {
        'Cache-Control': 'public, max-age=900', // 15 min cache
      },
    });
  } catch (error) {
    console.error('Error generating regional forecast:', error);
    return NextResponse.json(
      { error: 'Failed to generate regional forecast' },
      { status: 500 }
    );
  }
}
