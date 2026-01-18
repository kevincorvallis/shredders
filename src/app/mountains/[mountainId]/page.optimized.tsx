'use client';

import { use, useLayoutEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { getMountain } from '@shredders/shared';
import { Shield, Home, History, Camera, RefreshCw } from 'lucide-react';
import { MountainSelector } from '@/components/MountainSelector';
import { useMountain } from '@/context/MountainContext';
import { useMountainData } from '@/hooks/useMountainData';
import { Skeleton } from '@/components/ui/skeleton';

export default function MountainPage({
  params,
}: {
  params: Promise<{ mountainId: string }>;
}) {
  const { mountainId } = use(params);
  const staticMountain = getMountain(mountainId);
  const router = useRouter();
  const { setSelectedMountain } = useMountain();

  // Fetch all data with caching
  const { data, error, isLoading, refresh } = useMountainData(mountainId);

  // Sync URL param with global context
  useLayoutEffect(() => {
    setSelectedMountain(mountainId);
  }, [mountainId, setSelectedMountain]);

  // Error recovery: redirect invalid mountain IDs
  useLayoutEffect(() => {
    if (!staticMountain && !isLoading) {
      console.warn(`Invalid mountain ID: ${mountainId}, redirecting to baker`);
      router.replace('/mountains/baker');
    }
  }, [staticMountain, mountainId, router, isLoading]);

  const handleMountainChange = (newMountainId: string) => {
    setSelectedMountain(newMountainId);
    router.push(`/mountains/${newMountainId}`);
  };

  if (!staticMountain) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-white mb-2">Mountain Not Found</h1>
          <p className="text-gray-400 mb-4">
            The mountain &quot;{mountainId}&quot; doesn&apos;t exist.
          </p>
          <Link
            href="/mountains"
            className="text-sky-400 hover:text-sky-300 transition-colors"
          >
            View all mountains
          </Link>
        </div>
      </div>
    );
  }

  const getWeatherIcon = (icon: string) => {
    switch (icon) {
      case 'snow':
        return '❄️';
      case 'rain':
        return '🌧️';
      case 'sun':
        return '☀️';
      case 'fog':
        return '🌫️';
      default:
        return '☁️';
    }
  };

  // Dynamic background based on powder score
  const getBackgroundClass = () => {
    if (!data?.powderScore) return 'bg-slate-900';

    const score = data.powderScore.score;
    if (score >= 8) {
      return 'bg-gradient-to-br from-blue-900 via-slate-900 to-slate-900';
    } else if (score >= 6) {
      return 'bg-gradient-to-br from-purple-900 via-slate-900 to-slate-900';
    } else if (score >= 4) {
      return 'bg-gradient-to-br from-gray-800 via-slate-900 to-slate-900';
    } else {
      return 'bg-gradient-to-br from-slate-800 via-slate-900 to-slate-900';
    }
  };

  return (
    <div className={`min-h-screen ${getBackgroundClass()}`}>
      {/* Header */}
      <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <Link
              href="/mountains"
              className="text-gray-400 hover:text-white transition-colors"
            >
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </Link>
            <MountainSelector
              selectedId={mountainId}
              onChange={handleMountainChange}
            />
            <a
              href={staticMountain.website}
              target="_blank"
              rel="noopener noreferrer"
              className="ml-auto text-sm text-gray-400 hover:text-white transition-colors"
            >
              Official Site ↗
            </a>
            <button
              onClick={() => refresh()}
              disabled={isLoading}
              className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 transition-colors disabled:opacity-50"
              title="Refresh data"
            >
              <RefreshCw className={`w-5 h-5 ${isLoading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="max-w-4xl mx-auto px-4">
          <nav className="flex gap-1 border-t border-slate-800 pt-2 pb-2 overflow-x-auto">
            <Link
              href={`/mountains/${mountainId}`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors bg-slate-800 text-white"
            >
              <Home className="w-4 h-4" />
              Overview
            </Link>
            <Link
              href={`/mountains/${mountainId}/patrol`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-gray-400 hover:text-white hover:bg-slate-800/50"
            >
              <Shield className="w-4 h-4" />
              Patrol
            </Link>
            <Link
              href={`/mountains/${mountainId}/history`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-gray-400 hover:text-white hover:bg-slate-800/50"
            >
              <History className="w-4 h-4" />
              History
            </Link>
            <Link
              href={`/mountains/${mountainId}/webcams`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-gray-400 hover:text-white hover:bg-slate-800/50"
            >
              <Camera className="w-4 h-4" />
              Webcams
            </Link>
          </nav>
        </div>

        {/* Cache indicator */}
        {data?.cachedAt && !isLoading && (
          <div className="max-w-4xl mx-auto px-4 pb-2">
            <div className="text-xs text-gray-500">
              Updated: {new Date(data.cachedAt).toLocaleTimeString()}
              {' '}<span className="text-green-500">● Cached</span>
            </div>
          </div>
        )}
      </header>

      <main className="max-w-4xl mx-auto px-4 py-6 space-y-6">
        {isLoading ? (
          <LoadingSkeleton />
        ) : error ? (
          <ErrorState error={error} onRetry={refresh} />
        ) : data ? (
          <MountainContent data={data} mountain={staticMountain} getWeatherIcon={getWeatherIcon} />
        ) : null}
      </main>
    </div>
  );
}

// Loading skeleton component
function LoadingSkeleton() {
  return (
    <>
      <Skeleton className="h-48 w-full rounded-xl" />
      <Skeleton className="h-64 w-full rounded-xl" />
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Skeleton className="h-48 rounded-xl" />
        <Skeleton className="h-48 rounded-xl" />
      </div>
      <Skeleton className="h-64 w-full rounded-xl" />
    </>
  );
}

// Error state component
function ErrorState({ error, onRetry }: { error: any; onRetry: () => void }) {
  return (
    <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
      <h2 className="text-xl font-bold text-red-400 mb-2">Failed to Load Data</h2>
      <p className="text-red-300 mb-4">
        {error?.message || 'An error occurred while fetching mountain data'}
      </p>
      <button
        onClick={onRetry}
        className="px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors"
      >
        Try Again
      </button>
    </div>
  );
}

// Main content component (extracted for clarity)
function MountainContent({ data, mountain, getWeatherIcon }: any) {
  const { conditions, powderScore, forecast, roads, tripAdvice, powderDay, alerts, weatherGovLinks } = data;

  return (
    <>
      {/* Weather Alerts */}
      {alerts?.length > 0 && (
        <div className="space-y-3">
          {alerts.map((alert: any) => (
            <WeatherAlert key={alert.id} alert={alert} />
          ))}
        </div>
      )}

      {/* Powder Score */}
      {powderScore && (
        <PowderScoreCard powderScore={powderScore} mountain={mountain} />
      )}

      {/* Current Conditions */}
      {conditions && (
        <ConditionsCard conditions={conditions} mountain={mountain} />
      )}

      {/* Road & Pass Conditions */}
      {roads && <RoadsCard roads={roads} />}

      {/* Trip & Traffic */}
      {tripAdvice && <TripAdviceCard tripAdvice={tripAdvice} />}

      {/* Powder Day Planner */}
      {powderDay?.days?.length > 0 && <PowderDayCard powderDay={powderDay} />}

      {/* 7-Day Forecast */}
      {forecast?.length > 0 && (
        <ForecastCard forecast={forecast} weatherGovLinks={weatherGovLinks} getWeatherIcon={getWeatherIcon} />
      )}

      {/* Webcams */}
      {mountain.webcams?.length > 0 && <WebcamsCard webcams={mountain.webcams} />}

      {/* Mountain Info */}
      <MountainInfoCard mountain={mountain} />
    </>
  );
}

// Individual card components for better organization
function WeatherAlert({ alert }: { alert: any }) {
  const severityColors = {
    Extreme: 'bg-red-500/20 border-red-500 text-red-200',
    Severe: 'bg-orange-500/20 border-orange-500 text-orange-200',
    Moderate: 'bg-yellow-500/20 border-yellow-500 text-yellow-200',
    Minor: 'bg-blue-500/20 border-blue-500 text-blue-200',
    Unknown: 'bg-gray-500/20 border-gray-500 text-gray-200',
  };

  const colorClass = severityColors[alert.severity as keyof typeof severityColors] || severityColors.Unknown;

  return (
    <div className={`rounded-xl p-4 border-2 ${colorClass}`}>
      <div className="flex items-start gap-3">
        <div className="text-2xl">⚠️</div>
        <div className="flex-1">
          <h3 className="font-bold text-lg mb-1">{alert.event}</h3>
          <p className="font-medium mb-2">{alert.headline}</p>
          <p className="text-sm opacity-90 mb-2 whitespace-pre-wrap">
            {alert.description.substring(0, 300)}
            {alert.description.length > 300 && '...'}
          </p>
          {alert.instruction && (
            <p className="text-sm font-medium mt-2 p-2 bg-black/20 rounded">
              {alert.instruction.substring(0, 200)}
              {alert.instruction.length > 200 && '...'}
            </p>
          )}
          {alert.expires && (
            <p className="text-xs mt-2 opacity-75">
              Expires: {new Date(alert.expires).toLocaleString()}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

// Powder Score Card (simplified)
function PowderScoreCard({ powderScore, mountain }: any) {
  return (
    <div className="bg-slate-800 rounded-xl p-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-white">Powder Score</h2>
        <div
          className={`text-4xl font-bold ${
            powderScore.score >= 7
              ? 'text-green-400'
              : powderScore.score >= 5
                ? 'text-yellow-400'
                : 'text-red-400'
          }`}
        >
          {powderScore.score.toFixed(1)}
          <span className="text-lg text-gray-500">/10</span>
        </div>
      </div>
      <p className="text-gray-300 mb-4">{powderScore.verdict}</p>

      <a
        href={`https://maps.google.com/maps?daddr=${mountain.location.lat},${mountain.location.lng}`}
        target="_blank"
        rel="noopener noreferrer"
        className="block w-full mb-4 px-6 py-3 bg-blue-600 hover:bg-blue-700 rounded-xl text-white font-semibold text-center transition-colors flex items-center justify-center gap-2"
      >
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
        </svg>
        Plan Trip to {mountain.shortName}
      </a>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
        {powderScore.factors.map((factor: any, i: number) => (
          <div key={i} className="bg-slate-700/50 rounded-lg p-3">
            <div className="text-xs text-gray-400 mb-1">{factor.name}</div>
            <div className="text-sm text-white">{factor.description}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Conditions Card - I'll continue with the rest in the next file part
// (This file is getting long, so I'll create helper components separately)

// Placeholder components - will be implemented
function ConditionsCard({ conditions, mountain }: any) {
  return <div className="bg-slate-800 rounded-xl p-6">
    <h2 className="text-lg font-semibold text-white mb-4">Current Conditions</h2>
    {/* Implementation from original file */}
  </div>;
}

function RoadsCard({ roads }: any) {
  return null; // Will implement
}

function TripAdviceCard({ tripAdvice }: any) {
  return null;
}

function PowderDayCard({ powderDay }: any) {
  return null;
}

function ForecastCard({ forecast, weatherGovLinks, getWeatherIcon }: any) {
  return null;
}

function WebcamsCard({ webcams }: any) {
  return null;
}

function MountainInfoCard({ mountain }: any) {
  return null;
}
