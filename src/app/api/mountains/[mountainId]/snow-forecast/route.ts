import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { withCache } from '@/lib/cache';
import {
  getEnsembleProbabilityForecast,
  getElevationForecast,
  type EnsembleForecast,
  type ElevationForecast,
} from '@/lib/apis/open-meteo';

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

  const url = new URL(request.url);
  const days = Math.min(parseInt(url.searchParams.get('days') || '7', 10) || 7, 7);
  const includeEnsemble = url.searchParams.get('ensemble') !== 'false';
  const includeElevation = url.searchParams.get('elevation') !== 'false';

  try {
    const { lat, lng } = mountain.location;
    const { base, summit } = mountain.elevation;

    const cacheKey = `snow-forecast:${mountainId}:${days}:${includeEnsemble}:${includeElevation}`;

    const data = await withCache(
      cacheKey,
      async () => {
        const fetches: Promise<unknown>[] = [];

        // Index 0: ensemble (or null placeholder)
        fetches.push(
          includeEnsemble
            ? getEnsembleProbabilityForecast(lat, lng, days).catch(err => {
                console.warn('Ensemble fetch failed:', err);
                return null;
              })
            : Promise.resolve(null)
        );

        // Index 1: elevation (or null placeholder)
        fetches.push(
          includeElevation
            ? getElevationForecast(lat, lng, base, summit, days).catch(err => {
                console.warn('Elevation fetch failed:', err);
                return null;
              })
            : Promise.resolve(null)
        );

        const [ensemble, elevation] = await Promise.all(fetches);

        return {
          ensemble: ensemble as EnsembleForecast | null,
          elevation: elevation as ElevationForecast | null,
        };
      },
      1800 // 30 min cache
    );

    return NextResponse.json(
      {
        mountain: {
          id: mountain.id,
          name: mountain.name,
          shortName: mountain.shortName,
          elevation: mountain.elevation,
        },
        ensemble: data.ensemble,
        elevation: data.elevation,
      },
      {
        headers: {
          'Cache-Control': 'public, max-age=1800',
        },
      }
    );
  } catch (error) {
    console.error('Error fetching snow forecast:', error);
    return NextResponse.json(
      { error: 'Failed to fetch snow forecast' },
      { status: 500 }
    );
  }
}
