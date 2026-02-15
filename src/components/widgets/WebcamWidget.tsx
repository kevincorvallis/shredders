'use client';

import { useState } from 'react';

interface WebcamWidgetProps {
  mountain: string;
  name: string;
  url: string;
  refreshUrl?: string;
}

export function WebcamWidget({ mountain, name, url, refreshUrl }: WebcamWidgetProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  const handleRefresh = () => {
    setIsLoading(true);
    setHasError(false);
    setRefreshKey(prev => prev + 1);
  };

  // Add cache-busting query param
  const imageUrl = `${url}?t=${refreshKey}-${Date.now()}`;

  return (
    <div className="bg-gradient-to-br from-surface-tertiary/40 to-surface-tertiary/20 rounded-xl overflow-hidden border border-border-primary/30">
      <div className="flex items-center justify-between px-4 py-2 bg-black/20">
        <div>
          <h3 className="text-text-primary font-semibold text-sm">{mountain}</h3>
          <p className="text-text-tertiary text-xs">{name} Webcam</p>
        </div>
        <div className="flex items-center gap-2">
          <span className="flex items-center gap-1 text-xs text-green-400">
            <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
            LIVE
          </span>
          <button
            onClick={handleRefresh}
            className="p-1.5 hover:bg-white/10 rounded transition-colors"
            title="Refresh webcam"
          >
            <svg
              className="w-4 h-4 text-text-tertiary"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
          </button>
        </div>
      </div>

      <div className="relative aspect-video bg-surface-primary">
        {isLoading && (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-2 border-white/20 border-t-white"></div>
          </div>
        )}

        {hasError ? (
          <div className="absolute inset-0 flex flex-col items-center justify-center text-text-tertiary">
            <svg className="w-12 h-12 mb-2 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
            <p className="text-sm">Webcam unavailable</p>
            <button
              onClick={handleRefresh}
              className="mt-2 px-3 py-1 text-xs bg-white/10 hover:bg-white/20 rounded transition-colors"
            >
              Try again
            </button>
          </div>
        ) : (
          <img
            key={refreshKey}
            src={imageUrl}
            alt={`${mountain} ${name} webcam`}
            className={`w-full h-full object-cover ${isLoading ? 'opacity-0' : 'opacity-100'} transition-opacity duration-300`}
            onLoad={() => setIsLoading(false)}
            onError={() => {
              setIsLoading(false);
              setHasError(true);
            }}
          />
        )}
      </div>

      {refreshUrl && (
        <div className="px-4 py-2 bg-black/20 border-t border-white/5">
          <a
            href={refreshUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs text-accent hover:text-accent transition-colors"
          >
            View all webcams →
          </a>
        </div>
      )}
    </div>
  );
}
