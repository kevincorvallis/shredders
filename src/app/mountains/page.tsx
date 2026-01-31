'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { MountainMap } from '@/components/MountainMapLoader';
import { MountainCard, MountainCardSkeleton } from '@/components/MountainCard';
import { getAllMountains, getMountainsSortedByDistance, type MountainConfig } from '@shredders/shared';

interface MountainWithData extends MountainConfig {
  powderScore?: number;
  distance?: number;
}

export default function MountainsPage() {
  const router = useRouter();
  const [mountains, setMountains] = useState<MountainWithData[]>([]);
  const [selectedMountainId, setSelectedMountainId] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<'map' | 'list'>('map');
  const [isLoading, setIsLoading] = useState(true);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);

  // Get user location
  useEffect(() => {
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          });
        },
        () => {
          // Location denied or unavailable, use default
          console.log('Geolocation not available, using default');
        }
      );
    }
  }, []);

  // Fetch mountain data with powder scores
  useEffect(() => {
    async function fetchData() {
      const baseMountains = userLocation
        ? getMountainsSortedByDistance(userLocation.lat, userLocation.lng)
        : getAllMountains().map((m) => ({ ...m, distance: undefined }));

      setMountains(baseMountains);
      setIsLoading(false);

      // Fetch all powder scores in one request instead of 15!
      try {
        const res = await fetch('/api/mountains/batch/powder-scores');
        if (res.ok) {
          const batchData = await res.json();
          const scoreMap = new Map(
            batchData.scores.map((s: any) => [s.mountainId, s.score])
          );

          setMountains((prev) =>
            prev.map((m) => ({
              ...m,
              powderScore: scoreMap.get(m.id) as number | undefined,
            }))
          );
        }
      } catch (error) {
        console.error('Error fetching powder scores:', error);
      }
    }

    fetchData();
  }, [userLocation]);

  const handleMountainSelect = (mountainId: string) => {
    setSelectedMountainId(mountainId);
    router.push(`/mountains/${mountainId}`);
  };

  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Link href="/" className="text-gray-400 hover:text-white transition-colors">
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </Link>
              <h1 className="text-xl font-bold text-white">PNW Mountains</h1>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setViewMode('map')}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  viewMode === 'map'
                    ? 'bg-sky-500 text-white'
                    : 'bg-slate-800 text-gray-400 hover:text-white'
                }`}
              >
                Map
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  viewMode === 'list'
                    ? 'bg-sky-500 text-white'
                    : 'bg-slate-800 text-gray-400 hover:text-white'
                }`}
              >
                List
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      {viewMode === 'map' ? (
        <div className="h-[calc(100vh-73px)]">
          <MountainMap
            selectedMountainId={selectedMountainId ?? undefined}
            onMountainSelect={handleMountainSelect}
            showUserLocation
          />
        </div>
      ) : (
        <div className="max-w-2xl mx-auto px-4 py-6">
          {userLocation && (
            <p className="text-sm text-gray-400 mb-4">
              Sorted by distance from your location
            </p>
          )}
          <div className="space-y-3">
            {isLoading ? (
              <MountainCardSkeleton count={15} />
            ) : (
              mountains.map((mountain) => (
                <MountainCard
                  key={mountain.id}
                  mountain={mountain}
                  powderScore={mountain.powderScore}
                  distance={mountain.distance}
                  isSelected={mountain.id === selectedMountainId}
                  onClick={() => handleMountainSelect(mountain.id)}
                />
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}
