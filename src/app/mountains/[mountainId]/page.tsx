'use client';

import { useState, useEffect, useLayoutEffect, use } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { getMountain } from '@/data/mountains';
import { Shield, Home, History, Camera } from 'lucide-react';
import { MountainSelector } from '@/components/MountainSelector';
import { useMountain } from '@/context/MountainContext';
import { useMountainData } from '@/lib/hooks/useMountainData';
import { MountainStatus } from '@/components/MountainStatus';
import { NavigateButton } from '@/components/NavigateButton';
import Image from 'next/image';

interface Conditions {
  snowDepth: number | null;
  snowfall24h: number;
  snowfall48h: number;
  temperature: number | null;
  conditions: string;
  wind: { speed: number; direction: string } | null;
  freezingLevel: number | null;
  rainRisk: {
    score: number;
    description: string;
  } | null;
  elevation?: { base: number; summit: number };
}

interface PowderScore {
  score: number;
  verdict: string;
  factors: Array<{
    name: string;
    value: number;
    weight: number;
    contribution: number;
    description: string;
  }>;
}

interface ForecastDay {
  date: string;
  dayOfWeek: string;
  high: number;
  low: number;
  snowfall: number;
  precipProbability: number;
  conditions: string;
  icon: string;
}

interface RoadsResponse {
  supported: boolean;
  configured: boolean;
  provider: string | null;
  passes: Array<{
    id: number;
    name: string;
    dateUpdated?: string | null;
    roadCondition?: string | null;
    weatherCondition?: string | null;
    temperatureF?: number | null;
    travelAdvisoryActive?: boolean | null;
    restrictions: Array<{ direction?: string | null; text?: string | null }>;
  }>;
  message?: string;
}

interface TripAdviceResponse {
  generated: string;
  headline: string;
  crowd: 'low' | 'medium' | 'high';
  trafficRisk: 'low' | 'medium' | 'high';
  roadRisk: 'low' | 'medium' | 'high';
  notes: string[];
  suggestedDepartures: Array<{ from: string; suggestion: string }>;
}

interface WeatherAlert {
  id: string;
  event: string;
  headline: string;
  severity: 'Extreme' | 'Severe' | 'Moderate' | 'Minor' | 'Unknown';
  urgency: 'Immediate' | 'Expected' | 'Future' | 'Past' | 'Unknown';
  description: string;
  instruction: string | null;
  onset: string | null;
  expires: string | null;
}

interface WeatherGovLinks {
  forecast: string;
  hourly: string;
  detailed: string;
  alerts: string;
  discussion: string;
}

interface PowderDayPlanResponse {
  generated: string;
  days: Array<{
    date: string;
    dayOfWeek: string;
    predictedPowderScore: number;
    confidence: number;
    verdict: 'send' | 'maybe' | 'wait';
    bestWindow: string;
    crowdRisk: 'low' | 'medium' | 'high';
    travelNotes: string[];
    forecastSnapshot: {
      snowfall: number;
      high: number;
      low: number;
      windSpeed: number;
      precipProbability: number;
      precipType: 'snow' | 'rain' | 'mixed' | 'none';
      conditions: string;
    };
  }>;
}

export default function MountainPage({
  params,
}: {
  params: Promise<{ mountainId: string }>;
}) {
  const { mountainId } = use(params);
  const mountain = getMountain(mountainId);
  const router = useRouter();
  const { setSelectedMountain } = useMountain();

  // Sync URL param with global context IMMEDIATELY (before paint)
  // This prevents the race condition where old data briefly shows
  useLayoutEffect(() => {
    setSelectedMountain(mountainId);
  }, [mountainId, setSelectedMountain]);

  // Error recovery: redirect invalid mountain IDs to default
  useEffect(() => {
    if (!mountain) {
      console.warn(`Invalid mountain ID: ${mountainId}, redirecting to baker`);
      router.replace('/mountains/baker');
    }
  }, [mountain, mountainId, router]);

  const handleMountainChange = (newMountainId: string) => {
    setSelectedMountain(newMountainId);
    router.push(`/mountains/${newMountainId}`);
  };

  // Use the batched data hook for better performance and caching
  const { data: mountainData, error: dataError, isLoading } = useMountainData(mountainId);

  // Extract data from batched response
  const conditions = mountainData?.conditions || null;
  const powderScore = mountainData?.powderScore || null;
  const forecast = mountainData?.forecast || [];
  const roads = mountainData?.roads || null;
  const tripAdvice = mountainData?.tripAdvice || null;
  const powderDayPlan = mountainData?.powderDay || null;
  const alerts = mountainData?.alerts || [];
  const weatherGovLinks = mountainData?.weatherGovLinks || null;
  const error = dataError ? 'Failed to load mountain data' : null;

  if (!mountain) {
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
    if (!powderScore) return 'bg-slate-900';

    if (powderScore.score >= 8) {
      return 'bg-gradient-to-br from-blue-900 via-slate-900 to-slate-900';
    } else if (powderScore.score >= 6) {
      return 'bg-gradient-to-br from-purple-900 via-slate-900 to-slate-900';
    } else if (powderScore.score >= 4) {
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

            {/* Mountain Logo */}
            {mountain.logo && (
              <div className="flex-shrink-0">
                <Image
                  src={mountain.logo}
                  alt={`${mountain.name} logo`}
                  width={40}
                  height={40}
                  className="rounded-lg"
                />
              </div>
            )}

            {/* Mountain Selector */}
            <MountainSelector
              selectedId={mountainId}
              onChange={handleMountainChange}
            />

            {/* Status Badge */}
            {(conditions?.liftStatus || mountain.status) && (
              <div className="hidden md:block">
                <MountainStatus
                  status={conditions?.liftStatus ? {
                    isOpen: conditions.liftStatus.isOpen,
                    liftsOpen: `${conditions.liftStatus.liftsOpen}/${conditions.liftStatus.liftsTotal}`,
                    runsOpen: conditions.liftStatus.runsOpen && conditions.liftStatus.runsTotal
                      ? `${conditions.liftStatus.runsOpen}/${conditions.liftStatus.runsTotal}`
                      : undefined,
                    message: conditions.liftStatus.message || undefined,
                    lastUpdated: conditions.liftStatus.lastUpdated,
                    percentOpen: conditions.liftStatus.liftsTotal > 0
                      ? Math.round((conditions.liftStatus.liftsOpen / conditions.liftStatus.liftsTotal) * 100)
                      : undefined,
                  } : mountain.status}
                  variant="compact"
                />
              </div>
            )}

            <div className="ml-auto flex items-center gap-2">
              <NavigateButton
                lat={mountain.location.lat}
                lng={mountain.location.lng}
                mountainName={mountain.name}
                variant="secondary"
                size="sm"
              />
              <a
                href={mountain.website}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-gray-400 hover:text-white transition-colors hidden sm:block"
              >
                Official Site ↗
              </a>
            </div>
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
      </header>

      <main className="max-w-4xl mx-auto px-4 py-6 space-y-6">
        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <div className="flex items-center gap-2 text-gray-400">
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
        ) : error ? (
          <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 text-red-400">
            {error}
          </div>
        ) : (
          <>
            {/* Mountain Status - Mobile */}
            {(conditions?.liftStatus || mountain.status) && (
              <div className="md:hidden">
                <MountainStatus
                  status={conditions?.liftStatus ? {
                    isOpen: conditions.liftStatus.isOpen,
                    liftsOpen: `${conditions.liftStatus.liftsOpen}/${conditions.liftStatus.liftsTotal}`,
                    runsOpen: conditions.liftStatus.runsOpen && conditions.liftStatus.runsTotal
                      ? `${conditions.liftStatus.runsOpen}/${conditions.liftStatus.runsTotal}`
                      : undefined,
                    message: conditions.liftStatus.message || undefined,
                    lastUpdated: conditions.liftStatus.lastUpdated,
                    percentOpen: conditions.liftStatus.liftsTotal > 0
                      ? Math.round((conditions.liftStatus.liftsOpen / conditions.liftStatus.liftsTotal) * 100)
                      : undefined,
                  } : mountain.status}
                  variant="full"
                />
              </div>
            )}

            {/* Weather Alerts */}
            {alerts.length > 0 && (
              <div className="space-y-3">
                {alerts.map((alert) => {
                  const severityColors = {
                    Extreme: 'bg-red-500/20 border-red-500 text-red-200',
                    Severe: 'bg-orange-500/20 border-orange-500 text-orange-200',
                    Moderate: 'bg-yellow-500/20 border-yellow-500 text-yellow-200',
                    Minor: 'bg-blue-500/20 border-blue-500 text-blue-200',
                    Unknown: 'bg-gray-500/20 border-gray-500 text-gray-200',
                  };

                  const colorClass = severityColors[alert.severity as keyof typeof severityColors] || severityColors.Unknown;

                  return (
                    <div key={alert.id} className={`rounded-xl p-4 border-2 ${colorClass}`}>
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
                })}
              </div>
            )}

            {/* Powder Score */}
            {powderScore && (
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

                {/* Navigate CTA */}
                <div className="mb-4">
                  <NavigateButton
                    lat={mountain.location.lat}
                    lng={mountain.location.lng}
                    mountainName={mountain.shortName}
                    variant="primary"
                    size="lg"
                    className="w-full"
                  />
                </div>

                <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                  {powderScore.factors.map((factor: any, i: number) => (
                    <div key={i} className="bg-slate-700/50 rounded-lg p-3">
                      <div className="text-xs text-gray-400 mb-1">{factor.name}</div>
                      <div className="text-sm text-white">{factor.description}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Current Conditions */}
            {conditions && (
              <div className="bg-slate-800 rounded-xl p-6">
                <h2 className="text-lg font-semibold text-white mb-4">Current Conditions</h2>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="bg-slate-700/50 rounded-lg p-4 text-center">
                    <div className="text-3xl mb-1">❄️</div>
                    <div className="text-2xl font-bold text-white">
                      {conditions.snowDepth ?? '--'}&quot;
                    </div>
                    <div className="text-xs text-gray-400">Base Depth</div>
                  </div>
                  <div className="bg-slate-700/50 rounded-lg p-4 text-center">
                    <div className="text-3xl mb-1">🌨️</div>
                    <div className="text-2xl font-bold text-white">
                      {conditions.snowfall24h}&quot;
                    </div>
                    <div className="text-xs text-gray-400">24hr Snowfall</div>
                  </div>
                  <div className="bg-slate-700/50 rounded-lg p-4 text-center">
                    <div className="text-3xl mb-1">🌡️</div>
                    <div className="text-2xl font-bold text-white">
                      {conditions.temperature ?? '--'}°F
                    </div>
                    <div className="text-xs text-gray-400">Temperature</div>
                  </div>
                  <div className="bg-slate-700/50 rounded-lg p-4 text-center">
                    <div className="text-3xl mb-1">💨</div>
                    <div className="text-2xl font-bold text-white">
                      {conditions.wind?.speed ?? '--'} mph
                    </div>
                    <div className="text-xs text-gray-400">
                      Wind {conditions.wind?.direction ?? ''}
                    </div>
                  </div>
                </div>

                {/* Freezing Level / Snow Line */}
                {conditions.freezingLevel !== null && (
                  <div className="mt-4 bg-slate-700/30 rounded-lg p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="text-2xl">🏔️</div>
                        <div>
                          <div className="text-sm font-medium text-white">
                            Snow Line: {conditions.freezingLevel.toLocaleString()}&apos;
                          </div>
                          <div className="text-xs text-gray-400">
                            {conditions.rainRisk?.description ?? 'Freezing level elevation'}
                          </div>
                        </div>
                      </div>
                      {conditions.rainRisk && (
                        <div
                          className={`px-2 py-1 rounded text-xs font-medium ${
                            conditions.rainRisk.score >= 7
                              ? 'bg-green-500/20 text-green-400'
                              : conditions.rainRisk.score >= 4
                                ? 'bg-yellow-500/20 text-yellow-400'
                                : 'bg-red-500/20 text-red-400'
                          }`}
                        >
                          {conditions.rainRisk.score >= 7
                            ? 'All Snow'
                            : conditions.rainRisk.score >= 4
                              ? 'Mixed'
                              : 'Rain Risk'}
                        </div>
                      )}
                    </div>
                    {conditions.elevation && conditions.freezingLevel !== null && (
                      <div className="mt-3 h-2 bg-slate-600 rounded-full overflow-hidden relative">
                        {/* Base to Summit gradient */}
                        <div
                          className="absolute inset-y-0 left-0 bg-gradient-to-r from-blue-500 to-sky-400"
                          style={{
                            width: `${Math.max(0, Math.min(100, ((conditions.freezingLevel - conditions.elevation.base) / (conditions.elevation.summit - conditions.elevation.base)) * 100))}%`,
                          }}
                        />
                        {/* Freezing level marker */}
                        <div
                          className="absolute top-1/2 -translate-y-1/2 w-1 h-4 bg-white rounded-full shadow"
                          style={{
                            left: `${Math.max(0, Math.min(100, ((conditions.freezingLevel - conditions.elevation.base) / (conditions.elevation.summit - conditions.elevation.base)) * 100))}%`,
                          }}
                        />
                      </div>
                    )}
                    {conditions.elevation && (
                      <div className="mt-1 flex justify-between text-xs text-gray-500">
                        <span>Base {conditions.elevation.base.toLocaleString()}&apos;</span>
                        <span>Summit {conditions.elevation.summit.toLocaleString()}&apos;</span>
                      </div>
                    )}
                  </div>
                )}

                {!mountain.snotel && (
                  <p className="mt-4 text-sm text-amber-400/80">
                    Note: Limited SNOTEL data for this mountain. Some values may be estimated.
                  </p>
                )}
              </div>
            )}

            {/* Road & Pass Conditions */}
            {roads && (
              <div className="bg-slate-800 rounded-xl p-6">
                <h2 className="text-lg font-semibold text-white mb-2">Road &amp; Pass Conditions</h2>
                <p className="text-sm text-gray-400 mb-4">
                  Closures and restrictions can change fast. Always verify before you drive.
                </p>

                {!roads.supported ? (
                  <div className="text-gray-300">{roads.message ?? 'Road data not supported for this mountain.'}</div>
                ) : !roads.configured ? (
                  <div className="text-gray-300">{roads.message ?? 'Road data not configured.'}</div>
                ) : roads.passes.length === 0 ? (
                  <div className="text-gray-300">No relevant pass data found.</div>
                ) : (
                  <div className="space-y-3">
                    {roads.passes.slice(0, 2).map((p: any) => (
                      <div key={p.id} className="bg-slate-700/50 rounded-lg p-4">
                        <div className="flex items-center justify-between mb-2">
                          <div className="text-white font-medium">{p.name}</div>
                          <div className="text-xs text-gray-400">{roads.provider ?? ''}</div>
                        </div>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                          <div>
                            <div className="text-xs text-gray-400">Road</div>
                            <div className="text-sm text-white">{p.roadCondition ?? 'Unknown'}</div>
                          </div>
                          <div>
                            <div className="text-xs text-gray-400">Weather</div>
                            <div className="text-sm text-white">{p.weatherCondition ?? 'Unknown'}</div>
                          </div>
                          <div>
                            <div className="text-xs text-gray-400">Pass Temp</div>
                            <div className="text-sm text-white">
                              {(p.temperatureF ?? null) !== null ? `${p.temperatureF}°F` : '—'}
                            </div>
                          </div>
                        </div>

                        {p.restrictions?.length > 0 && (
                          <div className="mt-3 pt-3 border-t border-white/10">
                            <div className="text-xs text-gray-400 mb-1">Restrictions</div>
                            <div className="text-sm text-gray-200 space-y-1">
                              {p.restrictions.slice(0, 3).map((r: any, idx: number) => (
                                <div key={idx}>
                                  <span className="text-gray-400">{r.direction ? `${r.direction}: ` : ''}</span>
                                  <span>{r.text}</span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}

                        {p.travelAdvisoryActive && (
                          <div className="mt-3 text-xs text-amber-300">Travel advisory active</div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* Trip & Traffic */}
            {tripAdvice && (
              <div className="bg-slate-800 rounded-xl p-6">
                <div className="flex items-start justify-between gap-4 mb-3">
                  <div>
                    <h2 className="text-lg font-semibold text-white">Trip &amp; Traffic</h2>
                    <p className="text-sm text-gray-400">Heuristic guidance based on weather + powder demand.</p>
                  </div>
                  <div className="flex gap-2">
                    <span className="text-xs px-2 py-1 rounded border border-slate-600 text-gray-200 bg-slate-700/40">
                      Traffic: {tripAdvice.trafficRisk}
                    </span>
                    <span className="text-xs px-2 py-1 rounded border border-slate-600 text-gray-200 bg-slate-700/40">
                      Roads: {tripAdvice.roadRisk}
                    </span>
                  </div>
                </div>

                <div className="text-gray-200 text-sm font-medium mb-3">{tripAdvice.headline}</div>

                {tripAdvice.suggestedDepartures?.length > 0 && (
                  <div className="bg-slate-700/50 rounded-lg p-4 mb-3">
                    <div className="text-xs text-gray-400 mb-2">Suggested timing</div>
                    <div className="space-y-1 text-sm text-gray-200">
                      {tripAdvice.suggestedDepartures.slice(0, 2).map((s: any, idx: number) => (
                        <div key={idx}>
                          <span className="text-gray-400">{s.from}: </span>
                          <span>{s.suggestion}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {tripAdvice.notes?.length > 0 && (
                  <div className="text-sm text-gray-300 space-y-1">
                    {tripAdvice.notes.slice(0, 3).map((n: any, idx: number) => (
                      <div key={idx}>• {n}</div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* Powder Day Planner */}
            {powderDayPlan && powderDayPlan.days?.length > 0 && (
              <div className="bg-slate-800 rounded-xl p-6">
                <h2 className="text-lg font-semibold text-white mb-2">Powder Day Planner</h2>
                <p className="text-sm text-gray-400 mb-4">
                  Prediction-style view combining forecast + travel considerations.
                </p>

                <div className="grid md:grid-cols-3 gap-3">
                  {powderDayPlan.days.slice(0, 3).map((d: any, idx: number) => (
                    <div key={idx} className="bg-slate-700/50 rounded-lg p-4">
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <div className="text-white font-medium">
                            {idx === 0 ? 'Today' : d.dayOfWeek}
                          </div>
                          <div className="text-xs text-gray-400">{d.forecastSnapshot.conditions}</div>
                        </div>
                        <div className="text-right">
                          <div className="text-2xl font-bold text-white">{d.predictedPowderScore}/10</div>
                          <div className="text-xs text-gray-400">Conf {d.confidence}%</div>
                        </div>
                      </div>

                      <div className="text-xs text-gray-300 mb-2">
                        {d.forecastSnapshot.snowfall}&quot; snow • {d.forecastSnapshot.high}°/{d.forecastSnapshot.low}° • {d.forecastSnapshot.windSpeed} mph
                      </div>

                      <div className="text-sm text-gray-200">
                        <span className="text-gray-400">Window: </span>
                        <span>{d.bestWindow}</span>
                      </div>

                      {d.travelNotes?.length > 0 && (
                        <div className="mt-2 text-xs text-gray-400 space-y-1">
                          {d.travelNotes.slice(0, 2).map((n: any, i: number) => (
                            <div key={i}>• {n}</div>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* 7-Day Forecast */}
            {forecast.length > 0 && (
              <div className="bg-slate-800 rounded-xl p-6">
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-lg font-semibold text-white">7-Day Forecast</h2>
                  {weatherGovLinks && (
                    <div className="flex gap-2">
                      <a
                        href={weatherGovLinks.hourly}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-xs px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-700 text-white transition-colors flex items-center gap-1"
                      >
                        <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                        </svg>
                        Hourly
                      </a>
                      <a
                        href={weatherGovLinks.forecast}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-xs px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-700 text-white transition-colors flex items-center gap-1"
                      >
                        Weather.gov
                        <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                        </svg>
                      </a>
                    </div>
                  )}
                </div>
                <div className="grid grid-cols-7 gap-2">
                  {forecast.map((day, i) => (
                    <div
                      key={i}
                      className="bg-slate-700/50 rounded-lg p-3 text-center"
                    >
                      <div className="text-xs text-gray-400 mb-1">{day.dayOfWeek}</div>
                      <div className="text-2xl mb-1">{getWeatherIcon(day.icon)}</div>
                      <div className="text-sm text-white font-medium">
                        {day.high}° / {day.low}°
                      </div>
                      {day.snowfall > 0 && (
                        <div className="text-xs text-sky-400 mt-1">
                          {day.snowfall}&quot; snow
                        </div>
                      )}
                    </div>
                  ))}
                </div>
                <div className="mt-4 pt-4 border-t border-slate-700 flex items-center justify-between text-xs text-gray-400">
                  <div className="flex items-center gap-2">
                    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                    </svg>
                    <span>Powered by NOAA Weather.gov</span>
                  </div>
                  {weatherGovLinks && (
                    <a
                      href={weatherGovLinks.discussion}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="hover:text-gray-300 transition-colors underline"
                    >
                      Forecast Discussion
                    </a>
                  )}
                </div>
              </div>
            )}

            {/* Webcams */}
            {mountain.webcams.length > 0 && (
              <div className="bg-slate-800 rounded-xl p-6">
                <h2 className="text-lg font-semibold text-white mb-4">Webcams</h2>
                <div className="grid md:grid-cols-2 gap-4">
                  {mountain.webcams.map((webcam) => (
                    <div key={webcam.id} className="bg-slate-700/50 rounded-lg overflow-hidden">
                      <div className="aspect-video bg-slate-700 relative">
                        <img
                          src={webcam.url}
                          alt={webcam.name}
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = 'none';
                          }}
                        />
                      </div>
                      <div className="p-3">
                        <div className="text-sm text-white font-medium">{webcam.name}</div>
                        {webcam.refreshUrl && (
                          <a
                            href={webcam.refreshUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-xs text-sky-400 hover:text-sky-300"
                          >
                            View on website ↗
                          </a>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Mountain Info */}
            <div className="bg-slate-800 rounded-xl p-6">
              <h2 className="text-lg font-semibold text-white mb-4">Mountain Info</h2>
              <div className="grid md:grid-cols-2 gap-4 text-sm">
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Base Elevation</span>
                    <span className="text-white">
                      {mountain.elevation.base.toLocaleString()}ft
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Summit Elevation</span>
                    <span className="text-white">
                      {mountain.elevation.summit.toLocaleString()}ft
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Vertical Drop</span>
                    <span className="text-white">
                      {(mountain.elevation.summit - mountain.elevation.base).toLocaleString()}ft
                    </span>
                  </div>
                </div>
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Region</span>
                    <span className="text-white capitalize">{mountain.region}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">SNOTEL Station</span>
                    <span className="text-white">
                      {mountain.snotel?.stationName ?? 'N/A'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">NOAA Grid</span>
                    <span className="text-white">
                      {mountain.noaa ? `${mountain.noaa.gridOffice}/${mountain.noaa.gridX},${mountain.noaa.gridY}` : 'N/A'}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  );
}
