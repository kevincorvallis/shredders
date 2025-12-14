import { isHolidayWindow, isWeekend } from './trip-advice';

export type PowderDayVerdict = 'send' | 'maybe' | 'wait';

export interface PowderDayInput {
  mountainId: string;
  mountainName: string;
  forecast: Array<{
    date: string; // YYYY-MM-DD
    dayOfWeek: string;
    high: number;
    low: number;
    snowfall: number;
    precipProbability: number;
    precipType: 'snow' | 'rain' | 'mixed' | 'none';
    wind: { speed: number; gust: number };
    conditions: string;
  }>;
  currentPowderScore?: number | null;
  roads?: {
    supported: boolean;
    configured: boolean;
    passes: Array<{
      name: string;
      roadCondition?: string | null;
      weatherCondition?: string | null;
      travelAdvisoryActive?: boolean | null;
      restrictions: Array<{ direction?: string | null; text?: string | null }>;
    }>;
  } | null;
}

export interface PowderDayPlanDay {
  date: string;
  dayOfWeek: string;
  predictedPowderScore: number; // 1-10
  confidence: number; // 0-100
  verdict: PowderDayVerdict;
  bestWindow: string;
  crowdRisk: 'low' | 'medium' | 'high';
  travelNotes: string[];
  forecastSnapshot: {
    snowfall: number;
    high: number;
    low: number;
    windSpeed: number;
    precipProbability: number;
    precipType: 'snow' | 'rain' | 'mixed' | 'none';
    conditions: string;
  };
}

export interface PowderDayPlan {
  generated: string;
  mountainId: string;
  mountainName: string;
  days: PowderDayPlanDay[];
}

function clamp(n: number, min: number, max: number) {
  return Math.max(min, Math.min(max, n));
}

function scoreFromForecast(day: PowderDayInput['forecast'][number]): number {
  const snow = day.snowfall ?? 0;

  let score = 3;
  if (snow >= 14) score = 10;
  else if (snow >= 10) score = 9;
  else if (snow >= 6) score = 8;
  else if (snow >= 4) score = 7;
  else if (snow >= 2) score = 6;
  else if (snow >= 1) score = 5;
  else score = 3;

  // Temperature penalties/bonuses
  const avgTemp = (day.high + day.low) / 2;
  if (day.high >= 38 || day.precipType === 'rain') score -= 3;
  else if (day.high >= 34) score -= 2;
  else if (avgTemp <= 15) score -= 1;
  else if (avgTemp >= 22 && avgTemp <= 31) score += 1;

  // Wind penalty
  if ((day.wind?.speed ?? 0) >= 30) score -= 2;
  else if ((day.wind?.speed ?? 0) >= 20) score -= 1;

  // Precip type adjustments
  if (day.precipType === 'mixed') score -= 1;
  if (day.precipType === 'none' && snow === 0) score -= 1;

  // Probability influences (low prob means uncertain / could be less snow)
  if ((day.precipProbability ?? 0) < 30 && snow >= 4) score -= 1;

  return clamp(Math.round(score), 1, 10);
}

function confidenceForDay(dayIndex: number, precipProbability: number, precipType: string): number {
  // Near-term is more reliable; probability helps.
  const horizonBase = dayIndex === 0 ? 85 : dayIndex === 1 ? 75 : 65;
  const prob = clamp(Math.round((precipProbability ?? 0)), 0, 100);

  let conf = Math.round(horizonBase * 0.6 + prob * 0.4);
  if (precipType === 'mixed') conf -= 5;
  if (precipType === 'rain') conf -= 10;
  if (prob === 0) conf -= 5;

  return clamp(conf, 35, 95);
}

function verdictFromScore(score: number): PowderDayVerdict {
  if (score >= 8) return 'send';
  if (score >= 6) return 'maybe';
  return 'wait';
}

function bestWindowForDay(score: number, windSpeed: number, snow: number): string {
  if (score >= 8) {
    if (windSpeed >= 25) return 'Wait for wind to ease, then go (late AM / midday)';
    if (snow >= 8) return 'First chair (early)';
    return 'Early laps';
  }
  if (score >= 6) return 'Morning to early afternoon';
  return 'If you go: groomers + flexible timing';
}

function crowdRiskForDate(dateStr: string, predictedScore: number, mountainId: string): 'low' | 'medium' | 'high' {
  const date = new Date(`${dateStr}T12:00:00`);
  let score = 0;
  if (isWeekend(date)) score += 1;
  if (isHolidayWindow(date)) score += 1;
  if (predictedScore >= 8) score += 1;

  // Heuristic: closer mountains spike more.
  if (mountainId === 'snoqualmie' || mountainId === 'stevens') score += 1;

  if (score >= 3) return 'high';
  if (score >= 2) return 'medium';
  return 'low';
}

function roadContextNotes(roads: PowderDayInput['roads']): string[] {
  if (!roads?.supported) return [];
  if (!roads.configured) return ['Road/pass data not configured; check DOT sites before driving.'];
  if (!roads.passes?.[0]) return [];

  const p = roads.passes[0];
  const notes: string[] = [];
  if (p.roadCondition) notes.push(`Current pass road: ${p.roadCondition}.`);
  if (p.weatherCondition) notes.push(`Current pass weather: ${p.weatherCondition}.`);
  if (p.travelAdvisoryActive) notes.push('Travel advisory active right now.');
  const restrictionText = (p.restrictions || []).map((r) => r.text).filter(Boolean)[0];
  if (restrictionText) notes.push(`Restriction posted: ${restrictionText}`);
  return notes;
}

export function computePowderDayPlan(input: PowderDayInput): PowderDayPlan {
  const days = input.forecast.slice(0, 3).map((day, idx): PowderDayPlanDay => {
    const predictedPowderScore = scoreFromForecast(day);
    const confidence = confidenceForDay(idx, day.precipProbability, day.precipType);
    const verdict = verdictFromScore(predictedPowderScore);
    const crowdRisk = crowdRiskForDate(day.date, predictedPowderScore, input.mountainId);

    const travelNotes: string[] = [];
    if (crowdRisk === 'high') travelNotes.push('Expect parking/lines; leave early.');
    else if (crowdRisk === 'medium') travelNotes.push('Some crowding likely; avoid late morning arrival.');

    if (day.precipType === 'rain' || day.high >= 38) travelNotes.push('Warm temps: watch for rain/wet snow.');
    if ((day.wind?.speed ?? 0) >= 25) travelNotes.push('Wind may impact lifts/quality; look for sheltered terrain.');

    travelNotes.push(...roadContextNotes(input.roads));

    return {
      date: day.date,
      dayOfWeek: day.dayOfWeek,
      predictedPowderScore,
      confidence,
      verdict,
      bestWindow: bestWindowForDay(predictedPowderScore, day.wind?.speed ?? 0, day.snowfall ?? 0),
      crowdRisk,
      travelNotes: travelNotes.slice(0, 6),
      forecastSnapshot: {
        snowfall: day.snowfall,
        high: day.high,
        low: day.low,
        windSpeed: day.wind?.speed ?? 0,
        precipProbability: day.precipProbability,
        precipType: day.precipType,
        conditions: day.conditions,
      },
    };
  });

  // If day 0 exists and we have a current powder score, blend slightly.
  if (days[0] && (input.currentPowderScore ?? null) !== null) {
    const blended = clamp(Math.round((days[0].predictedPowderScore * 0.7 + (input.currentPowderScore ?? 0) * 0.3) * 10) / 10, 1, 10);
    days[0] = {
      ...days[0],
      predictedPowderScore: Math.round(blended),
    };
  }

  return {
    generated: new Date().toISOString(),
    mountainId: input.mountainId,
    mountainName: input.mountainName,
    days,
  };
}
