'use client';

interface ForecastDay {
  dayOfWeek: string;
  date: string;
  high: number;
  low: number;
  snowfall: number;
  conditions: string;
  wind?: {
    speed: number;
    direction: string;
  };
  precipChance?: number;
}

interface ForecastWidgetProps {
  mountain: string;
  data: ForecastDay[];
}

export function ForecastWidget({ mountain, data }: ForecastWidgetProps) {
  const getWeatherIcon = (conditions: string, snowfall: number) => {
    const c = conditions.toLowerCase();
    if (snowfall >= 6) return '🌨️';
    if (snowfall > 0 || c.includes('snow')) return '❄️';
    if (c.includes('rain')) return '🌧️';
    if (c.includes('cloud') || c.includes('overcast')) return '☁️';
    if (c.includes('partly')) return '⛅';
    if (c.includes('sun') || c.includes('clear')) return '☀️';
    return '🌤️';
  };

  const getSnowHighlight = (snowfall: number) => {
    if (snowfall >= 12) return 'bg-cyan-500/30 text-cyan-300';
    if (snowfall >= 6) return 'bg-cyan-500/20 text-cyan-400';
    if (snowfall > 0) return 'text-cyan-500';
    return 'text-text-quaternary';
  };

  return (
    <div className="bg-gradient-to-br from-indigo-500/20 to-purple-600/10 rounded-xl p-4 border border-indigo-500/30">
      <div className="flex items-center justify-between mb-3">
        <div>
          <h3 className="text-text-primary font-semibold text-sm">{mountain}</h3>
          <p className="text-text-tertiary text-xs">{data.length}-Day Forecast</p>
        </div>
      </div>

      <div className="space-y-2">
        {data.map((day, idx) => (
          <div
            key={idx}
            className={`flex items-center justify-between py-2 ${idx > 0 ? 'border-t border-white/5' : ''}`}
          >
            <div className="flex items-center gap-3 flex-1">
              <span className="text-2xl">{getWeatherIcon(day.conditions, day.snowfall)}</span>
              <div>
                <div className="text-text-primary text-sm font-medium">
                  {idx === 0 ? 'Today' : idx === 1 ? 'Tomorrow' : day.dayOfWeek}
                </div>
                <div className="text-text-quaternary text-xs truncate max-w-[120px]">
                  {day.conditions}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-4">
              {/* Temperature */}
              <div className="text-right">
                <span className="text-text-primary text-sm">{day.high}°</span>
                <span className="text-text-quaternary text-sm"> / {day.low}°</span>
              </div>

              {/* Snowfall */}
              <div className={`text-right min-w-[45px] px-1.5 py-0.5 rounded text-sm font-medium ${getSnowHighlight(day.snowfall)}`}>
                {day.snowfall > 0 ? `${day.snowfall}"` : '—'}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Legend */}
      <div className="mt-3 pt-3 border-t border-white/10 flex items-center justify-between text-xs text-text-quaternary">
        <span>Temps in °F</span>
        <span>Snowfall in inches</span>
      </div>
    </div>
  );
}
