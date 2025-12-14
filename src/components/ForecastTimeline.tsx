'use client';

import { ForecastDay } from '@/types/mountain';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from 'recharts';

interface ForecastTimelineProps {
  forecast: ForecastDay[];
}

const weatherIcons: Record<ForecastDay['icon'], string> = {
  sun: '☀️',
  cloud: '☁️',
  snow: '❄️',
  rain: '🌧️',
  mixed: '🌨️',
  fog: '🌫️',
};

export function ForecastTimeline({ forecast }: ForecastTimelineProps) {
  const chartData = forecast.map((day) => ({
    name: day.date.toLocaleDateString('en-US', { weekday: 'short' }),
    snowfall: day.snowfall,
    high: day.high,
    low: day.low,
    icon: day.icon,
    conditions: day.conditions,
  }));

  const getBarColor = (snowfall: number) => {
    if (snowfall >= 10) return '#22c55e'; // green-500
    if (snowfall >= 6) return '#3b82f6'; // blue-500
    if (snowfall > 0) return '#93c5fd'; // blue-300
    return '#e5e7eb'; // gray-200
  };

  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-4">7-Day Forecast</h2>

      {/* Chart */}
      <div className="h-48 mb-4">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
            <XAxis
              dataKey="name"
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#6b7280', fontSize: 12 }}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#6b7280', fontSize: 12 }}
              tickFormatter={(value) => `${value}"`}
            />
            <Tooltip
              content={({ active, payload }) => {
                if (active && payload && payload.length) {
                  const data = payload[0].payload;
                  return (
                    <div className="bg-white shadow-lg rounded-lg p-3 border">
                      <p className="font-semibold">{data.name}</p>
                      <p className="text-sm text-blue-600">{data.snowfall}&quot; snow</p>
                      <p className="text-sm text-gray-500">{data.conditions}</p>
                      <p className="text-sm text-gray-500">
                        {data.high}° / {data.low}°
                      </p>
                    </div>
                  );
                }
                return null;
              }}
            />
            <Bar dataKey="snowfall" radius={[4, 4, 0, 0]}>
              {chartData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={getBarColor(entry.snowfall)} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Day cards */}
      <div className="grid grid-cols-7 gap-2">
        {forecast.map((day, index) => (
          <div
            key={index}
            className={`text-center p-2 rounded-lg ${
              index === 0 ? 'bg-blue-50 border border-blue-200' : 'bg-gray-50'
            }`}
          >
            <p className="text-xs text-gray-500">
              {day.date.toLocaleDateString('en-US', { weekday: 'short' })}
            </p>
            <p className="text-2xl my-1">{weatherIcons[day.icon]}</p>
            <p className="text-sm font-semibold text-gray-900">
              {day.snowfall > 0 ? `${day.snowfall}"` : '-'}
            </p>
            <p className="text-xs text-gray-500">
              {day.high}° / {day.low}°
            </p>
          </div>
        ))}
      </div>

      {/* Legend */}
      <div className="flex items-center justify-center gap-4 mt-4 text-xs text-gray-500">
        <div className="flex items-center gap-1">
          <span className="w-3 h-3 rounded bg-green-500" />
          <span>10&quot;+ (Epic)</span>
        </div>
        <div className="flex items-center gap-1">
          <span className="w-3 h-3 rounded bg-blue-500" />
          <span>6-10&quot; (Great)</span>
        </div>
        <div className="flex items-center gap-1">
          <span className="w-3 h-3 rounded bg-blue-300" />
          <span>1-6&quot; (Good)</span>
        </div>
      </div>
    </div>
  );
}
