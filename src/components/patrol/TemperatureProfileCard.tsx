'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

interface TemperatureProfileCardProps {
  baseElevation: number;
  summitElevation: number;
  temperature: number;
  tempMax: number | null;
  tempMin: number | null;
  freezingLevel: number;
  inversionDetected: boolean;
  inversionMessage?: string;
}

export function TemperatureProfileCard({
  baseElevation,
  summitElevation,
  temperature,
  tempMax,
  tempMin,
  freezingLevel,
  inversionDetected,
  inversionMessage,
}: TemperatureProfileCardProps) {
  // Calculate approximate temps at different elevations
  const midElevation = (baseElevation + summitElevation) / 2;
  const lapseRate = 3.5; // °F per 1000ft (dry adiabatic approximation)

  const baseTemp = temperature;
  const midTemp = temperature - ((midElevation - baseElevation) / 1000) * lapseRate;
  const summitTemp = temperature - ((summitElevation - baseElevation) / 1000) * lapseRate;

  const elevations = [
    { label: 'Summit', elevation: summitElevation, temp: Math.round(summitTemp) },
    { label: 'Mid-Mtn', elevation: midElevation, temp: Math.round(midTemp) },
    { label: 'Base', elevation: baseElevation, temp: Math.round(baseTemp) },
  ];

  // Normalize for chart (0-100 scale for x position based on temp range)
  const temps = elevations.map(e => e.temp);
  const minTemp = Math.min(...temps, freezingLevel < summitElevation && freezingLevel > baseElevation ? 32 : temps[0]) - 5;
  const maxTemp = Math.max(...temps) + 5;
  const tempRange = maxTemp - minTemp;

  const getTempX = (temp: number) => ((temp - minTemp) / tempRange) * 100;
  const freezingX = getTempX(32);

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle>Temperature Profile</CardTitle>
          {inversionDetected && (
            <Badge variant="warning">Inversion</Badge>
          )}
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Temperature chart */}
          <div className="relative h-40">
            {/* Freezing line - positioned in the chart area (right side, after 72px label) */}
            <div
              className="absolute top-0 bottom-0 w-px bg-blue-500/50"
              style={{ left: `calc(72px + (100% - 72px) * ${freezingX / 100})` }}
            >
              <div className="absolute -top-1 left-0 -translate-x-1/2 text-[10px] text-blue-400 whitespace-nowrap">
                32°F
              </div>
            </div>

            {/* Elevation levels */}
            {elevations.map((level, i) => {
              const y = (i / (elevations.length - 1)) * 100;
              const x = getTempX(level.temp);

              return (
                <div
                  key={level.label}
                  className="absolute left-0 right-0 flex items-center"
                  style={{ top: `${y}%`, transform: 'translateY(-50%)' }}
                >
                  {/* Elevation label */}
                  <div className="w-[72px] flex-shrink-0 text-right pr-3">
                    <div className="text-xs font-medium text-slate-300">{level.label}</div>
                    <div className="text-[10px] text-slate-500">{level.elevation.toLocaleString()}ft</div>
                  </div>

                  {/* Temperature bar */}
                  <div className="flex-1 h-6 relative min-w-0">
                    <div
                      className={`absolute left-0 h-full rounded-r ${
                        level.temp < 25 ? 'bg-cyan-500/30' :
                        level.temp < 32 ? 'bg-blue-500/30' :
                        level.temp < 40 ? 'bg-amber-500/30' :
                        'bg-red-500/30'
                      }`}
                      style={{ width: `${x}%` }}
                    />
                    <div
                      className="absolute h-full flex items-center"
                      style={{ left: `${x}%` }}
                    >
                      <div
                        className={`w-3 h-3 rounded-full border-2 flex-shrink-0 ${
                          level.temp < 32 ? 'bg-blue-500 border-blue-300' : 'bg-amber-500 border-amber-300'
                        }`}
                      />
                      <span className="ml-2 text-sm font-medium text-slate-200 whitespace-nowrap">
                        {level.temp}°F
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Freezing level indicator */}
          <div className="flex items-center justify-between text-sm border-t border-slate-800 pt-3">
            <span className="text-slate-400">Freezing Level</span>
            <span className="font-medium text-blue-400">
              {freezingLevel < baseElevation
                ? 'Below base'
                : freezingLevel > summitElevation
                ? 'Above summit'
                : `~${freezingLevel.toLocaleString()}ft`}
            </span>
          </div>

          {/* 24hr range */}
          {tempMax !== null && tempMin !== null && (
            <div className="flex items-center justify-between text-sm">
              <span className="text-slate-400">24hr Range</span>
              <span className="font-medium">
                <span className="text-blue-400">{tempMin}°F</span>
                <span className="text-slate-500 mx-1">→</span>
                <span className="text-amber-400">{tempMax}°F</span>
              </span>
            </div>
          )}

          {/* Inversion warning */}
          {inversionDetected && inversionMessage && (
            <div className="text-xs text-amber-400 bg-amber-500/10 rounded p-2">
              {inversionMessage}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
