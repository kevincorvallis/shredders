'use client';

import { Card, CardContent } from '@/components/ui/card';
import { Wind, Droplets, Eye, Thermometer, Snowflake, CloudSnow, TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface MetricCardProps {
  label: string;
  value: string | number;
  unit?: string;
  icon: React.ReactNode;
  trend?: 'up' | 'down' | 'stable';
  status?: 'good' | 'warning' | 'danger';
  subValue?: string;
}

function MetricCard({ label, value, unit, icon, trend, status, subValue }: MetricCardProps) {
  const statusColors = {
    good: 'text-emerald-400',
    warning: 'text-amber-400',
    danger: 'text-red-400',
  };

  const TrendIcon = trend === 'up' ? TrendingUp : trend === 'down' ? TrendingDown : Minus;

  return (
    <Card className="bg-slate-900/30">
      <CardContent className="p-3">
        <div className="flex items-start justify-between">
          <div className="text-slate-500">{icon}</div>
          {trend && (
            <TrendIcon className={`w-3 h-3 ${
              trend === 'up' ? 'text-emerald-400' :
              trend === 'down' ? 'text-red-400' :
              'text-slate-400'
            }`} />
          )}
        </div>
        <div className="mt-2">
          <div className={`text-2xl font-bold ${status ? statusColors[status] : 'text-slate-100'}`}>
            {value}
            {unit && <span className="text-sm font-normal text-slate-400 ml-1">{unit}</span>}
          </div>
          <div className="text-xs text-slate-500 uppercase tracking-wide mt-0.5">{label}</div>
          {subValue && (
            <div className="text-xs text-slate-400 mt-1">{subValue}</div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

interface MetricsGridProps {
  windChill: number;
  humidity: number | null;
  visibility: number | null;
  visibilityCategory: string;
  skyCover: number | null;
  precipProbability: number | null;
  snowDepth: number;
  snowfall24h: number;
  snowfall7d: number;
  temperature: number;
}

export function MetricsGrid({
  windChill,
  humidity,
  visibility,
  visibilityCategory,
  skyCover,
  precipProbability,
  snowDepth,
  snowfall24h,
  snowfall7d,
  temperature,
}: MetricsGridProps) {
  // Determine wind chill status
  const windChillStatus = windChill < -10 ? 'danger' : windChill < 10 ? 'warning' : 'good';

  // Determine visibility status
  const visibilityStatus =
    visibilityCategory === 'very-poor' || visibilityCategory === 'poor' ? 'danger' :
    visibilityCategory === 'moderate' ? 'warning' : 'good';

  // Determine humidity status (high humidity can mean wet snow)
  const humidityStatus = humidity !== null && humidity > 85 ? 'warning' : 'good';

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
      <MetricCard
        label="Wind Chill"
        value={windChill}
        unit="°F"
        icon={<Thermometer className="w-4 h-4" />}
        status={windChillStatus}
        subValue={`Actual: ${temperature}°F`}
      />

      <MetricCard
        label="Humidity"
        value={humidity ?? '--'}
        unit={humidity !== null ? '%' : ''}
        icon={<Droplets className="w-4 h-4" />}
        status={humidityStatus}
      />

      <MetricCard
        label="Visibility"
        value={visibility ?? '--'}
        unit={visibility !== null ? 'mi' : ''}
        icon={<Eye className="w-4 h-4" />}
        status={visibilityStatus}
        subValue={visibilityCategory.replace('-', ' ')}
      />

      <MetricCard
        label="Sky Cover"
        value={skyCover ?? '--'}
        unit={skyCover !== null ? '%' : ''}
        icon={<CloudSnow className="w-4 h-4" />}
      />

      <MetricCard
        label="Precip Chance"
        value={precipProbability ?? '--'}
        unit={precipProbability !== null ? '%' : ''}
        icon={<Snowflake className="w-4 h-4" />}
        status={precipProbability !== null && precipProbability > 50 ? 'warning' : 'good'}
      />

      <MetricCard
        label="Snow Depth"
        value={snowDepth}
        unit="in"
        icon={<Snowflake className="w-4 h-4" />}
        trend={snowfall24h > 0 ? 'up' : 'stable'}
      />

      <MetricCard
        label="24hr Snow"
        value={snowfall24h}
        unit="in"
        icon={<Snowflake className="w-4 h-4" />}
        status={snowfall24h > 12 ? 'warning' : 'good'}
      />

      <MetricCard
        label="7-Day Snow"
        value={snowfall7d}
        unit="in"
        icon={<Snowflake className="w-4 h-4" />}
        trend={snowfall7d > 20 ? 'up' : 'stable'}
      />
    </div>
  );
}
