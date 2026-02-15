'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import {
  STABILITY_STYLES,
  TREND_STYLES,
  SNOW_TYPE_STYLES,
  type StabilityRating,
  type Trend,
  type SnowType,
} from '@/lib/design-tokens';

interface StabilityFactor {
  name: string;
  status: 'positive' | 'negative' | 'neutral';
  description: string;
}

interface SnowStabilityCardProps {
  rating: StabilityRating;
  trend: Trend;
  factors: StabilityFactor[];
  snowType: SnowType;
  density: number | null;
  settlingRate: number | null;
  snowfall24h: number;
  message: string;
}

export function SnowStabilityCard({
  rating,
  trend,
  factors,
  snowType,
  density,
  settlingRate,
  snowfall24h,
  message,
}: SnowStabilityCardProps) {
  const stabilityStyle = STABILITY_STYLES[rating];
  const trendStyle = TREND_STYLES[trend];
  const snowTypeStyle = SNOW_TYPE_STYLES[snowType];

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle>Snow Stability</CardTitle>
          <div className="flex items-center gap-2">
            <Badge className={`${stabilityStyle.bg} ${stabilityStyle.color}`}>
              {stabilityStyle.label}
            </Badge>
            <span className={`text-sm ${trendStyle.color}`}>
              {trendStyle.icon}
            </span>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Snow type indicator */}
        <div className={`flex items-center gap-2 p-2 rounded ${snowTypeStyle.bg}`}>
          <span className="text-lg">{snowTypeStyle.icon}</span>
          <div>
            <div className={`text-sm font-medium ${snowTypeStyle.color}`}>
              {snowTypeStyle.label}
            </div>
            <div className="text-xs text-text-tertiary">Current snow type</div>
          </div>
        </div>

        {/* Key metrics */}
        <div className="grid grid-cols-3 gap-3 text-center">
          <div className="bg-surface-secondary/50 rounded p-2">
            <div className="text-lg font-bold text-text-primary">
              {snowfall24h > 0 ? `${snowfall24h}"` : '--'}
            </div>
            <div className="text-[10px] text-text-quaternary uppercase">24hr Snow</div>
          </div>
          <div className="bg-surface-secondary/50 rounded p-2">
            <div className="text-lg font-bold text-text-primary">
              {density !== null ? `${density}%` : '--'}
            </div>
            <div className="text-[10px] text-text-quaternary uppercase">Density</div>
          </div>
          <div className="bg-surface-secondary/50 rounded p-2">
            <div className="text-lg font-bold text-text-primary">
              {settlingRate !== null ? `${settlingRate.toFixed(1)}"` : '--'}
            </div>
            <div className="text-[10px] text-text-quaternary uppercase">Settling/Day</div>
          </div>
        </div>

        {/* Density progress bar */}
        {density !== null && (
          <div className="space-y-1">
            <div className="flex justify-between text-xs">
              <span className="text-text-tertiary">Snow Density</span>
              <span className="text-text-secondary">{density}%</span>
            </div>
            <Progress
              value={density}
              className="h-2"
              indicatorClassName={
                density < 25 ? 'bg-cyan-500' :
                density < 40 ? 'bg-blue-500' :
                'bg-text-tertiary'
              }
            />
            <div className="flex justify-between text-[10px] text-text-quaternary">
              <span>Light/Dry</span>
              <span>Dense/Settled</span>
            </div>
          </div>
        )}

        {/* Stability factors */}
        <div className="space-y-2">
          <div className="text-xs font-medium text-text-tertiary uppercase">Factors</div>
          {factors.map((factor, i) => (
            <div
              key={i}
              className="flex items-start gap-2 text-sm"
            >
              <span className={
                factor.status === 'positive' ? 'text-emerald-400' :
                factor.status === 'negative' ? 'text-red-400' :
                'text-text-tertiary'
              }>
                {factor.status === 'positive' ? '✓' : factor.status === 'negative' ? '✗' : '•'}
              </span>
              <div>
                <span className="font-medium text-text-secondary">{factor.name}:</span>{' '}
                <span className="text-text-tertiary">{factor.description}</span>
              </div>
            </div>
          ))}
        </div>

        {/* Summary message */}
        <div className="text-xs text-text-tertiary border-t border-border-secondary pt-3">
          {message}
        </div>
      </CardContent>
    </Card>
  );
}
