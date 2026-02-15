'use client';

type PassSummary = {
  id: number;
  name: string;
  dateUpdated?: string | null;
  roadCondition?: string | null;
  weatherCondition?: string | null;
  temperatureF?: number | null;
  travelAdvisoryActive?: boolean | null;
  restrictions: Array<{ direction?: string | null; text?: string | null }>;
};

interface RoadsWidgetProps {
  mountain: string;
  data: {
    supported: boolean;
    configured: boolean;
    provider: string | null;
    passes: PassSummary[];
    message?: string;
  };
}

export function RoadsWidget({ mountain, data }: RoadsWidgetProps) {
  const pass = data.passes?.[0];

  return (
    <div className="bg-gradient-to-br from-amber-500/20 to-orange-600/10 rounded-xl p-4 border border-amber-500/30">
      <div className="flex items-center justify-between mb-3">
        <div>
          <h3 className="text-text-primary font-semibold text-sm">{mountain}</h3>
          <p className="text-text-tertiary text-xs">Road & Pass Conditions</p>
        </div>
        <span className="text-text-quaternary text-xs">{data.provider ?? ''}</span>
      </div>

      {!data.supported ? (
        <div className="text-text-tertiary text-sm">{data.message ?? 'Not supported for this mountain.'}</div>
      ) : !data.configured ? (
        <div className="text-text-tertiary text-sm">{data.message ?? 'Road data not configured.'}</div>
      ) : !pass ? (
        <div className="text-text-tertiary text-sm">No relevant pass data found.</div>
      ) : (
        <div className="space-y-2">
          <div className="bg-black/20 rounded-lg p-2.5">
            <div className="text-text-tertiary text-xs mb-1">Pass</div>
            <div className="text-text-primary text-sm font-semibold">{pass.name}</div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="bg-black/20 rounded-lg p-2.5">
              <div className="text-text-tertiary text-xs mb-1">Road</div>
              <div className="text-text-primary text-sm font-medium">{pass.roadCondition ?? 'Unknown'}</div>
            </div>
            <div className="bg-black/20 rounded-lg p-2.5">
              <div className="text-text-tertiary text-xs mb-1">Weather</div>
              <div className="text-text-primary text-sm font-medium">{pass.weatherCondition ?? 'Unknown'}</div>
            </div>
          </div>

          {(pass.temperatureF ?? null) !== null && (
            <div className="bg-black/20 rounded-lg p-2.5">
              <div className="text-text-tertiary text-xs mb-1">Pass Temp</div>
              <div className="text-text-primary text-sm font-medium">{pass.temperatureF}°F</div>
            </div>
          )}

          {pass.restrictions?.length > 0 && (
            <div className="bg-black/20 rounded-lg p-2.5">
              <div className="text-text-tertiary text-xs mb-1">Restrictions</div>
              <div className="text-text-primary text-sm">
                {pass.restrictions.slice(0, 2).map((r, idx) => (
                  <div key={idx} className="text-sm">
                    <span className="text-text-secondary">{r.direction ? `${r.direction}: ` : ''}</span>
                    <span>{r.text}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {pass.travelAdvisoryActive && (
            <div className="text-amber-300 text-xs">Travel advisory active</div>
          )}
        </div>
      )}

      <div className="mt-3 pt-3 border-t border-white/10 text-xs text-text-quaternary">
        Road data can change fast; always verify before you drive.
      </div>
    </div>
  );
}
