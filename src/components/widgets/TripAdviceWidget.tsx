'use client';

type RiskLevel = 'low' | 'medium' | 'high';

type TripAdviceData = {
  generated: string;
  crowd: 'low' | 'medium' | 'high';
  trafficRisk: RiskLevel;
  roadRisk: RiskLevel;
  headline: string;
  notes: string[];
  suggestedDepartures: Array<{ from: string; suggestion: string }>;
};

interface TripAdviceWidgetProps {
  mountain: string;
  data: TripAdviceData;
}

function badge(level: RiskLevel) {
  switch (level) {
    case 'high':
      return 'text-red-300 bg-red-500/15 border-red-500/30';
    case 'medium':
      return 'text-amber-300 bg-amber-500/15 border-amber-500/30';
    default:
      return 'text-emerald-300 bg-emerald-500/15 border-emerald-500/30';
  }
}

export function TripAdviceWidget({ mountain, data }: TripAdviceWidgetProps) {
  return (
    <div className="bg-gradient-to-br from-surface-tertiary/40 to-surface-tertiary/20 rounded-xl p-4 border border-border-primary/30">
      <div className="flex items-center justify-between mb-3">
        <div>
          <h3 className="text-text-primary font-semibold text-sm">{mountain}</h3>
          <p className="text-text-tertiary text-xs">Trip &amp; Traffic</p>
        </div>
        <div className="flex gap-2">
          <span className={`text-xs px-2 py-0.5 rounded border ${badge(data.trafficRisk)}`}>Traffic: {data.trafficRisk}</span>
          <span className={`text-xs px-2 py-0.5 rounded border ${badge(data.roadRisk)}`}>Roads: {data.roadRisk}</span>
        </div>
      </div>

      <div className="text-text-secondary text-sm font-medium mb-2">{data.headline}</div>

      {data.suggestedDepartures?.length > 0 && (
        <div className="bg-black/20 rounded-lg p-2.5 mb-2">
          <div className="text-text-tertiary text-xs mb-1">Suggested timing</div>
          <div className="text-text-secondary text-sm">
            {data.suggestedDepartures.slice(0, 2).map((s, idx) => (
              <div key={idx}>
                <span className="text-text-tertiary">{s.from}: </span>
                <span>{s.suggestion}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {data.notes?.length > 0 && (
        <div className="text-xs text-text-tertiary space-y-1">
          {data.notes.slice(0, 3).map((n, idx) => (
            <div key={idx}>• {n}</div>
          ))}
        </div>
      )}
    </div>
  );
}
