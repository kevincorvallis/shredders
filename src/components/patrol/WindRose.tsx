'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ASPECTS, type Aspect } from '@/lib/design-tokens';
import type { WindDataPoint } from '@/lib/apis/noaa';

interface WindRoseProps {
  currentSpeed: number;
  currentGust: number | null;
  currentDirection: number;
  currentDirectionCardinal: string;
  windHistory?: WindDataPoint[];
  loadedAspects?: Aspect[];
}

export function WindRose({
  currentSpeed,
  currentGust,
  currentDirection,
  currentDirectionCardinal,
  windHistory = [],
  loadedAspects = [],
}: WindRoseProps) {
  const size = 200;
  const center = size / 2;
  const radius = 80;

  // Calculate wind arrow position
  const arrowAngle = (currentDirection - 90) * (Math.PI / 180);
  const arrowLength = Math.min(radius - 10, (currentSpeed / 50) * (radius - 10));

  // Draw compass directions
  const directions = ASPECTS.map((dir, i) => {
    const angle = (i * 45 - 90) * (Math.PI / 180);
    const x = center + Math.cos(angle) * (radius + 15);
    const y = center + Math.sin(angle) * (radius + 15);
    const isLoaded = loadedAspects.includes(dir);
    return { dir, x, y, angle, isLoaded };
  });

  // Draw wind history dots
  const historyDots = windHistory.slice(-6).map((point, i) => {
    const angle = (point.direction - 90) * (Math.PI / 180);
    const distance = Math.min(radius - 20, (point.speed / 50) * (radius - 20));
    const x = center + Math.cos(angle) * distance;
    const y = center + Math.sin(angle) * distance;
    const opacity = 0.3 + (i / 6) * 0.5;
    return { x, y, opacity, speed: point.speed };
  });

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle>Wind Rose</CardTitle>
          <Badge variant={currentSpeed > 25 ? 'danger' : currentSpeed > 15 ? 'warning' : 'success'}>
            {currentSpeed} mph
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col items-center">
          <svg width={size} height={size} className="overflow-visible">
            {/* Background circles */}
            <circle cx={center} cy={center} r={radius} fill="none" stroke="currentColor" strokeOpacity={0.1} />
            <circle cx={center} cy={center} r={radius * 0.66} fill="none" stroke="currentColor" strokeOpacity={0.1} />
            <circle cx={center} cy={center} r={radius * 0.33} fill="none" stroke="currentColor" strokeOpacity={0.1} />

            {/* Cross lines */}
            <line x1={center} y1={center - radius} x2={center} y2={center + radius} stroke="currentColor" strokeOpacity={0.1} />
            <line x1={center - radius} y1={center} x2={center + radius} y2={center} stroke="currentColor" strokeOpacity={0.1} />

            {/* Direction labels */}
            {directions.map(({ dir, x, y, isLoaded }) => (
              <text
                key={dir}
                x={x}
                y={y}
                textAnchor="middle"
                dominantBaseline="middle"
                className={`text-xs font-medium ${isLoaded ? 'fill-amber-400' : 'fill-slate-400'}`}
              >
                {dir}
              </text>
            ))}

            {/* Loaded aspects highlight */}
            {loadedAspects.map((aspect) => {
              const i = ASPECTS.indexOf(aspect);
              const startAngle = (i * 45 - 22.5 - 90) * (Math.PI / 180);
              const endAngle = (i * 45 + 22.5 - 90) * (Math.PI / 180);
              const x1 = center + Math.cos(startAngle) * radius;
              const y1 = center + Math.sin(startAngle) * radius;
              const x2 = center + Math.cos(endAngle) * radius;
              const y2 = center + Math.sin(endAngle) * radius;
              return (
                <path
                  key={`loaded-${aspect}`}
                  d={`M ${center} ${center} L ${x1} ${y1} A ${radius} ${radius} 0 0 1 ${x2} ${y2} Z`}
                  fill="rgb(245 158 11 / 0.15)"
                  stroke="rgb(245 158 11 / 0.3)"
                  strokeWidth={1}
                />
              );
            })}

            {/* Wind history trail */}
            {historyDots.map((dot, i) => (
              <circle
                key={i}
                cx={dot.x}
                cy={dot.y}
                r={3}
                fill="rgb(59 130 246)"
                opacity={dot.opacity}
              />
            ))}

            {/* Gust ring */}
            {currentGust && currentGust > currentSpeed && (
              <circle
                cx={center}
                cy={center}
                r={Math.min(radius - 5, (currentGust / 50) * (radius - 5))}
                fill="none"
                stroke="rgb(239 68 68)"
                strokeWidth={2}
                strokeDasharray="4 4"
                opacity={0.5}
              />
            )}

            {/* Current wind arrow */}
            <g transform={`translate(${center}, ${center})`}>
              <line
                x1={0}
                y1={0}
                x2={Math.cos(arrowAngle) * arrowLength}
                y2={Math.sin(arrowAngle) * arrowLength}
                stroke="rgb(59 130 246)"
                strokeWidth={3}
                strokeLinecap="round"
              />
              {/* Arrow head */}
              <polygon
                points={`
                  ${Math.cos(arrowAngle) * arrowLength},${Math.sin(arrowAngle) * arrowLength}
                  ${Math.cos(arrowAngle - 0.4) * (arrowLength - 10)},${Math.sin(arrowAngle - 0.4) * (arrowLength - 10)}
                  ${Math.cos(arrowAngle + 0.4) * (arrowLength - 10)},${Math.sin(arrowAngle + 0.4) * (arrowLength - 10)}
                `}
                fill="rgb(59 130 246)"
              />
            </g>

            {/* Center dot */}
            <circle cx={center} cy={center} r={4} fill="rgb(148 163 184)" />
          </svg>

          {/* Legend */}
          <div className="mt-4 grid grid-cols-2 gap-4 text-sm">
            <div className="flex items-center gap-2">
              <div className="h-3 w-3 rounded-full bg-blue-500" />
              <span className="text-slate-400">Wind: {currentSpeed} mph {currentDirectionCardinal}</span>
            </div>
            {currentGust && (
              <div className="flex items-center gap-2">
                <div className="h-3 w-3 rounded-full border-2 border-dashed border-red-500" />
                <span className="text-slate-400">Gust: {currentGust} mph</span>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
