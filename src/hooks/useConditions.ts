import { useMountainData } from './useMountainData';
import type { ForecastDay } from '@/types/mountain';

interface ConditionsForDate {
  forecast: ForecastDay | null;
  allForecasts: ForecastDay[];
  bestPowderDay: ForecastDay | null;
  isLoading: boolean;
  error: any;
}

function scoreForecast(day: ForecastDay): number {
  let score = 0;
  score += day.snowfall * 10;
  if (day.snowfall >= 6) score += 20;
  if (day.snowfall >= 12) score += 30;
  if (day.high < 32) score += 10;
  if (day.high < 28) score += 5;
  if (day.precipProbability >= 70 && day.precipType === 'snow') score += 15;
  if (day.wind.gust > 40) score -= 10;
  if (day.wind.gust > 50) score -= 15;
  return score;
}

function findBestPowderDay(forecasts: ForecastDay[], excludeDate?: string): ForecastDay | null {
  const today = new Date().toISOString().split('T')[0];
  const futureDays = forecasts.filter((day) => {
    const dateStr = typeof day.date === 'string' ? day.date : new Date(day.date).toISOString().split('T')[0];
    return dateStr >= today && dateStr !== excludeDate;
  });

  // Primary: day with most snowfall >= 3"
  const snowDays = futureDays.filter((d) => d.snowfall >= 3);
  if (snowDays.length > 0) {
    return snowDays.reduce((best, day) => (day.snowfall > best.snowfall ? day : best));
  }

  // Secondary: best scored day with any snow or high precip probability
  const candidates = futureDays
    .filter((d) => d.snowfall > 0 || d.precipProbability >= 60)
    .sort((a, b) => scoreForecast(b) - scoreForecast(a));

  return candidates[0] || null;
}

export function useConditions(mountainId: string, eventDate?: string): ConditionsForDate {
  const { data, error, isLoading } = useMountainData(mountainId);

  if (!data || !data.forecast) {
    return { forecast: null, allForecasts: [], bestPowderDay: null, isLoading, error };
  }

  const forecasts: ForecastDay[] = data.forecast;

  // Find forecast for selected date
  let matchingForecast: ForecastDay | null = null;
  if (eventDate) {
    matchingForecast = forecasts.find((day) => {
      const dateStr = typeof day.date === 'string' ? day.date : new Date(day.date).toISOString().split('T')[0];
      return dateStr === eventDate;
    }) || null;
  }

  const bestPowderDay = findBestPowderDay(forecasts, eventDate);

  return {
    forecast: matchingForecast,
    allForecasts: forecasts,
    bestPowderDay,
    isLoading,
    error,
  };
}
