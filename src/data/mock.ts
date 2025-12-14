import { Mountain, CurrentConditions, ForecastDay, PowderPrediction, AISummary } from '@/types/mountain';

export const mtBaker: Mountain = {
  id: 'mt-baker',
  name: 'Mt. Baker',
  location: {
    lat: 48.857,
    lng: -121.669,
  },
  elevation: {
    base: 3500,
    summit: 5089,
  },
  snotelStationId: '910', // Wells Creek
};

export const mockCurrentConditions: CurrentConditions = {
  timestamp: new Date(),
  temperature: {
    base: 28,
    summit: 18,
  },
  snowDepth: 142,
  snowfall24h: 8,
  snowfall48h: 14,
  snowfall7d: 32,
  snowWaterEquivalent: 58.4,
  wind: {
    speed: 15,
    direction: 'SW',
    gust: 28,
  },
  visibility: 'snowing',
};

const today = new Date();

export const mockForecast: ForecastDay[] = [
  {
    date: today,
    high: 30,
    low: 22,
    snowfall: 6,
    precipProbability: 90,
    precipType: 'snow',
    wind: { speed: 12, gust: 25 },
    conditions: 'Heavy snow',
    icon: 'snow',
  },
  {
    date: new Date(today.getTime() + 86400000),
    high: 28,
    low: 20,
    snowfall: 10,
    precipProbability: 95,
    precipType: 'snow',
    wind: { speed: 18, gust: 35 },
    conditions: 'Heavy snow, windy',
    icon: 'snow',
  },
  {
    date: new Date(today.getTime() + 86400000 * 2),
    high: 32,
    low: 24,
    snowfall: 4,
    precipProbability: 70,
    precipType: 'snow',
    wind: { speed: 8, gust: 15 },
    conditions: 'Light snow',
    icon: 'snow',
  },
  {
    date: new Date(today.getTime() + 86400000 * 3),
    high: 35,
    low: 28,
    snowfall: 0,
    precipProbability: 20,
    precipType: 'none',
    wind: { speed: 5, gust: 10 },
    conditions: 'Partly cloudy',
    icon: 'cloud',
  },
  {
    date: new Date(today.getTime() + 86400000 * 4),
    high: 34,
    low: 26,
    snowfall: 2,
    precipProbability: 45,
    precipType: 'snow',
    wind: { speed: 10, gust: 18 },
    conditions: 'Scattered flurries',
    icon: 'cloud',
  },
  {
    date: new Date(today.getTime() + 86400000 * 5),
    high: 30,
    low: 22,
    snowfall: 8,
    precipProbability: 85,
    precipType: 'snow',
    wind: { speed: 14, gust: 28 },
    conditions: 'Snow showers',
    icon: 'snow',
  },
  {
    date: new Date(today.getTime() + 86400000 * 6),
    high: 28,
    low: 20,
    snowfall: 12,
    precipProbability: 95,
    precipType: 'snow',
    wind: { speed: 20, gust: 40 },
    conditions: 'Heavy snow',
    icon: 'snow',
  },
];

export const mockPowderPrediction: PowderPrediction = {
  date: new Date(today.getTime() + 86400000), // Tomorrow
  score: 87,
  confidence: 82,
  factors: [
    {
      name: 'Fresh Snow',
      contribution: 35,
      description: '10" expected overnight',
    },
    {
      name: 'Temperature',
      contribution: 25,
      description: 'Cold temps will preserve powder',
    },
    {
      name: 'Base Depth',
      contribution: 15,
      description: 'Excellent 142" base',
    },
    {
      name: 'Wind',
      contribution: -8,
      description: 'Moderate winds may cause drifting',
    },
  ],
};

export const mockAISummary: AISummary = {
  generated: new Date(),
  headline: 'Powder Alert: 10"+ Expected Tonight',
  conditions: 'A strong Pacific storm is moving in, bringing heavy snowfall to Mt. Baker through tomorrow morning. Current snow depth is 142" with excellent coverage across all terrain.',
  recommendation: 'Tomorrow is shaping up to be an exceptional powder day. Arrive early to catch first tracks on the fresh snow before it gets tracked out.',
  bestTimeToGo: 'First chair tomorrow morning (9 AM) for the best conditions',
};
