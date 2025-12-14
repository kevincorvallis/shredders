type CrowdLevel = 'low' | 'medium' | 'high';
type RiskLevel = 'low' | 'medium' | 'high';

export interface TripAdviceInput {
  mountainId: string;
  mountainName: string;
  powderScore?: number | null;
  upcomingSnow48h?: number | null;
  isWeekend: boolean;
  isHolidayWindow: boolean;
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

export interface TripAdviceResult {
  generated: string;
  crowd: CrowdLevel;
  trafficRisk: RiskLevel;
  roadRisk: RiskLevel;
  headline: string;
  notes: string[];
  suggestedDepartures: Array<{ from: string; suggestion: string }>;
}

function clampRisk(level: number): RiskLevel {
  if (level >= 2) return 'high';
  if (level >= 1) return 'medium';
  return 'low';
}

function clampCrowd(level: number): CrowdLevel {
  if (level >= 2) return 'high';
  if (level >= 1) return 'medium';
  return 'low';
}

function getDefaultTrafficBias(mountainId: string): number {
  // Heuristic: closer-to-metro resorts tend to see more traffic spikes.
  switch (mountainId) {
    case 'snoqualmie':
      return 2;
    case 'stevens':
      return 2;
    case 'crystal':
      return 1;
    case 'whitepass':
      return 0;
    case 'baker':
      return 0;
    case 'meadows':
    case 'timberline':
      return 1;
    case 'bachelor':
      return 0;
    default:
      return 0;
  }
}

function scorePowderInterest(powderScore?: number | null, upcomingSnow48h?: number | null): number {
  let score = 0;
  if ((powderScore ?? 0) >= 8) score += 2;
  else if ((powderScore ?? 0) >= 6) score += 1;

  if ((upcomingSnow48h ?? 0) >= 12) score += 2;
  else if ((upcomingSnow48h ?? 0) >= 6) score += 1;

  return score;
}

function hasRestrictionText(roads?: TripAdviceInput['roads']): boolean {
  const firstPass = roads?.passes?.[0];
  if (!firstPass) return false;
  return (firstPass.restrictions || []).some((r) => (r.text ?? '').trim().length > 0);
}

function looksIcyOrSnowing(roads?: TripAdviceInput['roads']): boolean {
  const firstPass = roads?.passes?.[0];
  if (!firstPass) return false;
  const road = (firstPass.roadCondition ?? '').toLowerCase();
  const weather = (firstPass.weatherCondition ?? '').toLowerCase();
  return (
    road.includes('snow') ||
    road.includes('ice') ||
    road.includes('slush') ||
    road.includes('compact') ||
    weather.includes('snow') ||
    weather.includes('blowing') ||
    weather.includes('fog')
  );
}

export function computeTripAdvice(input: TripAdviceInput): TripAdviceResult {
  const powderInterest = scorePowderInterest(input.powderScore, input.upcomingSnow48h);

  // Crowd score
  let crowdScore = 0;
  if (input.isWeekend) crowdScore += 1;
  if (input.isHolidayWindow) crowdScore += 1;
  if (powderInterest >= 3) crowdScore += 1;
  else if (powderInterest >= 2) crowdScore += 0.5;

  // Traffic risk score
  let trafficScore = getDefaultTrafficBias(input.mountainId);
  if (input.isWeekend) trafficScore += 1;
  if (input.isHolidayWindow) trafficScore += 1;
  if (powderInterest >= 2) trafficScore += 1;

  // Road risk score (use pass conditions when available)
  let roadScore = 0;
  const roads = input.roads;
  if (roads?.supported && roads?.configured && roads.passes.length > 0) {
    if (looksIcyOrSnowing(roads)) roadScore += 1;
    if (hasRestrictionText(roads)) roadScore += 1;
    if (roads.passes[0]?.travelAdvisoryActive) roadScore += 1;
  } else {
    // fall back to weather-based risk
    if ((input.upcomingSnow48h ?? 0) >= 6) roadScore += 1;
    if ((input.upcomingSnow48h ?? 0) >= 12) roadScore += 1;
  }

  const crowd = clampCrowd(Math.floor(crowdScore));
  const trafficRisk = clampRisk(Math.floor(trafficScore / 2));
  const roadRisk = clampRisk(Math.floor(roadScore));

  const notes: string[] = [];
  if (input.isWeekend) notes.push('Weekend demand tends to spike early AM.');
  if (input.isHolidayWindow) notes.push('Holiday window: expect parking pressure + slower drives.');
  if ((input.powderScore ?? 0) >= 8) notes.push('High powder score usually means more drivers and earlier lots.');

  if (roads?.supported && roads?.configured && roads.passes?.[0]) {
    const p = roads.passes[0];
    if (p.roadCondition) notes.push(`Pass road: ${p.roadCondition}.`);
    if (p.weatherCondition) notes.push(`Pass weather: ${p.weatherCondition}.`);
    if (hasRestrictionText(roads)) notes.push('Restrictions posted — check traction/chain guidance.');
  } else if ((input.upcomingSnow48h ?? 0) >= 6) {
    notes.push('Meaningful snow in the next 48h: plan extra drive time and traction gear.');
  }

  const suggestedDepartures: Array<{ from: string; suggestion: string }> = [];
  // Keep this intentionally generic (no hard-coded ETAs).
  if (trafficRisk === 'high' || crowd === 'high') {
    suggestedDepartures.push({ from: 'Metro area', suggestion: 'Aim to be on the road before 6:00 AM to beat the rush.' });
    suggestedDepartures.push({ from: 'Closer towns', suggestion: 'Arrive before first chair; lots fill early on storm days.' });
  } else if (trafficRisk === 'medium' || crowd === 'medium') {
    suggestedDepartures.push({ from: 'Metro area', suggestion: 'Earlier is better; avoid mid-morning arrivals.' });
  } else {
    suggestedDepartures.push({ from: 'Any', suggestion: 'Traffic likely manageable; still check conditions before leaving.' });
  }

  const headlineParts: string[] = [];
  headlineParts.push(crowd === 'high' ? 'Crowds likely' : crowd === 'medium' ? 'Some crowds' : 'Lower crowds');
  headlineParts.push(roadRisk === 'high' ? 'drive carefully' : roadRisk === 'medium' ? 'watch the roads' : 'roads look reasonable');

  return {
    generated: new Date().toISOString(),
    crowd,
    trafficRisk,
    roadRisk,
    headline: headlineParts.join(' • '),
    notes,
    suggestedDepartures,
  };
}

export function isWeekend(date: Date): boolean {
  const day = date.getDay();
  return day === 0 || day === 6;
}

export function isHolidayWindow(date: Date): boolean {
  // Simple heuristic windows (US ski traffic spikes):
  // - Dec 24 through Jan 1
  // - MLK Day weekend (3rd Monday in Jan)
  // - Presidents' Day weekend (3rd Monday in Feb)
  const month = date.getMonth(); // 0-based
  const dayOfMonth = date.getDate();

  if (month === 11 && dayOfMonth >= 24) return true;
  if (month === 0 && dayOfMonth <= 1) return true;

  const year = date.getFullYear();
  const thirdMonday = (m: number) => {
    const d = new Date(year, m, 1);
    const firstMondayOffset = (8 - d.getDay()) % 7;
    return 1 + firstMondayOffset + 14;
  };

  if (month === 0) {
    const mlk = thirdMonday(0);
    return dayOfMonth >= mlk - 2 && dayOfMonth <= mlk;
  }

  if (month === 1) {
    const prez = thirdMonday(1);
    return dayOfMonth >= prez - 2 && dayOfMonth <= prez;
  }

  return false;
}
