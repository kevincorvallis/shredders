import { NextResponse } from 'next/server';
import { getAllMountains } from '@shredders/shared';
import { withCache } from '@/lib/cache';
import { getHistoricalData } from '@/lib/apis/snotel';
import { getForecast } from '@/lib/apis/noaa';
import { getDailyForecast } from '@/lib/apis/open-meteo';

/**
 * Batch endpoint to get current conditions for all mountains
 * This reduces 15+ API calls down to just 1 request
 */
export async function GET() {
  try {
    const data = await withCache(
      'mountains:batch:conditions',
      async () => {
        const mountains = getAllMountains();

        // Fetch all mountain conditions in parallel
        const results = await Promise.allSettled(
          mountains.map(async (mountain) => {
            try {
              let snowDepth = 0;
              let snowfall24h = 0;
              let snowfall48h = 0;
              let temperature: number | undefined;
              let wind: { speed: number; direction: string } | undefined;
              let conditions = 'Unknown';

              // Fetch SNOTEL and weather data in parallel
              const [snotelResult, weatherResult] = await Promise.allSettled([
                // SNOTEL data
                mountain.snotel
                  ? getHistoricalData(mountain.snotel.stationId, 3)
                  : Promise.resolve(null),
                // Weather data (NOAA or Open-Meteo fallback)
                mountain.noaa
                  ? getForecast(mountain.noaa)
                  : getDailyForecast(mountain.location.lat, mountain.location.lng, 1),
              ]);

              // Process SNOTEL data
              const historyData = snotelResult.status === 'fulfilled' ? snotelResult.value : null;
              if (historyData && historyData.length > 0) {
                const today = historyData.find(h =>
                  h.date.startsWith(new Date().toISOString().split('T')[0])
                );
                const yesterday = historyData.find(h =>
                  h.date.startsWith(new Date(Date.now() - 86400000).toISOString().split('T')[0])
                );
                const dayBefore = historyData.find(h =>
                  h.date.startsWith(new Date(Date.now() - 172800000).toISOString().split('T')[0])
                );

                if (today) {
                  snowDepth = today.snowDepth || 0;
                  snowfall24h = Math.max(0, yesterday ? (today.snowDepth - yesterday.snowDepth) : 0);
                  snowfall48h = Math.max(0, dayBefore ? (today.snowDepth - dayBefore.snowDepth) : snowfall24h);
                }
              }

              // Process weather data
              const weatherData = weatherResult.status === 'fulfilled' ? weatherResult.value : null;
              if (weatherData && Array.isArray(weatherData) && weatherData.length > 0) {
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                const current = weatherData[0] as any;
                if (mountain.noaa) {
                  // NOAA forecast data — ProcessedForecastDay has wind.speed/gust but no direction
                  temperature = Math.round((current.high + current.low) / 2);
                  wind = {
                    speed: current.wind?.speed || 0,
                    direction: current.windDirection || ''
                  };
                  conditions = current.conditions || 'Unknown';
                } else {
                  // Open-Meteo daily data — has windDirection in degrees
                  temperature = Math.round((current.highTemp + current.lowTemp) / 2);
                  const dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW'];
                  const dirIndex = current.windDirection != null ? Math.round(current.windDirection / 22.5) % 16 : -1;
                  wind = {
                    speed: current.windSpeedMax || 0,
                    direction: dirIndex >= 0 ? dirs[dirIndex] : ''
                  };
                  conditions = 'Unknown';
                }
              }

              return {
                mountainId: mountain.id,
                mountainName: mountain.shortName,
                snowDepth,
                snowfall24h: Math.max(0, snowfall24h),
                snowfall48h: Math.max(0, snowfall48h),
                temperature,
                wind,
                conditions,
                dataSources: {
                  snotel: !!mountain.snotel,
                  noaa: !!mountain.noaa,
                  openMeteo: true
                }
              };
            } catch (error) {
              console.error(`Error fetching conditions for ${mountain.id}:`, error);
              return {
                mountainId: mountain.id,
                mountainName: mountain.shortName,
                error: true,
              };
            }
          })
        );

        // Extract successful results
        const conditionsData = results
          .filter((result) => result.status === 'fulfilled')
          .map((result) => result.value);

        return {
          data: conditionsData,
          count: conditionsData.length,
          cachedAt: new Date().toISOString(),
        };
      },
      300 // 5 minute cache
    );

    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching batch conditions data:', error);
    return NextResponse.json(
      { error: 'Failed to fetch conditions data' },
      { status: 500 }
    );
  }
}