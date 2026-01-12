/**
 * Test fixtures and mock data generators
 * Used across all test files for consistent, realistic test data
 */

import type { MountainConfig } from '@shredders/shared/mountains';

/**
 * Generate a mock mountain configuration
 */
export const mockMountain = (overrides?: Partial<MountainConfig>): MountainConfig => ({
  id: 'baker',
  name: 'Mt. Baker',
  shortName: 'Baker',
  location: {
    lat: 48.8566,
    lng: -121.6654,
  },
  elevation: {
    base: 3500,
    summit: 5089,
  },
  region: 'washington',
  snotel: {
    stationId: '1174',
    stationName: 'MT BAKER',
  },
  noaa: {
    gridOffice: 'SEW',
    gridX: 142,
    gridY: 108,
  },
  webcams: [
    {
      id: 'baker-panorama',
      name: 'Panorama Dome',
      url: 'https://www.mtbaker.us/webcams/',
      refreshUrl: 'https://www.mtbaker.us/webcams/',
    },
  ],
  color: '#1E88E5',
  website: 'https://www.mtbaker.us',
  logo: null,
  passType: 'independent',
  ...overrides,
});

/**
 * Generate mock conditions data
 */
export const mockConditions = (overrides?: Partial<any>) => ({
  timestamp: new Date().toISOString(),
  mountain: {
    id: 'baker',
    name: 'Mt. Baker',
    elevation: {
      base: 3500,
      summit: 5089,
    },
  },
  temperature: {
    base: 28,
    summit: 18,
  },
  snowDepth: 156,
  snowfall24h: 8,
  snowfall48h: 14,
  snowfall7d: 24,
  snowWaterEquivalent: 42.5,
  freezingLevel: 2800,
  wind: {
    speed: 12,
    direction: 'NW',
    gust: 18,
  },
  visibility: 'clear',
  ...overrides,
});

/**
 * Generate mock forecast data
 */
export const mockForecast = (overrides?: Partial<any>) => ({
  mountain: 'baker',
  forecast: [
    {
      date: new Date().toISOString().split('T')[0],
      tempHigh: 32,
      tempLow: 24,
      snow: 6,
      windSpeed: 15,
      windDirection: 'NW',
      conditions: 'Snow',
    },
    {
      date: new Date(Date.now() + 86400000).toISOString().split('T')[0],
      tempHigh: 30,
      tempLow: 22,
      snow: 4,
      windSpeed: 10,
      windDirection: 'W',
      conditions: 'Partly Cloudy',
    },
  ],
  ...overrides,
});

/**
 * Generate mock powder score
 */
export const mockPowderScore = (overrides?: Partial<any>) => ({
  mountainId: 'baker',
  score: 8.5,
  breakdown: {
    freshSnow: 9,
    recentSnow: 8,
    temperature: 9,
    wind: 7,
    upcomingSnow: 8,
    snowLine: 9,
    visibility: 9,
    conditions: 8,
  },
  timestamp: new Date().toISOString(),
  ...overrides,
});

/**
 * Generate mock mountain status (from scraper)
 */
export const mockMountainStatus = (overrides?: Partial<any>) => ({
  mountainId: 'baker',
  isOpen: true,
  liftsOpen: 8,
  liftsTotal: 10,
  runsOpen: 98,
  runsTotal: 100,
  lastUpdated: new Date().toISOString(),
  conditions: 'Powder',
  ...overrides,
});

/**
 * Generate multiple mock mountains for list endpoints
 */
export const mockMountainsList = (count: number = 5): MountainConfig[] => {
  const mountains: Array<Partial<MountainConfig> & { id: string; name: string }> = [
    { id: 'baker', name: 'Mt. Baker', region: 'washington' },
    { id: 'stevens', name: 'Stevens Pass', region: 'washington' },
    { id: 'crystal', name: 'Crystal Mountain', region: 'washington' },
    { id: 'bachelor', name: 'Mt. Bachelor', region: 'oregon' },
    { id: 'meadows', name: 'Mt. Hood Meadows', region: 'oregon' },
    { id: 'schweitzer', name: 'Schweitzer', region: 'idaho' },
    { id: 'whistler', name: 'Whistler Blackcomb', region: 'canada' },
  ];

  return mountains.slice(0, count).map((m) => mockMountain(m));
};

/**
 * Generate mock SNOTEL API response
 */
export const mockSnotelResponse = (overrides?: Partial<any>) => ({
  stationId: '1174',
  stationName: 'MT BAKER',
  elevation: 4200,
  data: [
    {
      date: new Date().toISOString().split('T')[0],
      snowDepth: 156,
      snowWaterEquivalent: 42.5,
      temperature: 24,
      precipitation: 0.8,
    },
  ],
  ...overrides,
});

/**
 * Generate mock NOAA API response
 */
export const mockNoaaResponse = (overrides?: Partial<any>) => ({
  properties: {
    periods: [
      {
        number: 1,
        name: 'Today',
        temperature: 32,
        windSpeed: '15 mph',
        windDirection: 'NW',
        shortForecast: 'Snow',
        detailedForecast: 'Snow. High near 32. Northwest wind around 15 mph.',
      },
      {
        number: 2,
        name: 'Tonight',
        temperature: 22,
        windSpeed: '10 mph',
        windDirection: 'W',
        shortForecast: 'Partly Cloudy',
        detailedForecast: 'Partly cloudy. Low around 22.',
      },
    ],
  },
  ...overrides,
});

/**
 * Generate mock user check-in
 */
export const mockCheckIn = (overrides?: Partial<any>) => ({
  id: 'checkin-123',
  userId: 'user-456',
  mountainId: 'baker',
  rating: 5,
  snowQuality: 'powder',
  crowdLevel: 'moderate',
  tripReport: 'Amazing powder day! Deep snow everywhere.',
  isPublic: true,
  createdAt: new Date().toISOString(),
  ...overrides,
});

/**
 * Mock HTML snapshot for scraper testing
 * Real HTML would be saved as fixtures, this is a minimal example
 */
export const mockBakerHTML = `
<!DOCTYPE html>
<html>
<head><title>Mt. Baker Ski Area</title></head>
<body>
  <div class="mountain-status">
    <div class="lifts-open">8</div>
    <div class="lifts-total">10</div>
    <div class="runs-open">98</div>
    <div class="runs-total">100</div>
    <div class="conditions">Powder</div>
  </div>
</body>
</html>
`;
