'use client';

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Area,
  AreaChart,
} from 'recharts';

interface HistoryDataPoint {
  date: string;
  snowDepth: number;
  snowfall?: number;
}

interface ChartWidgetProps {
  mountain: string;
  chartType: 'snow_depth' | 'snowfall';
  days: number;
  data: HistoryDataPoint[];
}

export function ChartWidget({ mountain, chartType, days, data }: ChartWidgetProps) {
  // Format data for the chart
  const chartData = data.map((d) => ({
    ...d,
    date: new Date(d.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    fullDate: d.date,
  }));

  // Get min/max for Y axis
  const values = chartData.map((d) => chartType === 'snow_depth' ? d.snowDepth : (d.snowfall || 0));
  const minValue = Math.min(...values);
  const maxValue = Math.max(...values);
  const padding = (maxValue - minValue) * 0.1;

  const CustomTooltip = ({ active, payload, label }: { active?: boolean; payload?: Array<{ value: number; payload: { fullDate: string } }>; label?: string }) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-surface-secondary border border-border-primary rounded-lg px-3 py-2 shadow-lg">
          <p className="text-text-tertiary text-xs mb-1">{label}</p>
          <p className="text-text-primary font-semibold">
            {chartType === 'snow_depth' ? `${payload[0].value}" depth` : `${payload[0].value}" snowfall`}
          </p>
        </div>
      );
    }
    return null;
  };

  // Calculate change
  const firstValue = chartData[0]?.[chartType === 'snow_depth' ? 'snowDepth' : 'snowfall'] || 0;
  const lastValue = chartData[chartData.length - 1]?.[chartType === 'snow_depth' ? 'snowDepth' : 'snowfall'] || 0;
  const change = lastValue - firstValue;

  return (
    <div className="bg-gradient-to-br from-violet-500/20 to-purple-600/10 rounded-xl p-4 border border-violet-500/30">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="text-text-primary font-semibold text-sm">{mountain}</h3>
          <p className="text-text-tertiary text-xs">
            {chartType === 'snow_depth' ? 'Snow Depth' : 'Daily Snowfall'} - {days} Days
          </p>
        </div>
        <div className="text-right">
          <div className="text-text-primary text-lg font-bold">{lastValue}"</div>
          <div className={`text-xs ${change >= 0 ? 'text-green-400' : 'text-red-400'}`}>
            {change >= 0 ? '+' : ''}{change}" from start
          </div>
        </div>
      </div>

      <div className="h-48">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={chartData} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
            <defs>
              <linearGradient id="snowGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#06b6d4" stopOpacity={0.4} />
                <stop offset="95%" stopColor="#06b6d4" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.3} />
            <XAxis
              dataKey="date"
              tick={{ fill: '#9ca3af', fontSize: 10 }}
              axisLine={{ stroke: '#4b5563' }}
              tickLine={false}
              interval="preserveStartEnd"
            />
            <YAxis
              domain={[Math.max(0, minValue - padding), maxValue + padding]}
              tick={{ fill: '#9ca3af', fontSize: 10 }}
              axisLine={{ stroke: '#4b5563' }}
              tickLine={false}
              tickFormatter={(val) => `${val}"`}
            />
            <Tooltip content={<CustomTooltip />} />
            <Area
              type="monotone"
              dataKey={chartType === 'snow_depth' ? 'snowDepth' : 'snowfall'}
              stroke="#06b6d4"
              strokeWidth={2}
              fill="url(#snowGradient)"
              dot={false}
              activeDot={{ r: 4, fill: '#06b6d4', stroke: '#fff', strokeWidth: 2 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-2 mt-3 pt-3 border-t border-white/10">
        <div className="text-center">
          <div className="text-text-quaternary text-xs">Min</div>
          <div className="text-text-primary text-sm font-medium">{Math.round(minValue)}"</div>
        </div>
        <div className="text-center">
          <div className="text-text-quaternary text-xs">Max</div>
          <div className="text-text-primary text-sm font-medium">{Math.round(maxValue)}"</div>
        </div>
        <div className="text-center">
          <div className="text-text-quaternary text-xs">Avg</div>
          <div className="text-text-primary text-sm font-medium">
            {Math.round(values.reduce((a, b) => a + b, 0) / values.length)}"
          </div>
        </div>
      </div>
    </div>
  );
}
