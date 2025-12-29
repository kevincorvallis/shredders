'use client';

import { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { MountainMap } from '@/components/MountainMapLoader';
import { Intro } from '@/components/Intro';
import { SnowfallTable } from '@/components/SnowfallTable';
import { getAllMountains, getMountainsByRegion, type MountainConfig } from '@/data/mountains';
import { getPowderScoreStyle } from '@/lib/design-tokens';
import { prefetchMountainData } from '@/lib/hooks/useMountainData';
import {
  Mountain,
  Snowflake,
  Wind,
  Thermometer,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  MapPin,
  MessageSquare,
  BarChart3,
  Calendar,
  Clock,
  ChevronRight,
  RefreshCw,
  Navigation,
  CloudSnow,
  Sun,
  Cloud,
  CloudRain,
  Cloudy,
} from 'lucide-react';

// Types
interface MountainData {
  id: string;
  name: string;
  shortName: string;
  region: string;
  color: string;
  elevation: { base: number; summit: number };
  powderScore?: number;
  conditions?: {
    snowDepth: number;
    snowfall24h: number;
    snowfall48h: number;
    temperature: number;
    windSpeed: number;
    windDirection: string;
    conditions: string;
  };
  forecast?: Array<{
    date: string;
    dayOfWeek: string;
    high: number;
    low: number;
    snowfall: number;
    conditions: string;
    icon: string;
  }>;
  alerts?: Array<{
    type: string;
    severity: string;
    title: string;
    message: string;
  }>;
}

interface RegionSummary {
  region: string;
  displayName: string;
  mountains: MountainData[];
  avgScore: number;
  totalSnowfall24h: number;
  bestMountain: MountainData | null;
}

// Weather icon component
function WeatherIcon({ icon, className = "w-5 h-5" }: { icon: string; className?: string }) {
  switch (icon) {
    case 'snow':
      return <CloudSnow className={className} />;
    case 'rain':
      return <CloudRain className={className} />;
    case 'sun':
      return <Sun className={className} />;
    case 'cloud':
      return <Cloud className={className} />;
    default:
      return <Cloudy className={className} />;
  }
}

// Powder Score Ring Component
function PowderScoreRing({ score, size = 'md' }: { score: number; size?: 'sm' | 'md' | 'lg' }) {
  const style = getPowderScoreStyle(score);
  const sizeClasses = {
    sm: 'w-12 h-12 text-lg',
    md: 'w-20 h-20 text-2xl',
    lg: 'w-28 h-28 text-4xl',
  };
  const strokeWidth = size === 'lg' ? 4 : size === 'md' ? 3 : 2;
  const radius = size === 'lg' ? 50 : size === 'md' ? 36 : 22;
  const circumference = 2 * Math.PI * radius;
  const progress = (score / 10) * circumference;

  return (
    <div className={`relative ${sizeClasses[size]} flex items-center justify-center`}>
      <svg className="absolute inset-0 -rotate-90" viewBox="0 0 120 120">
        <circle
          cx="60"
          cy="60"
          r={radius}
          fill="none"
          stroke="currentColor"
          strokeWidth={strokeWidth}
          className="text-slate-700"
        />
        <circle
          cx="60"
          cy="60"
          r={radius}
          fill="none"
          stroke="currentColor"
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={circumference - progress}
          strokeLinecap="round"
          className={style.color}
        />
      </svg>
      <span className={`font-bold ${style.color}`}>{score.toFixed(1)}</span>
    </div>
  );
}

// Mountain Mini Card
function MountainMiniCard({ mountain, onClick }: { mountain: MountainData; onClick: () => void }) {
  const style = mountain.powderScore ? getPowderScoreStyle(mountain.powderScore) : null;

  return (
    <button
      onClick={onClick}
      onMouseEnter={() => prefetchMountainData(mountain.id)}
      onFocus={() => prefetchMountainData(mountain.id)}
      className="flex items-center gap-3 p-3 bg-slate-800/50 hover:bg-slate-700/50 rounded-lg border border-slate-700/50 hover:border-slate-600 transition-all w-full text-left group"
    >
      <div
        className="w-2 h-8 rounded-full flex-shrink-0"
        style={{ backgroundColor: mountain.color }}
      />
      <div className="flex-1 min-w-0">
        <div className="text-sm font-medium text-white truncate group-hover:text-sky-400 transition-colors">
          {mountain.shortName}
        </div>
        <div className="text-xs text-slate-400">
          {mountain.conditions?.snowfall24h ?? 0}" new
        </div>
      </div>
      {mountain.powderScore !== undefined && (
        <div className={`text-lg font-bold ${style?.color ?? 'text-slate-400'}`}>
          {mountain.powderScore.toFixed(1)}
        </div>
      )}
    </button>
  );
}

// Alert Banner Component
function AlertBanner({ alerts }: { alerts: Array<{ mountain: string; type: string; severity: string; title: string; message: string }> }) {
  if (alerts.length === 0) return null;

  const highSeverityAlerts = alerts.filter(a => a.severity === 'high' || a.severity === 'extreme');
  if (highSeverityAlerts.length === 0) return null;

  return (
    <div className="bg-gradient-to-r from-red-500/20 via-orange-500/20 to-red-500/20 border border-red-500/30 rounded-xl p-4 mb-6">
      <div className="flex items-start gap-3">
        <AlertTriangle className="w-5 h-5 text-red-400 flex-shrink-0 mt-0.5" />
        <div className="flex-1">
          <h3 className="text-red-400 font-semibold mb-2">Active Alerts ({highSeverityAlerts.length})</h3>
          <div className="space-y-2">
            {highSeverityAlerts.slice(0, 3).map((alert, i) => (
              <div key={i} className="text-sm">
                <span className="text-white font-medium">{alert.mountain}:</span>{' '}
                <span className="text-slate-300">{alert.title} - {alert.message}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// Region Card Component
function RegionCard({ region, onMountainClick }: { region: RegionSummary; onMountainClick: (id: string) => void }) {
  const style = region.avgScore ? getPowderScoreStyle(region.avgScore) : null;

  return (
    <Card className="bg-slate-900/50 border-slate-800 overflow-hidden">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg">{region.displayName}</CardTitle>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="text-xs">
              {region.mountains.length} resorts
            </Badge>
            {region.avgScore > 0 && (
              <span className={`text-lg font-bold ${style?.color}`}>
                {region.avgScore.toFixed(1)}
              </span>
            )}
          </div>
        </div>
        {region.totalSnowfall24h > 0 && (
          <div className="flex items-center gap-1 text-sm text-sky-400">
            <Snowflake className="w-3 h-3" />
            {region.totalSnowfall24h}" total across region
          </div>
        )}
      </CardHeader>
      <CardContent className="pt-0">
        <div className="grid gap-2">
          {region.mountains
            .sort((a, b) => (b.powderScore ?? 0) - (a.powderScore ?? 0))
            .slice(0, 4)
            .map((mountain) => (
              <MountainMiniCard
                key={mountain.id}
                mountain={mountain}
                onClick={() => onMountainClick(mountain.id)}
              />
            ))}
        </div>
        {region.mountains.length > 4 && (
          <Link
            href="/mountains"
            className="flex items-center justify-center gap-1 mt-3 text-sm text-slate-400 hover:text-white transition-colors"
          >
            View all {region.mountains.length} mountains
            <ChevronRight className="w-4 h-4" />
          </Link>
        )}
      </CardContent>
    </Card>
  );
}

// Forecast Preview Component
function ForecastPreview({ forecasts }: { forecasts: Array<{ mountain: string; color: string; days: Array<{ dayOfWeek: string; snowfall: number; icon: string }> }> }) {
  const days = ['Today', 'Tomorrow', 'Day 3'];

  // Aggregate snowfall by day
  const aggregatedDays = days.map((dayLabel, idx) => {
    let totalSnow = 0;
    let dominantIcon = 'cloud';
    const snowCounts: Record<string, number> = {};

    forecasts.forEach(f => {
      if (f.days[idx]) {
        totalSnow += f.days[idx].snowfall;
        const icon = f.days[idx].icon;
        snowCounts[icon] = (snowCounts[icon] || 0) + 1;
      }
    });

    // Find most common icon
    let maxCount = 0;
    Object.entries(snowCounts).forEach(([icon, count]) => {
      if (count > maxCount) {
        maxCount = count;
        dominantIcon = icon;
      }
    });

    return { dayLabel, totalSnow, dominantIcon, dayOfWeek: forecasts[0]?.days[idx]?.dayOfWeek || dayLabel };
  });

  return (
    <Card className="bg-slate-900/50 border-slate-800">
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg flex items-center gap-2">
            <Calendar className="w-5 h-5 text-sky-400" />
            3-Day Outlook
          </CardTitle>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-3 gap-4">
          {aggregatedDays.map((day, i) => (
            <div key={i} className="text-center p-4 bg-slate-800/50 rounded-lg">
              <div className="text-xs text-slate-400 mb-2">{day.dayLabel}</div>
              <WeatherIcon icon={day.dominantIcon} className="w-8 h-8 mx-auto mb-2 text-slate-300" />
              {day.totalSnow > 0 ? (
                <div className="text-xl font-bold text-sky-400">{day.totalSnow.toFixed(0)}"</div>
              ) : (
                <div className="text-xl font-bold text-slate-500">--</div>
              )}
              <div className="text-xs text-slate-500">total snow</div>
            </div>
          ))}
        </div>

        {/* Individual mountain snowfall */}
        <div className="mt-4 pt-4 border-t border-slate-800">
          <div className="text-xs text-slate-400 mb-2">Expected Snowfall by Resort</div>
          <div className="space-y-2 max-h-32 overflow-y-auto">
            {forecasts
              .filter(f => f.days.some(d => d.snowfall > 0))
              .sort((a, b) => {
                const aTotal = a.days.reduce((sum, d) => sum + d.snowfall, 0);
                const bTotal = b.days.reduce((sum, d) => sum + d.snowfall, 0);
                return bTotal - aTotal;
              })
              .slice(0, 5)
              .map((f, i) => {
                const total = f.days.reduce((sum, d) => sum + d.snowfall, 0);
                return (
                  <div key={i} className="flex items-center gap-2 text-sm">
                    <div className="w-2 h-2 rounded-full" style={{ backgroundColor: f.color }} />
                    <span className="text-slate-300 flex-1">{f.mountain}</span>
                    <span className="text-sky-400 font-medium">{total}"</span>
                  </div>
                );
              })}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// Stats Grid Component
function StatsGrid({ mountains }: { mountains: MountainData[] }) {
  const stats = useMemo(() => {
    const withConditions = mountains.filter(m => m.conditions);
    const withScores = mountains.filter(m => m.powderScore !== undefined);

    const totalSnow24h = withConditions.reduce((sum, m) => sum + (m.conditions?.snowfall24h ?? 0), 0);
    const avgScore = withScores.length > 0
      ? withScores.reduce((sum, m) => sum + (m.powderScore ?? 0), 0) / withScores.length
      : 0;
    const avgTemp = withConditions.length > 0
      ? withConditions.reduce((sum, m) => sum + (m.conditions?.temperature ?? 0), 0) / withConditions.length
      : 0;
    const maxSnow = Math.max(...withConditions.map(m => m.conditions?.snowfall24h ?? 0));

    return { totalSnow24h, avgScore, avgTemp, maxSnow, reporting: withConditions.length };
  }, [mountains]);

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
      <Card className="bg-gradient-to-br from-sky-500/20 to-sky-600/10 border-sky-500/30">
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-sky-500/20 rounded-lg">
              <Snowflake className="w-5 h-5 text-sky-400" />
            </div>
            <div>
              <div className="text-2xl font-bold text-white">{stats.totalSnow24h.toFixed(0)}"</div>
              <div className="text-xs text-slate-400">24hr Regional Snow</div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="bg-gradient-to-br from-emerald-500/20 to-emerald-600/10 border-emerald-500/30">
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-emerald-500/20 rounded-lg">
              <TrendingUp className="w-5 h-5 text-emerald-400" />
            </div>
            <div>
              <div className="text-2xl font-bold text-white">{stats.avgScore.toFixed(1)}</div>
              <div className="text-xs text-slate-400">Avg Powder Score</div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="bg-gradient-to-br from-amber-500/20 to-amber-600/10 border-amber-500/30">
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-amber-500/20 rounded-lg">
              <Thermometer className="w-5 h-5 text-amber-400" />
            </div>
            <div>
              <div className="text-2xl font-bold text-white">{stats.avgTemp.toFixed(0)}°F</div>
              <div className="text-xs text-slate-400">Avg Temperature</div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="bg-gradient-to-br from-purple-500/20 to-purple-600/10 border-purple-500/30">
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-500/20 rounded-lg">
              <Mountain className="w-5 h-5 text-purple-400" />
            </div>
            <div>
              <div className="text-2xl font-bold text-white">{stats.reporting}</div>
              <div className="text-xs text-slate-400">Resorts Reporting</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Hero Featured Mountain
function HeroMountain({ mountain, onNavigate }: { mountain: MountainData; onNavigate: () => void }) {
  const scoreStyle = mountain.powderScore ? getPowderScoreStyle(mountain.powderScore) : null;

  return (
    <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-slate-800 via-slate-900 to-slate-950 border border-slate-700 mb-6">
      {/* Background gradient accent */}
      <div
        className="absolute inset-0 opacity-20"
        style={{
          background: `radial-gradient(ellipse at top right, ${mountain.color}40, transparent 50%)`,
        }}
      />

      <div className="relative p-6 md:p-8">
        <div className="flex flex-col md:flex-row md:items-center gap-6">
          {/* Left: Mountain Info */}
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-2">
              <Badge className="bg-emerald-500/20 text-emerald-400 border-emerald-500/30">
                Top Pick Today
              </Badge>
              <span className="text-xs text-slate-500">
                <Clock className="w-3 h-3 inline mr-1" />
                Updated {new Date().toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })}
              </span>
            </div>

            <h2 className="text-3xl md:text-4xl font-bold text-white mb-2">
              {mountain.name}
            </h2>

            <p className="text-slate-400 mb-4">
              {mountain.elevation.base.toLocaleString()}' - {mountain.elevation.summit.toLocaleString()}' elevation
            </p>

            {/* Quick Stats */}
            <div className="grid grid-cols-4 gap-3 mb-4">
              <div className="text-center p-2 bg-slate-800/50 rounded-lg">
                <div className="text-xl font-bold text-white">{mountain.conditions?.snowDepth ?? '--'}"</div>
                <div className="text-xs text-slate-500">Base</div>
              </div>
              <div className="text-center p-2 bg-slate-800/50 rounded-lg">
                <div className="text-xl font-bold text-sky-400">{mountain.conditions?.snowfall24h ?? 0}"</div>
                <div className="text-xs text-slate-500">24hr</div>
              </div>
              <div className="text-center p-2 bg-slate-800/50 rounded-lg">
                <div className="text-xl font-bold text-white">{mountain.conditions?.temperature ?? '--'}°</div>
                <div className="text-xs text-slate-500">Temp</div>
              </div>
              <div className="text-center p-2 bg-slate-800/50 rounded-lg">
                <div className="text-xl font-bold text-white">{mountain.conditions?.windSpeed ?? '--'}</div>
                <div className="text-xs text-slate-500">Wind</div>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={onNavigate}
                className="px-4 py-2 bg-sky-500 hover:bg-sky-600 text-white font-medium rounded-lg transition-colors flex items-center gap-2"
              >
                View Details
                <ChevronRight className="w-4 h-4" />
              </button>
              <Link
                href={`/mountains/${mountain.id}/patrol`}
                className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white font-medium rounded-lg transition-colors"
              >
                Patrol Dashboard
              </Link>
            </div>
          </div>

          {/* Right: Powder Score */}
          <div className="flex flex-col items-center">
            <PowderScoreRing score={mountain.powderScore ?? 0} size="lg" />
            <div className="text-sm text-slate-400 mt-2">Powder Score</div>
            {mountain.powderScore && (
              <div className={`text-sm font-medium mt-1 ${scoreStyle?.color}`}>
                {mountain.powderScore >= 8 ? 'Epic Conditions!' :
                 mountain.powderScore >= 6 ? 'Great Day!' :
                 mountain.powderScore >= 4 ? 'Decent' : 'Wait for Better'}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// Main Dashboard Component
export default function Dashboard() {
  const router = useRouter();
  const [mountains, setMountains] = useState<MountainData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [showMap, setShowMap] = useState(false);
  const [showIntro, setShowIntro] = useState(false);

  const allMountains = getAllMountains();

  // Check if user has seen intro before
  useEffect(() => {
    const hasSeenIntro = localStorage.getItem('hasSeenIntro');
    if (!hasSeenIntro) {
      setShowIntro(true);
    }
  }, []);

  // Handle intro completion
  const handleIntroComplete = () => {
    localStorage.setItem('hasSeenIntro', 'true');
    setShowIntro(false);
  };

  // Fetch all mountain data
  const fetchAllData = async (showRefresh = false) => {
    if (showRefresh) setIsRefreshing(true);

    try {
      const mountainData: MountainData[] = await Promise.all(
        allMountains.map(async (m) => {
          const base: MountainData = {
            id: m.id,
            name: m.name,
            shortName: m.shortName,
            region: m.region,
            color: m.color,
            elevation: m.elevation,
          };

          try {
            const [conditionsRes, scoreRes, forecastRes] = await Promise.all([
              fetch(`/api/mountains/${m.id}/conditions`).catch(() => null),
              fetch(`/api/mountains/${m.id}/powder-score`).catch(() => null),
              fetch(`/api/mountains/${m.id}/forecast`).catch(() => null),
            ]);

            if (conditionsRes?.ok) {
              const data = await conditionsRes.json();
              base.conditions = {
                snowDepth: data.snowDepth ?? 0,
                snowfall24h: data.snowfall24h ?? 0,
                snowfall48h: data.snowfall48h ?? 0,
                temperature: data.temperature,
                windSpeed: data.wind?.speed ?? 0,
                windDirection: data.wind?.direction ?? 'N',
                conditions: data.conditions ?? 'Unknown',
              };
            }

            if (scoreRes?.ok) {
              const data = await scoreRes.json();
              base.powderScore = data.score;
            }

            if (forecastRes?.ok) {
              const data = await forecastRes.json();
              base.forecast = data.forecast?.slice(0, 3) ?? [];
            }
          } catch (err) {
            console.error(`Error fetching data for ${m.id}:`, err);
          }

          return base;
        })
      );

      setMountains(mountainData);
      setLastUpdated(new Date());
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchAllData();
    // Refresh every 10 minutes
    const interval = setInterval(() => fetchAllData(true), 10 * 60 * 1000);
    return () => clearInterval(interval);
  }, []);

  // Computed data
  const topMountain = useMemo(() => {
    return mountains
      .filter(m => m.powderScore !== undefined)
      .sort((a, b) => (b.powderScore ?? 0) - (a.powderScore ?? 0))[0];
  }, [mountains]);

  const regionSummaries = useMemo((): RegionSummary[] => {
    const regions = [
      { region: 'washington', displayName: 'Washington' },
      { region: 'oregon', displayName: 'Oregon' },
      { region: 'idaho', displayName: 'Idaho' },
    ];

    return regions.map(r => {
      const regionMountains = mountains.filter(m => m.region === r.region);
      const withScores = regionMountains.filter(m => m.powderScore !== undefined);
      const avgScore = withScores.length > 0
        ? withScores.reduce((sum, m) => sum + (m.powderScore ?? 0), 0) / withScores.length
        : 0;
      const totalSnowfall24h = regionMountains.reduce(
        (sum, m) => sum + (m.conditions?.snowfall24h ?? 0),
        0
      );
      const bestMountain = regionMountains
        .filter(m => m.powderScore !== undefined)
        .sort((a, b) => (b.powderScore ?? 0) - (a.powderScore ?? 0))[0] ?? null;

      return {
        ...r,
        mountains: regionMountains,
        avgScore,
        totalSnowfall24h,
        bestMountain,
      };
    });
  }, [mountains]);

  const allAlerts = useMemo(() => {
    const alerts: Array<{ mountain: string; type: string; severity: string; title: string; message: string }> = [];
    mountains.forEach(m => {
      m.alerts?.forEach(a => {
        alerts.push({ mountain: m.name, ...a });
      });
    });
    return alerts;
  }, [mountains]);

  const forecastData = useMemo(() => {
    return mountains
      .filter(m => m.forecast && m.forecast.length > 0)
      .map(m => ({
        mountain: m.shortName,
        color: m.color,
        days: m.forecast!.map(f => ({
          dayOfWeek: f.dayOfWeek,
          snowfall: f.snowfall,
          icon: f.icon,
        })),
      }));
  }, [mountains]);

  const handleMountainClick = (id: string) => {
    router.push(`/mountains/${id}`);
  };

  if (isLoading) {
    return (
      <>
        {showIntro && <Intro onComplete={handleIntroComplete} />}
        <div className="min-h-screen bg-slate-950 text-slate-100">
          <div className="max-w-7xl mx-auto px-4 py-8">
            <Skeleton className="h-12 w-64 mb-8" />
            <Skeleton className="h-64 w-full mb-6 rounded-2xl" />
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
              {[...Array(4)].map((_, i) => (
                <Skeleton key={i} className="h-24 rounded-xl" />
              ))}
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {[...Array(3)].map((_, i) => (
                <Skeleton key={i} className="h-80 rounded-xl" />
              ))}
            </div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      {showIntro && <Intro onComplete={handleIntroComplete} />}
      <div className="min-h-screen bg-slate-950 text-slate-100">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-slate-950/90 backdrop-blur-lg border-b border-slate-800">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                <Mountain className="w-7 h-7 text-sky-400" />
                Shredders
              </h1>
              <p className="text-sm text-slate-400">
                PNW Mountain Conditions Dashboard
              </p>
            </div>

            <div className="flex items-center gap-3">
              <span className="text-xs text-slate-500 hidden md:block">
                Updated {lastUpdated.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })}
              </span>
              <button
                onClick={() => fetchAllData(true)}
                disabled={isRefreshing}
                className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 transition-colors disabled:opacity-50"
              >
                <RefreshCw className={`w-5 h-5 ${isRefreshing ? 'animate-spin' : ''}`} />
              </button>
              <button
                onClick={() => setShowMap(!showMap)}
                className={`p-2 rounded-lg transition-colors ${showMap ? 'bg-sky-500 text-white' : 'bg-slate-800 hover:bg-slate-700'}`}
              >
                <MapPin className="w-5 h-5" />
              </button>
              <Link
                href="/chat"
                className="px-4 py-2 bg-gradient-to-r from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700 text-white font-medium rounded-lg transition-colors flex items-center gap-2"
              >
                <MessageSquare className="w-4 h-4" />
                <span className="hidden md:inline">Ask AI</span>
              </Link>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-6">
        {/* Alerts Banner */}
        <AlertBanner alerts={allAlerts} />

        {/* Map Toggle Section */}
        {showMap && (
          <div className="mb-6 h-[400px] rounded-2xl overflow-hidden border border-slate-800">
            <MountainMap
              onMountainSelect={handleMountainClick}
              showUserLocation
            />
          </div>
        )}

        {/* Hero: Featured Mountain */}
        {topMountain && (
          <HeroMountain
            mountain={topMountain}
            onNavigate={() => handleMountainClick(topMountain.id)}
          />
        )}

        {/* Snowfall Tracker Table */}
        <div className="mb-6">
          <SnowfallTable daysBack={7} daysForward={7} />
        </div>

        {/* Stats Grid */}
        <StatsGrid mountains={mountains} />

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
          {/* Regions */}
          {regionSummaries.map((region) => (
            <RegionCard
              key={region.region}
              region={region}
              onMountainClick={handleMountainClick}
            />
          ))}
        </div>

        {/* Forecast & Quick Actions Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          {/* 3-Day Forecast */}
          <ForecastPreview forecasts={forecastData} />

          {/* Quick Actions */}
          <Card className="bg-slate-900/50 border-slate-800">
            <CardHeader className="pb-2">
              <CardTitle className="text-lg flex items-center gap-2">
                <Navigation className="w-5 h-5 text-emerald-400" />
                Quick Actions
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-3">
                <Link
                  href="/mountains"
                  className="flex flex-col items-center gap-2 p-4 bg-slate-800/50 hover:bg-slate-700/50 rounded-lg transition-colors"
                >
                  <Mountain className="w-8 h-8 text-sky-400" />
                  <span className="text-sm font-medium text-white">All Mountains</span>
                  <span className="text-xs text-slate-400">Map & List View</span>
                </Link>

                <Link
                  href="/chat"
                  className="flex flex-col items-center gap-2 p-4 bg-slate-800/50 hover:bg-slate-700/50 rounded-lg transition-colors"
                >
                  <MessageSquare className="w-8 h-8 text-violet-400" />
                  <span className="text-sm font-medium text-white">AI Assistant</span>
                  <span className="text-xs text-slate-400">Ask about conditions</span>
                </Link>

                <Link
                  href={topMountain ? `/mountains/${topMountain.id}/patrol` : '/mountains'}
                  className="flex flex-col items-center gap-2 p-4 bg-slate-800/50 hover:bg-slate-700/50 rounded-lg transition-colors"
                >
                  <AlertTriangle className="w-8 h-8 text-amber-400" />
                  <span className="text-sm font-medium text-white">Patrol Dashboard</span>
                  <span className="text-xs text-slate-400">Safety & hazards</span>
                </Link>

                <Link
                  href={topMountain ? `/mountains/${topMountain.id}/webcams` : '/mountains'}
                  className="flex flex-col items-center gap-2 p-4 bg-slate-800/50 hover:bg-slate-700/50 rounded-lg transition-colors"
                >
                  <BarChart3 className="w-8 h-8 text-emerald-400" />
                  <span className="text-sm font-medium text-white">Live Webcams</span>
                  <span className="text-xs text-slate-400">See conditions</span>
                </Link>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Top Mountains Leaderboard */}
        <Card className="bg-slate-900/50 border-slate-800 mb-6">
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-emerald-400" />
                Today's Leaderboard
              </CardTitle>
              <Link href="/mountains" className="text-sm text-sky-400 hover:text-sky-300 flex items-center gap-1">
                View All <ChevronRight className="w-4 h-4" />
              </Link>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              {mountains
                .filter(m => m.powderScore !== undefined)
                .sort((a, b) => (b.powderScore ?? 0) - (a.powderScore ?? 0))
                .slice(0, 6)
                .map((mountain, idx) => {
                  const style = getPowderScoreStyle(mountain.powderScore ?? 0);
                  return (
                    <button
                      key={mountain.id}
                      onClick={() => handleMountainClick(mountain.id)}
                      className="flex items-center gap-3 p-3 bg-slate-800/50 hover:bg-slate-700/50 rounded-lg border border-slate-700/50 hover:border-slate-600 transition-all text-left"
                    >
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm ${
                        idx === 0 ? 'bg-amber-500/20 text-amber-400' :
                        idx === 1 ? 'bg-slate-400/20 text-slate-300' :
                        idx === 2 ? 'bg-orange-500/20 text-orange-400' :
                        'bg-slate-700 text-slate-400'
                      }`}>
                        {idx + 1}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium text-white truncate">{mountain.shortName}</div>
                        <div className="text-xs text-slate-400 capitalize">{mountain.region}</div>
                      </div>
                      <div className={`text-xl font-bold ${style.color}`}>
                        {mountain.powderScore?.toFixed(1)}
                      </div>
                    </button>
                  );
                })}
            </div>
          </CardContent>
        </Card>

        {/* Footer */}
        <footer className="text-center py-8 border-t border-slate-800">
          <p className="text-sm text-slate-500">
            Data sources: NRCS SNOTEL • NOAA National Weather Service • Open-Meteo
          </p>
          <p className="text-xs text-slate-600 mt-2">
            Built with Next.js + Claude AI • {new Date().getFullYear()}
          </p>
        </footer>
      </main>
    </div>
    </>
  );
}
