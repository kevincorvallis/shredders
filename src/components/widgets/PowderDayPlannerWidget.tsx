'use client';

type PlanDay = {
  date: string;
  dayOfWeek: string;
  predictedPowderScore: number;
  confidence: number;
  verdict: 'send' | 'maybe' | 'wait';
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
};

interface PowderDayPlannerWidgetProps {
  mountain: string;
  data: {
    generated: string;
    days: PlanDay[];
  };
}

function verdictStyle(verdict: PlanDay['verdict']) {
  switch (verdict) {
    case 'send':
      return 'text-emerald-300 bg-emerald-500/15 border-emerald-500/30';
    case 'maybe':
      return 'text-amber-300 bg-amber-500/15 border-amber-500/30';
    default:
      return 'text-gray-300 bg-slate-500/15 border-slate-500/30';
  }
}

export function PowderDayPlannerWidget({ mountain, data }: PowderDayPlannerWidgetProps) {
  const days = data.days || [];

  return (
    <div className="bg-gradient-to-br from-violet-500/20 to-purple-600/10 rounded-xl p-4 border border-violet-500/30">
      <div className="flex items-center justify-between mb-3">
        <div>
          <h3 className="text-white font-semibold text-sm">{mountain}</h3>
          <p className="text-gray-400 text-xs">Powder Day Planner (next 3 days)</p>
        </div>
      </div>

      {days.length === 0 ? (
        <div className="text-gray-400 text-sm">No prediction data available.</div>
      ) : (
        <div className="space-y-3">
          {days.slice(0, 3).map((d, idx) => (
            <div key={idx} className="bg-black/20 rounded-lg p-3">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="text-white text-sm font-semibold">
                    {idx === 0 ? 'Today' : d.dayOfWeek} • {d.date}
                  </div>
                  <div className="text-gray-400 text-xs">{d.forecastSnapshot.conditions}</div>
                </div>
                <div className="text-right">
                  <div className="text-white text-lg font-bold">{d.predictedPowderScore}/10</div>
                  <div className="text-gray-400 text-xs">Conf {d.confidence}%</div>
                </div>
              </div>

              <div className="mt-2 flex flex-wrap items-center gap-2">
                <span className={`text-xs px-2 py-0.5 rounded border ${verdictStyle(d.verdict)}`}>{d.verdict.toUpperCase()}</span>
                <span className="text-xs px-2 py-0.5 rounded border border-slate-600 text-gray-200 bg-slate-700/40">
                  Crowd: {d.crowdRisk}
                </span>
                <span className="text-xs text-gray-400">
                  {d.forecastSnapshot.snowfall}&quot; snow • {d.forecastSnapshot.high}°/{d.forecastSnapshot.low}° • {d.forecastSnapshot.windSpeed} mph
                </span>
              </div>

              <div className="mt-2 text-sm text-gray-200">
                <span className="text-gray-400">Best window: </span>
                <span>{d.bestWindow}</span>
              </div>

              {d.travelNotes?.length > 0 && (
                <div className="mt-2 text-xs text-gray-400 space-y-1">
                  {d.travelNotes.slice(0, 3).map((n, i) => (
                    <div key={i}>• {n}</div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
