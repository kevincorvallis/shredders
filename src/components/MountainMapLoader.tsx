'use client';

import { useState, useEffect } from 'react';
import { getAllMountains, type MountainConfig, calculateDistance } from '@/data/mountains';

interface MountainMapProps {
  selectedMountainId?: string;
  onMountainSelect?: (mountainId: string) => void;
  showUserLocation?: boolean;
}

interface MountainWithScore extends MountainConfig {
  powderScore?: number;
  distance?: number;
}

export function MountainMap({
  selectedMountainId,
  onMountainSelect,
  showUserLocation = true,
}: MountainMapProps) {
  const [mountains, setMountains] = useState<MountainWithScore[]>([]);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Get user location
  useEffect(() => {
    if (showUserLocation && 'geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          });
        },
        () => console.log('Location access denied')
      );
    }
  }, [showUserLocation]);

  // Fetch mountains with powder scores
  useEffect(() => {
    async function fetchMountainData() {
      const allMountains = getAllMountains();
      const mountainsWithScores: MountainWithScore[] = [];

      for (const mountain of allMountains) {
        try {
          const response = await fetch(`/api/mountains/${mountain.id}/powder-score`);
          if (response.ok) {
            const data = await response.json();
            mountainsWithScores.push({
              ...mountain,
              powderScore: data.score,
            });
          } else {
            mountainsWithScores.push(mountain);
          }
        } catch {
          mountainsWithScores.push(mountain);
        }
      }

      setMountains(mountainsWithScores);
      setIsLoading(false);
    }

    fetchMountainData();
  }, []);

  // Update distances when user location changes
  useEffect(() => {
    if (userLocation) {
      setMountains((prev) =>
        prev.map((m) => ({
          ...m,
          distance: calculateDistance(
            userLocation.lat,
            userLocation.lng,
            m.location.lat,
            m.location.lng
          ),
        })).sort((a, b) => (a.distance ?? 999) - (b.distance ?? 999))
      );
    }
  }, [userLocation]);

  const getScoreColor = (score?: number) => {
    if (score === undefined) return 'bg-slate-500';
    if (score >= 7) return 'bg-green-500';
    if (score >= 5) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  // Washington mountains (lat > 46.5)
  const waMountains = mountains.filter((m) => m.region === 'washington');
  // Oregon mountains
  const orMountains = mountains.filter((m) => m.region === 'oregon');

  return (
    <div className="w-full h-full bg-slate-800 rounded-xl p-4 overflow-auto">
      {/* Map visualization placeholder */}
      <div className="relative mb-6">
        <div className="aspect-video bg-slate-700/50 rounded-xl overflow-hidden relative">
          {/* Simple SVG map of PNW */}
          <svg viewBox="0 0 400 300" className="w-full h-full">
            {/* Background */}
            <rect width="400" height="300" fill="#1e293b" />

            {/* Simple state outlines */}
            <path
              d="M50,50 L350,50 L350,150 L50,150 Z"
              fill="none"
              stroke="#475569"
              strokeWidth="1"
            />
            <text x="200" y="100" textAnchor="middle" fill="#64748b" fontSize="14">
              WASHINGTON
            </text>
            <path
              d="M50,150 L350,150 L350,280 L50,280 Z"
              fill="none"
              stroke="#475569"
              strokeWidth="1"
            />
            <text x="200" y="215" textAnchor="middle" fill="#64748b" fontSize="14">
              OREGON
            </text>

            {/* Mountain markers */}
            {mountains.map((mountain) => {
              // Map coordinates to SVG space (simplified)
              const x = ((mountain.location.lng + 125) / 10) * 400;
              const y = mountain.region === 'washington'
                ? 50 + (150 - 50) * ((49 - mountain.location.lat) / 3)
                : 150 + (280 - 150) * ((47 - mountain.location.lat) / 4);

              return (
                <g key={mountain.id} className="cursor-pointer" onClick={() => onMountainSelect?.(mountain.id)}>
                  <circle
                    cx={Math.max(30, Math.min(370, x))}
                    cy={Math.max(30, Math.min(270, y))}
                    r={mountain.id === selectedMountainId ? 14 : 10}
                    fill={mountain.powderScore !== undefined
                      ? mountain.powderScore >= 7 ? '#22c55e' : mountain.powderScore >= 5 ? '#eab308' : '#ef4444'
                      : mountain.color
                    }
                    stroke={mountain.id === selectedMountainId ? '#fff' : 'none'}
                    strokeWidth="2"
                  />
                  <text
                    x={Math.max(30, Math.min(370, x))}
                    y={Math.max(30, Math.min(270, y)) + 4}
                    textAnchor="middle"
                    fill="#fff"
                    fontSize="10"
                    fontWeight="bold"
                  >
                    {mountain.powderScore?.toFixed(0) ?? '?'}
                  </text>
                </g>
              );
            })}
          </svg>

          {/* Loading overlay */}
          {isLoading && (
            <div className="absolute inset-0 bg-slate-900/50 flex items-center justify-center">
              <div className="flex items-center gap-2 text-white">
                <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  />
                </svg>
                <span>Loading conditions...</span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center justify-center gap-6 mb-6 text-xs">
        <div className="flex items-center gap-1.5">
          <span className="w-3 h-3 rounded-full bg-green-500" />
          <span className="text-gray-300">7+ Great</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="w-3 h-3 rounded-full bg-yellow-500" />
          <span className="text-gray-300">5-7 Good</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="w-3 h-3 rounded-full bg-red-500" />
          <span className="text-gray-300">&lt;5 Fair</span>
        </div>
      </div>

      {/* Mountain list */}
      <div className="grid md:grid-cols-2 gap-4">
        {/* Washington */}
        <div>
          <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-3">
            Washington
          </h3>
          <div className="space-y-2">
            {waMountains.map((mountain) => (
              <button
                key={mountain.id}
                onClick={() => onMountainSelect?.(mountain.id)}
                className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors ${
                  mountain.id === selectedMountainId
                    ? 'bg-sky-500/20 border border-sky-500'
                    : 'bg-slate-700/50 hover:bg-slate-700 border border-transparent'
                }`}
              >
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-bold ${getScoreColor(mountain.powderScore)}`}
                >
                  {mountain.powderScore?.toFixed(0) ?? '?'}
                </div>
                <div className="flex-1 text-left">
                  <div className="text-white font-medium">{mountain.shortName}</div>
                  <div className="text-xs text-gray-400">
                    {mountain.elevation.summit.toLocaleString()}ft
                    {mountain.distance !== undefined && ` • ${mountain.distance.toFixed(0)} mi`}
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Oregon */}
        <div>
          <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-3">
            Oregon
          </h3>
          <div className="space-y-2">
            {orMountains.map((mountain) => (
              <button
                key={mountain.id}
                onClick={() => onMountainSelect?.(mountain.id)}
                className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors ${
                  mountain.id === selectedMountainId
                    ? 'bg-sky-500/20 border border-sky-500'
                    : 'bg-slate-700/50 hover:bg-slate-700 border border-transparent'
                }`}
              >
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-bold ${getScoreColor(mountain.powderScore)}`}
                >
                  {mountain.powderScore?.toFixed(0) ?? '?'}
                </div>
                <div className="flex-1 text-left">
                  <div className="text-white font-medium">{mountain.shortName}</div>
                  <div className="text-xs text-gray-400">
                    {mountain.elevation.summit.toLocaleString()}ft
                    {mountain.distance !== undefined && ` • ${mountain.distance.toFixed(0)} mi`}
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* User location status */}
      {showUserLocation && userLocation && (
        <div className="mt-4 text-center text-xs text-gray-500">
          Sorted by distance from your location
        </div>
      )}
    </div>
  );
}
