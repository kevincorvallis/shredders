export type Severity = 'low' | 'moderate' | 'considerable' | 'high' | 'extreme';

export const SEVERITY_STYLES = {
  low: {
    bg: 'bg-emerald-500/20',
    text: 'text-emerald-400',
    border: 'border-emerald-500',
    fill: 'fill-emerald-500',
    label: 'Low'
  },
  moderate: {
    bg: 'bg-amber-500/20',
    text: 'text-amber-400',
    border: 'border-amber-500',
    fill: 'fill-amber-500',
    label: 'Moderate'
  },
  considerable: {
    bg: 'bg-orange-500/20',
    text: 'text-orange-400',
    border: 'border-orange-500',
    fill: 'fill-orange-500',
    label: 'Considerable'
  },
  high: {
    bg: 'bg-red-500/20',
    text: 'text-red-400',
    border: 'border-red-500',
    fill: 'fill-red-500',
    label: 'High'
  },
  extreme: {
    bg: 'bg-rose-600/20',
    text: 'text-rose-400',
    border: 'border-rose-600',
    fill: 'fill-rose-600',
    label: 'Extreme'
  },
} as const;

export const POWDER_SCORE_COLORS = {
  excellent: { min: 8, color: 'text-emerald-400', bg: 'bg-emerald-500/20' },
  good: { min: 6, color: 'text-lime-400', bg: 'bg-lime-500/20' },
  fair: { min: 4, color: 'text-amber-400', bg: 'bg-amber-500/20' },
  poor: { min: 0, color: 'text-red-400', bg: 'bg-red-500/20' },
} as const;

export function getPowderScoreStyle(score: number) {
  if (score >= 8) return POWDER_SCORE_COLORS.excellent;
  if (score >= 6) return POWDER_SCORE_COLORS.good;
  if (score >= 4) return POWDER_SCORE_COLORS.fair;
  return POWDER_SCORE_COLORS.poor;
}

export type SnowType = 'dry-powder' | 'mixed' | 'wet-heavy';

export const SNOW_TYPE_STYLES: Record<SnowType, { label: string; color: string; bg: string; icon: string }> = {
  'dry-powder': {
    label: 'Dry Powder',
    color: 'text-cyan-400',
    bg: 'bg-cyan-500/20',
    icon: '❄️'
  },
  'mixed': {
    label: 'Mixed',
    color: 'text-amber-400',
    bg: 'bg-amber-500/20',
    icon: '🌨️'
  },
  'wet-heavy': {
    label: 'Wet/Heavy',
    color: 'text-blue-400',
    bg: 'bg-blue-500/20',
    icon: '💧'
  },
} as const;

export type StabilityRating = 'good' | 'fair' | 'poor' | 'unknown';

export const STABILITY_STYLES: Record<StabilityRating, { label: string; color: string; bg: string }> = {
  good: { label: 'Good', color: 'text-emerald-400', bg: 'bg-emerald-500/20' },
  fair: { label: 'Fair', color: 'text-amber-400', bg: 'bg-amber-500/20' },
  poor: { label: 'Poor', color: 'text-red-400', bg: 'bg-red-500/20' },
  unknown: { label: 'Unknown', color: 'text-text-tertiary', bg: 'bg-surface-tertiary/40' },
} as const;

export type Trend = 'improving' | 'stable' | 'declining';

export const TREND_STYLES: Record<Trend, { label: string; color: string; icon: string }> = {
  improving: { label: 'Improving', color: 'text-emerald-400', icon: '↑' },
  stable: { label: 'Stable', color: 'text-text-tertiary', icon: '→' },
  declining: { label: 'Declining', color: 'text-red-400', icon: '↓' },
} as const;

export const ASPECTS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'] as const;
export type Aspect = typeof ASPECTS[number];

export const ELEVATION_BANDS = ['Alpine', 'Treeline', 'Below Treeline'] as const;
export type ElevationBand = typeof ELEVATION_BANDS[number];

export function degreesToAspect(degrees: number): Aspect {
  const normalized = ((degrees % 360) + 360) % 360;
  const index = Math.round(normalized / 45) % 8;
  return ASPECTS[index];
}

export function aspectToDegrees(aspect: Aspect): number {
  const index = ASPECTS.indexOf(aspect);
  return index * 45;
}
