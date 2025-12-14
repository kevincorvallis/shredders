// SNOTEL (NRCS AWDB) API Client
// Station: Wells Creek (910:WA:SNTL) - nearest to Mt. Baker
// Docs: https://wcc.sc.egov.usda.gov/awdbRestApi/

const WELLS_CREEK_STATION = '910:WA:SNTL';
const BASE_URL = 'https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1';

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
  elements: string[],
  beginDate: string,
  endDate: string
): Promise<SnotelResponse[]> {
  const url = new URL(`${BASE_URL}/data`);
  url.searchParams.set('stationTriplets', WELLS_CREEK_STATION);
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

export async function getCurrentConditions(): Promise<SnotelConditions> {
  const today = new Date();
  const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);

  const endDate = formatDate(today);
  const beginDate = formatDate(sevenDaysAgo);

  // Fetch snow depth (SNWD), snow water equivalent (WTEQ), temperature (TOBS), precipitation (PREC)
  const response = await fetchSnotelData(
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

export async function getHistoricalData(days: number = 30): Promise<SnotelHistoryPoint[]> {
  const today = new Date();
  const startDate = new Date(today.getTime() - days * 24 * 60 * 60 * 1000);

  const response = await fetchSnotelData(
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

export async function getStationMetadata() {
  const url = `${BASE_URL}/stations?stationTriplets=${WELLS_CREEK_STATION}`;
  const response = await fetch(url);
  return response.json();
}
