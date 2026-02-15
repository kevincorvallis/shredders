'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft, RefreshCw, ExternalLink } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { SafetyAlertBanner } from '@/components/patrol/SafetyAlertBanner';
import { WindRose } from '@/components/patrol/WindRose';
import { HazardMatrixCard } from '@/components/patrol/HazardMatrixCard';
import { TemperatureProfileCard } from '@/components/patrol/TemperatureProfileCard';
import { SnowStabilityCard } from '@/components/patrol/SnowStabilityCard';
import { MetricsGrid } from '@/components/patrol/MetricsGrid';
import { getPowderScoreStyle } from '@/lib/design-tokens';

interface SafetyData {
  timestamp: string;
  mountain: string;
  dataQuality: {
    hasSnotel: boolean;
    hasWeather: boolean;
    hasWindHistory: boolean;
  };
  alerts: Array<{
    type: 'wind_loading' | 'new_snow' | 'warm_temps' | 'poor_visibility' | 'wind_chill';
    severity: 'low' | 'moderate' | 'considerable' | 'high' | 'extreme';
    title: string;
    message: string;
  }>;
  metrics: {
    windLoading: {
      index: number;
      severity: string;
      loadedAspects: string[];
      crossLoadedAspects: string[];
      message: string;
    };
    inversionRisk: {
      detected: boolean;
      confidence: number;
      type: string;
      message: string;
    };
    snowStability: {
      rating: 'good' | 'fair' | 'poor' | 'unknown';
      trend: 'improving' | 'stable' | 'declining';
      factors: Array<{
        name: string;
        status: 'positive' | 'negative' | 'neutral';
        description: string;
      }>;
      message: string;
    };
    snowType: 'dry-powder' | 'mixed' | 'wet-heavy';
    windChill: number;
    freezingLevel: number;
    hazardMatrix: Array<{
      aspect: string;
      elevation: string;
      risk: 1 | 2 | 3 | 4 | 5;
      factors: string[];
    }>;
  };
  conditions: {
    temperature: number;
    tempMax24hr: number | null;
    tempMin24hr: number | null;
    diurnalRange: number | null;
    humidity: number | null;
    windSpeed: number;
    windGust: number | null;
    windDirection: number;
    windDirectionCardinal: string;
    visibility: number | null;
    visibilityCategory: string;
    skyCover: number | null;
    precipProbability: number | null;
  };
  snowpack: {
    depth: number;
    swe: number;
    density: number | null;
    snowfall24h: number;
    snowfall48h: number;
    snowfall7d: number;
    settlingRate: number | null;
  } | null;
  windHistory: Array<{
    time: string;
    speed: number;
    gust: number | null;
    direction: number;
  }>;
}

interface MountainData {
  id: string;
  name: string;
  shortName: string;
  elevation: { base: number; summit: number };
  website: string;
}

export default function PatrolDashboardPage() {
  const params = useParams();
  const mountainId = params.mountainId as string;

  const [safetyData, setSafetyData] = useState<SafetyData | null>(null);
  const [mountainData, setMountainData] = useState<MountainData | null>(null);
  const [powderScore, setPowderScore] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);

    try {
      const [safetyRes, mountainRes, scoreRes] = await Promise.all([
        fetch(`/api/mountains/${mountainId}/safety`),
        fetch(`/api/mountains/${mountainId}`),
        fetch(`/api/mountains/${mountainId}/powder-score`),
      ]);

      // Check all responses before parsing JSON
      if (!safetyRes.ok) {
        throw new Error(`Failed to fetch safety data: ${safetyRes.status} ${safetyRes.statusText}`);
      }

      const [safety, mountain, score] = await Promise.all([
        safetyRes.json(),
        mountainRes.ok ? mountainRes.json() : null,
        scoreRes.ok ? scoreRes.json() : null,
      ]);

      setSafetyData(safety);
      setMountainData(mountain);
      setPowderScore(score?.score ?? null);
      setError(null);
    } catch (err) {
      console.error('Patrol page fetch error:', err);
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
    // Refresh every 5 minutes
    const interval = setInterval(() => fetchData(true), 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, [mountainId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-background text-text-primary p-4 md:p-6">
        <div className="max-w-7xl mx-auto space-y-6">
          <Skeleton className="h-12 w-64" />
          <Skeleton className="h-24 w-full" />
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Skeleton className="h-48" />
            <Skeleton className="h-48" />
            <Skeleton className="h-48" />
          </div>
        </div>
      </div>
    );
  }

  if (error || !safetyData) {
    return (
      <div className="min-h-screen bg-background text-text-primary p-4 md:p-6">
        <div className="max-w-7xl mx-auto">
          <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-6 text-center">
            <h2 className="text-xl font-semibold text-red-400 mb-2">Error Loading Data</h2>
            <p className="text-text-tertiary">{error || 'Unable to load safety data'}</p>
            <button
              onClick={() => fetchData()}
              className="mt-4 px-4 py-2 bg-surface-secondary rounded-lg hover:bg-surface-tertiary transition-colors"
            >
              Try Again
            </button>
          </div>
        </div>
      </div>
    );
  }

  const scoreStyle = powderScore !== null ? getPowderScoreStyle(powderScore) : null;

  return (
    <div className="min-h-screen bg-background text-text-primary">
      {/* Header */}
      <header className="border-b border-border-secondary bg-surface-primary/50 sticky top-0 z-10 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Link
                href={`/mountains/${mountainId}`}
                className="p-2 rounded-lg hover:bg-surface-secondary transition-colors"
              >
                <ArrowLeft className="w-5 h-5" />
              </Link>
              <div>
                <h1 className="text-xl font-bold">
                  {mountainData?.name || mountainId} Patrol Dashboard
                </h1>
                <p className="text-sm text-text-tertiary">
                  Professional conditions monitoring
                </p>
              </div>
            </div>

            <div className="flex items-center gap-4">
              {/* Data quality indicators */}
              <div className="hidden md:flex items-center gap-2 text-xs">
                <Badge variant={safetyData.dataQuality.hasSnotel ? 'success' : 'outline'}>
                  SNOTEL
                </Badge>
                <Badge variant={safetyData.dataQuality.hasWeather ? 'success' : 'outline'}>
                  NOAA
                </Badge>
              </div>

              {/* Refresh button */}
              <button
                onClick={() => fetchData(true)}
                disabled={refreshing}
                className="p-2 rounded-lg hover:bg-surface-secondary transition-colors disabled:opacity-50"
              >
                <RefreshCw className={`w-5 h-5 ${refreshing ? 'animate-spin' : ''}`} />
              </button>

              {/* External link */}
              {mountainData?.website && (
                <a
                  href={mountainData.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="p-2 rounded-lg hover:bg-surface-secondary transition-colors"
                >
                  <ExternalLink className="w-5 h-5" />
                </a>
              )}
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-6 space-y-6">
        {/* Safety Alerts */}
        <SafetyAlertBanner
          alerts={safetyData.alerts}
          lastUpdated={safetyData.timestamp}
        />

        {/* Quick Stats Row */}
        <div className="grid grid-cols-3 gap-4">
          {/* Powder Score */}
          <Card className="bg-gradient-to-br from-surface-primary to-surface-secondary">
            <CardContent className="p-4 text-center">
              <div className={`text-4xl font-bold ${scoreStyle?.color || 'text-text-secondary'}`}>
                {powderScore?.toFixed(1) ?? '--'}
              </div>
              <div className="text-sm text-text-tertiary mt-1">Powder Score</div>
            </CardContent>
          </Card>

          {/* Wind Loading */}
          <Card className="bg-gradient-to-br from-surface-primary to-surface-secondary">
            <CardContent className="p-4 text-center">
              <div className="flex justify-center gap-1">
                {[1, 2, 3, 4, 5].map((i) => (
                  <div
                    key={i}
                    className={`w-4 h-8 rounded ${
                      i <= safetyData.metrics.windLoading.index
                        ? safetyData.metrics.windLoading.index >= 4 ? 'bg-red-500' :
                          safetyData.metrics.windLoading.index >= 3 ? 'bg-amber-500' :
                          'bg-emerald-500'
                        : 'bg-surface-tertiary'
                    }`}
                  />
                ))}
              </div>
              <div className="text-sm text-text-tertiary mt-2">Wind Loading</div>
            </CardContent>
          </Card>

          {/* Snow Type */}
          <Card className="bg-gradient-to-br from-surface-primary to-surface-secondary">
            <CardContent className="p-4 text-center">
              <div className="text-2xl">
                {safetyData.metrics.snowType === 'dry-powder' ? '❄️' :
                 safetyData.metrics.snowType === 'wet-heavy' ? '💧' : '🌨️'}
              </div>
              <div className="text-sm font-medium text-text-secondary mt-1">
                {safetyData.metrics.snowType === 'dry-powder' ? 'Dry Powder' :
                 safetyData.metrics.snowType === 'wet-heavy' ? 'Wet/Heavy' : 'Mixed'}
              </div>
              <div className="text-xs text-text-tertiary">Snow Type</div>
            </CardContent>
          </Card>
        </div>

        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Left Column */}
          <div className="space-y-6">
            <HazardMatrixCard
              matrix={safetyData.metrics.hazardMatrix as any}
              loadedAspects={safetyData.metrics.windLoading.loadedAspects as any}
            />

            <TemperatureProfileCard
              baseElevation={mountainData?.elevation.base || 4000}
              summitElevation={mountainData?.elevation.summit || 6000}
              temperature={safetyData.conditions.temperature}
              tempMax={safetyData.conditions.tempMax24hr}
              tempMin={safetyData.conditions.tempMin24hr}
              freezingLevel={safetyData.metrics.freezingLevel}
              inversionDetected={safetyData.metrics.inversionRisk.detected}
              inversionMessage={safetyData.metrics.inversionRisk.message}
            />
          </div>

          {/* Right Column */}
          <div className="space-y-6">
            <WindRose
              currentSpeed={safetyData.conditions.windSpeed}
              currentGust={safetyData.conditions.windGust}
              currentDirection={safetyData.conditions.windDirection}
              currentDirectionCardinal={safetyData.conditions.windDirectionCardinal}
              windHistory={safetyData.windHistory}
              loadedAspects={safetyData.metrics.windLoading.loadedAspects as any}
            />

            <SnowStabilityCard
              rating={safetyData.metrics.snowStability.rating}
              trend={safetyData.metrics.snowStability.trend}
              factors={safetyData.metrics.snowStability.factors}
              snowType={safetyData.metrics.snowType}
              density={safetyData.snowpack?.density ?? null}
              settlingRate={safetyData.snowpack?.settlingRate ?? null}
              snowfall24h={safetyData.snowpack?.snowfall24h ?? 0}
              message={safetyData.metrics.snowStability.message}
            />
          </div>
        </div>

        {/* Metrics Grid */}
        <div>
          <h2 className="text-lg font-semibold text-text-secondary mb-4">Quick Metrics</h2>
          <MetricsGrid
            windChill={safetyData.metrics.windChill}
            humidity={safetyData.conditions.humidity}
            visibility={safetyData.conditions.visibility}
            visibilityCategory={safetyData.conditions.visibilityCategory}
            skyCover={safetyData.conditions.skyCover}
            precipProbability={safetyData.conditions.precipProbability}
            snowDepth={safetyData.snowpack?.depth ?? 0}
            snowfall24h={safetyData.snowpack?.snowfall24h ?? 0}
            snowfall7d={safetyData.snowpack?.snowfall7d ?? 0}
            temperature={safetyData.conditions.temperature}
          />
        </div>

        {/* Footer */}
        <footer className="text-center text-xs text-text-quaternary pt-6 border-t border-border-secondary">
          <p>
            Data sources: NRCS SNOTEL • NOAA National Weather Service
          </p>
          <p className="mt-1">
            Last updated: {new Date(safetyData.timestamp).toLocaleString()}
          </p>
        </footer>
      </main>
    </div>
  );
}
