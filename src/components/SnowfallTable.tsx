'use client';

import { useState, useEffect, useRef, useMemo } from 'react';
import { getAllMountains, type MountainConfig } from '@shredders/shared';
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

  // Index of the last actual day (the one right before forecast starts)
  const dividerIndex = useMemo(() => {
    for (let i = dateRange.length - 1; i >= 0; i--) {
      if (!dateRange[i].isForecast) return i;
    }
    return -1;
  }, [dateRange]);

  useEffect(() => {
    async function fetchSnowfallData() {
      setIsLoading(true);

      try {
        const response = await fetch(
          `/api/mountains/batch/snowfall?daysBack=${daysBack}&daysForward=${daysForward}`
        );

        if (!response.ok) {
          throw new Error('Failed to fetch snowfall data');
        }

        const batchData = await response.json();

        const data: SnowfallData[] = batchData.data.map((mountainData: any) => ({
          mountainId: mountainData.mountainId,
          dates: mountainData.dates,
        }));

        setSnowfallData(data);
      } catch (error) {
        console.error('Error fetching snowfall data:', error);
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

      setTimeout(() => {
        if (scrollContainerRef.current) {
          const todayIndex = daysBack;
          const cellWidth = window.innerWidth < 640 ? 40 : 56;
          scrollContainerRef.current.scrollLeft = todayIndex * cellWidth - 160;
        }
      }, 100);
    }

    fetchSnowfallData();
  }, [daysBack, daysForward]);

  const getSnowfallColor = (snowfall: number, isForecast: boolean) => {
    if (snowfall === 0) return isForecast ? 'bg-surface-secondary/20' : '';
    if (snowfall < 2) return 'bg-snow-1';
    if (snowfall < 4) return 'bg-snow-2';
    if (snowfall < 6) return 'bg-snow-3';
    if (snowfall < 10) return 'bg-snow-4';
    return 'bg-snow-5';
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const day = date.getDate();
    const dayOfWeek = date.toLocaleDateString('en-US', { weekday: 'short' });
    return { day, dayOfWeek };
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
      <div className="bg-surface-primary rounded-xl p-4">
        <div className="flex items-center justify-center gap-2 text-text-secondary text-sm">
          <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          <span>Loading snowfall data...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-surface-primary rounded-xl overflow-hidden">
      {/* Compact header */}
      <div className="px-3 py-2 border-b border-border-secondary flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h2 className="text-sm font-semibold text-text-primary">Snowfall</h2>
          <div className="hidden sm:flex items-center gap-2 text-[9px] text-text-quaternary">
            <div className="flex items-center gap-0.5"><div className="w-2 h-2 rounded-sm bg-snow-1" /><span>1-2</span></div>
            <div className="flex items-center gap-0.5"><div className="w-2 h-2 rounded-sm bg-snow-3" /><span>4-6</span></div>
            <div className="flex items-center gap-0.5"><div className="w-2 h-2 rounded-sm bg-snow-5" /><span>10+</span></div>
          </div>
        </div>
        <div className="flex items-center gap-0.5">
          <button onClick={scrollLeft} className="p-1 hover:bg-surface-secondary rounded transition-colors" aria-label="Scroll left">
            <ChevronLeft className="w-3.5 h-3.5 text-text-tertiary" />
          </button>
          <button onClick={scrollRight} className="p-1 hover:bg-surface-secondary rounded transition-colors" aria-label="Scroll right">
            <ChevronRight className="w-3.5 h-3.5 text-text-tertiary" />
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="relative">
        {/* Fixed mountain names column */}
        <div className="absolute left-0 top-0 bottom-0 w-24 sm:w-32 bg-surface-primary z-10 border-r border-border-secondary">
          {/* Header spacer */}
          <div className="h-12" />

          {/* Mountain names */}
          {mountains.map((mountain) => (
            <Link
              key={mountain.id}
              href={`/mountains/${mountain.id}`}
              className="flex items-center gap-2 px-3 h-10 hover:bg-accent-subtle transition-colors"
            >
              <div
                className="w-2 h-2 rounded-full flex-shrink-0"
                style={{ backgroundColor: mountain.color }}
              />
              <span className="text-[11px] sm:text-xs font-medium text-text-primary truncate">
                {mountain.shortName}
              </span>
            </Link>
          ))}
        </div>

        {/* Scrollable data area */}
        <div
          ref={scrollContainerRef}
          className="overflow-x-auto pl-24 sm:pl-32 scrollbar-thin"
        >
          <div className="inline-block min-w-full">
            {/* Date headers */}
            <div className="flex bg-surface-primary">
              {dateRange.map((dateInfo, index) => {
                const { day, dayOfWeek } = formatDate(dateInfo.date);
                const isDivider = index === dividerIndex;
                return (
                  <div
                    key={index}
                    className={`w-10 sm:w-14 h-12 flex flex-col items-center justify-center ${
                      isDivider ? 'border-r border-dashed border-text-quaternary' : ''
                    }`}
                  >
                    <div className="text-[9px] sm:text-[10px] text-text-quaternary leading-none">{dayOfWeek}</div>
                    <div className={`text-xs sm:text-sm font-semibold leading-tight ${
                      dateInfo.isToday ? 'text-accent' : 'text-text-primary'
                    }`}>
                      {day}
                    </div>
                    {dateInfo.isToday && (
                      <div className="w-1 h-1 rounded-full bg-accent mt-0.5" />
                    )}
                  </div>
                );
              })}
            </div>

            {/* Data grid with hairline gaps */}
            <div className="flex flex-col gap-px bg-border-secondary">
              {snowfallData.map((mountainData) => {
                const mountain = mountains.find((m) => m.id === mountainData.mountainId);
                if (!mountain) return null;

                return (
                  <div key={mountain.id} className="flex gap-px">
                    {mountainData.dates.map((dateData, index) => {
                      const isDivider = index === dividerIndex;
                      const colorClass = getSnowfallColor(dateData.snowfall, dateData.isForecast);
                      return (
                        <div
                          key={index}
                          className={`w-10 sm:w-14 h-10 flex items-center justify-center ${
                            colorClass || 'bg-surface-primary'
                          } ${
                            isDivider ? 'border-r border-dashed border-text-quaternary' : ''
                          }`}
                        >
                          {dateData.snowfall > 0 && (
                            <span className="text-[11px] sm:text-xs font-semibold text-text-primary">
                              {dateData.snowfall}
                            </span>
                          )}
                        </div>
                      );
                    })}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
