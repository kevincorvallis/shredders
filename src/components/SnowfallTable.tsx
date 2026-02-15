'use client';

import { useState, useEffect, useRef, useMemo } from 'react';
import { getAllMountains, type MountainConfig } from '@shredders/shared';
import Image from 'next/image';
import Link from 'next/link';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface SnowfallData {
  mountainId: string;
  dates: {
    date: string;
    snowfall: number;
    isForecast: boolean;
    isToday: boolean;
  }[];
}

interface SnowfallTableProps {
  daysBack?: number;
  daysForward?: number;
}

export function SnowfallTable({ daysBack = 7, daysForward = 7 }: SnowfallTableProps) {
  const [snowfallData, setSnowfallData] = useState<SnowfallData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const mountains = getAllMountains();

  // Generate date range (memoized to avoid recalculation on every render)
  const dateRange = useMemo(() => {
    const dates = [];
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (let i = daysBack; i > 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      dates.push({
        date: date.toISOString().split('T')[0],
        isForecast: false,
        isToday: false,
      });
    }

    dates.push({
      date: today.toISOString().split('T')[0],
      isForecast: false,
      isToday: true,
    });

    for (let i = 1; i <= daysForward; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() + i);
      dates.push({
        date: date.toISOString().split('T')[0],
        isForecast: true,
        isToday: false,
      });
    }

    return dates;
  }, [daysBack, daysForward]);

  useEffect(() => {
    async function fetchSnowfallData() {
      setIsLoading(true);

      try {
        // Use batch endpoint - 1 request instead of 30!
        const response = await fetch(
          `/api/mountains/batch/snowfall?daysBack=${daysBack}&daysForward=${daysForward}`
        );

        if (!response.ok) {
          throw new Error('Failed to fetch snowfall data');
        }

        const batchData = await response.json();

        // Transform batch data to match expected format
        const data: SnowfallData[] = batchData.data.map((mountainData: any) => ({
          mountainId: mountainData.mountainId,
          dates: mountainData.dates,
        }));

        setSnowfallData(data);
      } catch (error) {
        console.error('Error fetching snowfall data:', error);
        // Fallback to empty data
        setSnowfallData(
          mountains.map((mountain) => ({
            mountainId: mountain.id,
            dates: dateRange.map((dateInfo) => ({
              date: dateInfo.date,
              snowfall: 0,
              isForecast: dateInfo.isForecast,
              isToday: dateInfo.isToday,
            })),
          }))
        );
      }

      setIsLoading(false);

      // Scroll to today after loading
      setTimeout(() => {
        if (scrollContainerRef.current) {
          const todayIndex = daysBack;
          const cellWidth = 80; // approximate
          scrollContainerRef.current.scrollLeft = todayIndex * cellWidth - 200;
        }
      }, 100);
    }

    fetchSnowfallData();
  }, [daysBack, daysForward]);

  const getSnowfallColor = (snowfall: number, isForecast: boolean) => {
    if (snowfall === 0) return isForecast ? 'bg-surface-secondary/30' : 'bg-surface-secondary/50';
    if (snowfall < 2) return 'bg-snow-1 text-text-primary';
    if (snowfall < 4) return 'bg-snow-2 text-text-primary';
    if (snowfall < 6) return 'bg-snow-3 text-text-primary';
    if (snowfall < 10) return 'bg-snow-4 text-text-primary';
    return 'bg-snow-5 text-text-primary font-bold';
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const month = date.toLocaleDateString('en-US', { month: 'short' });
    const day = date.getDate();
    const dayOfWeek = date.toLocaleDateString('en-US', { weekday: 'short' });
    return { month, day, dayOfWeek };
  };

  const scrollLeft = () => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollBy({ left: -240, behavior: 'smooth' });
    }
  };

  const scrollRight = () => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollBy({ left: 240, behavior: 'smooth' });
    }
  };

  if (isLoading) {
    return (
      <div className="bg-surface-primary rounded-2xl p-8">
        <div className="flex items-center justify-center">
          <div className="flex items-center gap-2 text-text-secondary">
            <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
            <span>Loading snowfall data...</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-surface-primary rounded-2xl overflow-hidden">
      {/* Header */}
      <div className="p-4 border-b border-border-secondary flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-text-primary tracking-tight">Snowfall Tracker</h2>
          <p className="text-sm text-text-secondary">Past {daysBack} days • Next {daysForward} days</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={scrollLeft}
            className="p-2 bg-surface-secondary hover:bg-surface-tertiary rounded-lg transition-colors"
            aria-label="Scroll left"
          >
            <ChevronLeft className="w-5 h-5 text-text-primary" />
          </button>
          <button
            onClick={scrollRight}
            className="p-2 bg-surface-secondary hover:bg-surface-tertiary rounded-lg transition-colors"
            aria-label="Scroll right"
          >
            <ChevronRight className="w-5 h-5 text-text-primary" />
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="relative">
        {/* Fixed mountain names column */}
        <div className="absolute left-0 top-0 bottom-0 w-48 bg-surface-primary z-10 border-r border-border-secondary">
          {/* Header spacer */}
          <div className="h-20 border-b border-border-secondary" />

          {/* Mountain names */}
          {mountains.map((mountain) => (
            <Link
              key={mountain.id}
              href={`/mountains/${mountain.id}`}
              className="flex items-center gap-3 p-3 h-16 border-b border-border-secondary hover:bg-accent-subtle transition-colors"
            >
              {mountain.logo ? (
                <Image
                  src={mountain.logo}
                  alt={mountain.name}
                  width={32}
                  height={32}
                  className="rounded flex-shrink-0"
                />
              ) : (
                <div
                  className="w-8 h-8 rounded flex items-center justify-center flex-shrink-0"
                  style={{ backgroundColor: mountain.color + '40' }}
                >
                  <span className="text-sm">🏔️</span>
                </div>
              )}
              <div className="min-w-0 flex-1">
                <div className="text-sm font-medium text-text-primary truncate">
                  {mountain.shortName}
                </div>
                <div className="text-xs text-text-tertiary truncate capitalize">
                  {mountain.region}
                </div>
              </div>
            </Link>
          ))}
        </div>

        {/* Scrollable data area */}
        <div
          ref={scrollContainerRef}
          className="overflow-x-auto pl-48 scrollbar-thin "
        >
          <div className="inline-block min-w-full">
            {/* Date headers */}
            <div className="flex border-b border-border-secondary bg-surface-primary/95 sticky top-0 z-5">
              {dateRange.map((dateInfo, index) => {
                const { month, day, dayOfWeek } = formatDate(dateInfo.date);
                return (
                  <div
                    key={index}
                    className={`w-20 p-2 text-center border-r border-border-secondary ${
                      dateInfo.isToday ? 'bg-accent-subtle' : ''
                    }`}
                  >
                    <div className="text-xs text-text-tertiary">{dayOfWeek}</div>
                    <div className={`text-sm font-semibold ${dateInfo.isToday ? 'text-accent' : 'text-text-primary'}`}>
                      {month} {day}
                    </div>
                    <div className="text-xs text-text-quaternary">
                      {dateInfo.isForecast ? 'forecast' : 'actual'}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Data rows */}
            {snowfallData.map((mountainData) => {
              const mountain = mountains.find((m) => m.id === mountainData.mountainId);
              if (!mountain) return null;

              return (
                <div key={mountain.id} className="flex border-b border-border-secondary">
                  {mountainData.dates.map((dateData, index) => (
                    <div
                      key={index}
                      className={`w-20 h-16 p-2 flex items-center justify-center border-r border-border-secondary ${
                        dateData.isToday ? 'bg-accent-subtle/50' : ''
                      } ${getSnowfallColor(dateData.snowfall, dateData.isForecast)}`}
                    >
                      <div className="text-center">
                        {dateData.snowfall > 0 ? (
                          <>
                            <div className="text-lg font-bold">{dateData.snowfall}"</div>
                            {dateData.snowfall >= 6 && (
                              <div className="text-xs">❄️</div>
                            )}
                          </>
                        ) : (
                          <div className="text-text-quaternary text-sm">—</div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Legend */}
      <div className="p-4 border-t border-border-secondary bg-surface-primary/50">
        <div className="flex items-center gap-6 text-xs text-text-secondary">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-snow-1" />
            <span>1-2"</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-snow-2" />
            <span>2-4"</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-snow-3" />
            <span>4-6"</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-snow-4" />
            <span>6-10"</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-snow-5" />
            <span>10"+</span>
          </div>
          <div className="ml-auto flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-accent" />
            <span className="text-accent">Today</span>
          </div>
        </div>
      </div>
    </div>
  );
}
