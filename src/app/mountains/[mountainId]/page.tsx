'use client';

import { useState, useEffect, useLayoutEffect, use, useMemo } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { getMountain } from '@shredders/shared';
import { Shield, Home, History, Camera } from 'lucide-react';
import { MountainSelector } from '@/components/MountainSelector';
import { useMountain } from '@/context/MountainContext';
import { useMountainData } from '@/hooks/useMountainData';
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

type RoadsResponse = Array<{
  id: number;
  name: string;
  dateUpdated?: string | null;
  roadCondition?: string | null;
  weatherCondition?: string | null;
  temperatureF?: number | null;
  travelAdvisoryActive?: boolean | null;
  restrictions: Array<{ direction?: string | null; text?: string | null }>;
}>;

interface TripAdviceResponse {
  generated: string;
  headline: string;
  todayOutlook: string;
  weekAhead: string;
  uncertainty: string;
  bestDay: string;
  recommendation: string;
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
  const extendedForecast = mountainData?.extendedForecast || null;
  const ensemble = mountainData?.ensemble || null;
  const elevationForecast = mountainData?.elevationForecast || null;
  const error = dataError ? 'Failed to load mountain data' : null;
  const [forecastTab, setForecastTab] = useState<'7day' | 'elevation' | 'confidence' | 'extended'>('7day');
  const forecastTabs = useMemo(() => {
    const tabs: { id: typeof forecastTab; label: string }[] = [];
    if (forecast.length > 0) tabs.push({ id: '7day', label: '7-Day' });
    if (elevationForecast) tabs.push({ id: 'elevation', label: 'Elevation' });
    if (ensemble?.days?.length > 0) tabs.push({ id: 'confidence', label: 'Confidence' });
    if (extendedForecast && extendedForecast.length > 7) tabs.push({ id: 'extended', label: 'Extended' });
    return tabs;
  }, [forecast, elevationForecast, ensemble, extendedForecast]);

  // Reset forecast tab when switching mountains or when current tab is unavailable
  useEffect(() => {
    if (forecastTabs.length > 0 && !forecastTabs.some(t => t.id === forecastTab)) {
      setForecastTab(forecastTabs[0].id);
    }
  }, [forecastTabs, forecastTab]);

  if (!mountain) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-semibold text-text-primary mb-2">Mountain Not Found</h1>
          <p className="text-text-secondary mb-4">
            The mountain &quot;{mountainId}&quot; doesn&apos;t exist.
          </p>
          <Link
            href="/mountains"
            className="text-accent hover:text-accent-hover transition-colors"
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

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-[var(--header-bg)] backdrop-blur-xl backdrop-saturate-150 border-b border-border-secondary">
        <div className="max-w-4xl mx-auto px-4 py-3">
          <div className="flex items-center gap-2">
            <Link
              href="/mountains"
              className="text-text-secondary hover:text-text-primary transition-colors"
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
                  width={32}
                  height={32}
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
                className="text-sm text-text-secondary hover:text-text-primary transition-colors hidden sm:block"
              >
                Official Site ↗
              </a>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="max-w-4xl mx-auto px-4">
          <nav className="flex gap-1 border-t border-border-secondary pt-2 pb-2 overflow-x-auto">
            <Link
              href={`/mountains/${mountainId}`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors bg-accent-subtle text-accent"
            >
              <Home className="w-4 h-4" />
              Overview
            </Link>
            <Link
              href={`/mountains/${mountainId}/patrol`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-secondary hover:text-text-primary hover:bg-surface-primary/50"
            >
              <Shield className="w-4 h-4" />
              Patrol
            </Link>
            <Link
              href={`/mountains/${mountainId}/history`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-secondary hover:text-text-primary hover:bg-surface-primary/50"
            >
              <History className="w-4 h-4" />
              History
            </Link>
            <Link
              href={`/mountains/${mountainId}/webcams`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-secondary hover:text-text-primary hover:bg-surface-primary/50"
            >
              <Camera className="w-4 h-4" />
              Webcams
            </Link>
          </nav>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-4 space-y-3">
        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <div className="flex items-center gap-2 text-text-secondary">
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
          <div className="bg-red-500/10 border border-red-500/30 rounded-2xl p-4 text-red-400">
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
                    Unknown: 'bg-gray-500/20 border-gray-500 text-text-primary',
                  };

                  const colorClass = severityColors[alert.severity as keyof typeof severityColors] || severityColors.Unknown;

                  return (
                    <div key={alert.id} className={`rounded-2xl p-4 border-2 ${colorClass}`}>
                      <div className="flex items-start gap-3">
                        <div className="text-2xl">⚠️</div>
                        <div className="flex-1">
                          <h3 className="font-semibold text-lg mb-1">{alert.event}</h3>
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
              <div className="bg-surface-primary rounded-xl p-4">
                <div className="flex items-center gap-3">
                  <div
                    className={`text-3xl font-bold ${
                      powderScore.score >= 7
                        ? 'text-green-400'
                        : powderScore.score >= 5
                          ? 'text-yellow-400'
                          : 'text-red-400'
                    }`}
                  >
                    {powderScore.score.toFixed(1)}
                    <span className="text-sm text-text-tertiary">/10</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium text-text-primary">{powderScore.verdict}</div>
                    <div className="flex flex-wrap gap-x-3 gap-y-0.5 mt-0.5">
                      {powderScore.factors.map((factor: any, i: number) => (
                        <span key={i} className="text-[11px] text-text-tertiary">{factor.description}</span>
                      ))}
                    </div>
                  </div>
                  <NavigateButton
                    lat={mountain.location.lat}
                    lng={mountain.location.lng}
                    mountainName={mountain.shortName}
                    variant="primary"
                    size="sm"
                  />
                </div>
              </div>
            )}

            {/* Current Conditions - Compact */}
            {conditions && (
              <div className="bg-surface-primary rounded-xl p-4">
                <div className="flex items-center justify-between mb-3">
                  <h2 className="text-sm font-semibold text-text-primary">Conditions</h2>
                  {conditions.rainRisk && (
                    <div
                      className={`px-2 py-0.5 rounded text-[11px] font-medium ${
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
                <div className="grid grid-cols-4 gap-2 text-center">
                  <div>
                    <div className="text-lg font-semibold text-text-primary">{conditions.snowDepth ?? '--'}&quot;</div>
                    <div className="text-[10px] text-text-tertiary">Depth</div>
                  </div>
                  <div>
                    <div className="text-lg font-semibold text-accent">{conditions.snowfall24h}&quot;</div>
                    <div className="text-[10px] text-text-tertiary">24h Snow</div>
                  </div>
                  <div>
                    <div className="text-lg font-semibold text-text-primary">{conditions.temperature ?? '--'}°</div>
                    <div className="text-[10px] text-text-tertiary">Temp</div>
                  </div>
                  <div>
                    <div className="text-lg font-semibold text-text-primary">{conditions.wind?.speed ?? '--'}</div>
                    <div className="text-[10px] text-text-tertiary">Wind mph</div>
                  </div>
                </div>

                {/* Snow Line Bar */}
                {conditions.freezingLevel !== null && conditions.elevation && (
                  <div className="mt-3">
                    <div className="flex items-center justify-between text-[11px] mb-1">
                      <span className="text-text-tertiary">Snow line {conditions.freezingLevel.toLocaleString()}&apos;</span>
                      <span className="text-text-quaternary">{conditions.elevation.base.toLocaleString()}&apos; — {conditions.elevation.summit.toLocaleString()}&apos;</span>
                    </div>
                    <div className="h-1.5 bg-surface-tertiary rounded-full overflow-hidden relative">
                      <div
                        className="absolute inset-y-0 left-0 bg-gradient-to-r from-blue-500 to-sky-400"
                        style={{
                          width: `${Math.max(0, Math.min(100, ((conditions.freezingLevel - conditions.elevation.base) / (conditions.elevation.summit - conditions.elevation.base)) * 100))}%`,
                        }}
                      />
                    </div>
                  </div>
                )}

                {!mountain.snotel && (
                  <p className="mt-2 text-[11px] text-amber-400/80">Limited SNOTEL data. Some values may be estimated.</p>
                )}
              </div>
            )}

            {/* Road & Pass Conditions */}
            {roads && Array.isArray(roads) && roads.length > 0 && (
              <div className="bg-surface-primary rounded-xl p-4">
                <h2 className="text-sm font-semibold text-text-primary mb-2">Roads</h2>
                <div className="space-y-2">
                  {roads.slice(0, 2).map((p: any) => (
                    <div key={p.id} className="bg-surface-secondary rounded-lg p-3">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-sm font-medium text-text-primary">{p.name}</span>
                        {p.travelAdvisoryActive && (
                          <span className="text-[10px] text-amber-300 bg-amber-500/10 px-1.5 py-0.5 rounded">Advisory</span>
                        )}
                      </div>
                      <div className="flex gap-4 text-xs">
                        <span className="text-text-secondary">Road: <span className="text-text-primary">{p.roadCondition ?? '—'}</span></span>
                        <span className="text-text-secondary">Weather: <span className="text-text-primary">{p.weatherCondition ?? '—'}</span></span>
                        {(p.temperatureF ?? null) !== null && (
                          <span className="text-text-secondary">{p.temperatureF}°F</span>
                        )}
                      </div>
                      {p.restrictions?.length > 0 && (
                        <div className="mt-1.5 text-[11px] text-text-secondary">
                          {p.restrictions.slice(0, 2).map((r: any, idx: number) => (
                            <span key={idx}>{idx > 0 ? ' · ' : ''}{r.direction ? `${r.direction}: ` : ''}{r.text}</span>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Trip Advice (AI) */}
            {tripAdvice && (
              <div className="bg-surface-primary rounded-xl p-4">
                <div className="flex items-center gap-2 mb-2">
                  <h2 className="text-sm font-semibold text-text-primary">Trip Advice</h2>
                  {tripAdvice.bestDay && (
                    <span className="text-[10px] px-1.5 py-0.5 rounded bg-accent/10 text-accent">Best: {tripAdvice.bestDay}</span>
                  )}
                </div>
                <p className="text-sm font-medium text-text-primary">{tripAdvice.headline}</p>
                {tripAdvice.todayOutlook && (
                  <p className="text-xs text-text-secondary mt-1">{tripAdvice.todayOutlook}</p>
                )}
                {tripAdvice.weekAhead && (
                  <p className="text-xs text-text-tertiary mt-1">{tripAdvice.weekAhead}</p>
                )}
                {tripAdvice.recommendation && (
                  <p className="text-xs text-accent mt-1.5">{tripAdvice.recommendation}</p>
                )}
              </div>
            )}

            {/* Forecast — Tabbed */}
            {forecastTabs.length > 0 && (
              <div className="bg-surface-primary rounded-xl p-4">
                {/* Tab bar */}
                <div className="flex items-center justify-between mb-3">
                  <div className="flex gap-1">
                    {forecastTabs.map((tab) => (
                      <button
                        key={tab.id}
                        onClick={() => setForecastTab(tab.id)}
                        className={`px-2.5 py-1 rounded-md text-xs font-medium transition-colors ${
                          forecastTab === tab.id
                            ? 'bg-accent text-text-primary'
                            : 'text-text-tertiary hover:text-text-primary hover:bg-surface-secondary'
                        }`}
                      >
                        {tab.label}
                      </button>
                    ))}
                  </div>
                  {forecastTab === '7day' && weatherGovLinks && (
                    <div className="flex gap-1.5">
                      <a href={weatherGovLinks.hourly} target="_blank" rel="noopener noreferrer" className="text-[10px] px-2 py-1 rounded bg-surface-secondary text-text-secondary hover:text-text-primary transition-colors">Hourly</a>
                      <a href={weatherGovLinks.forecast} target="_blank" rel="noopener noreferrer" className="text-[10px] px-2 py-1 rounded bg-surface-secondary text-text-secondary hover:text-text-primary transition-colors">Weather.gov</a>
                    </div>
                  )}
                </div>

                {/* 7-Day content */}
                {forecastTab === '7day' && forecast.length > 0 && (
                  <div className="grid grid-cols-4 sm:grid-cols-7 gap-1.5">
                    {forecast.map((day, i) => (
                      <div key={i} className="bg-surface-secondary rounded-lg p-2 text-center">
                        <div className="text-[10px] text-text-tertiary">{day.dayOfWeek}</div>
                        <div className="text-lg my-0.5">{getWeatherIcon(day.icon)}</div>
                        <div className="text-xs font-medium text-text-primary">{day.high}°/{day.low}°</div>
                        {day.snowfall > 0 && (
                          <div className="text-[11px] text-accent">{day.snowfall}&quot;</div>
                        )}
                      </div>
                    ))}
                  </div>
                )}

                {/* Elevation content */}
                {forecastTab === 'elevation' && elevationForecast && (
                  <>
                    <div className="grid grid-cols-3 gap-2 mb-3">
                      {(['summit', 'mid', 'base'] as const).map((band) => {
                        const data = elevationForecast[band];
                        if (!data || !data.days?.length) return null;
                        const today = data.days[0];
                        const label = band === 'summit' ? 'Summit' : band === 'mid' ? 'Mid' : 'Base';
                        const precipColor = today.precipType === 'snow' ? 'text-accent' : today.precipType === 'rain' ? 'text-red-400' : 'text-yellow-400';
                        return (
                          <div key={band} className="bg-surface-secondary rounded-lg p-2.5 text-center">
                            <div className="text-[10px] text-text-tertiary">{label} · {data.elevation.toLocaleString()}&apos;</div>
                            <div className="text-base font-semibold text-text-primary">{today.highTemp}°/{today.lowTemp}°</div>
                            {today.snowfall > 0 && <div className={`text-[11px] ${precipColor}`}>{today.snowfall}&quot; snow</div>}
                            {today.precipitation > 0 && today.precipType !== 'snow' && <div className={`text-[11px] ${precipColor}`}>{today.precipitation}&quot; {today.precipType}</div>}
                          </div>
                        );
                      })}
                    </div>
                    {elevationForecast.summit.days.length > 1 && (
                      <table className="w-full text-xs">
                        <thead>
                          <tr className="text-text-quaternary text-[10px]">
                            <th className="text-left py-1 pr-2 font-medium">Day</th>
                            <th className="text-center py-1 px-1 font-medium">Summit</th>
                            <th className="text-center py-1 px-1 font-medium">Mid</th>
                            <th className="text-center py-1 px-1 font-medium">Base</th>
                          </tr>
                        </thead>
                        <tbody>
                          {elevationForecast.summit.days.slice(1, 6).map((day: any, i: number) => {
                            const mid = elevationForecast.mid.days[i + 1];
                            const base = elevationForecast.base.days[i + 1];
                            const dayLabel = new Date(day.date).toLocaleDateString('en-US', { weekday: 'short' });
                            return (
                              <tr key={day.date} className="border-t border-border-secondary">
                                <td className="py-1 pr-2 text-text-secondary">{dayLabel}</td>
                                <td className="py-1 px-1 text-center text-text-primary">
                                  {day.snowfall > 0 ? <span className="text-accent">{day.snowfall}&quot;</span> : `${day.highTemp}°`}
                                </td>
                                <td className="py-1 px-1 text-center text-text-primary">
                                  {mid?.snowfall > 0 ? <span className="text-accent">{mid.snowfall}&quot;</span> : `${mid?.highTemp ?? '--'}°`}
                                </td>
                                <td className="py-1 px-1 text-center text-text-primary">
                                  {base?.snowfall > 0 ? <span className="text-accent">{base.snowfall}&quot;</span> : `${base?.highTemp ?? '--'}°`}
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    )}
                  </>
                )}

                {/* Confidence (ensemble) content */}
                {forecastTab === 'confidence' && ensemble?.days?.length > 0 && (
                  <>
                    <p className="text-[10px] text-text-quaternary mb-2">{ensemble.memberCount}-member {ensemble.model} ensemble</p>
                    <div className="space-y-1.5">
                      {ensemble.days.slice(0, 7).map((day: any) => {
                        const dayLabel = new Date(day.date).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
                        const maxSnow = Math.max(...ensemble.days.slice(0, 7).map((d: any) => d.snowfall.p90), 1);
                        return (
                          <div key={day.date} className="flex items-center gap-2">
                            <div className="w-[72px] text-[11px] text-text-secondary flex-shrink-0">{dayLabel}</div>
                            <div className="flex-1 h-4 bg-surface-secondary rounded-full overflow-hidden relative">
                              <div className="absolute inset-y-0 bg-accent/30 rounded-full" style={{ left: `${(day.snowfall.p10 / maxSnow) * 100}%`, width: `${((day.snowfall.p90 - day.snowfall.p10) / maxSnow) * 100}%` }} />
                              <div className="absolute inset-y-0 bg-accent/60 rounded-full" style={{ left: `${(day.snowfall.p25 / maxSnow) * 100}%`, width: `${((day.snowfall.p75 - day.snowfall.p25) / maxSnow) * 100}%` }} />
                              <div className="absolute top-0.5 bottom-0.5 w-0.5 bg-accent rounded-full" style={{ left: `${(day.snowfall.p50 / maxSnow) * 100}%` }} />
                            </div>
                            <div className="w-14 text-[11px] text-text-primary text-right flex-shrink-0">
                              {day.snowfall.p50}&quot; <span className="text-text-quaternary">({day.snowfall.p10}-{day.snowfall.p90})</span>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                    {ensemble.days[0] && (
                      <div className="mt-3 pt-3 border-t border-border-secondary flex flex-wrap gap-2">
                        {[
                          { label: '1"+', value: ensemble.days[0].probability.over1in },
                          { label: '3"+', value: ensemble.days[0].probability.over3in },
                          { label: '6"+', value: ensemble.days[0].probability.over6in },
                          { label: '12"+', value: ensemble.days[0].probability.over12in },
                        ].filter(p => p.value > 0).map((p) => (
                          <div key={p.label} className="bg-surface-secondary rounded px-2 py-1 text-center">
                            <span className="text-[10px] text-text-tertiary">{p.label} </span>
                            <span className="text-xs font-semibold text-text-primary">{p.value}%</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </>
                )}

                {/* Extended content */}
                {forecastTab === 'extended' && extendedForecast && extendedForecast.length > 7 && (
                  <>
                    <div className="overflow-x-auto -mx-1">
                      <div className="flex gap-1.5 px-1">
                        {extendedForecast.slice(7).map((day: any, i: number) => {
                          const dayLabel = new Date(day.date).toLocaleDateString('en-US', { weekday: 'short' });
                          const dateLabel = new Date(day.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
                          return (
                            <div key={i} className="bg-surface-secondary rounded-lg p-2 text-center flex-shrink-0 w-16">
                              <div className="text-[9px] text-text-quaternary">{dayLabel}</div>
                              <div className="text-[9px] text-text-quaternary">{dateLabel}</div>
                              <div className="text-xs font-medium text-text-primary mt-0.5">{day.highTemp}°/{day.lowTemp}°</div>
                              {day.snowfallSum > 0 && <div className="text-[10px] text-accent">{day.snowfallSum}&quot;</div>}
                              {day.precipProbability > 0 && <div className="text-[9px] text-text-quaternary">{day.precipProbability}%</div>}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                    <div className="mt-2 text-[10px] text-text-quaternary">Days 8-16 via Open-Meteo. Confidence decreases beyond 7 days.</div>
                  </>
                )}
              </div>
            )}

            {/* Webcams */}
            {mountain.webcams.length > 0 && (
              <div className="bg-surface-primary rounded-xl p-4">
                <h2 className="text-sm font-semibold text-text-primary mb-3">Webcams</h2>
                <div className="grid grid-cols-2 gap-2">
                  {mountain.webcams.map((webcam) => (
                    <a key={webcam.id} href={webcam.refreshUrl || '#'} target="_blank" rel="noopener noreferrer" className="block rounded-lg overflow-hidden group">
                      <div className="aspect-video bg-surface-secondary relative">
                        <img
                          src={webcam.url}
                          alt={webcam.name}
                          className="w-full h-full object-cover"
                          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                        />
                      </div>
                      <div className="py-1.5 px-0.5">
                        <div className="text-[11px] text-text-secondary group-hover:text-text-primary transition-colors truncate">{webcam.name}</div>
                      </div>
                    </a>
                  ))}
                </div>
              </div>
            )}

            {/* Mountain Info — Compact */}
            <div className="bg-surface-primary rounded-xl p-4">
              <h2 className="text-sm font-semibold text-text-primary mb-2">Info</h2>
              <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs">
                <span className="text-text-secondary">Base <span className="text-text-primary">{mountain.elevation.base.toLocaleString()}&apos;</span></span>
                <span className="text-text-secondary">Summit <span className="text-text-primary">{mountain.elevation.summit.toLocaleString()}&apos;</span></span>
                <span className="text-text-secondary">Vert <span className="text-text-primary">{(mountain.elevation.summit - mountain.elevation.base).toLocaleString()}&apos;</span></span>
                <span className="text-text-secondary">Region <span className="text-text-primary capitalize">{mountain.region}</span></span>
                {mountain.snotel && <span className="text-text-secondary">SNOTEL <span className="text-text-primary">{mountain.snotel.stationName}</span></span>}
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  );
}
