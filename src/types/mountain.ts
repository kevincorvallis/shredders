export interface Mountain {
  id: string;
  name: string;
  location: {
    lat: number;
    lng: number;
  };
  elevation: {
    base: number; // feet
    summit: number;
  };
  snotelStationId?: string;
}

export interface CurrentConditions {
  timestamp: Date;
  temperature: {
    base: number; // fahrenheit
    summit: number;
  };
  snowDepth: number; // inches
  snowfall24h: number;
  snowfall48h: number;
  snowfall7d: number;
  snowWaterEquivalent: number; // inches
  wind: {
    speed: number; // mph
    direction: string;
    gust: number;
  };
  visibility: 'clear' | 'partly-cloudy' | 'cloudy' | 'snowing' | 'fog';
}

export interface ForecastDay {
  date: Date;
  high: number;
  low: number;
  snowfall: number; // predicted inches
  precipProbability: number; // 0-100
  precipType: 'snow' | 'rain' | 'mixed' | 'none';
  wind: {
    speed: number;
    gust: number;
  };
  conditions: string;
  icon: 'sun' | 'cloud' | 'snow' | 'rain' | 'mixed' | 'fog';
}

export interface PowderPrediction {
  date: Date;
  score: number; // 0-100
  confidence: number; // 0-100
  factors: {
    name: string;
    contribution: number; // how much this factor contributes to the score
    description: string;
  }[];
}

export interface AISummary {
  generated: Date;
  headline: string;
  conditions: string;
  recommendation: string;
  bestTimeToGo: string;
}
