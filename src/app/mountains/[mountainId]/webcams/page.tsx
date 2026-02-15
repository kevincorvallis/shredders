'use client';

import { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { getMountain } from '@shredders/shared';
import { Shield, Home, History, Camera, ArrowLeft, RefreshCw, ExternalLink } from 'lucide-react';

interface Webcam {
  id: string;
  name: string;
  url: string;
  refreshUrl?: string;
}

interface RoadWebcam {
  id: string;
  name: string;
  url: string;
  highway: string;
  milepost?: string;
  agency: 'WSDOT' | 'ODOT' | 'ITD';
}

export default function WebcamsPage({
  params,
}: {
  params: Promise<{ mountainId: string }>;
}) {
  const { mountainId } = use(params);
  const mountain = getMountain(mountainId);

  const [refreshKey, setRefreshKey] = useState(0);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefresh = () => {
    setIsRefreshing(true);
    setRefreshKey((k) => k + 1);
    setTimeout(() => setIsRefreshing(false), 1000);
  };

  // Auto-refresh every 2 minutes
  useEffect(() => {
    const interval = setInterval(() => {
      setRefreshKey((k) => k + 1);
    }, 2 * 60 * 1000);
    return () => clearInterval(interval);
  }, []);

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

  const webcams: Webcam[] = mountain.webcams || [];
  const roadWebcams: RoadWebcam[] = mountain.roadWebcams || [];

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
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-text-tertiary hover:text-text-primary hover:bg-surface-secondary/50"
            >
              <History className="w-4 h-4" />
              History
            </Link>
            <Link
              href={`/mountains/${mountainId}/webcams`}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors bg-surface-secondary text-text-primary"
            >
              <Camera className="w-4 h-4" />
              Webcams
            </Link>
          </nav>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-6 space-y-6">
        {/* Header with refresh */}
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-text-primary">Live Webcams</h2>
          <button
            onClick={handleRefresh}
            disabled={isRefreshing}
            className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-surface-secondary hover:bg-surface-tertiary transition-colors disabled:opacity-50"
          >
            <RefreshCw className={`w-4 h-4 text-text-tertiary ${isRefreshing ? 'animate-spin' : ''}`} />
            <span className="text-sm text-text-secondary">Refresh</span>
          </button>
        </div>

        {webcams.length === 0 && roadWebcams.length === 0 ? (
          <div className="bg-surface-secondary rounded-xl p-8 text-center">
            <Camera className="w-12 h-12 text-text-quaternary mx-auto mb-4" />
            <h3 className="text-lg font-medium text-text-primary mb-2">No Webcams Available</h3>
            <p className="text-text-tertiary">
              Webcam feeds are not available for this mountain.
            </p>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Resort Webcams */}
            {webcams.length > 0 && (
              <div className="space-y-4">
                <h3 className="text-md font-semibold text-text-primary flex items-center gap-2">
                  <Camera className="w-5 h-5" />
                  Resort Webcams
                </h3>
                {webcams.map((webcam) => (
                  <div key={webcam.id} className="bg-surface-secondary rounded-xl overflow-hidden">
                    <div className="aspect-video bg-surface-tertiary relative">
                      <img
                        key={`${webcam.id}-${refreshKey}`}
                        src={`${webcam.url}${webcam.url.includes('?') ? '&' : '?'}t=${refreshKey}`}
                        alt={webcam.name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          const target = e.target as HTMLImageElement;
                          target.style.display = 'none';
                          const parent = target.parentElement;
                          if (parent && !parent.querySelector('.error-message')) {
                            const errorDiv = document.createElement('div');
                            errorDiv.className = 'error-message absolute inset-0 flex items-center justify-center text-text-quaternary';
                            errorDiv.innerHTML = '<span>Image unavailable</span>';
                            parent.appendChild(errorDiv);
                          }
                        }}
                      />
                    </div>
                    <div className="p-4 flex items-center justify-between">
                      <div>
                        <h3 className="text-text-primary font-medium">{webcam.name}</h3>
                        <p className="text-sm text-text-tertiary">Auto-refreshes every 2 minutes</p>
                      </div>
                      {webcam.refreshUrl && (
                        <a
                          href={webcam.refreshUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex items-center gap-1 text-sm text-accent hover:text-accent-hover transition-colors"
                        >
                          <span>View on site</span>
                          <ExternalLink className="w-4 h-4" />
                        </a>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Road/Highway Webcams */}
            {roadWebcams.length > 0 && (
              <div className="space-y-4">
                <h3 className="text-md font-semibold text-text-primary flex items-center gap-2">
                  <Camera className="w-5 h-5" />
                  Road & Highway Webcams
                </h3>
                {roadWebcams.map((webcam) => (
                  <div key={webcam.id} className="bg-surface-secondary rounded-xl overflow-hidden">
                    <div className="aspect-video bg-surface-tertiary relative">
                      <img
                        key={`${webcam.id}-${refreshKey}`}
                        src={`${webcam.url}${webcam.url.includes('?') ? '&' : '?'}t=${refreshKey}`}
                        alt={webcam.name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          const target = e.target as HTMLImageElement;
                          target.style.display = 'none';
                          const parent = target.parentElement;
                          if (parent && !parent.querySelector('.error-message')) {
                            const errorDiv = document.createElement('div');
                            errorDiv.className = 'error-message absolute inset-0 flex items-center justify-center text-text-quaternary';
                            errorDiv.innerHTML = '<span>Image unavailable</span>';
                            parent.appendChild(errorDiv);
                          }
                        }}
                      />
                    </div>
                    <div className="p-4">
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <h3 className="text-text-primary font-medium">{webcam.name}</h3>
                          <p className="text-sm text-text-tertiary">
                            {webcam.highway} {webcam.milepost && `• MP ${webcam.milepost}`} • {webcam.agency}
                          </p>
                        </div>
                      </div>
                      <p className="text-xs text-text-quaternary">Auto-refreshes every 2 minutes</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Tips */}
        <div className="bg-surface-secondary/50 rounded-xl p-4 text-sm text-text-tertiary">
          <p>
            Webcam images are loaded directly from the resort&apos;s servers.
            Availability and update frequency vary by location.
          </p>
        </div>
      </main>
    </div>
  );
}
