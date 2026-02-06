import { getMountain } from '@shredders/shared';
import { withCache } from '@/lib/cache';
import { getCurrentConditions } from '@/lib/apis/snotel';
import { getForecast, getCurrentWeather, filterActiveAlerts } from '@/lib/apis/noaa';
import { getCurrentFreezingLevelFeet, calculateRainRiskScore, getDailyForecast } from '@/lib/apis/open-meteo';
import { getWeatherAlerts } from '@/lib/apis/noaa';
import { getLatestLiftStatus } from '@/lib/dynamodb';
import { calculateMountainTemperatures, estimateReferenceElevation } from '@/lib/calculations/temperature-lapse';

/**
 * Fetch all data for a single mountain, with caching.
 * Shared between the individual /mountains/[id]/all endpoint and the batch endpoint.
 */
export async function getMountainAllData(mountainId: string) {
  const mountain = getMountain(mountainId);
  if (!mountain) return null;

  return withCache(
    `mountain:${mountainId}:all`,
    async () => {
      const [
        snotelData,
        weatherData,
        forecastData,
        alertsData,
        freezingLevel,
        openMeteoDaily,
        liftStatusData,
      ] = await Promise.allSettled([
        mountain.snotel
          ? getCurrentConditions(mountain.snotel.stationId).catch(() => null)
          : Promise.resolve(null),
        mountain.noaa
          ? getCurrentWeather(mountain.noaa).catch(() => null)
          : Promise.resolve(null),
        mountain.noaa
          ? getForecast(mountain.noaa).catch(() => [])
          : Promise.resolve([]),
        getWeatherAlerts(mountain.location.lat, mountain.location.lng).catch(() => []),
        getCurrentFreezingLevelFeet(mountain.location.lat, mountain.location.lng).catch(() => null),
        getDailyForecast(mountain.location.lat, mountain.location.lng, 1).catch(() => []),
        getLatestLiftStatus(mountainId).catch(() => null),
      ]);

      const snotel = snotelData.status === 'fulfilled' ? snotelData.value : null;
      const weather = weatherData.status === 'fulfilled' ? weatherData.value : null;
      const forecast = forecastData.status === 'fulfilled' ? forecastData.value : [];
      const rawAlerts = alertsData.status === 'fulfilled' ? alertsData.value : [];
      const freezing = freezingLevel.status === 'fulfilled' ? freezingLevel.value : null;
      const dailyForecast = openMeteoDaily.status === 'fulfilled' ? openMeteoDaily.value : [];
      const liftStatus = liftStatusData.status === 'fulfilled' ? liftStatusData.value : null;

      const alerts = filterActiveAlerts(rawAlerts);

      const todaySunData = dailyForecast.length > 0 && dailyForecast[0].sunrise && dailyForecast[0].sunset
        ? { sunrise: dailyForecast[0].sunrise, sunset: dailyForecast[0].sunset }
        : null;

      const rainRisk = freezing
        ? calculateRainRiskScore(freezing, mountain.elevation.base, mountain.elevation.summit)
        : null;

      const referenceTemp = weather?.temperature ?? snotel?.temperature ?? null;
      let temperaturesByElevation = null;

      if (referenceTemp !== null) {
        const referenceElevation = estimateReferenceElevation(
          null,
          mountain.elevation.base,
          mountain.elevation.summit
        );

        temperaturesByElevation = calculateMountainTemperatures(
          referenceTemp,
          referenceElevation,
          mountain.elevation.base,
          mountain.elevation.summit
        );
      }

      const conditions = {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        snowDepth: snotel?.snowDepth ?? null,
        snowWaterEquivalent: snotel?.snowWaterEquivalent ?? null,
        snowfall24h: snotel?.snowfall24h ?? 0,
        snowfall48h: snotel?.snowfall48h ?? 0,
        snowfall7d: snotel?.snowfall7d ?? 0,
        temperature: referenceTemp,
        temperatureByElevation: temperaturesByElevation,
        conditions: weather?.conditions ?? 'Unknown',
        wind: weather ? { speed: weather.windSpeed, direction: weather.windDirection } : null,
        lastUpdated: snotel?.lastUpdated ?? new Date().toISOString(),
        freezingLevel: freezing,
        rainRisk: rainRisk ? { score: rainRisk.score, description: rainRisk.description } : null,
        elevation: mountain.elevation,
        liftStatus: liftStatus
          ? {
              isOpen: liftStatus.isOpen,
              liftsOpen: liftStatus.liftsOpen,
              liftsTotal: liftStatus.liftsTotal,
              runsOpen: liftStatus.runsOpen,
              runsTotal: liftStatus.runsTotal,
              message: liftStatus.message,
              lastUpdated: liftStatus.scrapedAt,
            }
          : null,
        dataSources: {
          snotel: mountain.snotel
            ? { available: !!snotel, stationName: mountain.snotel.stationName }
            : null,
          noaa: mountain.noaa
            ? { available: !!weather, gridOffice: mountain.noaa.gridOffice }
            : { available: false, gridOffice: 'N/A' },
          openMeteo: { available: freezing !== null },
          liftStatus: { available: !!liftStatus },
        },
      };

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
      score += rainRisk ? Math.min(rainRisk.score / 10 * 1.8, 1.8) : 0;

      const finalScore = Math.min(Math.max(score, 0), 10);
      let verdict = '';
      if (finalScore >= 8) verdict = 'Epic conditions - powder day!';
      else if (finalScore >= 6) verdict = 'Great day for skiing - fresh snow awaits!';
      else if (finalScore >= 4) verdict = 'Good conditions - worth the trip';
      else verdict = 'Fair conditions';

      const upcomingSnow = forecast.slice(0, 2).reduce((sum: number, day: any) => sum + (day.snowfall || 0), 0);

      const powderScore = {
        mountain: { id: mountain.id, name: mountain.name, shortName: mountain.shortName },
        score: finalScore,
        factors: [
          {
            name: 'Fresh Snow (24h)',
            value: snowfall24h,
            weight: 0.25,
            contribution: Math.min(snowfall24h / 12 * 2.5, 2.5),
            description: `${snowfall24h}" in last 24 hours`,
          },
          {
            name: 'Temperature',
            value: temperature ?? 0,
            weight: 0.25,
            contribution: temperature < 28 ? 2.5 : temperature < 32 ? 1.5 : 0,
            description: `${temperature}°F - ${temperature < 32 ? 'Cold smoke' : 'Mild'}`,
          },
        ],
        verdict,
        conditions: { snowfall24h, snowfall48h, temperature: temperature ?? 0, windSpeed, upcomingSnow },
        dataAvailable: { snotel: !!snotel, noaa: !!weather },
      };

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
          roadWebcams: mountain.roadWebcams,
          logo: mountain.logo,
          status: mountain.status,
          snotel: mountain.snotel,
          noaa: mountain.noaa,
        },
        conditions,
        powderScore,
        forecast: forecast || [],
        sunData: todaySunData,
        roads: null,
        tripAdvice: null,
        powderDay: null,
        alerts: alerts || [],
        weatherGovLinks: {
          forecast: `https://forecast.weather.gov/MapClick.php?lat=${mountain.location.lat}&lon=${mountain.location.lng}`,
          hourly: `https://forecast.weather.gov/MapClick.php?lat=${mountain.location.lat}&lon=${mountain.location.lng}&FcstType=graphical`,
          alerts: `https://alerts.weather.gov/search?point=${mountain.location.lat},${mountain.location.lng}`,
        },
        status: mountain.status,
        cachedAt: new Date().toISOString(),
      };
    },
    600
  );
}
