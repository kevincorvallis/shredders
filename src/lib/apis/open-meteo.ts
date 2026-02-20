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
    sunrise?: string[];
    sunset?: string[];
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
  sunrise?: string; // ISO 8601 time
  sunset?: string; // ISO 8601 time
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
    daily: 'snowfall_sum,precipitation_sum,temperature_2m_max,temperature_2m_min,sunrise,sunset',
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
    sunrise: data.daily?.sunrise?.[i],
    sunset: data.daily?.sunset?.[i],
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
    daily: 'snowfall_sum,precipitation_sum,temperature_2m_max,temperature_2m_min,sunrise,sunset',
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
    sunrise: data.daily?.sunrise?.[i],
    sunset: data.daily?.sunset?.[i],
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

// ============================================================
// Extended Forecast Support (10-16 days)
// ============================================================

const EXTENDED_FORECAST_URL = 'https://api.open-meteo.com/v1/forecast';

export interface ExtendedDailyForecast {
  date: string;
  snowfallSum: number; // inches
  precipitationSum: number; // inches
  highTemp: number; // fahrenheit
  lowTemp: number; // fahrenheit
  windSpeedMax: number; // mph
  windGustMax: number; // mph
  windDirection: number; // degrees
  precipProbability: number; // 0-100
  weatherCode: number;
  sunrise?: string;
  sunset?: string;
}

export interface ExtendedOutlook {
  days: ExtendedDailyForecast[];
  patterns: WeatherPattern[];
  generatedAt: string;
}

export interface WeatherPattern {
  type: 'storm_cycle' | 'high_pressure' | 'cold_pattern' | 'warm_pattern' | 'transition' | 'neutral';
  startDate: string;
  endDate: string;
  description: string;
  confidence: 'high' | 'medium' | 'low';
}

/**
 * Get extended 16-day forecast from Open-Meteo
 */
export async function getExtendedForecast(
  lat: number,
  lng: number,
  days: number = 16
): Promise<ExtendedDailyForecast[]> {
  const params = {
    latitude: lat.toString(),
    longitude: lng.toString(),
    daily: [
      'snowfall_sum',
      'precipitation_sum',
      'temperature_2m_max',
      'temperature_2m_min',
      'wind_speed_10m_max',
      'wind_gusts_10m_max',
      'wind_direction_10m_dominant',
      'precipitation_probability_max',
      'weather_code',
      'sunrise',
      'sunset',
    ].join(','),
    timezone: 'America/Los_Angeles',
    forecast_days: Math.min(days, 16).toString(),
  };

  const url = new URL(EXTENDED_FORECAST_URL);
  Object.entries(params).forEach(([key, value]) => {
    url.searchParams.set(key, value);
  });

  const response = await fetch(url.toString());
  if (!response.ok) {
    throw new Error(`Open-Meteo API error: ${response.status}`);
  }

  const data = await response.json();

  if (!data.daily?.time) {
    return [];
  }

  return data.daily.time.map((date: string, i: number) => ({
    date,
    snowfallSum: cmToInches(data.daily.snowfall_sum?.[i] || 0),
    precipitationSum: mmToInches(data.daily.precipitation_sum?.[i] || 0),
    highTemp: celsiusToFahrenheit(data.daily.temperature_2m_max?.[i] || 0),
    lowTemp: celsiusToFahrenheit(data.daily.temperature_2m_min?.[i] || 0),
    windSpeedMax: Math.round((data.daily.wind_speed_10m_max?.[i] || 0) * 0.621371), // km/h to mph
    windGustMax: Math.round((data.daily.wind_gusts_10m_max?.[i] || 0) * 0.621371),
    windDirection: data.daily.wind_direction_10m_dominant?.[i] || 0,
    precipProbability: data.daily.precipitation_probability_max?.[i] || 0,
    weatherCode: data.daily.weather_code?.[i] || 0,
    sunrise: data.daily.sunrise?.[i],
    sunset: data.daily.sunset?.[i],
  }));
}

// ============================================================
// Multi-Model Support (GFS, ECMWF, etc.)
// ============================================================

const ENSEMBLE_URL = 'https://ensemble-api.open-meteo.com/v1/ensemble';

export type ModelSource = 'gfs' | 'ecmwf' | 'icon' | 'gem';

export interface ModelForecast {
  model: ModelSource;
  date: string;
  snowfallSum: number; // inches
  precipitationSum: number; // inches
  highTemp: number; // fahrenheit
  lowTemp: number; // fahrenheit
}

export interface MultiModelData {
  models: Record<ModelSource, ModelForecast[]>;
  agreement: ModelAgreement[];
  generatedAt: string;
}

export interface ModelAgreement {
  date: string;
  snowfallRange: { min: number; max: number; spread: number };
  precipRange: { min: number; max: number; spread: number };
  tempRange: { min: number; max: number; spread: number };
  confidence: 'high' | 'medium' | 'low';
  confidencePercent: number;
}

/**
 * Fetch forecast from a specific model ensemble
 */
async function fetchModelForecast(
  lat: number,
  lng: number,
  model: ModelSource,
  days: number = 7
): Promise<ModelForecast[]> {
  // Map model names to Open-Meteo ensemble model names
  const modelMap: Record<ModelSource, string> = {
    gfs: 'gfs_seamless',
    ecmwf: 'ecmwf_ifs04',
    icon: 'icon_seamless',
    gem: 'gem_global',
  };

  const params = {
    latitude: lat.toString(),
    longitude: lng.toString(),
    daily: 'snowfall_sum,precipitation_sum,temperature_2m_max,temperature_2m_min',
    timezone: 'America/Los_Angeles',
    forecast_days: Math.min(days, 16).toString(),
    models: modelMap[model],
  };

  const url = new URL(ENSEMBLE_URL);
  Object.entries(params).forEach(([key, value]) => {
    url.searchParams.set(key, value);
  });

  try {
    const response = await fetch(url.toString());
    if (!response.ok) {
      console.warn(`Model ${model} fetch failed: ${response.status}`);
      return [];
    }

    const data = await response.json();

    if (!data.daily?.time) {
      return [];
    }

    return data.daily.time.map((date: string, i: number) => ({
      model,
      date,
      snowfallSum: cmToInches(data.daily.snowfall_sum?.[i] || 0),
      precipitationSum: mmToInches(data.daily.precipitation_sum?.[i] || 0),
      highTemp: celsiusToFahrenheit(data.daily.temperature_2m_max?.[i] || 0),
      lowTemp: celsiusToFahrenheit(data.daily.temperature_2m_min?.[i] || 0),
    }));
  } catch (error) {
    console.warn(`Model ${model} fetch error:`, error);
    return [];
  }
}

/**
 * Get multi-model forecast data for comparison
 */
export async function getMultiModelForecast(
  lat: number,
  lng: number,
  days: number = 7
): Promise<MultiModelData> {
  const models: ModelSource[] = ['gfs', 'ecmwf', 'icon', 'gem'];

  // Fetch all models in parallel
  const results = await Promise.all(
    models.map(model => fetchModelForecast(lat, lng, model, days))
  );

  const modelData: Record<ModelSource, ModelForecast[]> = {
    gfs: results[0] || [],
    ecmwf: results[1] || [],
    icon: results[2] || [],
    gem: results[3] || [],
  };

  // Calculate agreement across models
  const agreement = calculateModelAgreement(modelData, days);

  return {
    models: modelData,
    agreement,
    generatedAt: new Date().toISOString(),
  };
}

/**
 * Calculate model agreement/divergence for each day
 */
function calculateModelAgreement(
  models: Record<ModelSource, ModelForecast[]>,
  days: number
): ModelAgreement[] {
  const agreement: ModelAgreement[] = [];

  for (let i = 0; i < days; i++) {
    const snowValues: number[] = [];
    const precipValues: number[] = [];
    const tempValues: number[] = [];
    let date = '';

    for (const modelForecasts of Object.values(models)) {
      if (modelForecasts[i]) {
        date = modelForecasts[i].date;
        snowValues.push(modelForecasts[i].snowfallSum);
        precipValues.push(modelForecasts[i].precipitationSum);
        tempValues.push(modelForecasts[i].highTemp);
      }
    }

    if (snowValues.length === 0) continue;

    const snowRange = {
      min: Math.min(...snowValues),
      max: Math.max(...snowValues),
      spread: Math.max(...snowValues) - Math.min(...snowValues),
    };

    const precipRange = {
      min: Math.min(...precipValues),
      max: Math.max(...precipValues),
      spread: Math.max(...precipValues) - Math.min(...precipValues),
    };

    const tempRange = {
      min: Math.min(...tempValues),
      max: Math.max(...tempValues),
      spread: Math.max(...tempValues) - Math.min(...tempValues),
    };

    // Calculate confidence based on spread
    // Snowfall spread: <2" = high, 2-5" = medium, >5" = low
    // Temp spread: <5°F = high, 5-10°F = medium, >10°F = low
    let confidenceScore = 100;

    // Penalize for snowfall divergence
    if (snowRange.spread > 5) confidenceScore -= 30;
    else if (snowRange.spread > 2) confidenceScore -= 15;

    // Penalize for temperature divergence
    if (tempRange.spread > 10) confidenceScore -= 25;
    else if (tempRange.spread > 5) confidenceScore -= 10;

    // Penalize for days further out
    confidenceScore -= i * 5;

    confidenceScore = Math.max(20, Math.min(100, confidenceScore));

    const confidence: 'high' | 'medium' | 'low' =
      confidenceScore >= 70 ? 'high' :
      confidenceScore >= 45 ? 'medium' : 'low';

    agreement.push({
      date,
      snowfallRange: snowRange,
      precipRange,
      tempRange,
      confidence,
      confidencePercent: confidenceScore,
    });
  }

  return agreement;
}

// ============================================================
// Ensemble Probability Forecast (ECMWF IFS 0.25°, 51 members)
// ============================================================

export interface EnsembleForecastDay {
  date: string;
  snowfall: {
    p10: number;  // inches
    p25: number;
    p50: number;
    p75: number;
    p90: number;
    mean: number;
  };
  probability: {
    over1in: number;   // 0-100
    over3in: number;
    over6in: number;
    over12in: number;
  };
}

export interface EnsembleForecast {
  days: EnsembleForecastDay[];
  memberCount: number;
  model: string;
  generatedAt: string;
}

function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  const idx = (p / 100) * (sorted.length - 1);
  const lower = Math.floor(idx);
  const upper = Math.ceil(idx);
  if (lower === upper) return sorted[lower];
  const value = sorted[lower] + (sorted[upper] - sorted[lower]) * (idx - lower);
  return Math.round(value * 10) / 10;
}

function probabilityExceeding(values: number[], threshold: number): number {
  if (values.length === 0) return 0;
  const count = values.filter(v => v > threshold).length;
  return Math.round((count / values.length) * 100);
}

function feetToMeters(feet: number): number {
  return Math.round(feet / 3.28084);
}

interface EnsembleApiResponse {
  hourly?: {
    time?: string[];
    snowfall_member01?: number[];
    [key: string]: number[] | string[] | undefined;
  };
}

/**
 * Fetch raw hourly snowfall from all 51 ECMWF IFS ensemble members
 */
async function fetchEnsembleMembers(
  lat: number,
  lng: number,
  days: number
): Promise<EnsembleApiResponse> {
  const url = new URL(ENSEMBLE_URL);
  url.searchParams.set('latitude', lat.toString());
  url.searchParams.set('longitude', lng.toString());
  url.searchParams.set('hourly', 'snowfall');
  url.searchParams.set('models', 'ecmwf_ifs025');
  url.searchParams.set('timezone', 'America/Los_Angeles');
  url.searchParams.set('forecast_days', Math.min(days, 7).toString());

  const response = await fetch(url.toString(), {
    signal: AbortSignal.timeout(15000),
  });

  if (!response.ok) {
    throw new Error(`Ensemble API error: ${response.status}`);
  }

  return response.json();
}

/**
 * Get probabilistic snow forecast from 51 ECMWF IFS ensemble members.
 * Returns percentiles (p10-p90) and probability of exceeding thresholds.
 */
export async function getEnsembleProbabilityForecast(
  lat: number,
  lng: number,
  days: number = 7
): Promise<EnsembleForecast> {
  const cappedDays = Math.min(days, 7);
  const data = await fetchEnsembleMembers(lat, lng, cappedDays);

  if (!data.hourly?.time) {
    throw new Error('No ensemble data available');
  }

  const times = data.hourly.time;

  // Collect all member arrays dynamically (ECMWF IFS 0.25° returns 50 members)
  const memberArrays: number[][] = [];
  for (let m = 1; m <= 50; m++) {
    const key = `snowfall_member${String(m).padStart(2, '0')}`;
    const arr = data.hourly[key] as number[] | undefined;
    if (arr) memberArrays.push(arr);
  }

  if (memberArrays.length === 0) {
    throw new Error('No ensemble member data found');
  }

  // Group hours into days and sum snowfall per member per day
  const dayMap = new Map<string, number[]>(); // date -> member totals (cm)

  for (let h = 0; h < times.length; h++) {
    const date = times[h].split('T')[0];
    if (!dayMap.has(date)) {
      dayMap.set(date, new Array(memberArrays.length).fill(0));
    }
    const totals = dayMap.get(date)!;
    for (let m = 0; m < memberArrays.length; m++) {
      totals[m] += memberArrays[m][h] || 0;
    }
  }

  // Build forecast days
  const forecastDays: EnsembleForecastDay[] = [];

  for (const [date, memberTotals] of dayMap) {
    // Convert cm to inches for each member
    const inchValues = memberTotals.map(cm => cmToInches(cm));
    const sorted = [...inchValues].sort((a, b) => a - b);
    const mean = inchValues.reduce((s, v) => s + v, 0) / inchValues.length;

    forecastDays.push({
      date,
      snowfall: {
        p10: percentile(sorted, 10),
        p25: percentile(sorted, 25),
        p50: percentile(sorted, 50),
        p75: percentile(sorted, 75),
        p90: percentile(sorted, 90),
        mean: Math.round(mean * 10) / 10,
      },
      probability: {
        over1in: probabilityExceeding(inchValues, 1),
        over3in: probabilityExceeding(inchValues, 3),
        over6in: probabilityExceeding(inchValues, 6),
        over12in: probabilityExceeding(inchValues, 12),
      },
    });
  }

  return {
    days: forecastDays,
    memberCount: memberArrays.length,
    model: 'ecmwf_ifs025',
    generatedAt: new Date().toISOString(),
  };
}

// ============================================================
// Elevation-Band Forecasts (base / mid / summit)
// ============================================================

export interface ElevationBandDay {
  date: string;
  snowfall: number;       // inches
  precipitation: number;  // inches
  highTemp: number;       // fahrenheit
  lowTemp: number;        // fahrenheit
  precipType: 'snow' | 'rain' | 'mixed';
}

export interface ElevationBandForecast {
  elevation: number; // feet
  days: ElevationBandDay[];
}

export interface ElevationForecast {
  base: ElevationBandForecast;
  mid: ElevationBandForecast;
  summit: ElevationBandForecast;
  generatedAt: string;
}

function determinePrecipType(
  snowfall: number,
  precip: number,
  highTemp: number,
  lowTemp: number
): 'snow' | 'rain' | 'mixed' {
  if (precip <= 0) return 'snow'; // no precip, default
  const snowRatio = snowfall / Math.max(precip, 0.01);
  if (snowRatio > 0.7) return 'snow';
  if (snowRatio < 0.2 || (highTemp > 38 && lowTemp > 32)) return 'rain';
  return 'mixed';
}

async function fetchForecastAtElevation(
  lat: number,
  lng: number,
  elevFeet: number,
  days: number
): Promise<ElevationBandDay[]> {
  const elevMeters = feetToMeters(elevFeet);

  const params: Record<string, string> = {
    latitude: lat.toString(),
    longitude: lng.toString(),
    daily: 'snowfall_sum,precipitation_sum,temperature_2m_max,temperature_2m_min',
    timezone: 'America/Los_Angeles',
    forecast_days: Math.min(days, 7).toString(),
    elevation: elevMeters.toString(),
  };

  const data = await fetchOpenMeteo(params);

  if (!data.daily?.time) return [];

  return data.daily.time.map((date, i) => {
    const snowfall = cmToInches(data.daily?.snowfall_sum?.[i] || 0);
    const precipitation = mmToInches(data.daily?.precipitation_sum?.[i] || 0);
    const highTemp = celsiusToFahrenheit(data.daily?.temperature_2m_max?.[i] || 0);
    const lowTemp = celsiusToFahrenheit(data.daily?.temperature_2m_min?.[i] || 0);

    return {
      date,
      snowfall,
      precipitation,
      highTemp,
      lowTemp,
      precipType: determinePrecipType(snowfall, precipitation, highTemp, lowTemp),
    };
  });
}

/**
 * Get forecast at 3 elevation bands: base, mid (avg), summit.
 * Uses the standard Open-Meteo API with `&elevation=` param.
 */
export async function getElevationForecast(
  lat: number,
  lng: number,
  baseFeet: number,
  summitFeet: number,
  days: number = 7
): Promise<ElevationForecast> {
  const midFeet = Math.round((baseFeet + summitFeet) / 2);
  const cappedDays = Math.min(days, 7);

  const [baseDays, midDays, summitDays] = await Promise.all([
    fetchForecastAtElevation(lat, lng, baseFeet, cappedDays),
    fetchForecastAtElevation(lat, lng, midFeet, cappedDays),
    fetchForecastAtElevation(lat, lng, summitFeet, cappedDays),
  ]);

  return {
    base: { elevation: baseFeet, days: baseDays },
    mid: { elevation: midFeet, days: midDays },
    summit: { elevation: summitFeet, days: summitDays },
    generatedAt: new Date().toISOString(),
  };
}
