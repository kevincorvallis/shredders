/**
 * Model Agreement Calculator
 * Compares multiple weather models to determine forecast confidence
 * and generate human-readable confidence descriptions.
 */

import type { MultiModelData, ModelAgreement, ModelSource } from '../apis/open-meteo';

// ============================================================
// Types
// ============================================================

export type ConfidenceLevel = 'high' | 'medium' | 'low';

export interface EnhancedConfidence {
  level: ConfidenceLevel;
  percent: number;
  label: string;
  description: string;
  modelSummary: string;
  snowRange: string;
  recommendation: string;
}

export interface DailyConfidence extends EnhancedConfidence {
  date: string;
  modelAgreement: {
    agreeing: ModelSource[];
    diverging: ModelSource[];
    snowPredictions: Record<ModelSource, number>;
  };
}

export interface ForecastConfidenceReport {
  days: DailyConfidence[];
  overallConfidence: EnhancedConfidence;
  reliableThrough: string | null; // Last date with high confidence
  narrative: string;
  generatedAt: string;
}

// ============================================================
// Confidence Calculations
// ============================================================

/**
 * Convert confidence percentage to level
 */
export function percentToLevel(percent: number): ConfidenceLevel {
  if (percent >= 70) return 'high';
  if (percent >= 45) return 'medium';
  return 'low';
}

/**
 * Get confidence label based on level
 */
export function getConfidenceLabel(level: ConfidenceLevel): string {
  const labels: Record<ConfidenceLevel, string> = {
    high: 'High Confidence',
    medium: 'Medium Confidence',
    low: 'Low Confidence',
  };
  return labels[level];
}

/**
 * Get confidence description based on level and context
 */
export function getConfidenceDescription(
  level: ConfidenceLevel,
  snowSpread: number,
  dayIndex: number
): string {
  if (level === 'high') {
    if (dayIndex <= 2) {
      return 'Models are in strong agreement. Forecast is reliable.';
    }
    return 'Good model agreement. Forecast likely to verify.';
  }

  if (level === 'medium') {
    if (snowSpread > 3) {
      return `Models differ by ${Math.round(snowSpread)}" on snowfall. Expect some variation.`;
    }
    return 'Some model uncertainty. Forecast could shift by a few inches.';
  }

  // Low confidence
  if (dayIndex > 5) {
    return 'Extended range forecast - expect significant changes as we get closer.';
  }
  return `High model disagreement (${Math.round(snowSpread)}" spread). Watch for forecast updates.`;
}

/**
 * Generate model summary text
 */
function generateModelSummary(
  models: Record<ModelSource, number>,
  agreeing: ModelSource[],
  diverging: ModelSource[]
): string {
  if (diverging.length === 0) {
    return 'All models agree';
  }

  const agreementCount = agreeing.length;
  const total = Object.keys(models).length;

  if (agreementCount >= total - 1) {
    const outlier = diverging[0];
    const outlierValue = models[outlier];
    return `${outlier.toUpperCase()} is the outlier at ${outlierValue}"`;
  }

  return `Models split: ${agreeing.length}/${total} agree`;
}

/**
 * Generate snow range text
 */
function generateSnowRange(min: number, max: number): string {
  if (min === max || Math.abs(max - min) < 0.5) {
    return `${Math.round(min)}"`;
  }
  return `${Math.round(min)}-${Math.round(max)}"`;
}

/**
 * Generate recommendation based on confidence
 */
function generateRecommendation(
  level: ConfidenceLevel,
  expectedSnow: number,
  dayIndex: number
): string {
  if (level === 'high') {
    if (expectedSnow >= 6) {
      return 'Plan for powder - forecast is reliable';
    }
    if (expectedSnow >= 2) {
      return 'Fresh snow likely - conditions should improve';
    }
    return 'Dry day expected - check groomer reports';
  }

  if (level === 'medium') {
    if (expectedSnow >= 4) {
      return 'Good chance for fresh snow, but amounts uncertain';
    }
    return 'Monitor updates - forecast may change';
  }

  // Low confidence
  if (dayIndex > 5) {
    return 'Too far out - check back in a few days';
  }
  return 'High uncertainty - be flexible with plans';
}

// ============================================================
// Main Functions
// ============================================================

/**
 * Analyze model agreement for a single day
 */
export function analyzeDailyAgreement(
  agreement: ModelAgreement,
  modelData: Record<ModelSource, { date: string; snowfallSum: number }[]>,
  dayIndex: number
): DailyConfidence {
  const { date, snowfallRange, confidencePercent } = agreement;

  // Get snow predictions from each model for this day
  const snowPredictions: Record<ModelSource, number> = {} as Record<ModelSource, number>;
  for (const [model, forecasts] of Object.entries(modelData)) {
    const dayForecast = forecasts[dayIndex];
    if (dayForecast) {
      snowPredictions[model as ModelSource] = dayForecast.snowfallSum;
    }
  }

  // Determine which models agree/diverge
  const avgSnow = (snowfallRange.min + snowfallRange.max) / 2;
  const tolerance = Math.max(1, avgSnow * 0.3); // 30% tolerance or 1 inch

  const agreeing: ModelSource[] = [];
  const diverging: ModelSource[] = [];

  for (const [model, snow] of Object.entries(snowPredictions)) {
    if (Math.abs(snow - avgSnow) <= tolerance) {
      agreeing.push(model as ModelSource);
    } else {
      diverging.push(model as ModelSource);
    }
  }

  const level = percentToLevel(confidencePercent);

  return {
    date,
    level,
    percent: confidencePercent,
    label: getConfidenceLabel(level),
    description: getConfidenceDescription(level, snowfallRange.spread, dayIndex),
    modelSummary: generateModelSummary(snowPredictions, agreeing, diverging),
    snowRange: generateSnowRange(snowfallRange.min, snowfallRange.max),
    recommendation: generateRecommendation(level, avgSnow, dayIndex),
    modelAgreement: {
      agreeing,
      diverging,
      snowPredictions,
    },
  };
}

/**
 * Calculate overall forecast confidence
 */
export function calculateOverallConfidence(
  dailyConfidences: DailyConfidence[]
): EnhancedConfidence {
  if (dailyConfidences.length === 0) {
    return {
      level: 'low',
      percent: 0,
      label: 'No Data',
      description: 'No forecast data available',
      modelSummary: 'N/A',
      snowRange: '0"',
      recommendation: 'Check back later for forecast',
    };
  }

  // Weight early days more heavily
  const weights = dailyConfidences.map((_, i) => Math.max(0.5, 1 - i * 0.1));
  const totalWeight = weights.reduce((sum, w) => sum + w, 0);

  const weightedPercent = dailyConfidences.reduce(
    (sum, d, i) => sum + d.percent * weights[i],
    0
  ) / totalWeight;

  // Calculate total snow range
  let minSnow = 0;
  let maxSnow = 0;
  for (const day of dailyConfidences) {
    const { snowPredictions } = day.modelAgreement;
    minSnow += Math.min(...Object.values(snowPredictions));
    maxSnow += Math.max(...Object.values(snowPredictions));
  }

  const level = percentToLevel(weightedPercent);

  // Determine overall description
  const highConfDays = dailyConfidences.filter(d => d.level === 'high').length;
  const totalDays = dailyConfidences.length;

  let description: string;
  if (highConfDays >= totalDays * 0.7) {
    description = 'Strong model agreement across the forecast period';
  } else if (highConfDays >= totalDays * 0.4) {
    description = 'Mixed confidence - near-term forecast more reliable';
  } else {
    description = 'Significant uncertainty across the forecast period';
  }

  return {
    level,
    percent: Math.round(weightedPercent),
    label: getConfidenceLabel(level),
    description,
    modelSummary: `${highConfDays}/${totalDays} days with high confidence`,
    snowRange: generateSnowRange(minSnow, maxSnow),
    recommendation: level === 'high'
      ? 'Forecast is reliable for planning'
      : level === 'medium'
      ? 'Plan flexibly - expect some changes'
      : 'Too uncertain - monitor closely',
  };
}

/**
 * Find the last date with high confidence
 */
function findReliableThrough(dailyConfidences: DailyConfidence[]): string | null {
  for (let i = dailyConfidences.length - 1; i >= 0; i--) {
    if (dailyConfidences[i].level === 'high') {
      // Check if all prior days are also high/medium
      const priorOk = dailyConfidences.slice(0, i + 1).every(d => d.level !== 'low');
      if (priorOk) {
        return dailyConfidences[i].date;
      }
    }
  }

  // If first day is high, return it
  if (dailyConfidences[0]?.level === 'high') {
    return dailyConfidences[0].date;
  }

  return null;
}

/**
 * Generate narrative text for the confidence report
 */
function generateConfidenceNarrative(
  dailyConfidences: DailyConfidence[],
  overallConfidence: EnhancedConfidence,
  reliableThrough: string | null
): string {
  const parts: string[] = [];

  // Overall assessment
  parts.push(overallConfidence.description + '.');

  // Reliable through date
  if (reliableThrough) {
    const reliableDate = new Date(reliableThrough);
    const dayName = reliableDate.toLocaleDateString('en-US', { weekday: 'long' });
    parts.push(`Forecast reliable through ${dayName}.`);
  }

  // Snow range
  parts.push(`Expected accumulation: ${overallConfidence.snowRange}.`);

  // Any days with notable divergence
  const lowConfDays = dailyConfidences.filter(d => d.level === 'low');
  if (lowConfDays.length > 0) {
    const dayNames = lowConfDays.slice(0, 2).map(d => {
      const date = new Date(d.date);
      return date.toLocaleDateString('en-US', { weekday: 'short' });
    });
    parts.push(`Watch for changes: ${dayNames.join(', ')}.`);
  }

  return parts.join(' ');
}

/**
 * Generate a complete forecast confidence report
 */
export function generateConfidenceReport(
  multiModelData: MultiModelData
): ForecastConfidenceReport {
  const { models, agreement } = multiModelData;

  // Analyze each day
  const dailyConfidences = agreement.map((dayAgreement, index) =>
    analyzeDailyAgreement(dayAgreement, models, index)
  );

  // Calculate overall confidence
  const overallConfidence = calculateOverallConfidence(dailyConfidences);

  // Find reliable through date
  const reliableThrough = findReliableThrough(dailyConfidences);

  // Generate narrative
  const narrative = generateConfidenceNarrative(
    dailyConfidences,
    overallConfidence,
    reliableThrough
  );

  return {
    days: dailyConfidences,
    overallConfidence,
    reliableThrough,
    narrative,
    generatedAt: new Date().toISOString(),
  };
}

/**
 * Get a simple confidence badge for display
 */
export function getConfidenceBadge(level: ConfidenceLevel): {
  text: string;
  color: string;
  bgColor: string;
} {
  const badges: Record<ConfidenceLevel, { text: string; color: string; bgColor: string }> = {
    high: { text: 'High', color: '#166534', bgColor: '#dcfce7' },
    medium: { text: 'Medium', color: '#854d0e', bgColor: '#fef9c3' },
    low: { text: 'Low', color: '#991b1b', bgColor: '#fee2e2' },
  };
  return badges[level];
}
