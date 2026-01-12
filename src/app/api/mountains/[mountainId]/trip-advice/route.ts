import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { computeTripAdvice, isHolidayWindow, isWeekend } from '@/lib/calculations/trip-advice';

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
    // Pull in the same data the user sees.
    const [powderScoreRes, forecastRes, roadsRes] = await Promise.all([
      fetch(new URL(`/api/mountains/${mountainId}/powder-score`, request.url)),
      fetch(new URL(`/api/mountains/${mountainId}/forecast`, request.url)),
      fetch(new URL(`/api/mountains/${mountainId}/roads`, request.url)).catch(() => null),
    ]);

    const powderScoreJson = powderScoreRes.ok ? await powderScoreRes.json() : null;
    const forecastJson = forecastRes.ok ? await forecastRes.json() : null;
    const roadsJson = roadsRes && roadsRes.ok ? await roadsRes.json() : null;

    const upcomingSnow48h = Array.isArray(forecastJson?.forecast)
      ? forecastJson.forecast.slice(0, 2).reduce((sum: number, d: { snowfall?: number }) => sum + (d?.snowfall ?? 0), 0)
      : null;

    const now = new Date();
    const advice = computeTripAdvice({
      mountainId,
      mountainName: mountain.name,
      powderScore: powderScoreJson?.score ?? null,
      upcomingSnow48h,
      isWeekend: isWeekend(now),
      isHolidayWindow: isHolidayWindow(now),
      roads: roadsJson
        ? {
            supported: !!roadsJson.supported,
            configured: !!roadsJson.configured,
            passes: Array.isArray(roadsJson.passes) ? roadsJson.passes : [],
          }
        : null,
    });

    return NextResponse.json(
      {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        ...advice,
      },
      {
        headers: {
          'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
        },
      }
    );
  } catch (error) {
    console.error('Error generating trip advice:', error);
    return NextResponse.json(
      {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        generated: new Date().toISOString(),
        crowd: 'medium',
        trafficRisk: 'medium',
        roadRisk: 'medium',
        headline: 'Trip advice unavailable',
        notes: ['Unable to generate trip planning advice right now.'],
        suggestedDepartures: [{ from: 'Any', suggestion: 'Check roads before you drive.' }],
      },
      {
        status: 200,
        headers: {
          'Cache-Control': 'public, s-maxage=120, stale-while-revalidate=300',
        },
      }
    );
  }
}
