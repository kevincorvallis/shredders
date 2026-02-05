import { NextResponse } from 'next/server';
import { getAllMountains } from '@shredders/shared';
import { withCache } from '@/lib/cache';
import { getForecast, type NOAAGridConfig } from '@/lib/apis/noaa';
import { getHistoricalData } from '@/lib/apis/snotel';

/**
 * Batch endpoint to get snowfall history + forecast for all mountains
 * This reduces 30 API calls (15 × 2) down to just 1 request
 */
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const daysBack = parseInt(searchParams.get('daysBack') || '7');
  const daysForward = parseInt(searchParams.get('daysForward') || '7');

  try {
    const data = await withCache(
      `mountains:batch:snowfall:${daysBack}:${daysForward}`,
      async () => {
        const mountains = getAllMountains();

        // Fetch all mountain snowfall data in parallel
        const results = await Promise.allSettled(
          mountains.map(async (mountain) => {
            try {
              // Fetch history and forecast in parallel
              const [historyData, forecastData] = await Promise.allSettled([
                mountain.snotel
                  ? getHistoricalData(mountain.snotel.stationId, daysBack + 1)
                  : Promise.resolve(null),
                mountain.noaa
                  ? getForecast(mountain.noaa)
                  : Promise.resolve([]),
              ]);

              const history =
                historyData.status === 'fulfilled' && historyData.value
                  ? historyData.value
                  : [];
              const forecast =
                forecastData.status === 'fulfilled' && forecastData.value
                  ? forecastData.value
                  : [];

              // Generate date range
              const dates = [];
              const today = new Date();
              today.setHours(0, 0, 0, 0);

              // Build O(1) lookup maps from history and forecast arrays
              const historyByDate = new Map<string, number>();
              for (const h of history as any[]) {
                const dateKey = h.date?.substring(0, 10);
                if (dateKey) historyByDate.set(dateKey, h.snowfall || 0);
              }

              const forecastByDate = new Map<string, number>();
              for (const f of forecast as any[]) {
                const dateKey = f.date?.substring(0, 10);
                if (dateKey) forecastByDate.set(dateKey, f.snowfall || 0);
              }

              // Build snowfall array using map lookups
              for (let i = daysBack; i > 0; i--) {
                const date = new Date(today);
                date.setDate(date.getDate() - i);
                const dateStr = date.toISOString().split('T')[0];

                dates.push({
                  date: dateStr,
                  snowfall: historyByDate.get(dateStr) || 0,
                  isForecast: false,
                  isToday: false,
                });
              }

              // Today
              const todayStr = today.toISOString().split('T')[0];
              dates.push({
                date: todayStr,
                snowfall: historyByDate.get(todayStr) || 0,
                isForecast: false,
                isToday: true,
              });

              // Forecast
              for (let i = 1; i <= daysForward; i++) {
                const date = new Date(today);
                date.setDate(date.getDate() + i);
                const dateStr = date.toISOString().split('T')[0];

                dates.push({
                  date: dateStr,
                  snowfall: forecastByDate.get(dateStr) || 0,
                  isForecast: true,
                  isToday: false,
                });
              }

              return {
                mountainId: mountain.id,
                mountainName: mountain.shortName,
                dates,
              };
            } catch (error) {
              console.error(`Error fetching snowfall for ${mountain.id}:`, error);
              return {
                mountainId: mountain.id,
                mountainName: mountain.shortName,
                dates: [],
                error: true,
              };
            }
          })
        );

        // Extract successful results
        const snowfallData = results
          .filter((result) => result.status === 'fulfilled')
          .map((result) => result.value);

        return {
          data: snowfallData,
          count: snowfallData.length,
          daysBack,
          daysForward,
          cachedAt: new Date().toISOString(),
        };
      },
      600 // 10 minute cache
    );

    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching batch snowfall data:', error);
    return NextResponse.json(
      { error: 'Failed to fetch snowfall data' },
      { status: 500 }
    );
  }
}
