'use client';

import type { ForecastDay } from '@/types/mountain';

interface ForecastPreviewProps {
  forecast: ForecastDay;
  compact?: boolean;
}

const weatherIcons: Record<string, string> = {
  sun: '☀️',
  cloud: '☁️',
  snow: '❄️',
  rain: '🌧️',
  mixed: '🌨️',
  fog: '🌫️',
};

export function ForecastPreview({ forecast, compact }: ForecastPreviewProps) {
  const isPowderDay = forecast.snowfall >= 6;
  const icon = weatherIcons[forecast.icon] || '🌤️';

  if (compact) {
    return (
      <div className="flex items-center gap-2 text-sm">
        <span>{icon}</span>
        <span className="text-text-tertiary">
          {forecast.high}°/{forecast.low}°
        </span>
        {forecast.snowfall > 0 && (
          <span className="text-accent">{forecast.snowfall}" snow</span>
        )}
        {isPowderDay && (
          <span className="text-xs bg-sky-500/20 text-sky-300 px-1.5 py-0.5 rounded-full font-medium">
            Powder Day!
          </span>
        )}
      </div>
    );
  }

  return (
    <div
      className={`rounded-xl p-4 border ${
        isPowderDay
          ? 'bg-sky-500/10 border-sky-500/30'
          : 'bg-surface-secondary/50 border-border-primary'
      }`}
    >
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <span className="text-3xl">{icon}</span>
          <div>
            <p className="text-text-primary font-medium">{forecast.conditions}</p>
            <p className="text-sm text-text-tertiary">
              {forecast.high}° / {forecast.low}°F
            </p>
          </div>
        </div>
        {isPowderDay && (
          <span className="text-xs bg-accent text-text-primary px-2.5 py-1 rounded-full font-semibold">
            Powder Day!
          </span>
        )}
      </div>

      <div className="mt-3 grid grid-cols-3 gap-3">
        <div>
          <p className="text-xs text-text-quaternary">Snowfall</p>
          <p className="text-sm font-medium text-text-primary">{forecast.snowfall}"</p>
        </div>
        <div>
          <p className="text-xs text-text-quaternary">Precip</p>
          <p className="text-sm font-medium text-text-primary">{forecast.precipProbability}%</p>
        </div>
        <div>
          <p className="text-xs text-text-quaternary">Wind</p>
          <p className="text-sm font-medium text-text-primary">
            {forecast.wind.speed} mph
            {forecast.wind.gust > 30 && (
              <span className="text-amber-400"> (G{forecast.wind.gust})</span>
            )}
          </p>
        </div>
      </div>
    </div>
  );
}

interface BestPowderDayBannerProps {
  day: ForecastDay;
  onApply: () => void;
}

export function BestPowderDayBanner({ day, onApply }: BestPowderDayBannerProps) {
  const dateStr = typeof day.date === 'string' ? day.date : new Date(day.date).toISOString().split('T')[0];
  const dayOfWeek = new Date(dateStr + 'T12:00:00').toLocaleDateString('en-US', { weekday: 'long' });
  const dateFormatted = new Date(dateStr + 'T12:00:00').toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });

  return (
    <button
      type="button"
      onClick={onApply}
      className="w-full flex items-center gap-3 p-3 rounded-xl bg-gradient-to-r from-cyan-500/10 to-blue-500/10 border border-cyan-500/20 hover:border-cyan-500/40 transition-colors text-left"
    >
      <span className="text-xl">✨</span>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-text-primary">
          Best Powder Day: {dayOfWeek}, {dateFormatted}
        </p>
        <p className="text-xs text-cyan-400">
          {day.snowfall}" expected snow
        </p>
      </div>
      <span className="text-xs font-semibold text-text-primary bg-gradient-to-r from-cyan-500 to-blue-500 px-3 py-1 rounded-full shrink-0">
        Apply
      </span>
    </button>
  );
}
