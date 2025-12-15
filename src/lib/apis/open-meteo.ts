// Open-Meteo Weather API Client
// Docs: https://open-meteo.com/en/docs
// Free, no API key required

const BASE_URL = 'https://api.open-meteo.com/v1/forecast';

// API response types
interface OpenMeteoResponse {
  latitude: number;
  longitude: number;
  elevation: number;
  timezone: string;
  hourly?: {
    time: string[];
    temperature_2m?: number[];
    snowfall?: number[];
    snow_depth?: number[];
    freezing_level_height?: number[];
    precipitation?: number[];
    precipitation_probability?: number[];
  };
  daily?: {
    time: string[];
    snowfall_sum?: number[];
    precipitation_sum?: number[];
    temperature_2m_max?: number[];
    temperature_2m_min?: number[];
  };
}

// Exported types
export interface FreezingLevelData {
  current: number; // meters
  hourly: Array<{
    time: string;
    level: number; // meters
  }>;
  average24h: number; // meters
  min24h: number;
  max24h: number;
}

export interface OpenMeteoHourlySnow {
  time: string;
  snowfall: number; // inches
  snowDepth: number; // inches
  temperature: number; // fahrenheit
  precipitation: number; // inches
  precipProbability: number; // 0-100
}

export interface OpenMeteoDailyForecast {
  date: string;
  snowfallSum: number; // inches
  precipitationSum: number; // inches
  highTemp: number; // fahrenheit
  lowTemp: number; // fahrenheit
}

// Unit conversions
function metersToFeet(meters: number): number {
  return Math.round(meters * 3.28084);
}

function celsiusToFahrenheit(celsius: number): number {
  return Math.round(celsius * 9 / 5 + 32);
}

function cmToInches(cm: number): number {
  return Math.round(cm / 2.54 * 10) / 10;
}

function mmToInches(mm: number): number {
  return Math.round(mm / 25.4 * 100) / 100;
}

async function fetchOpenMeteo(params: Record<string, string>): Promise<OpenMeteoResponse> {
  const url = new URL(BASE_URL);
  Object.entries(params).forEach(([key, value]) => {
    url.searchParams.set(key, value);
  });

  const response = await fetch(url.toString());

  if (!response.ok) {
    throw new Error(`Open-Meteo API error: ${response.status}`);
  }

  return response.json();
}

/**
 * Get freezing level height (rain/snow line) data
 * This is the altitude where temperature equals 0°C
 */
export async function getFreezingLevel(lat: number, lng: number): Promise<FreezingLevelData> {
  const data = await fetchOpenMeteo({
    latitude: lat.toString(),
    longitude: lng.toString(),
    hourly: 'freezing_level_height',
    timezone: 'America/Los_Angeles',
    forecast_days: '2',
  });

  if (!data.hourly?.freezing_level_height || !data.hourly?.time) {
    throw new Error('No freezing level data available');
  }

  const hourly = data.hourly.time.map((time, i) => ({
    time,
    level: data.hourly!.freezing_level_height![i] || 0,
  }));

  // Get current (first value)
  const current = hourly[0]?.level || 0;

  // Calculate 24h stats (first 24 hours)
  const next24h = hourly.slice(0, 24).map(h => h.level);
  const average24h = next24h.reduce((sum, v) => sum + v, 0) / next24h.length;
  const min24h = Math.min(...next24h);
  const max24h = Math.max(...next24h);

  return {
    current,
    hourly,
    average24h: Math.round(average24h),
    min24h,
    max24h,
  };
}

/**
 * Get current freezing level in feet (convenience function)
 */
export async function getCurrentFreezingLevelFeet(lat: number, lng: number): Promise<number> {
  const data = await getFreezingLevel(lat, lng);
  return metersToFeet(data.current);
}

/**
 * Get hourly snowfall and snow depth data
 */
export async function getHourlySnowfall(lat: number, lng: number): Promise<OpenMeteoHourlySnow[]> {
  const data = await fetchOpenMeteo({
    latitude: lat.toString(),
    longitude: lng.toString(),
    hourly: 'snowfall,snow_depth,temperature_2m,precipitation,precipitation_probability',
    timezone: 'America/Los_Angeles',
    forecast_days: '3',
  });

  if (!data.hourly?.time) {
    return [];
  }

  return data.hourly.time.map((time, i) => ({
    time,
    snowfall: cmToInches(data.hourly?.snowfall?.[i] || 0),
    snowDepth: cmToInches((data.hourly?.snow_depth?.[i] || 0) * 100), // snow_depth is in meters
    temperature: celsiusToFahrenheit(data.hourly?.temperature_2m?.[i] || 0),
    precipitation: mmToInches(data.hourly?.precipitation?.[i] || 0),
    precipProbability: data.hourly?.precipitation_probability?.[i] || 0,
  }));
}

/**
 * Get daily forecast summary
 */
export async function getDailyForecast(lat: number, lng: number, days: number = 7): Promise<OpenMeteoDailyForecast[]> {
  const data = await fetchOpenMeteo({
    latitude: lat.toString(),
    longitude: lng.toString(),
    daily: 'snowfall_sum,precipitation_sum,temperature_2m_max,temperature_2m_min',
    timezone: 'America/Los_Angeles',
    forecast_days: days.toString(),
  });

  if (!data.daily?.time) {
    return [];
  }

  return data.daily.time.map((date, i) => ({
    date,
    snowfallSum: cmToInches(data.daily?.snowfall_sum?.[i] || 0),
    precipitationSum: mmToInches(data.daily?.precipitation_sum?.[i] || 0),
    highTemp: celsiusToFahrenheit(data.daily?.temperature_2m_max?.[i] || 0),
    lowTemp: celsiusToFahrenheit(data.daily?.temperature_2m_min?.[i] || 0),
  }));
}

/**
 * Get comprehensive forecast data in a single request
 */
export interface OpenMeteoComprehensive {
  freezingLevel: FreezingLevelData;
  hourlySnow: OpenMeteoHourlySnow[];
  dailyForecast: OpenMeteoDailyForecast[];
}

export async function getComprehensiveForecast(
  lat: number,
  lng: number,
  days: number = 7
): Promise<OpenMeteoComprehensive> {
  const data = await fetchOpenMeteo({
    latitude: lat.toString(),
    longitude: lng.toString(),
    hourly: 'snowfall,snow_depth,temperature_2m,precipitation,precipitation_probability,freezing_level_height',
    daily: 'snowfall_sum,precipitation_sum,temperature_2m_max,temperature_2m_min',
    timezone: 'America/Los_Angeles',
    forecast_days: days.toString(),
  });

  // Process freezing level
  const freezingHourly = data.hourly?.time?.map((time, i) => ({
    time,
    level: data.hourly?.freezing_level_height?.[i] || 0,
  })) || [];

  const currentLevel = freezingHourly[0]?.level || 0;
  const next24h = freezingHourly.slice(0, 24).map(h => h.level);
  const average24h = next24h.length > 0
    ? next24h.reduce((sum, v) => sum + v, 0) / next24h.length
    : 0;

  const freezingLevel: FreezingLevelData = {
    current: currentLevel,
    hourly: freezingHourly,
    average24h: Math.round(average24h),
    min24h: next24h.length > 0 ? Math.min(...next24h) : 0,
    max24h: next24h.length > 0 ? Math.max(...next24h) : 0,
  };

  // Process hourly snow
  const hourlySnow: OpenMeteoHourlySnow[] = data.hourly?.time?.map((time, i) => ({
    time,
    snowfall: cmToInches(data.hourly?.snowfall?.[i] || 0),
    snowDepth: cmToInches((data.hourly?.snow_depth?.[i] || 0) * 100),
    temperature: celsiusToFahrenheit(data.hourly?.temperature_2m?.[i] || 0),
    precipitation: mmToInches(data.hourly?.precipitation?.[i] || 0),
    precipProbability: data.hourly?.precipitation_probability?.[i] || 0,
  })) || [];

  // Process daily forecast
  const dailyForecast: OpenMeteoDailyForecast[] = data.daily?.time?.map((date, i) => ({
    date,
    snowfallSum: cmToInches(data.daily?.snowfall_sum?.[i] || 0),
    precipitationSum: mmToInches(data.daily?.precipitation_sum?.[i] || 0),
    highTemp: celsiusToFahrenheit(data.daily?.temperature_2m_max?.[i] || 0),
    lowTemp: celsiusToFahrenheit(data.daily?.temperature_2m_min?.[i] || 0),
  })) || [];

  return {
    freezingLevel,
    hourlySnow,
    dailyForecast,
  };
}

/**
 * Calculate rain risk based on freezing level vs mountain elevation
 * Returns 0-10 score (10 = all snow, 0 = all rain)
 */
export function calculateRainRiskScore(
  freezingLevelFeet: number,
  baseElevation: number,
  summitElevation: number
): { score: number; description: string } {
  // Freezing level above summit = all rain
  if (freezingLevelFeet > summitElevation) {
    return {
      score: 0,
      description: `${freezingLevelFeet.toLocaleString()}' - Rain at all elevations`,
    };
  }

  // Freezing level below base = all snow
  if (freezingLevelFeet < baseElevation) {
    return {
      score: 10,
      description: `${freezingLevelFeet.toLocaleString()}' - All snow expected`,
    };
  }

  // Partial: score based on % of vertical above freezing level
  const totalVertical = summitElevation - baseElevation;
  const snowableVertical = summitElevation - freezingLevelFeet;
  const score = Math.round((snowableVertical / totalVertical) * 10);

  return {
    score,
    description: `${freezingLevelFeet.toLocaleString()}' - Snow above ${freezingLevelFeet.toLocaleString()}'`,
  };
}
