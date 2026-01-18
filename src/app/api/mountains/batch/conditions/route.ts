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

              // Get SNOTEL data if available
              if (mountain.snotel) {
                try {
                  const historyData = await getHistoricalData(mountain.snotel.stationId, 3);
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
                      snowfall24h = yesterday ? (today.snowDepth - yesterday.snowDepth) : 0;
                      snowfall48h = dayBefore ? (today.snowDepth - dayBefore.snowDepth) : snowfall24h;
                    }
                  }
                } catch (error) {
                  console.error(`Error fetching SNOTEL data for ${mountain.id}:`, error);
                }
              }

              // Get weather data from NOAA or Open-Meteo
              try {
                if (mountain.noaa) {
                  const forecastData = await getForecast(mountain.noaa);
                  if (forecastData && forecastData.length > 0) {
                    const current = forecastData[0];
                    // For daily forecast, use average of high/low for current temp
                    temperature = Math.round((current.high + current.low) / 2);
                    wind = {
                      speed: current.wind.speed || 0,
                      direction: 'N' // NOAA doesn't provide direction in daily forecast
                    };
                    conditions = current.conditions || 'Unknown';
                  }
                } else {
                  // Fallback to Open-Meteo
                  const weatherData = await getDailyForecast(
                    mountain.location.lat,
                    mountain.location.lng,
                    1
                  );
                  if (weatherData && weatherData.length > 0) {
                    const current = weatherData[0];
                    temperature = Math.round((current.highTemp + current.lowTemp) / 2);
                    wind = {
                      speed: 0, // Open-Meteo daily doesn't include wind
                      direction: 'N'
                    };
                    conditions = 'Unknown'; // Open-Meteo doesn't provide conditions in daily
                  }
                }
              } catch (error) {
                console.error(`Error fetching weather data for ${mountain.id}:`, error);
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