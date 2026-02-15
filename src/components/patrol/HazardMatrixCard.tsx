'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { ASPECTS, ELEVATION_BANDS, type Aspect, type ElevationBand } from '@/lib/design-tokens';
import type { HazardMatrixEntry } from '@/lib/calculations/safety-metrics';

interface HazardMatrixCardProps {
  matrix: HazardMatrixEntry[];
  loadedAspects?: Aspect[];
}

const riskColors: Record<1 | 2 | 3 | 4 | 5, string> = {
  1: 'bg-emerald-500',
  2: 'bg-lime-500',
  3: 'bg-amber-500',
  4: 'bg-orange-500',
  5: 'bg-red-500',
};

const riskLabels: Record<1 | 2 | 3 | 4 | 5, string> = {
  1: 'Low',
  2: 'Moderate',
  3: 'Considerable',
  4: 'High',
  5: 'Extreme',
};

export function HazardMatrixCard({ matrix, loadedAspects = [] }: HazardMatrixCardProps) {
  const getEntry = (aspect: Aspect, elevation: ElevationBand) => {
    return matrix.find(e => e.aspect === aspect && e.elevation === elevation);
  };

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle>Hazard Matrix</CardTitle>
        <p className="text-xs text-text-quaternary">Risk by aspect and elevation</p>
      </CardHeader>
      <CardContent>
        <TooltipProvider>
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr>
                  <th className="p-1 text-left text-text-quaternary font-medium" />
                  {ASPECTS.map(aspect => (
                    <th
                      key={aspect}
                      className={`p-1 text-center font-medium ${
                        loadedAspects.includes(aspect) ? 'text-amber-400' : 'text-text-tertiary'
                      }`}
                    >
                      {aspect}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {ELEVATION_BANDS.map(elevation => (
                  <tr key={elevation}>
                    <td className="p-1 text-text-quaternary font-medium whitespace-nowrap">
                      {elevation === 'Below Treeline' ? 'Below TL' : elevation}
                    </td>
                    {ASPECTS.map(aspect => {
                      const entry = getEntry(aspect, elevation);
                      const risk = entry?.risk ?? 1;
                      const factors = entry?.factors ?? [];

                      return (
                        <td key={`${aspect}-${elevation}`} className="p-1">
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <button
                                className={`w-full h-6 rounded ${riskColors[risk]} opacity-80 hover:opacity-100 transition-opacity`}
                                aria-label={`${aspect} ${elevation}: ${riskLabels[risk]}`}
                              />
                            </TooltipTrigger>
                            <TooltipContent side="top" className="max-w-xs">
                              <div className="space-y-1">
                                <div className="font-medium">
                                  {aspect} - {elevation}
                                </div>
                                <div className={`text-sm ${risk >= 4 ? 'text-red-400' : risk >= 3 ? 'text-amber-400' : 'text-emerald-400'}`}>
                                  {riskLabels[risk]} Risk
                                </div>
                                {factors.length > 0 && (
                                  <ul className="text-xs text-text-tertiary list-disc list-inside">
                                    {factors.map((f, i) => (
                                      <li key={i}>{f}</li>
                                    ))}
                                  </ul>
                                )}
                              </div>
                            </TooltipContent>
                          </Tooltip>
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Legend */}
          <div className="mt-4 flex items-center justify-center gap-2 text-xs">
            {([1, 2, 3, 4, 5] as const).map(risk => (
              <div key={risk} className="flex items-center gap-1">
                <div className={`w-3 h-3 rounded ${riskColors[risk]}`} />
                <span className="text-text-tertiary">{riskLabels[risk]}</span>
              </div>
            ))}
          </div>
        </TooltipProvider>
      </CardContent>
    </Card>
  );
}
