'use client';

import { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { MountainMap } from '@/components/MountainMapLoader';
import { Intro } from '@/components/Intro';
import { SnowfallTable } from '@/components/SnowfallTable';
import { getAllMountains } from '@shredders/shared';
import { getPowderScoreStyle } from '@/lib/design-tokens';
import { prefetchMountainData } from '@/hooks/useMountainData';
import {
  Mountain,
  Snowflake,
  Thermometer,
  AlertTriangle,
  MapPin,
  MessageSquare,
  ChevronRight,
  RefreshCw,
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


// Compact Top Pick Banner
function TopPickBanner({ mountain, onClick }: { mountain: MountainData; onClick: () => void }) {
  const style = mountain.powderScore ? getPowderScoreStyle(mountain.powderScore) : null;
  const hasPowderScore = mountain.powderScore !== undefined && mountain.powderScore > 0;
  const hasSnow = (mountain.conditions?.snowfall24h ?? 0) > 0;
  const hasBase = (mountain.conditions?.snowDepth ?? 0) > 0;

  // Determine badge text and style
  let badgeText = 'Featured';
  let badgeClass = 'bg-slate-500/20 text-slate-400 border-slate-500/30';
  if (hasPowderScore) {
    badgeText = 'Top Pick';
    badgeClass = 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
  } else if (hasSnow) {
    badgeText = 'Fresh Snow';
    badgeClass = 'bg-sky-500/20 text-sky-400 border-sky-500/30';
  } else if (hasBase) {
    badgeText = 'Deep Base';
    badgeClass = 'bg-purple-500/20 text-purple-400 border-purple-500/30';
  }

  return (
    <button
      onClick={onClick}
      onMouseEnter={() => prefetchMountainData(mountain.id)}
      className="flex-1 flex items-center gap-2 px-3 py-2 bg-slate-800/50 border border-slate-700/50 rounded-lg hover:border-slate-600 transition-all text-left group"
    >
      <Badge className={`text-xs shrink-0 ${badgeClass}`}>
        {badgeText}
      </Badge>
      <div
        className="w-1 h-5 rounded-full shrink-0"
        style={{ backgroundColor: mountain.color }}
      />
      <span className="font-medium text-white group-hover:text-sky-400 transition-colors truncate text-sm">
        {mountain.shortName}
      </span>
      <div className="flex items-center gap-2 ml-auto shrink-0 text-xs">
        {hasSnow && (
          <span className="text-sky-400 font-medium">
            <Snowflake className="w-3 h-3 inline mr-0.5" />
            {mountain.conditions?.snowfall24h}" new
          </span>
        )}
        {hasBase && (
          <span className="text-slate-400">
            {mountain.conditions?.snowDepth}" base
          </span>
        )}
        {hasPowderScore && (
          <span className={`font-bold ${style?.color}`}>
            {mountain.powderScore?.toFixed(1)}
          </span>
        )}
        <ChevronRight className="w-3.5 h-3.5 text-slate-500 group-hover:text-sky-400" />
      </div>
    </button>
  );
}

// Compact Alert Strip
function AlertStrip({ alerts }: { alerts: Array<{ mountain: string; type: string; severity: string; title: string; message: string }> }) {
  const highSeverityAlerts = alerts.filter(a => a.severity === 'high' || a.severity === 'extreme');
  if (highSeverityAlerts.length === 0) return null;

  return (
    <div className="flex items-center gap-2 px-3 py-1.5 bg-red-500/10 border border-red-500/20 rounded-lg text-sm">
      <AlertTriangle className="w-4 h-4 text-red-400 shrink-0" />
      <span className="text-red-400 font-medium">{highSeverityAlerts.length} Alert{highSeverityAlerts.length > 1 ? 's' : ''}</span>
      <span className="text-slate-400 truncate">
        {highSeverityAlerts[0].mountain}: {highSeverityAlerts[0].title}
      </span>
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
      // Use batch endpoints to reduce API calls from 45+ to just 3
      const [conditionsRes, scoresRes, snowfallRes] = await Promise.all([
        fetch('/api/mountains/batch/conditions').catch(() => null),
        fetch('/api/mountains/batch/powder-scores').catch(() => null),
        fetch('/api/mountains/batch/snowfall?daysBack=7&daysForward=7').catch(() => null),
      ]);

      const conditionsData = conditionsRes?.ok ? await conditionsRes.json() : {};
      const scoresData = scoresRes?.ok ? await scoresRes.json() : {};
      const snowfallData = snowfallRes?.ok ? await snowfallRes.json() : { data: [] };

      const mountainData: MountainData[] = allMountains.map((m) => {
        const base: MountainData = {
          id: m.id,
          name: m.name,
          shortName: m.shortName,
          region: m.region,
          color: m.color,
          elevation: m.elevation,
        };

        // Add conditions data
        const conditions = conditionsData.data?.find((d: any) => d.mountainId === m.id);
        if (conditions) {
          base.conditions = {
            snowDepth: conditions.snowDepth ?? 0,
            snowfall24h: conditions.snowfall24h ?? 0,
            snowfall48h: conditions.snowfall48h ?? 0,
            temperature: conditions.temperature,
            windSpeed: conditions.wind?.speed ?? 0,
            windDirection: conditions.wind?.direction ?? 'N',
            conditions: conditions.conditions ?? 'Unknown',
          };
        }

        // Add powder score
        const score = scoresData.data?.find((d: any) => d.mountainId === m.id);
        if (score) {
          base.powderScore = score.score;
        }

        return base;
      });

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

  // Computed data - pick top mountain by powder score, snowfall, or base depth
  const topMountain = useMemo(() => {
    if (mountains.length === 0) return null;

    // First try by powder score
    const byScore = mountains
      .filter(m => m.powderScore !== undefined && m.powderScore > 0)
      .sort((a, b) => (b.powderScore ?? 0) - (a.powderScore ?? 0))[0];
    if (byScore) return byScore;

    // Then try by recent snowfall
    const bySnowfall = mountains
      .filter(m => m.conditions?.snowfall24h && m.conditions.snowfall24h > 0)
      .sort((a, b) => (b.conditions?.snowfall24h ?? 0) - (a.conditions?.snowfall24h ?? 0))[0];
    if (bySnowfall) return bySnowfall;

    // Then by deepest base
    const byBase = mountains
      .filter(m => m.conditions?.snowDepth && m.conditions.snowDepth > 0)
      .sort((a, b) => (b.conditions?.snowDepth ?? 0) - (a.conditions?.snowDepth ?? 0))[0];
    if (byBase) return byBase;

    // Fallback to first Washington mountain with conditions
    return mountains.find(m => m.region === 'washington' && m.conditions) || mountains[0];
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

  const handleMountainClick = (id: string) => {
    router.push(`/mountains/${id}`);
  };

  if (isLoading) {
    return (
      <>
        {showIntro && <Intro onComplete={handleIntroComplete} />}
        <div className="min-h-screen bg-slate-950 text-slate-100 pt-16">
          <div className="max-w-7xl mx-auto px-4 py-4">
            <Skeleton className="h-10 w-full mb-3 rounded-lg" />
            <Skeleton className="h-[400px] w-full rounded-xl" />
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      {showIntro && <Intro onComplete={handleIntroComplete} />}
      <div className="min-h-screen bg-slate-950 text-slate-100">
      {/* Compact Action Bar */}
      <div className="sticky top-16 z-30 bg-slate-950/95 backdrop-blur-lg border-b border-slate-800">
        <div className="max-w-7xl mx-auto px-4 py-2">
          <div className="flex items-center gap-4">
            {/* Stats - hidden on mobile */}
            <div className="hidden lg:flex items-center gap-3 text-xs">
              <div className="flex items-center gap-1">
                <Snowflake className="w-3.5 h-3.5 text-sky-400" />
                <span className="text-white font-medium">
                  {mountains.reduce((sum, m) => sum + (m.conditions?.snowfall24h ?? 0), 0).toFixed(0)}"
                </span>
                <span className="text-slate-500">24hr</span>
              </div>
              <div className="w-px h-3 bg-slate-700" />
              <div className="flex items-center gap-1">
                <Thermometer className="w-3.5 h-3.5 text-amber-400" />
                <span className="text-white font-medium">
                  {(mountains.filter(m => m.conditions).reduce((sum, m) => sum + (m.conditions?.temperature ?? 0), 0) /
                    Math.max(1, mountains.filter(m => m.conditions).length)).toFixed(0)}°
                </span>
              </div>
              <div className="w-px h-3 bg-slate-700" />
              <div className="flex items-center gap-1">
                <Mountain className="w-3.5 h-3.5 text-purple-400" />
                <span className="text-white font-medium">{mountains.filter(m => m.conditions).length}</span>
                <span className="text-slate-500">resorts</span>
              </div>
            </div>

            {/* Spacer */}
            <div className="flex-1" />

            {/* Quick Links */}
            <Link
              href="/mountains"
              className="text-xs text-slate-400 hover:text-white transition-colors hidden sm:block"
            >
              All Mountains
            </Link>

            {/* Actions */}
            <div className="flex items-center gap-2">
              <span className="text-xs text-slate-600 hidden md:block">
                {lastUpdated.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })}
              </span>
              <button
                onClick={() => fetchAllData(true)}
                disabled={isRefreshing}
                className="p-1.5 rounded-md bg-slate-800 hover:bg-slate-700 transition-colors disabled:opacity-50"
                title="Refresh data"
              >
                <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
              </button>
              <button
                onClick={() => setShowMap(!showMap)}
                className={`p-1.5 rounded-md transition-colors ${showMap ? 'bg-sky-500 text-white' : 'bg-slate-800 hover:bg-slate-700'}`}
                title="Toggle map"
              >
                <MapPin className="w-4 h-4" />
              </button>
              <Link
                href="/chat"
                className="px-3 py-1.5 bg-gradient-to-r from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700 text-white text-xs font-medium rounded-md transition-colors flex items-center gap-1.5"
              >
                <MessageSquare className="w-3.5 h-3.5" />
                <span className="hidden sm:inline">AI</span>
              </Link>
            </div>
          </div>
        </div>
      </div>

      <main className="max-w-7xl mx-auto px-4 py-3">
        {/* Alert + Top Pick row */}
        <div className="flex flex-col sm:flex-row gap-2 mb-3">
          <AlertStrip alerts={allAlerts} />
          {topMountain && (
            <TopPickBanner
              mountain={topMountain}
              onClick={() => handleMountainClick(topMountain.id)}
            />
          )}
        </div>

        {/* Map Toggle Section */}
        {showMap && (
          <div className="mb-3 h-[280px] rounded-lg overflow-hidden border border-slate-800">
            <MountainMap
              onMountainSelect={handleMountainClick}
              showUserLocation
            />
          </div>
        )}

        {/* Snowfall Tracker Table - the main focus */}
        <SnowfallTable daysBack={7} daysForward={7} />

        {/* Compact Footer */}
        <footer className="text-center py-3 mt-3 border-t border-slate-800">
          <p className="text-xs text-slate-600">
            NRCS SNOTEL • NOAA NWS • Open-Meteo
          </p>
        </footer>
      </main>
    </div>
    </>
  );
}
