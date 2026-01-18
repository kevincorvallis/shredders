import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import {
  getExtendedForecast,
  getMultiModelForecast,
  type ExtendedDailyForecast,
  type MultiModelData,
} from '@/lib/apis/open-meteo';
import { analyzePatterns, type PatternAnalysis } from '@/lib/calculations/pattern-analyzer';

export interface OutlookResponse {
  mountain: {
    id: string;
    name: string;
    shortName: string;
  };
  forecast: ExtendedDailyForecast[];
  patterns: PatternAnalysis;
  modelData?: MultiModelData;
  source: {
    provider: string;
    note: string;
  };
  generatedAt: string;
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

  // Parse query params
  const url = new URL(request.url);
  const days = Math.min(parseInt(url.searchParams.get('days') || '14'), 16);
  const includeModels = url.searchParams.get('models') === 'true';

  try {
    const { lat, lng } = mountain.location;

    // Fetch extended forecast
    const forecast = await getExtendedForecast(lat, lng, days);

    // Analyze patterns in the forecast
    const patterns = analyzePatterns(forecast);

    // Optionally fetch multi-model data
    let modelData: MultiModelData | undefined;
    if (includeModels) {
      try {
        modelData = await getMultiModelForecast(lat, lng, Math.min(days, 7));
      } catch (err) {
        console.warn('Failed to fetch multi-model data:', err);
        // Continue without model data
      }
    }

    const response: OutlookResponse = {
      mountain: {
        id: mountain.id,
        name: mountain.name,
        shortName: mountain.shortName,
      },
      forecast,
      patterns,
      modelData,
      source: {
        provider: 'Open-Meteo',
        note: 'Extended outlook uses Open-Meteo for 10-16 day forecasts. Confidence decreases significantly after day 7.',
      },
      generatedAt: new Date().toISOString(),
    };

    return NextResponse.json(response, {
      headers: {
        'Cache-Control': 'public, max-age=1800', // 30 min cache
      },
    });
  } catch (error) {
    console.error('Error fetching outlook:', error);
    return NextResponse.json(
      { error: 'Failed to fetch extended outlook' },
      { status: 500 }
    );
  }
}
