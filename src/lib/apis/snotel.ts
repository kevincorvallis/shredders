// SNOTEL (NRCS AWDB) API Client
// Docs: https://wcc.sc.egov.usda.gov/awdbRestApi/

const BASE_URL = 'https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1';

// Default station for backwards compatibility
export const DEFAULT_SNOTEL_STATION = '910:WA:SNTL'; // Wells Creek (Mt. Baker)

interface SnotelDataPoint {
  date: string;
  value: number | null;
}

interface SnotelElementData {
  stationElement: {
    elementCode: string;
    storedUnitCode: string;
  };
  values: SnotelDataPoint[];
}

interface SnotelResponse {
  stationTriplet: string;
  data: SnotelElementData[];
}

export interface SnotelConditions {
  snowDepth: number;
  snowWaterEquivalent: number;
  temperature: number;
  precipitation: number;
  snowfall24h: number;
  snowfall48h: number;
  snowfall7d: number;
  lastUpdated: string;
}

// Extended conditions for ski patrol dashboard
export interface ExtendedSnotelConditions extends SnotelConditions {
  humidity: number | null;
  snowDensity: number | null;
  tempMax24hr: number | null;
  tempMin24hr: number | null;
  windSpeed: number | null;
  windDirection: number | null;
  // Calculated values
  settlingRate: number | null; // inches/day of snow compaction
  diurnalRange: number | null; // difference between max/min temp
}

export interface SnotelHistoryPoint {
  date: string;
  snowDepth: number;
  snowfall: number;
  temperature: number;
}

function formatDate(date: Date): string {
  return date.toISOString().split('T')[0];
}

async function fetchSnotelData(
  stationId: string,
  elements: string[],
  beginDate: string,
  endDate: string
): Promise<SnotelResponse[]> {
  const url = new URL(`${BASE_URL}/data`);
  url.searchParams.set('stationTriplets', stationId);
  url.searchParams.set('elements', elements.join(','));
  url.searchParams.set('duration', 'DAILY');
  url.searchParams.set('beginDate', beginDate);
  url.searchParams.set('endDate', endDate);
  url.searchParams.set('getFlags', 'false');
  url.searchParams.set('alwaysReturnDailyFeb29', 'false');

  const response = await fetch(url.toString());

  if (!response.ok) {
    throw new Error(`SNOTEL API error: ${response.status}`);
  }

  return response.json();
}

function getValueForDate(data: SnotelElementData[], elementCode: string, date: string): number | null {
  const element = data.find(d => d.stationElement.elementCode === elementCode);
  if (!element) return null;

  const point = element.values.find(v => v.date === date);
  return point?.value ?? null;
}

function getLatestValue(data: SnotelElementData[], elementCode: string): { value: number | null; date: string | null } {
  const element = data.find(d => d.stationElement.elementCode === elementCode);
  if (!element || element.values.length === 0) return { value: null, date: null };

  // Get most recent non-null value
  for (let i = element.values.length - 1; i >= 0; i--) {
    if (element.values[i].value !== null) {
      return { value: element.values[i].value, date: element.values[i].date };
    }
  }

  return { value: null, date: null };
}

export async function getCurrentConditions(
  stationId: string = DEFAULT_SNOTEL_STATION
): Promise<SnotelConditions> {
  const today = new Date();
  const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);

  const endDate = formatDate(today);
  const beginDate = formatDate(sevenDaysAgo);

  // Fetch snow depth (SNWD), snow water equivalent (WTEQ), temperature (TOBS), precipitation (PREC)
  const response = await fetchSnotelData(
    stationId,
    ['SNWD', 'WTEQ', 'TOBS', 'PREC'],
    beginDate,
    endDate
  );

  if (!response.length || !response[0].data.length) {
    throw new Error('No SNOTEL data available');
  }

  const data = response[0].data;

  // Get current/latest values
  const snowDepth = getLatestValue(data, 'SNWD');
  const swe = getLatestValue(data, 'WTEQ');
  const temp = getLatestValue(data, 'TOBS');

  // Calculate snowfall over different periods
  const snowDepthElement = data.find(d => d.stationElement.elementCode === 'SNWD');
  const values = snowDepthElement?.values || [];

  // Sort by date descending
  const sortedValues = [...values]
    .filter(v => v.value !== null)
    .sort((a, b) => b.date.localeCompare(a.date));

  // Calculate snowfall deltas
  const currentDepth = sortedValues[0]?.value || 0;
  const depth24hAgo = sortedValues[1]?.value || currentDepth;
  const depth48hAgo = sortedValues[2]?.value || depth24hAgo;
  const depth7dAgo = sortedValues[6]?.value || sortedValues[sortedValues.length - 1]?.value || currentDepth;

  // Snowfall is positive change in depth (negative change means melting/settling)
  const snowfall24h = Math.max(0, currentDepth - depth24hAgo);
  const snowfall48h = Math.max(0, currentDepth - depth48hAgo);
  const snowfall7d = Math.max(0, currentDepth - depth7dAgo);

  return {
    snowDepth: snowDepth.value || 0,
    snowWaterEquivalent: swe.value || 0,
    temperature: temp.value || 32, // Default to freezing if no data
    precipitation: 0, // Would need cumulative calculation
    snowfall24h,
    snowfall48h,
    snowfall7d,
    lastUpdated: snowDepth.date || endDate,
  };
}

export async function getHistoricalData(
  stationId: string = DEFAULT_SNOTEL_STATION,
  days: number = 30
): Promise<SnotelHistoryPoint[]> {
  const today = new Date();
  const startDate = new Date(today.getTime() - days * 24 * 60 * 60 * 1000);

  const response = await fetchSnotelData(
    stationId,
    ['SNWD', 'TOBS'],
    formatDate(startDate),
    formatDate(today)
  );

  if (!response.length || !response[0].data.length) {
    return [];
  }

  const data = response[0].data;
  const snowDepthElement = data.find(d => d.stationElement.elementCode === 'SNWD');
  const tempElement = data.find(d => d.stationElement.elementCode === 'TOBS');

  if (!snowDepthElement) return [];

  const history: SnotelHistoryPoint[] = [];
  let previousDepth: number | null = null;

  for (const point of snowDepthElement.values) {
    if (point.value === null) continue;

    const temp = tempElement?.values.find(t => t.date === point.date)?.value || 32;
    const snowfall = previousDepth !== null ? Math.max(0, point.value - previousDepth) : 0;

    history.push({
      date: point.date,
      snowDepth: point.value,
      snowfall,
      temperature: temp,
    });

    previousDepth = point.value;
  }

  return history;
}

export async function getStationMetadata(stationId: string = DEFAULT_SNOTEL_STATION) {
  const url = `${BASE_URL}/stations?stationTriplets=${stationId}`;
  const response = await fetch(url);
  return response.json();
}

// Extended conditions for ski patrol dashboard
export async function getExtendedConditions(
  stationId: string = DEFAULT_SNOTEL_STATION
): Promise<ExtendedSnotelConditions> {
  const today = new Date();
  const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
  const twoDaysAgo = new Date(today.getTime() - 2 * 24 * 60 * 60 * 1000);

  const endDate = formatDate(today);
  const beginDate = formatDate(sevenDaysAgo);
  const shortBeginDate = formatDate(twoDaysAgo);

  // Fetch extended parameters:
  // SNWD - Snow Depth, WTEQ - Snow Water Equivalent, TOBS - Observed Temperature
  // PREC - Precipitation, RHUM - Relative Humidity (not always available)
  // TMAX - Max Temperature, TMIN - Min Temperature
  // WSOD - Wind Speed (rarely available), WDIR - Wind Direction (rarely available)
  const response = await fetchSnotelData(
    stationId,
    ['SNWD', 'WTEQ', 'TOBS', 'PREC', 'RHUM', 'TMAX', 'TMIN', 'WSOD', 'WDIR'],
    beginDate,
    endDate
  );

  if (!response.length || !response[0].data.length) {
    throw new Error('No SNOTEL data available');
  }

  const data = response[0].data;

  // Get current/latest values
  const snowDepth = getLatestValue(data, 'SNWD');
  const swe = getLatestValue(data, 'WTEQ');
  const temp = getLatestValue(data, 'TOBS');
  const humidity = getLatestValue(data, 'RHUM');
  const tempMax = getLatestValue(data, 'TMAX');
  const tempMin = getLatestValue(data, 'TMIN');
  const windSpeed = getLatestValue(data, 'WSOD');
  const windDirection = getLatestValue(data, 'WDIR');

  // Calculate snow density (SWE/Depth * 100 = density percentage)
  let snowDensity: number | null = null;
  if (snowDepth.value && swe.value && snowDepth.value > 0) {
    snowDensity = Math.round((swe.value / snowDepth.value) * 100);
  }

  // Calculate diurnal temperature range
  let diurnalRange: number | null = null;
  if (tempMax.value !== null && tempMin.value !== null) {
    diurnalRange = Math.round(tempMax.value - tempMin.value);
  }

  // Calculate settling rate (change in depth - new snow)
  const snowDepthElement = data.find(d => d.stationElement.elementCode === 'SNWD');
  const values = snowDepthElement?.values || [];
  const sortedValues = [...values]
    .filter(v => v.value !== null)
    .sort((a, b) => b.date.localeCompare(a.date));

  // Calculate snowfall deltas
  const currentDepth = sortedValues[0]?.value || 0;
  const depth24hAgo = sortedValues[1]?.value || currentDepth;
  const depth48hAgo = sortedValues[2]?.value || depth24hAgo;
  const depth7dAgo = sortedValues[6]?.value || sortedValues[sortedValues.length - 1]?.value || currentDepth;

  // Snowfall is positive change in depth
  const snowfall24h = Math.max(0, currentDepth - depth24hAgo);
  const snowfall48h = Math.max(0, currentDepth - depth48hAgo);
  const snowfall7d = Math.max(0, currentDepth - depth7dAgo);

  // Calculate settling rate (how much snow compacted in 24h)
  // Negative depth change when no precip = settling
  let settlingRate: number | null = null;
  const depthChange = currentDepth - depth24hAgo;
  if (depthChange < 0 && snowfall24h === 0) {
    settlingRate = Math.abs(depthChange);
  } else if (snowfall24h > 0) {
    // If it snowed, estimate settling from prior days
    const depth2dAgo = sortedValues[2]?.value || depth24hAgo;
    const depth3dAgo = sortedValues[3]?.value || depth2dAgo;
    const priorChange = depth24hAgo - depth2dAgo;
    if (priorChange < 0) {
      settlingRate = Math.abs(priorChange);
    }
  }

  return {
    snowDepth: snowDepth.value || 0,
    snowWaterEquivalent: swe.value || 0,
    temperature: temp.value || 32,
    precipitation: 0,
    snowfall24h,
    snowfall48h,
    snowfall7d,
    lastUpdated: snowDepth.date || endDate,
    // Extended fields
    humidity: humidity.value,
    snowDensity,
    tempMax24hr: tempMax.value,
    tempMin24hr: tempMin.value,
    windSpeed: windSpeed.value,
    windDirection: windDirection.value,
    settlingRate,
    diurnalRange,
  };
}

// Get multi-day history with extended data for trend analysis
export interface ExtendedHistoryPoint {
  date: string;
  snowDepth: number;
  snowfall: number;
  temperature: number;
  swe: number | null;
  density: number | null;
  tempMax: number | null;
  tempMin: number | null;
}

export async function getExtendedHistory(
  stationId: string = DEFAULT_SNOTEL_STATION,
  days: number = 7
): Promise<ExtendedHistoryPoint[]> {
  const today = new Date();
  const startDate = new Date(today.getTime() - days * 24 * 60 * 60 * 1000);

  const response = await fetchSnotelData(
    stationId,
    ['SNWD', 'WTEQ', 'TOBS', 'TMAX', 'TMIN'],
    formatDate(startDate),
    formatDate(today)
  );

  if (!response.length || !response[0].data.length) {
    return [];
  }

  const data = response[0].data;
  const snowDepthElement = data.find(d => d.stationElement.elementCode === 'SNWD');
  const sweElement = data.find(d => d.stationElement.elementCode === 'WTEQ');
  const tempElement = data.find(d => d.stationElement.elementCode === 'TOBS');
  const tempMaxElement = data.find(d => d.stationElement.elementCode === 'TMAX');
  const tempMinElement = data.find(d => d.stationElement.elementCode === 'TMIN');

  if (!snowDepthElement) return [];

  const history: ExtendedHistoryPoint[] = [];
  let previousDepth: number | null = null;

  for (const point of snowDepthElement.values) {
    if (point.value === null) continue;

    const swe = sweElement?.values.find(t => t.date === point.date)?.value ?? null;
    const temp = tempElement?.values.find(t => t.date === point.date)?.value ?? 32;
    const tempMax = tempMaxElement?.values.find(t => t.date === point.date)?.value ?? null;
    const tempMin = tempMinElement?.values.find(t => t.date === point.date)?.value ?? null;

    const snowfall = previousDepth !== null ? Math.max(0, point.value - previousDepth) : 0;

    // Calculate density for this day
    let density: number | null = null;
    if (swe !== null && point.value > 0) {
      density = Math.round((swe / point.value) * 100);
    }

    history.push({
      date: point.date,
      snowDepth: point.value,
      snowfall,
      temperature: temp,
      swe,
      density,
      tempMax,
      tempMin,
    });

    previousDepth = point.value;
  }

  return history;
}
