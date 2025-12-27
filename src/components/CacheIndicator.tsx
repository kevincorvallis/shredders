'use client';

import { useState, useEffect } from 'react';

interface CacheIndicatorProps {
  cachedAt?: string;
  isLoading?: boolean;
  className?: string;
}

export function CacheIndicator({ cachedAt, isLoading, className = '' }: CacheIndicatorProps) {
  const [timeAgo, setTimeAgo] = useState<string>('');

  useEffect(() => {
    if (!cachedAt) return;

    const updateTimeAgo = () => {
      const cached = new Date(cachedAt);
      const now = new Date();
      const diffMs = now.getTime() - cached.getTime();
      const diffSec = Math.floor(diffMs / 1000);
      const diffMin = Math.floor(diffSec / 60);

      if (diffSec < 60) {
        setTimeAgo(`${diffSec}s ago`);
      } else if (diffMin < 60) {
        setTimeAgo(`${diffMin}m ago`);
      } else {
        setTimeAgo(cached.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }));
      }
    };

    updateTimeAgo();
    const interval = setInterval(updateTimeAgo, 10000); // Update every 10 seconds

    return () => clearInterval(interval);
  }, [cachedAt]);

  if (isLoading) {
    return (
      <div className={`flex items-center gap-1.5 text-xs ${className}`}>
        <div className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
        <span className="text-blue-400">Loading...</span>
      </div>
    );
  }

  if (!cachedAt) return null;

  return (
    <div className={`flex items-center gap-1.5 text-xs ${className}`}>
      <div className="w-2 h-2 rounded-full bg-green-500" />
      <span className="text-gray-400">
        Updated {timeAgo}
      </span>
    </div>
  );
}
