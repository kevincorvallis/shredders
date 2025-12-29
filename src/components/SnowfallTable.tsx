'use client';

import { useState, useEffect, useRef } from 'react';
import { getAllMountains, type MountainConfig } from '@/data/mountains';
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

  // Generate date range
  const generateDateRange = () => {
    const dates = [];
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Past dates
    for (let i = daysBack; i > 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      dates.push({
        date: date.toISOString().split('T')[0],
        isForecast: false,
        isToday: false,
      });
    }

    // Today
    dates.push({
      date: today.toISOString().split('T')[0],
      isForecast: false,
      isToday: true,
    });

    // Future dates
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
  };

  const dateRange = generateDateRange();

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
    if (snowfall === 0) return isForecast ? 'bg-slate-800/30' : 'bg-slate-800/50';
    if (snowfall < 2) return 'bg-blue-900/40 text-blue-200';
    if (snowfall < 4) return 'bg-blue-700/50 text-blue-100';
    if (snowfall < 6) return 'bg-blue-600/60 text-white';
    if (snowfall < 10) return 'bg-blue-500/70 text-white';
    return 'bg-blue-400/80 text-white font-bold';
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
      <div className="bg-slate-900 rounded-xl p-8">
        <div className="flex items-center justify-center">
          <div className="flex items-center gap-2 text-gray-400">
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
    <div className="bg-slate-900 rounded-xl overflow-hidden">
      {/* Header */}
      <div className="p-4 border-b border-slate-800 flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-white">Snowfall Tracker</h2>
          <p className="text-sm text-gray-400">Past {daysBack} days • Next {daysForward} days</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={scrollLeft}
            className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-colors"
            aria-label="Scroll left"
          >
            <ChevronLeft className="w-5 h-5 text-white" />
          </button>
          <button
            onClick={scrollRight}
            className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-colors"
            aria-label="Scroll right"
          >
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="relative">
        {/* Fixed mountain names column */}
        <div className="absolute left-0 top-0 bottom-0 w-48 bg-slate-900 z-10 border-r border-slate-800">
          {/* Header spacer */}
          <div className="h-20 border-b border-slate-800" />

          {/* Mountain names */}
          {mountains.map((mountain) => (
            <Link
              key={mountain.id}
              href={`/mountains/${mountain.id}`}
              className="flex items-center gap-3 p-3 h-16 border-b border-slate-800 hover:bg-slate-800/50 transition-colors"
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
                <div className="text-sm font-medium text-white truncate">
                  {mountain.shortName}
                </div>
                <div className="text-xs text-gray-500 truncate capitalize">
                  {mountain.region}
                </div>
              </div>
            </Link>
          ))}
        </div>

        {/* Scrollable data area */}
        <div
          ref={scrollContainerRef}
          className="overflow-x-auto pl-48 scrollbar-thin scrollbar-thumb-slate-700 scrollbar-track-slate-900"
        >
          <div className="inline-block min-w-full">
            {/* Date headers */}
            <div className="flex border-b border-slate-800 bg-slate-900/95 sticky top-0 z-5">
              {dateRange.map((dateInfo, index) => {
                const { month, day, dayOfWeek } = formatDate(dateInfo.date);
                return (
                  <div
                    key={index}
                    className={`w-20 p-2 text-center border-r border-slate-800 ${
                      dateInfo.isToday ? 'bg-sky-900/30' : ''
                    }`}
                  >
                    <div className="text-xs text-gray-500">{dayOfWeek}</div>
                    <div className={`text-sm font-semibold ${dateInfo.isToday ? 'text-sky-400' : 'text-white'}`}>
                      {month} {day}
                    </div>
                    <div className="text-xs text-gray-600">
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
                <div key={mountain.id} className="flex border-b border-slate-800">
                  {mountainData.dates.map((dateData, index) => (
                    <div
                      key={index}
                      className={`w-20 h-16 p-2 flex items-center justify-center border-r border-slate-800 ${
                        dateData.isToday ? 'bg-sky-900/10' : ''
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
                          <div className="text-gray-600 text-sm">—</div>
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
      <div className="p-4 border-t border-slate-800 bg-slate-900/50">
        <div className="flex items-center gap-6 text-xs text-gray-400">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-blue-900/40" />
            <span>1-2"</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-blue-700/50" />
            <span>2-4"</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-blue-600/60" />
            <span>4-6"</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-blue-500/70" />
            <span>6-10"</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-blue-400/80" />
            <span>10"+</span>
          </div>
          <div className="ml-auto flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-sky-400" />
            <span className="text-sky-400">Today</span>
          </div>
        </div>
      </div>
    </div>
  );
}
