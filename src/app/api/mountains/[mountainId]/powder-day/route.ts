import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { computePowderDayPlan } from '@/lib/calculations/powder-day-planner';

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
    const [forecastRes, powderScoreRes, roadsRes] = await Promise.all([
      fetch(new URL(`/api/mountains/${mountainId}/forecast`, request.url)),
      fetch(new URL(`/api/mountains/${mountainId}/powder-score`, request.url)),
      fetch(new URL(`/api/mountains/${mountainId}/roads`, request.url)).catch(() => null),
    ]);

    const forecastJson = forecastRes.ok ? await forecastRes.json() : null;
    const powderScoreJson = powderScoreRes.ok ? await powderScoreRes.json() : null;
    const roadsJson = roadsRes && roadsRes.ok ? await roadsRes.json() : null;

    const plan = computePowderDayPlan({
      mountainId,
      mountainName: mountain.name,
      forecast: Array.isArray(forecastJson?.forecast) ? forecastJson.forecast : [],
      currentPowderScore: powderScoreJson?.score ?? null,
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
        ...plan,
      },
      {
        headers: {
          'Cache-Control': 'public, s-maxage=900, stale-while-revalidate=1800',
        },
      }
    );
  } catch (error) {
    console.error('Error generating powder day plan:', error);
    return NextResponse.json(
      {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        generated: new Date().toISOString(),
        mountainId,
        mountainName: mountain.name,
        days: [],
        error: 'Powder day plan temporarily unavailable',
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
