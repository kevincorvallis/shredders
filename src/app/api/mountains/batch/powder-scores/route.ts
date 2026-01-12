import { NextResponse } from 'next/server';
import { getAllMountains } from '@shredders/shared';
import { withCache } from '@/lib/cache';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getCurrentWeather, type NOAAGridConfig } from '@/lib/apis/noaa';

/**
 * Batch endpoint to get powder scores for all mountains in one request
 * This dramatically reduces network overhead compared to 15 individual requests
 */
export async function GET() {
  try {
    const data = await withCache(
      'mountains:batch:powder-scores',
      async () => {
        const mountains = getAllMountains();

        // Fetch all mountain data in parallel
        const results = await Promise.allSettled(
          mountains.map(async (mountain) => {
            try {
              // Fetch SNOTEL and NOAA data in parallel
              const [snotelData, weatherData] = await Promise.allSettled([
                mountain.snotel
                  ? getCurrentConditions(mountain.snotel.stationId)
                  : Promise.resolve(null),
                mountain.noaa
                  ? getCurrentWeather(mountain.noaa)
                  : Promise.resolve(null),
              ]);

              const snotel = snotelData.status === 'fulfilled' ? snotelData.value : null;
              const weather = weatherData.status === 'fulfilled' ? weatherData.value : null;

              // Calculate powder score
              const snowfall24h = snotel?.snowfall24h ?? 0;
              const snowfall48h = snotel?.snowfall48h ?? 0;
              const temperature = weather?.temperature ?? snotel?.temperature ?? 32;
              const windSpeed = weather?.windSpeed ?? 0;

              let score = 0;
              score += Math.min(snowfall24h / 12 * 2.5, 2.5);
              score += Math.min(snowfall48h / 24 * 1.2, 1.2);
              score += temperature < 28 ? 2.5 : temperature < 32 ? 1.5 : 0;
              score += windSpeed < 10 ? 2 : windSpeed < 20 ? 1 : 0;

              return {
                mountainId: mountain.id,
                score: Math.min(Math.max(score, 0), 10),
                conditions: {
                  snowfall24h,
                  snowfall48h,
                  temperature,
                  windSpeed,
                },
              };
            } catch (error) {
              console.error(`Error fetching powder score for ${mountain.id}:`, error);
              return {
                mountainId: mountain.id,
                score: 0,
                conditions: {
                  snowfall24h: 0,
                  snowfall48h: 0,
                  temperature: 32,
                  windSpeed: 0,
                },
                error: true,
              };
            }
          })
        );

        // Extract successful results
        const scores = results
          .filter((result) => result.status === 'fulfilled')
          .map((result) => result.value);

        return {
          scores,
          count: scores.length,
          cachedAt: new Date().toISOString(),
        };
      },
      300 // 5 minute cache
    );

    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching batch powder scores:', error);
    return NextResponse.json(
      { error: 'Failed to fetch powder scores' },
      { status: 500 }
    );
  }
}
