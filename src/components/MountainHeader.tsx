'use client';

import { Mountain, CurrentConditions } from '@/types/mountain';

interface MountainHeaderProps {
  mountain: Mountain;
  conditions: CurrentConditions;
}

const visibilityIcons: Record<CurrentConditions['visibility'], string> = {
  clear: '☀️',
  'partly-cloudy': '⛅',
  cloudy: '☁️',
  snowing: '🌨️',
  fog: '🌫️',
};

export function MountainHeader({ mountain, conditions }: MountainHeaderProps) {
  const lastUpdated = new Date(conditions.timestamp).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });

  return (
    <div className="bg-gradient-to-r from-blue-900 to-indigo-900 text-white rounded-xl p-6 shadow-lg">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-3xl font-bold">{mountain.name}</h1>
          <p className="text-blue-200 text-sm mt-1">
            {mountain.elevation.base.toLocaleString()}&apos; - {mountain.elevation.summit.toLocaleString()}&apos; elevation
          </p>
        </div>
        <div className="text-right">
          <div className="text-5xl">
            {visibilityIcons[conditions.visibility]}
          </div>
          <p className="text-blue-200 text-xs mt-1">Updated {lastUpdated}</p>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4 mt-6">
        <div className="bg-white/10 rounded-lg p-4">
          <p className="text-blue-200 text-sm">Summit</p>
          <p className="text-2xl font-bold">{conditions.temperature.summit}°F</p>
        </div>
        <div className="bg-white/10 rounded-lg p-4">
          <p className="text-blue-200 text-sm">Base</p>
          <p className="text-2xl font-bold">{conditions.temperature.base}°F</p>
        </div>
        <div className="bg-white/10 rounded-lg p-4">
          <p className="text-blue-200 text-sm">Wind</p>
          <p className="text-2xl font-bold">
            {conditions.wind.speed}
            <span className="text-sm font-normal"> mph {conditions.wind.direction}</span>
          </p>
        </div>
      </div>
    </div>
  );
}
