'use client';

import { useState, useEffect, useMemo } from 'react';
import dynamic from 'next/dynamic';
import { getAllMountains, type MountainConfig, calculateDistance } from '@/data/mountains';

// Dynamic import for Leaflet to avoid SSR issues
const LeafletMap = dynamic(() => import('./LeafletMap'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full bg-slate-800 flex items-center justify-center">
      <div className="flex items-center gap-2 text-white">
        <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
        <span>Loading map...</span>
      </div>
    </div>
  ),
});

interface MountainMapProps {
  selectedMountainId?: string;
  onMountainSelect?: (mountainId: string) => void;
  showUserLocation?: boolean;
}

export interface MountainWithScore extends MountainConfig {
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

      // First, set mountains immediately
      setMountains(allMountains);
      setIsLoading(false);

      // Then fetch powder scores in parallel
      const scores = await Promise.allSettled(
        allMountains.map(async (mountain) => {
          const response = await fetch(`/api/mountains/${mountain.id}/powder-score`);
          if (response.ok) {
            const data = await response.json();
            return { id: mountain.id, score: data.score };
          }
          return null;
        })
      );

      // Update mountains with scores
      setMountains((prev) =>
        prev.map((m) => {
          const scoreResult = scores.find(
            (s) => s.status === 'fulfilled' && s.value?.id === m.id
          );
          return {
            ...m,
            powderScore:
              scoreResult?.status === 'fulfilled' ? scoreResult.value?.score : undefined,
          };
        })
      );
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
        }))
      );
    }
  }, [userLocation]);

  // Group mountains by region
  const mountainsByRegion = useMemo(() => {
    const sorted = userLocation
      ? [...mountains].sort((a, b) => (a.distance ?? 999) - (b.distance ?? 999))
      : mountains;

    return {
      washington: sorted.filter((m) => m.region === 'washington'),
      oregon: sorted.filter((m) => m.region === 'oregon'),
      idaho: sorted.filter((m) => m.region === 'idaho'),
    };
  }, [mountains, userLocation]);

  const getScoreColor = (score?: number) => {
    if (score === undefined) return 'bg-slate-500';
    if (score >= 7) return 'bg-green-500';
    if (score >= 5) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  const MountainButton = ({ mountain }: { mountain: MountainWithScore }) => (
    <button
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
  );

  return (
    <div className="w-full h-full bg-slate-800 flex flex-col overflow-hidden">
      {/* Leaflet Map */}
      <div className="flex-1 min-h-0 relative">
        <LeafletMap
          mountains={mountains}
          userLocation={userLocation}
          selectedMountainId={selectedMountainId}
          onMountainSelect={onMountainSelect}
          isLoading={isLoading}
        />

        {/* Legend overlay */}
        <div className="absolute bottom-4 left-4 bg-slate-900/90 rounded-lg px-3 py-2 flex items-center gap-4 text-xs z-[1000]">
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
      </div>

      {/* Mountain list by region */}
      <div className="bg-slate-900/95 backdrop-blur-sm border-t border-slate-700/50 p-6 max-h-96 overflow-y-auto rounded-t-2xl shadow-[0_-4px_20px_rgba(0,0,0,0.4)]">
        <div className="grid md:grid-cols-3 gap-6">
          {/* Washington */}
          <div>
            <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4">
              Washington ({mountainsByRegion.washington.length})
            </h3>
            <div className="space-y-3">
              {mountainsByRegion.washington.map((mountain) => (
                <MountainButton key={mountain.id} mountain={mountain} />
              ))}
            </div>
          </div>

          {/* Oregon */}
          <div>
            <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4">
              Oregon ({mountainsByRegion.oregon.length})
            </h3>
            <div className="space-y-3">
              {mountainsByRegion.oregon.map((mountain) => (
                <MountainButton key={mountain.id} mountain={mountain} />
              ))}
            </div>
          </div>

          {/* Idaho */}
          <div>
            <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4">
              Idaho ({mountainsByRegion.idaho.length})
            </h3>
            <div className="space-y-3">
              {mountainsByRegion.idaho.map((mountain) => (
                <MountainButton key={mountain.id} mountain={mountain} />
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
    </div>
  );
}
