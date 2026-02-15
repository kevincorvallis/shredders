'use client';

import Link from 'next/link';
import Image from 'next/image';
import { type MountainConfig } from '@shredders/shared';
import { prefetchMountainData } from '@/hooks/useMountainData';
import { MountainStatus } from './MountainStatus';

interface MountainCardProps {
  mountain: MountainConfig;
  powderScore?: number;
  distance?: number;
  isSelected?: boolean;
  onClick?: () => void;
}

export function MountainCard({
  mountain,
  powderScore,
  distance,
  isSelected,
  onClick,
}: MountainCardProps) {
  const className = `block w-full text-left p-4 bg-surface-primary hover:bg-surface-secondary rounded-2xl border transition-all ${
    isSelected
      ? 'border-accent ring-2 ring-accent/20'
      : 'border-border-secondary hover:border-border-primary shadow-sm hover:shadow-md'
  }`;

  const content = (
      <div className="space-y-3">
        <div className="flex items-start gap-3">
          {/* Logo */}
          {mountain.logo ? (
            <div className="flex-shrink-0">
              <Image
                src={mountain.logo}
                alt={`${mountain.name} logo`}
                width={48}
                height={48}
                className="rounded-xl"
                loading="lazy"
                quality={85}
              />
            </div>
          ) : (
            <div
              className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0"
              style={{ backgroundColor: mountain.color + '20' }}
            >
              <span className="text-xl">🏔️</span>
            </div>
          )}

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <h3 className="text-text-primary font-semibold truncate">{mountain.name}</h3>
              {!mountain.snotel && (
                <span className="px-1.5 py-0.5 bg-amber-500/10 text-amber-600 dark:text-amber-400 text-xs rounded">
                  Limited
                </span>
              )}
            </div>
            <div className="flex items-center gap-3 mt-1 text-sm text-text-secondary">
              <span>{mountain.elevation.summit.toLocaleString()}ft</span>
              <span className="capitalize">{mountain.region}</span>
              {distance !== undefined && <span>{distance.toFixed(0)} mi</span>}
            </div>
          </div>

          {powderScore !== undefined && (
            <div className="flex flex-col items-center">
              <div
                className={`text-2xl font-bold ${
                  powderScore >= 7
                    ? 'text-green-500'
                    : powderScore >= 5
                      ? 'text-yellow-500'
                      : 'text-red-500'
                }`}
              >
                {powderScore.toFixed(1)}
              </div>
              <div className="text-xs text-text-tertiary">score</div>
            </div>
          )}
        </div>

        {/* Status */}
        {mountain.status && (
          <MountainStatus status={mountain.status} variant="compact" />
        )}
      </div>
  );

  if (onClick) {
    return (
      <button onClick={onClick} type="button" className={className}>
        {content}
      </button>
    );
  }

  return (
    <Link
      href={`/mountains/${mountain.id}`}
      className={className}
      onMouseEnter={() => prefetchMountainData(mountain.id)}
      onFocus={() => prefetchMountainData(mountain.id)}
    >
      {content}
    </Link>
  );
}

interface MountainCardSkeletonProps {
  count?: number;
}

export function MountainCardSkeleton({ count = 1 }: MountainCardSkeletonProps) {
  return (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="p-4 bg-surface-primary rounded-2xl border border-border-secondary animate-pulse"
        >
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-xl bg-surface-tertiary" />
            <div className="flex-1">
              <div className="h-5 bg-surface-tertiary rounded w-32 mb-2" />
              <div className="h-4 bg-surface-tertiary rounded w-24" />
            </div>
            <div className="h-8 w-12 bg-surface-tertiary rounded" />
          </div>
        </div>
      ))}
    </>
  );
}
