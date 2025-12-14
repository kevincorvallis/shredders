'use client';

import { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { getMountain } from '@/data/mountains';
import { Shield, Home, History, Camera } from 'lucide-react';

interface Conditions {
  snowDepth: number | null;
  snowfall24h: number;
  snowfall48h: number;
  temperature: number | null;
  conditions: string;
  wind: { speed: number; direction: string } | null;
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

export default function MountainPage({
  params,
}: {
  params: Promise<{ mountainId: string }>;
}) {
  const { mountainId } = use(params);
  const mountain = getMountain(mountainId);

  const [conditions, setConditions] = useState<Conditions | null>(null);
  const [powderScore, setPowderScore] = useState<PowderScore | null>(null);
  const [forecast, setForecast] = useState<ForecastDay[]>([]);
  const [roads, setRoads] = useState<RoadsResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      if (!mountain) return;

      try {
        const [conditionsRes, scoreRes, forecastRes] = await Promise.all([
          fetch(`/api/mountains/${mountainId}/conditions`),
          fetch(`/api/mountains/${mountainId}/powder-score`),
          fetch(`/api/mountains/${mountainId}/forecast`),
        ]);

        // Road data is optional; don't block the rest of the page
        fetch(`/api/mountains/${mountainId}/roads`)
          .then((r) => (r.ok ? r.json() : null))
          .then((data) => {
            if (data) setRoads(data);
          })
          .catch(() => {
            // ignore
          });

        if (conditionsRes.ok) {
          const data = await conditionsRes.json();
          setConditions(data);
        }

        if (scoreRes.ok) {
          const data = await scoreRes.json();
          setPowderScore(data);
        }

        if (forecastRes.ok) {
          const data = await forecastRes.json();
          setForecast(data.forecast || []);
        }
      } catch (err) {
        setError('Failed to load mountain data');
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    }

    fetchData();
  }, [mountainId, mountain]);

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

  return (
    <div className="min-h-screen bg-slate-900">
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
            <div className="flex items-center gap-2">
              <span
                className="w-4 h-4 rounded-full"
                style={{ backgroundColor: mountain.color }}
              />
              <h1 className="text-xl font-bold text-white">{mountain.name}</h1>
            </div>
            <a
              href={mountain.website}
              target="_blank"
              rel="noopener noreferrer"
              className="ml-auto text-sm text-gray-400 hover:text-white transition-colors"
            >
              Official Site ↗
            </a>
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
                <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                  {powderScore.factors.map((factor, i) => (
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
                    {roads.passes.slice(0, 2).map((p) => (
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
                              {p.restrictions.slice(0, 3).map((r, idx) => (
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

            {/* 7-Day Forecast */}
            {forecast.length > 0 && (
              <div className="bg-slate-800 rounded-xl p-6">
                <h2 className="text-lg font-semibold text-white mb-4">7-Day Forecast</h2>
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
                      {mountain.noaa.gridOffice}/{mountain.noaa.gridX},{mountain.noaa.gridY}
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
