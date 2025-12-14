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
            <div className="text-xs text-slate-400">Current snow type</div>
          </div>
        </div>

        {/* Key metrics */}
        <div className="grid grid-cols-3 gap-3 text-center">
          <div className="bg-slate-800/50 rounded p-2">
            <div className="text-lg font-bold text-slate-200">
              {snowfall24h > 0 ? `${snowfall24h}"` : '--'}
            </div>
            <div className="text-[10px] text-slate-500 uppercase">24hr Snow</div>
          </div>
          <div className="bg-slate-800/50 rounded p-2">
            <div className="text-lg font-bold text-slate-200">
              {density !== null ? `${density}%` : '--'}
            </div>
            <div className="text-[10px] text-slate-500 uppercase">Density</div>
          </div>
          <div className="bg-slate-800/50 rounded p-2">
            <div className="text-lg font-bold text-slate-200">
              {settlingRate !== null ? `${settlingRate.toFixed(1)}"` : '--'}
            </div>
            <div className="text-[10px] text-slate-500 uppercase">Settling/Day</div>
          </div>
        </div>

        {/* Density progress bar */}
        {density !== null && (
          <div className="space-y-1">
            <div className="flex justify-between text-xs">
              <span className="text-slate-400">Snow Density</span>
              <span className="text-slate-300">{density}%</span>
            </div>
            <Progress
              value={density}
              className="h-2"
              indicatorClassName={
                density < 25 ? 'bg-cyan-500' :
                density < 40 ? 'bg-blue-500' :
                'bg-slate-400'
              }
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>Light/Dry</span>
              <span>Dense/Settled</span>
            </div>
          </div>
        )}

        {/* Stability factors */}
        <div className="space-y-2">
          <div className="text-xs font-medium text-slate-400 uppercase">Factors</div>
          {factors.map((factor, i) => (
            <div
              key={i}
              className="flex items-start gap-2 text-sm"
            >
              <span className={
                factor.status === 'positive' ? 'text-emerald-400' :
                factor.status === 'negative' ? 'text-red-400' :
                'text-slate-400'
              }>
                {factor.status === 'positive' ? '✓' : factor.status === 'negative' ? '✗' : '•'}
              </span>
              <div>
                <span className="font-medium text-slate-300">{factor.name}:</span>{' '}
                <span className="text-slate-400">{factor.description}</span>
              </div>
            </div>
          ))}
        </div>

        {/* Summary message */}
        <div className="text-xs text-slate-400 border-t border-slate-800 pt-3">
          {message}
        </div>
      </CardContent>
    </Card>
  );
}
