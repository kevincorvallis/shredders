'use client';

interface ConditionsData {
  snowDepth: number;
  snowfall24h: number;
  snowfall48h: number;
  snowfall7d: number;
  temperature: number;
  temperatureMax?: number;
  temperatureMin?: number;
  wind?: {
    speed: number;
    direction: string;
    gust?: number;
  };
  snowWaterEquivalent?: number;
  timestamp?: string;
}

interface ConditionsWidgetProps {
  mountain: string;
  data: ConditionsData;
}

export function ConditionsWidget({ mountain, data }: ConditionsWidgetProps) {
  const formatTime = (timestamp?: string) => {
    if (!timestamp) return 'Just now';
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  return (
    <div className="bg-gradient-to-br from-sky-500/20 to-blue-600/10 rounded-xl p-4 border border-sky-500/30">
      <div className="flex items-center justify-between mb-3">
        <div>
          <h3 className="text-white font-semibold text-sm">{mountain}</h3>
          <p className="text-gray-400 text-xs">Current Conditions</p>
        </div>
        <span className="text-gray-500 text-xs">{formatTime(data.timestamp)}</span>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {/* Snow Depth */}
        <div className="bg-black/20 rounded-lg p-2.5">
          <div className="text-gray-400 text-xs mb-1">Snow Depth</div>
          <div className="text-white text-xl font-bold">{data.snowDepth}"</div>
        </div>

        {/* Temperature */}
        <div className="bg-black/20 rounded-lg p-2.5">
          <div className="text-gray-400 text-xs mb-1">Temperature</div>
          <div className="text-white text-xl font-bold">{data.temperature}°F</div>
        </div>

        {/* 24h Snow */}
        <div className="bg-black/20 rounded-lg p-2.5">
          <div className="text-gray-400 text-xs mb-1">24h Snowfall</div>
          <div className="text-cyan-400 text-xl font-bold">{data.snowfall24h}"</div>
        </div>

        {/* 48h Snow */}
        <div className="bg-black/20 rounded-lg p-2.5">
          <div className="text-gray-400 text-xs mb-1">48h Snowfall</div>
          <div className="text-cyan-300 text-xl font-bold">{data.snowfall48h}"</div>
        </div>

        {/* Wind */}
        {data.wind && (
          <div className="bg-black/20 rounded-lg p-2.5">
            <div className="text-gray-400 text-xs mb-1">Wind</div>
            <div className="text-white text-lg font-bold">
              {data.wind.speed} mph {data.wind.direction}
            </div>
            {data.wind.gust && (
              <div className="text-gray-500 text-xs">Gusts to {data.wind.gust} mph</div>
            )}
          </div>
        )}

        {/* 7-day Snow */}
        <div className="bg-black/20 rounded-lg p-2.5">
          <div className="text-gray-400 text-xs mb-1">7-Day Snow</div>
          <div className="text-blue-400 text-xl font-bold">{data.snowfall7d}"</div>
        </div>
      </div>

      {data.snowWaterEquivalent && (
        <div className="mt-3 pt-3 border-t border-white/10">
          <div className="flex justify-between text-xs">
            <span className="text-gray-400">Snow Water Equivalent</span>
            <span className="text-gray-300">{data.snowWaterEquivalent}"</span>
          </div>
        </div>
      )}
    </div>
  );
}
