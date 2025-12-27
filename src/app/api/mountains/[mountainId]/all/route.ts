import { NextResponse } from 'next/server';
import { getMountain } from '@/data/mountains';
import { withCache } from '@/lib/cache';

/**
 * Batched API endpoint that fetches all mountain data in one request
 * This reduces network overhead and improves performance
 */
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
    // Use cache with 10-minute TTL
    const data = await withCache(
      `mountain:${mountainId}:all`,
      async () => {
        // Fetch all data in parallel
        const [
          conditionsRes,
          scoreRes,
          forecastRes,
          roadsRes,
          tripAdviceRes,
          powderDayRes,
          alertsRes,
          weatherGovLinksRes,
        ] = await Promise.allSettled([
          fetch(`${getBaseUrl()}/api/mountains/${mountainId}/conditions`),
          fetch(`${getBaseUrl()}/api/mountains/${mountainId}/powder-score`),
          fetch(`${getBaseUrl()}/api/mountains/${mountainId}/forecast`),
          fetch(`${getBaseUrl()}/api/mountains/${mountainId}/roads`),
          fetch(`${getBaseUrl()}/api/mountains/${mountainId}/trip-advice`),
          fetch(`${getBaseUrl()}/api/mountains/${mountainId}/powder-day`),
          fetch(`${getBaseUrl()}/api/mountains/${mountainId}/alerts`),
          fetch(`${getBaseUrl()}/api/mountains/${mountainId}/weather-gov-links`),
        ]);

        // Parse all responses
        const [
          conditions,
          powderScore,
          forecast,
          roads,
          tripAdvice,
          powderDay,
          alerts,
          weatherGovLinks,
        ] = await Promise.all([
          conditionsRes.status === 'fulfilled' && conditionsRes.value.ok
            ? conditionsRes.value.json()
            : null,
          scoreRes.status === 'fulfilled' && scoreRes.value.ok
            ? scoreRes.value.json()
            : null,
          forecastRes.status === 'fulfilled' && forecastRes.value.ok
            ? forecastRes.value.json()
            : null,
          roadsRes.status === 'fulfilled' && roadsRes.value.ok
            ? roadsRes.value.json()
            : null,
          tripAdviceRes.status === 'fulfilled' && tripAdviceRes.value.ok
            ? tripAdviceRes.value.json()
            : null,
          powderDayRes.status === 'fulfilled' && powderDayRes.value.ok
            ? powderDayRes.value.json()
            : null,
          alertsRes.status === 'fulfilled' && alertsRes.value.ok
            ? alertsRes.value.json()
            : null,
          weatherGovLinksRes.status === 'fulfilled' && weatherGovLinksRes.value.ok
            ? weatherGovLinksRes.value.json()
            : null,
        ]);

        return {
          mountain: {
            id: mountain.id,
            name: mountain.name,
            shortName: mountain.shortName,
            region: mountain.region,
            color: mountain.color,
            elevation: mountain.elevation,
            location: mountain.location,
            website: mountain.website,
            webcams: mountain.webcams,
          },
          conditions,
          powderScore,
          forecast: forecast?.forecast || [],
          roads,
          tripAdvice,
          powderDay,
          alerts: alerts?.alerts || [],
          weatherGovLinks: weatherGovLinks?.weatherGov || null,
          cachedAt: new Date().toISOString(),
        };
      },
      600 // 10 minute TTL
    );

    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching mountain data:', error);
    return NextResponse.json(
      { error: 'Failed to fetch mountain data' },
      { status: 500 }
    );
  }
}

function getBaseUrl() {
  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL}`;
  }
  return process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000';
}
