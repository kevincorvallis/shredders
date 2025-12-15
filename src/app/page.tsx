'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useMountain } from '@/context/MountainContext';
import { getMountain } from '@/data/mountains';

interface Conditions {
  snowDepth: number | null;
  snowfall24h: number;
  snowfall48h: number;
  snowfall7d: number;
  temperature: number | null;
  conditions: string;
  wind: { speed: number; direction: string } | null;
  freezingLevel: number | null;
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

export default function Home() {
  const { selectedMountainId } = useMountain();
  const mountain = getMountain(selectedMountainId);

  const [conditions, setConditions] = useState<Conditions | null>(null);
  const [powderScore, setPowderScore] = useState<PowderScore | null>(null);
  const [forecast, setForecast] = useState<ForecastDay[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      if (!mountain) return;

      setIsLoading(true);
      setError(null);

      try {
        const [conditionsRes, scoreRes, forecastRes] = await Promise.all([
          fetch(`/api/mountains/${selectedMountainId}/conditions`),
          fetch(`/api/mountains/${selectedMountainId}/powder-score`),
          fetch(`/api/mountains/${selectedMountainId}/forecast`),
        ]);

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
        setError('Failed to load data');
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    }

    fetchData();
  }, [selectedMountainId, mountain]);

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

  if (!mountain) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center text-gray-400">
          <p>Select a mountain to view conditions</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <div className="max-w-4xl mx-auto px-4 py-8">
        {/* Mountain Name */}
        <div className="mb-8 text-center">
          <div className="flex items-center justify-center gap-3 mb-2">
            <span
              className="w-4 h-4 rounded-full"
              style={{ backgroundColor: mountain.color }}
            />
            <h1 className="text-3xl font-bold text-white">{mountain.name}</h1>
          </div>
          <p className="text-gray-400">
            {mountain.elevation.base.toLocaleString()}' - {mountain.elevation.summit.toLocaleString()}' elevation
          </p>
          <Link
            href={`/mountains/${selectedMountainId}`}
            className="text-sky-400 hover:text-sky-300 text-sm mt-2 inline-block"
          >
            View full details →
          </Link>
        </div>

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
          <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 text-red-400 text-center">
            {error}
          </div>
        ) : (
          <div className="space-y-6">
            {/* Powder Score - Hero */}
            {powderScore && (
              <div className="bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl p-8 text-center">
                <div className="mb-4">
                  <div
                    className={`text-7xl font-bold inline-block ${
                      powderScore.score >= 7
                        ? 'text-green-400'
                        : powderScore.score >= 5
                          ? 'text-yellow-400'
                          : 'text-red-400'
                    }`}
                  >
                    {powderScore.score.toFixed(1)}
                  </div>
                  <div className="text-2xl text-gray-500">/10</div>
                </div>
                <div className="text-xl text-white font-medium mb-2">Powder Score</div>
                <p className="text-gray-300 max-w-md mx-auto">{powderScore.verdict}</p>

                {/* Factors */}
                <div className="mt-6 grid grid-cols-2 md:grid-cols-3 gap-3 max-w-2xl mx-auto">
                  {powderScore.factors.slice(0, 6).map((factor, i) => (
                    <div key={i} className="bg-slate-700/30 rounded-lg p-3 text-left">
                      <div className="text-xs text-gray-400 mb-1">{factor.name}</div>
                      <div className="text-sm text-white">{factor.description}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Quick Stats */}
            {conditions && (
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-slate-800 rounded-xl p-4 text-center">
                  <div className="text-3xl mb-1">❄️</div>
                  <div className="text-2xl font-bold text-white">
                    {conditions.snowDepth ?? '--'}"
                  </div>
                  <div className="text-xs text-gray-400">Snow Depth</div>
                </div>
                <div className="bg-slate-800 rounded-xl p-4 text-center">
                  <div className="text-3xl mb-1">🌨️</div>
                  <div className="text-2xl font-bold text-white">
                    {conditions.snowfall24h}"
                  </div>
                  <div className="text-xs text-gray-400">24hr Snow</div>
                </div>
                <div className="bg-slate-800 rounded-xl p-4 text-center">
                  <div className="text-3xl mb-1">🌡️</div>
                  <div className="text-2xl font-bold text-white">
                    {conditions.temperature ?? '--'}°F
                  </div>
                  <div className="text-xs text-gray-400">Temperature</div>
                </div>
                <div className="bg-slate-800 rounded-xl p-4 text-center">
                  <div className="text-3xl mb-1">💨</div>
                  <div className="text-2xl font-bold text-white">
                    {conditions.wind?.speed ?? '--'} mph
                  </div>
                  <div className="text-xs text-gray-400">Wind {conditions.wind?.direction ?? ''}</div>
                </div>
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
                          {day.snowfall}" snow
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Quick Links */}
            <div className="grid grid-cols-2 gap-4">
              <Link
                href="/chat"
                className="bg-gradient-to-r from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700 rounded-xl p-6 text-center transition-colors"
              >
                <div className="text-3xl mb-2">💬</div>
                <div className="text-white font-semibold">Ask AI</div>
                <div className="text-sm text-white/70">Chat about conditions</div>
              </Link>
              <Link
                href={`/mountains/${selectedMountainId}`}
                className="bg-slate-800 hover:bg-slate-700 rounded-xl p-6 text-center transition-colors"
              >
                <div className="text-3xl mb-2">📊</div>
                <div className="text-white font-semibold">Full Report</div>
                <div className="text-sm text-gray-400">Detailed conditions</div>
              </Link>
            </div>
          </div>
        )}

        {/* Footer */}
        <footer className="mt-12 text-center text-sm text-gray-500">
          <p>Data: NOAA Weather API, SNOTEL • Built with Next.js + Claude AI</p>
        </footer>
      </div>
    </div>
  );
}
