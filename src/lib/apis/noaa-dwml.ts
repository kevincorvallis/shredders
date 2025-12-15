// NOAA Digital Weather Markup Language (DWML) Parser
// Fetches hourly quantitative precipitation forecasts from NWS
// Docs: https://graphical.weather.gov/xml/

const DWML_BASE_URL = 'https://forecast.weather.gov/MapClick.php';

// Parsed hourly data point
export interface DWMLHourlyData {
  time: string;
  temperature: number;       // °F
  dewPoint: number;          // °F
  windChill: number;         // °F
  precipProbability: number; // 0-100%
  windSpeed: number;         // mph
  windGust: number;          // mph
  windDirection: number;     // degrees (0-360)
  cloudCover: number;        // 0-100%
  humidity: number;          // 0-100%
  qpf: number;               // inches (Quantitative Precipitation Forecast)
}

// Summary data
export interface DWMLPrecipitationSummary {
  total48h: number;     // total QPF in inches for next 48 hours
  total24h: number;     // total QPF in inches for next 24 hours
  maxHourlyRate: number; // max hourly precipitation rate
  hourlyData: DWMLHourlyData[];
}

/**
 * Fetch DWML XML data from NOAA
 */
async function fetchDWML(lat: number, lng: number): Promise<string> {
  const url = new URL(DWML_BASE_URL);
  url.searchParams.set('lat', lat.toString());
  url.searchParams.set('lon', lng.toString());
  url.searchParams.set('FcstType', 'digitalDWML');

  const response = await fetch(url.toString(), {
    headers: {
      'User-Agent': 'Shredders/1.0 (contact@shredders.app)',
    },
  });

  if (!response.ok) {
    throw new Error(`NOAA DWML API error: ${response.status}`);
  }

  return response.text();
}

/**
 * Parse time-series values from DWML XML
 * Uses regex since we're in a Node.js environment without DOM
 */
function parseTimeSeriesValues(xml: string, parameterName: string): number[] {
  // Match the parameter section
  const paramRegex = new RegExp(
    `<${parameterName}[^>]*>([\\s\\S]*?)</${parameterName}>`,
    'i'
  );
  const paramMatch = xml.match(paramRegex);
  if (!paramMatch) return [];

  // Extract all value tags
  const valueRegex = /<value[^>]*>([^<]*)<\/value>/gi;
  const values: number[] = [];
  let match;

  while ((match = valueRegex.exec(paramMatch[1])) !== null) {
    const value = match[1].trim();
    values.push(value === '' ? 0 : parseFloat(value) || 0);
  }

  return values;
}

/**
 * Parse time layout from DWML XML
 */
function parseTimeLayout(xml: string): string[] {
  // Find the first time-layout section with hourly data
  const layoutRegex = /<time-layout[^>]*>([\s\S]*?)<\/time-layout>/gi;
  const times: string[] = [];
  let match;

  while ((match = layoutRegex.exec(xml)) !== null) {
    const startTimeRegex = /<start-valid-time[^>]*>([^<]+)<\/start-valid-time>/gi;
    let timeMatch;
    const layoutTimes: string[] = [];

    while ((timeMatch = startTimeRegex.exec(match[1])) !== null) {
      layoutTimes.push(timeMatch[1]);
    }

    // Use the layout with the most entries (usually hourly)
    if (layoutTimes.length > times.length) {
      times.length = 0;
      times.push(...layoutTimes);
    }
  }

  return times;
}

/**
 * Get hourly QPF (Quantitative Precipitation Forecast) data
 */
export async function getHourlyQPF(lat: number, lng: number): Promise<DWMLHourlyData[]> {
  const xml = await fetchDWML(lat, lng);

  const times = parseTimeLayout(xml);
  const temperatures = parseTimeSeriesValues(xml, 'temperature');
  const dewPoints = parseTimeSeriesValues(xml, 'dew-point');
  const windChills = parseTimeSeriesValues(xml, 'wind-chill');
  const precipProbs = parseTimeSeriesValues(xml, 'probability-of-precipitation');
  const windSpeeds = parseTimeSeriesValues(xml, 'wind-speed');
  const windGusts = parseTimeSeriesValues(xml, 'wind-gust');
  const windDirections = parseTimeSeriesValues(xml, 'direction');
  const cloudCovers = parseTimeSeriesValues(xml, 'cloud-amount');
  const humidity = parseTimeSeriesValues(xml, 'humidity');
  const qpf = parseTimeSeriesValues(xml, 'hourly-qpf');

  // Combine into hourly data points
  const hourlyData: DWMLHourlyData[] = [];
  const maxLen = Math.min(times.length, 168); // Max 7 days of hourly data

  for (let i = 0; i < maxLen; i++) {
    hourlyData.push({
      time: times[i] || '',
      temperature: temperatures[i] || 0,
      dewPoint: dewPoints[i] || 0,
      windChill: windChills[i] || temperatures[i] || 0,
      precipProbability: precipProbs[i] || 0,
      windSpeed: windSpeeds[i] || 0,
      windGust: windGusts[i] || 0,
      windDirection: windDirections[i] || 0,
      cloudCover: cloudCovers[i] || 0,
      humidity: humidity[i] || 0,
      qpf: qpf[i] || 0,
    });
  }

  return hourlyData;
}

/**
 * Get precipitation summary for the next 24 and 48 hours
 */
export async function getPrecipitationSummary(lat: number, lng: number): Promise<DWMLPrecipitationSummary> {
  const hourlyData = await getHourlyQPF(lat, lng);

  // Sum QPF for 24h and 48h
  const data24h = hourlyData.slice(0, 24);
  const data48h = hourlyData.slice(0, 48);

  const total24h = data24h.reduce((sum, h) => sum + h.qpf, 0);
  const total48h = data48h.reduce((sum, h) => sum + h.qpf, 0);
  const maxHourlyRate = Math.max(...hourlyData.map(h => h.qpf), 0);

  return {
    total24h: Math.round(total24h * 100) / 100,
    total48h: Math.round(total48h * 100) / 100,
    maxHourlyRate: Math.round(maxHourlyRate * 100) / 100,
    hourlyData,
  };
}

/**
 * Get total precipitation for the next N hours
 */
export async function getTotalPrecipitation(lat: number, lng: number, hours: number = 48): Promise<number> {
  const summary = await getPrecipitationSummary(lat, lng);
  const data = summary.hourlyData.slice(0, hours);
  return data.reduce((sum, h) => sum + h.qpf, 0);
}

/**
 * Calculate expected snowfall from QPF using temperature-based snow ratio
 *
 * Snow ratios vary based on temperature:
 * - Very cold (<15°F): 15:1 to 20:1 (light, fluffy powder)
 * - Cold (15-25°F): 12:1 to 15:1 (good powder)
 * - Moderate (25-32°F): 8:1 to 12:1 (slightly heavier)
 * - Near freezing (32-35°F): 5:1 to 8:1 (wet, heavy snow)
 * - Above freezing (>35°F): Rain, not snow
 */
export function calculateSnowfallFromQPF(
  qpfInches: number,
  temperatureF: number,
  freezingLevelFeet: number,
  elevationFeet: number
): number {
  // If freezing level is above the elevation, it's rain
  if (freezingLevelFeet > elevationFeet) {
    return 0;
  }

  // Determine snow ratio based on temperature
  let snowRatio: number;
  if (temperatureF < 15) {
    snowRatio = 18; // Very light, fluffy
  } else if (temperatureF < 20) {
    snowRatio = 15; // Light powder
  } else if (temperatureF < 25) {
    snowRatio = 12; // Good powder
  } else if (temperatureF < 28) {
    snowRatio = 10; // Average
  } else if (temperatureF < 32) {
    snowRatio = 8; // Slightly heavy
  } else if (temperatureF < 35) {
    snowRatio = 5; // Wet, heavy snow
  } else {
    return 0; // Too warm, rain
  }

  return Math.round(qpfInches * snowRatio * 10) / 10;
}

/**
 * Get expected snowfall for the next N hours
 * Combines QPF with temperature-based snow ratio
 */
export async function getExpectedSnowfall(
  lat: number,
  lng: number,
  hours: number = 48,
  freezingLevelFeet: number,
  elevationFeet: number
): Promise<{ snowfall: number; qpf: number; avgTemp: number }> {
  const hourlyData = await getHourlyQPF(lat, lng);
  const data = hourlyData.slice(0, hours);

  let totalSnow = 0;
  let totalQPF = 0;
  let tempSum = 0;

  for (const hour of data) {
    totalQPF += hour.qpf;
    tempSum += hour.temperature;

    // Calculate snowfall for this hour
    const hourSnow = calculateSnowfallFromQPF(
      hour.qpf,
      hour.temperature,
      freezingLevelFeet,
      elevationFeet
    );
    totalSnow += hourSnow;
  }

  const avgTemp = data.length > 0 ? Math.round(tempSum / data.length) : 32;

  return {
    snowfall: Math.round(totalSnow * 10) / 10,
    qpf: Math.round(totalQPF * 100) / 100,
    avgTemp,
  };
}
