'use client';

import { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { getMountain } from '@shredders/shared';
import { Shield, Home, History, Camera, ArrowLeft, RefreshCw } from 'lucide-react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
  Legend,
} from 'recharts';

interface HistoryPoint {
  date: string;
  snowDepth: number;
  snowfall: number;
  temperature: number;
}

interface HistoryData {
  mountain: { id: string; name: string };
  history: HistoryPoint[];
  days: number;
  source: { provider: string; stationName: string };
}

export default function HistoryPage({
  params,
}: {
  params: Promise<{ mountainId: string }>;
}) {
  const { mountainId } = use(params);
  const mountain = getMountain(mountainId);

  const [historyData, setHistoryData] = useState<HistoryData | null>(null);
  const [days, setDays] = useState(30);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchHistory = async (numDays: number) => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await fetch(`/api/mountains/${mountainId}/history?days=${numDays}`);
      if (res.ok) {
        const data = await res.json();
        setHistoryData(data);
      } else {
        setError('Failed to load history data');
      }
    } catch {
      setError('Failed to load history data');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (mountain) {
      fetchHistory(days);
    }
  }, [mountainId, days, mountain]);

  if (!mountain) {
    return (
      <div className="min-h-screen bg-surface-primary flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-text-primary mb-2">Mountain Not Found</h1>
          <Link href="/mountains" className="text-accent hover:text-accent-hover">
            View all mountains
          </Link>
        </div>
      </div>
    );
  }

  const formattedHistory = historyData?.history.map((point) => ({
    ...point,
    dateLabel: new Date(point.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
  })) || [];

  return (
    <div className="min-h-screen bg-surface-primary">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-surface-primary/95 backdrop-blur-sm border-b border-border-secondary">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <Link
              href={`/mountains/${mountainId}`}
              className="text-text-tertiary hover:text-text-primary transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div className="flex items-center gap-2">
              <span
                className="w-4 h-4 rounded-full"
                style={{ backgroundColor: mountain.color }}
              />
              <h1 className="text-xl font-bold text-text-primary">{mountain.name}</h1>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="max-w-4xl mx-auto px-4">
          <nav className="flex gap-1 border-t border-border-secondary pt-2 pb-2 overflow-x-auto">
            <Link
              href={`/mountains/${mountainId}`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-tertiary hover:text-text-primary hover:bg-surface-secondary/50"
            >
              <Home className="w-4 h-4" />
              Overview
            </Link>
            <Link
              href={`/mountains/${mountainId}/patrol`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-tertiary hover:text-text-primary hover:bg-surface-secondary/50"
            >
              <Shield className="w-4 h-4" />
              Patrol
            </Link>
            <Link
              href={`/mountains/${mountainId}/history`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors bg-surface-secondary text-text-primary"
            >
              <History className="w-4 h-4" />
              History
            </Link>
            <Link
              href={`/mountains/${mountainId}/webcams`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-tertiary hover:text-text-primary hover:bg-surface-secondary/50"
            >
              <Camera className="w-4 h-4" />
              Webcams
            </Link>
          </nav>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-6 space-y-6">
        {/* Period Selector */}
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-text-primary">Snow History</h2>
          <div className="flex items-center gap-2">
            <div className="flex gap-1 bg-surface-secondary rounded-lg p-1">
              {[30, 60, 90].map((d) => (
                <button
                  key={d}
                  onClick={() => setDays(d)}
                  className={`px-3 py-1 rounded text-sm font-medium transition-colors ${
                    days === d
                      ? 'bg-surface-tertiary text-text-primary'
                      : 'text-text-tertiary hover:text-text-primary'
                  }`}
                >
                  {d}d
                </button>
              ))}
            </div>
            <button
              onClick={() => fetchHistory(days)}
              disabled={isLoading}
              className="p-2 rounded-lg hover:bg-surface-secondary transition-colors disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 text-text-tertiary ${isLoading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>

        {isLoading ? (
          <div className="bg-surface-secondary rounded-xl p-8 flex items-center justify-center">
            <div className="flex items-center gap-2 text-text-tertiary">
              <RefreshCw className="w-5 h-5 animate-spin" />
              <span>Loading history...</span>
            </div>
          </div>
        ) : error ? (
          <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 text-red-400">
            {error}
          </div>
        ) : (
          <>
            {/* Snow Depth Chart */}
            <div className="bg-surface-secondary rounded-xl p-6">
              <h3 className="text-sm font-medium text-text-tertiary mb-4">Snow Depth (inches)</h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={formattedHistory}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis
                      dataKey="dateLabel"
                      stroke="#64748b"
                      fontSize={12}
                      tickLine={false}
                    />
                    <YAxis stroke="#64748b" fontSize={12} tickLine={false} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#1e293b',
                        border: '1px solid #334155',
                        borderRadius: '8px',
                      }}
                      labelStyle={{ color: '#94a3b8' }}
                    />
                    <Legend />
                    <Line
                      type="monotone"
                      dataKey="snowDepth"
                      stroke="#38bdf8"
                      strokeWidth={2}
                      dot={false}
                      name="Snow Depth"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Daily Snowfall Chart */}
            <div className="bg-surface-secondary rounded-xl p-6">
              <h3 className="text-sm font-medium text-text-tertiary mb-4">Daily Snowfall (inches)</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={formattedHistory}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis
                      dataKey="dateLabel"
                      stroke="#64748b"
                      fontSize={12}
                      tickLine={false}
                    />
                    <YAxis stroke="#64748b" fontSize={12} tickLine={false} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#1e293b',
                        border: '1px solid #334155',
                        borderRadius: '8px',
                      }}
                      labelStyle={{ color: '#94a3b8' }}
                    />
                    <Line
                      type="monotone"
                      dataKey="snowfall"
                      stroke="#a78bfa"
                      strokeWidth={2}
                      dot={false}
                      name="Snowfall"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Temperature Chart */}
            <div className="bg-surface-secondary rounded-xl p-6">
              <h3 className="text-sm font-medium text-text-tertiary mb-4">Temperature (°F)</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={formattedHistory}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis
                      dataKey="dateLabel"
                      stroke="#64748b"
                      fontSize={12}
                      tickLine={false}
                    />
                    <YAxis stroke="#64748b" fontSize={12} tickLine={false} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#1e293b',
                        border: '1px solid #334155',
                        borderRadius: '8px',
                      }}
                      labelStyle={{ color: '#94a3b8' }}
                    />
                    <Line
                      type="monotone"
                      dataKey="temperature"
                      stroke="#fb923c"
                      strokeWidth={2}
                      dot={false}
                      name="Temperature"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Data Source */}
            {historyData?.source && (
              <div className="text-center text-xs text-text-quaternary">
                Data source: {historyData.source.provider} - {historyData.source.stationName}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}
