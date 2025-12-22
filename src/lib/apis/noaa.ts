// NOAA National Weather Service API Client
// Docs: https://www.weather.gov/documentation/services-web-api

const USER_AGENT = 'Shredders/1.0 (contact@shredders.app)';

// Grid config type for parameterized forecasts
export interface NOAAGridConfig {
  gridOffice: string; // e.g., "SEW", "PDT", "PQR"
  gridX: number;
  gridY: number;
}

// Default config for backwards compatibility (Mt. Baker)
export const DEFAULT_NOAA_CONFIG: NOAAGridConfig = {
  gridOffice: 'SEW',
  gridX: 157,
  gridY: 123,
};

interface NOAAPointsResponse {
  properties: {
    forecast: string;
    forecastHourly: string;
    forecastGridData: string;
    relativeLocation: {
      properties: {
        city: string;
        state: string;
      };
    };
  };
}

interface NOAAForecastPeriod {
  number: number;
  name: string;
  startTime: string;
  endTime: string;
  isDaytime: boolean;
  temperature: number;
  temperatureUnit: string;
  temperatureTrend: string | null;
  probabilityOfPrecipitation: {
    value: number | null;
  };
  windSpeed: string;
  windDirection: string;
  icon: string;
  shortForecast: string;
  detailedForecast: string;
}

interface NOAAForecastResponse {
  properties: {
    updated: string;
    generatedAt: string;
    periods: NOAAForecastPeriod[];
  };
}

interface NOAAGridDataResponse {
  properties: {
    temperature: { values: Array<{ validTime: string; value: number }> };
    snowfallAmount: { values: Array<{ validTime: string; value: number }> };
    windSpeed: { values: Array<{ validTime: string; value: number }> };
    windGust: { values: Array<{ validTime: string; value: number }> };
    windDirection: { values: Array<{ validTime: string; value: number }> };
    probabilityOfPrecipitation: { values: Array<{ validTime: string; value: number }> };
    relativeHumidity: { values: Array<{ validTime: string; value: number }> };
    visibility: { values: Array<{ validTime: string; value: number }> };
    skyCover: { values: Array<{ validTime: string; value: number }> };
  };
}

export interface ProcessedForecastDay {
  date: string;
  dayOfWeek: string;
  high: number;
  low: number;
  snowfall: number;
  precipProbability: number;
  precipType: 'snow' | 'rain' | 'mixed' | 'none';
  wind: { speed: number; gust: number };
  conditions: string;
  icon: string;
}

async function fetchWithRetry(url: string, retries = 3): Promise<Response> {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(url, {
        headers: {
          'User-Agent': USER_AGENT,
          'Accept': 'application/geo+json',
        },
      });

      if (response.ok) return response;

      if (response.status === 503 && i < retries - 1) {
        await new Promise(r => setTimeout(r, 1000 * (i + 1)));
        continue;
      }

      throw new Error(`NOAA API error: ${response.status}`);
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(r => setTimeout(r, 1000 * (i + 1)));
    }
  }
  throw new Error('Max retries reached');
}

export async function getGridPointUrls(lat: number, lng: number) {
  const url = `https://api.weather.gov/points/${lat},${lng}`;
  const response = await fetchWithRetry(url);
  const data: NOAAPointsResponse = await response.json();

  return {
    forecast: data.properties.forecast,
    forecastHourly: data.properties.forecastHourly,
    forecastGridData: data.properties.forecastGridData,
  };
}

export async function getForecast(
  config: NOAAGridConfig = DEFAULT_NOAA_CONFIG
): Promise<ProcessedForecastDay[]> {
  const forecastUrl = `https://api.weather.gov/gridpoints/${config.gridOffice}/${config.gridX},${config.gridY}/forecast`;
  const response = await fetchWithRetry(forecastUrl);
  const data: NOAAForecastResponse = await response.json();

  // Process periods into daily forecasts
  const dailyForecasts: Map<string, ProcessedForecastDay> = new Map();

  for (const period of data.properties.periods) {
    const date = new Date(period.startTime);
    const dateKey = date.toISOString().split('T')[0];

    const existing = dailyForecasts.get(dateKey);

    // Determine snow vs rain based on temperature and forecast text
    const isSnow = period.temperature < 35 ||
      period.shortForecast.toLowerCase().includes('snow');
    const isRain = period.shortForecast.toLowerCase().includes('rain');

    // Extract wind speed number from string like "10 to 15 mph"
    const windMatch = period.windSpeed.match(/(\d+)/g);
    const windSpeed = windMatch ? parseInt(windMatch[windMatch.length - 1]) : 0;

    // Estimate snowfall from forecast text
    let snowfall = 0;
    const snowMatch = period.detailedForecast.match(/(\d+)\s*(?:to\s*(\d+))?\s*inch/i);
    if (snowMatch && isSnow) {
      snowfall = snowMatch[2] ? parseInt(snowMatch[2]) : parseInt(snowMatch[1]);
    }

    // Determine icon
    let icon = 'cloud';
    if (period.shortForecast.toLowerCase().includes('snow')) icon = 'snow';
    else if (period.shortForecast.toLowerCase().includes('rain')) icon = 'rain';
    else if (period.shortForecast.toLowerCase().includes('sun') ||
             period.shortForecast.toLowerCase().includes('clear')) icon = 'sun';
    else if (period.shortForecast.toLowerCase().includes('fog')) icon = 'fog';

    if (!existing) {
      dailyForecasts.set(dateKey, {
        date: dateKey,
        dayOfWeek: date.toLocaleDateString('en-US', { weekday: 'short' }),
        high: period.isDaytime ? period.temperature : 0,
        low: period.isDaytime ? 0 : period.temperature,
        snowfall,
        precipProbability: period.probabilityOfPrecipitation?.value || 0,
        precipType: isSnow ? 'snow' : isRain ? 'rain' : 'none',
        wind: { speed: windSpeed, gust: Math.round(windSpeed * 1.5) },
        conditions: period.shortForecast,
        icon,
      });
    } else {
      // Update high/low based on daytime
      if (period.isDaytime) {
        existing.high = Math.max(existing.high, period.temperature);
      } else {
        existing.low = existing.low === 0 ? period.temperature : Math.min(existing.low, period.temperature);
      }
      existing.snowfall = Math.max(existing.snowfall, snowfall);
      existing.precipProbability = Math.max(existing.precipProbability, period.probabilityOfPrecipitation?.value || 0);
    }
  }

  // Return sorted array, limited to 7 days
  return Array.from(dailyForecasts.values())
    .sort((a, b) => a.date.localeCompare(b.date))
    .slice(0, 7);
}

export async function getCurrentWeather(
  config: NOAAGridConfig = DEFAULT_NOAA_CONFIG
) {
  const hourlyUrl = `https://api.weather.gov/gridpoints/${config.gridOffice}/${config.gridX},${config.gridY}/forecast/hourly`;
  const response = await fetchWithRetry(hourlyUrl);
  const data: NOAAForecastResponse = await response.json();

  const current = data.properties.periods[0];

  // Extract wind speed
  const windMatch = current.windSpeed.match(/(\d+)/g);
  const windSpeed = windMatch ? parseInt(windMatch[0]) : 0;

  return {
    temperature: current.temperature,
    conditions: current.shortForecast,
    windSpeed,
    windDirection: current.windDirection,
    icon: current.icon,
  };
}

// Extended weather data for ski patrol dashboard
export interface ExtendedCurrentWeather {
  temperature: number;
  conditions: string;
  windSpeed: number;
  windGust: number | null;
  windDirection: string;
  windDirectionDegrees: number | null;
  humidity: number | null;
  visibility: number | null; // in miles
  visibilityCategory: 'excellent' | 'good' | 'moderate' | 'poor' | 'very-poor';
  skyCover: number | null; // percentage
  precipProbability: number | null;
  icon: string;
}

function categorizeVisibility(visibilityMeters: number | null): ExtendedCurrentWeather['visibilityCategory'] {
  if (visibilityMeters === null) return 'good';
  const miles = visibilityMeters / 1609.34;
  if (miles >= 10) return 'excellent';
  if (miles >= 5) return 'good';
  if (miles >= 1) return 'moderate';
  if (miles >= 0.25) return 'poor';
  return 'very-poor';
}

function windDirectionToCardinal(degrees: number): string {
  const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  const index = Math.round(degrees / 22.5) % 16;
  return directions[index];
}

export async function getExtendedCurrentWeather(
  config: NOAAGridConfig = DEFAULT_NOAA_CONFIG
): Promise<ExtendedCurrentWeather> {
  // Fetch both hourly forecast and gridded data
  const [hourlyResponse, gridResponse] = await Promise.all([
    fetchWithRetry(`https://api.weather.gov/gridpoints/${config.gridOffice}/${config.gridX},${config.gridY}/forecast/hourly`),
    fetchWithRetry(`https://api.weather.gov/gridpoints/${config.gridOffice}/${config.gridX},${config.gridY}`)
  ]);

  const hourlyData: NOAAForecastResponse = await hourlyResponse.json();
  const gridData: NOAAGridDataResponse = await gridResponse.json();

  const current = hourlyData.properties.periods[0];

  // Extract wind speed
  const windMatch = current.windSpeed.match(/(\d+)/g);
  const windSpeed = windMatch ? parseInt(windMatch[0]) : 0;

  // Get current time for matching grid data
  const now = new Date();
  const findCurrentValue = (values: Array<{ validTime: string; value: number }> | undefined): number | null => {
    if (!values || values.length === 0) return null;
    // Find the value whose time range includes now
    for (const v of values) {
      const [start, duration] = v.validTime.split('/');
      const startTime = new Date(start);
      // Parse ISO 8601 duration (e.g., PT1H, PT3H)
      const hoursMatch = duration?.match(/PT(\d+)H/);
      const hours = hoursMatch ? parseInt(hoursMatch[1]) : 1;
      const endTime = new Date(startTime.getTime() + hours * 60 * 60 * 1000);
      if (now >= startTime && now <= endTime) {
        return v.value;
      }
    }
    // Fallback to first value
    return values[0]?.value ?? null;
  };

  // Extract gridded data values
  const windGust = findCurrentValue(gridData.properties.windGust?.values);
  const windDirectionDegrees = findCurrentValue(gridData.properties.windDirection?.values);
  const humidity = findCurrentValue(gridData.properties.relativeHumidity?.values);
  const visibility = findCurrentValue(gridData.properties.visibility?.values);
  const skyCover = findCurrentValue(gridData.properties.skyCover?.values);
  const precipProbability = findCurrentValue(gridData.properties.probabilityOfPrecipitation?.values);

  // Convert wind gust from km/h to mph if present (NOAA gridded data uses km/h)
  const windGustMph = windGust !== null ? Math.round(windGust * 0.621371) : null;

  // Convert visibility from meters to miles
  const visibilityMiles = visibility !== null ? Math.round(visibility / 1609.34 * 10) / 10 : null;

  return {
    temperature: current.temperature,
    conditions: current.shortForecast,
    windSpeed,
    windGust: windGustMph,
    windDirection: windDirectionDegrees !== null ? windDirectionToCardinal(windDirectionDegrees) : current.windDirection,
    windDirectionDegrees,
    humidity: humidity !== null ? Math.round(humidity) : null,
    visibility: visibilityMiles,
    visibilityCategory: categorizeVisibility(visibility),
    skyCover: skyCover !== null ? Math.round(skyCover) : null,
    precipProbability: precipProbability !== null ? Math.round(precipProbability) : null,
    icon: current.icon,
  };
}

// Get wind data for the past hours (for wind rose visualization)
export interface WindDataPoint {
  time: string;
  speed: number;
  gust: number | null;
  direction: number;
}

export async function getRecentWindData(
  config: NOAAGridConfig = DEFAULT_NOAA_CONFIG,
  hours: number = 6
): Promise<WindDataPoint[]> {
  const gridUrl = `https://api.weather.gov/gridpoints/${config.gridOffice}/${config.gridX},${config.gridY}`;
  const response = await fetchWithRetry(gridUrl);
  const data: NOAAGridDataResponse = await response.json();

  const now = new Date();
  const cutoff = new Date(now.getTime() - hours * 60 * 60 * 1000);

  const windData: WindDataPoint[] = [];

  // Get wind speed data
  const speedValues = data.properties.windSpeed?.values || [];
  const gustValues = data.properties.windGust?.values || [];
  const directionValues = data.properties.windDirection?.values || [];

  for (const speedPoint of speedValues) {
    const [start] = speedPoint.validTime.split('/');
    const time = new Date(start);

    // Only include recent data
    if (time < cutoff || time > now) continue;

    // Find matching gust and direction
    const gust = gustValues.find(g => g.validTime.split('/')[0] === start)?.value ?? null;
    const direction = directionValues.find(d => d.validTime.split('/')[0] === start)?.value ?? 0;

    windData.push({
      time: start,
      speed: Math.round(speedPoint.value * 0.621371), // Convert km/h to mph
      gust: gust !== null ? Math.round(gust * 0.621371) : null,
      direction,
    });
  }

  return windData.sort((a, b) => new Date(a.time).getTime() - new Date(b.time).getTime());
}

// Weather Alerts
export interface WeatherAlert {
  id: string;
  event: string; // e.g., "Winter Storm Warning"
  headline: string;
  severity: 'Extreme' | 'Severe' | 'Moderate' | 'Minor' | 'Unknown';
  urgency: 'Immediate' | 'Expected' | 'Future' | 'Past' | 'Unknown';
  certainty: 'Observed' | 'Likely' | 'Possible' | 'Unlikely' | 'Unknown';
  onset: string | null;
  expires: string | null;
  description: string;
  instruction: string | null;
  areaDesc: string;
}

export async function getWeatherAlerts(lat: number, lng: number): Promise<WeatherAlert[]> {
  try {
    const url = `https://api.weather.gov/alerts/active?point=${lat},${lng}`;
    const response = await fetchWithRetry(url);
    const data = await response.json();

    if (!data.features || data.features.length === 0) {
      return [];
    }

    return data.features.map((feature: any) => ({
      id: feature.id,
      event: feature.properties.event,
      headline: feature.properties.headline,
      severity: feature.properties.severity,
      urgency: feature.properties.urgency,
      certainty: feature.properties.certainty,
      onset: feature.properties.onset,
      expires: feature.properties.expires,
      description: feature.properties.description,
      instruction: feature.properties.instruction,
      areaDesc: feature.properties.areaDesc,
    }));
  } catch (error) {
    console.error('Error fetching weather alerts:', error);
    return [];
  }
}

// Hourly Forecast (next 48-156 hours)
export interface HourlyForecastPeriod {
  time: string;
  temperature: number;
  temperatureUnit: string;
  dewpoint: number | null;
  windSpeed: number;
  windDirection: string;
  windDirectionDegrees: number | null;
  icon: string;
  shortForecast: string;
  precipProbability: number | null;
  relativeHumidity: number | null;
}

export async function getHourlyForecast(
  config: NOAAGridConfig = DEFAULT_NOAA_CONFIG,
  hours: number = 48
): Promise<HourlyForecastPeriod[]> {
  const hourlyUrl = `https://api.weather.gov/gridpoints/${config.gridOffice}/${config.gridX},${config.gridY}/forecast/hourly`;
  const response = await fetchWithRetry(hourlyUrl);
  const data: NOAAForecastResponse = await response.json();

  return data.properties.periods.slice(0, hours).map(period => {
    const windMatch = period.windSpeed.match(/(\d+)/g);
    const windSpeed = windMatch ? parseInt(windMatch[0]) : 0;

    return {
      time: period.startTime,
      temperature: period.temperature,
      temperatureUnit: period.temperatureUnit,
      dewpoint: null, // Not in standard hourly forecast
      windSpeed,
      windDirection: period.windDirection,
      windDirectionDegrees: null,
      icon: period.icon,
      shortForecast: period.shortForecast,
      precipProbability: period.probabilityOfPrecipitation?.value ?? null,
      relativeHumidity: null,
    };
  });
}

// Forecast Discussion (detailed text forecast from meteorologists)
export interface ForecastDiscussion {
  issuedTime: string;
  productCode: string;
  issuingOffice: string;
  text: string;
}

export async function getForecastDiscussion(
  config: NOAAGridConfig = DEFAULT_NOAA_CONFIG
): Promise<ForecastDiscussion | null> {
  try {
    // Get the zone for the grid point
    const zoneUrl = `https://api.weather.gov/gridpoints/${config.gridOffice}/${config.gridX},${config.gridY}`;
    const zoneResponse = await fetchWithRetry(zoneUrl);
    const zoneData = await zoneResponse.json();

    const forecastZone = zoneData.properties.forecastZone;
    if (!forecastZone) return null;

    // Extract zone ID from URL (e.g., https://api.weather.gov/zones/forecast/WAZ567 -> WAZ567)
    const zoneId = forecastZone.split('/').pop();

    // Get latest discussion for this zone
    const discussionUrl = `https://api.weather.gov/products/types/AFD/locations/${config.gridOffice}`;
    const discussionResponse = await fetchWithRetry(discussionUrl);
    const discussionData = await discussionResponse.json();

    if (!discussionData['@graph'] || discussionData['@graph'].length === 0) {
      return null;
    }

    // Get the most recent product
    const latestProduct = discussionData['@graph'][0];
    const productUrl = latestProduct['@id'];

    const productResponse = await fetchWithRetry(productUrl);
    const productData = await productResponse.json();

    return {
      issuedTime: productData.issuanceTime,
      productCode: productData.productCode,
      issuingOffice: config.gridOffice,
      text: productData.productText,
    };
  } catch (error) {
    console.error('Error fetching forecast discussion:', error);
    return null;
  }
}

// Generate weather.gov URLs for deep linking
export function getWeatherGovUrls(lat: number, lng: number, config: NOAAGridConfig) {
  const latRounded = lat.toFixed(4);
  const lngRounded = lng.toFixed(4);

  return {
    // Main forecast page
    forecast: `https://forecast.weather.gov/MapClick.php?lat=${latRounded}&lon=${lngRounded}`,

    // Hourly graph
    hourly: `https://forecast.weather.gov/MapClick.php?lat=${latRounded}&lon=${lngRounded}&unit=0&lg=english&FcstType=graphical`,

    // Detailed forecast
    detailed: `https://forecast.weather.gov/MapClick.php?lat=${latRounded}&lon=${lngRounded}&unit=0&lg=english&FcstType=text`,

    // Alerts
    alerts: `https://alerts.weather.gov/search?lat=${latRounded}&lon=${lngRounded}`,

    // Grid data
    grid: `https://api.weather.gov/gridpoints/${config.gridOffice}/${config.gridX},${config.gridY}`,

    // Forecast discussion
    discussion: `https://forecast.weather.gov/product.php?site=${config.gridOffice}&issuedby=${config.gridOffice}&product=AFD`,
  };
}
