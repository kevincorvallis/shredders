// NOAA National Weather Service API Client
// Docs: https://www.weather.gov/documentation/services-web-api

const MT_BAKER_LAT = 48.857;
const MT_BAKER_LNG = -121.669;
const USER_AGENT = 'PowderTracker/1.0 (contact@shredders.app)';

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
    probabilityOfPrecipitation: { values: Array<{ validTime: string; value: number }> };
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

export async function getGridPointUrls() {
  const url = `https://api.weather.gov/points/${MT_BAKER_LAT},${MT_BAKER_LNG}`;
  const response = await fetchWithRetry(url);
  const data: NOAAPointsResponse = await response.json();

  return {
    forecast: data.properties.forecast,
    forecastHourly: data.properties.forecastHourly,
    forecastGridData: data.properties.forecastGridData,
  };
}

export async function getForecast(): Promise<ProcessedForecastDay[]> {
  // Get the forecast URL for Mt. Baker area
  const forecastUrl = 'https://api.weather.gov/gridpoints/SEW/157,123/forecast';
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

export async function getCurrentWeather() {
  // Get hourly forecast for current conditions
  const hourlyUrl = 'https://api.weather.gov/gridpoints/SEW/157,123/forecast/hourly';
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
