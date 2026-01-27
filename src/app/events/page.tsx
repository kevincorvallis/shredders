'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/hooks/useAuth';
import type { Event, EventsListResponse } from '@/types/event';

// Sample events to show non-logged-in users what the feature looks like
const SAMPLE_EVENTS = [
  {
    id: 'sample-1',
    title: 'First Tracks Friday',
    mountainId: 'snoqualmie',
    mountainName: 'Summit at Snoqualmie',
    eventDate: getUpcomingDate(2),
    departureTime: '06:00:00',
    departureLocation: 'Seattle - Capitol Hill',
    goingCount: 8,
    maybeCount: 3,
    skillLevel: 'beginner' as const,
    carpoolAvailable: true,
    carpoolSeats: 4,
    organizer: { name: 'Sam T.', avatar: 'S' },
  },
  {
    id: 'sample-2',
    title: 'Powder Day at Baker!',
    mountainId: 'baker',
    mountainName: 'Mt. Baker',
    eventDate: getUpcomingDate(3),
    departureTime: '05:30:00',
    departureLocation: 'Bellingham',
    goingCount: 6,
    maybeCount: 2,
    skillLevel: 'intermediate' as const,
    carpoolAvailable: true,
    carpoolSeats: 3,
    organizer: { name: 'Alex M.', avatar: 'A' },
  },
  {
    id: 'sample-3',
    title: 'Backside Bowls Session',
    mountainId: 'stevens',
    mountainName: 'Stevens Pass',
    eventDate: getUpcomingDate(5),
    departureTime: '06:30:00',
    departureLocation: 'Bellevue - Downtown',
    goingCount: 4,
    maybeCount: 1,
    skillLevel: 'advanced' as const,
    carpoolAvailable: true,
    carpoolSeats: 2,
    organizer: { name: 'Jamie K.', avatar: 'J' },
  },
  {
    id: 'sample-4',
    title: 'Steep Chutes & Cliffs',
    mountainId: 'crystal',
    mountainName: 'Crystal Mountain',
    eventDate: getUpcomingDate(7),
    departureTime: '05:00:00',
    departureLocation: 'Tacoma',
    goingCount: 3,
    maybeCount: 0,
    skillLevel: 'expert' as const,
    carpoolAvailable: false,
    carpoolSeats: 0,
    organizer: { name: 'Morgan R.', avatar: 'M' },
  },
  {
    id: 'sample-5',
    title: 'Group Day - All Welcome!',
    mountainId: 'whistler',
    mountainName: 'Whistler Blackcomb',
    eventDate: getUpcomingDate(10),
    departureTime: '04:00:00',
    departureLocation: 'Seattle - University District',
    goingCount: 12,
    maybeCount: 5,
    skillLevel: 'all' as const,
    carpoolAvailable: true,
    carpoolSeats: 6,
    organizer: { name: 'Taylor W.', avatar: 'T' },
  },
];

function getUpcomingDate(daysFromNow: number): string {
  const date = new Date();
  date.setDate(date.getDate() + daysFromNow);
  return date.toISOString().split('T')[0];
}

// Ski trail difficulty icon component
function SkillLevelIcon({ level }: { level: string }) {
  switch (level) {
    case 'beginner':
      // Green circle
      return (
        <span className="inline-block w-3 h-3 rounded-full bg-green-500" />
      );
    case 'intermediate':
      // Blue square
      return (
        <span className="inline-block w-3 h-3 bg-blue-500" />
      );
    case 'advanced':
      // Black diamond
      return (
        <span className="inline-block w-3 h-3 bg-black rotate-45 transform" />
      );
    case 'expert':
      // Double black diamond
      return (
        <span className="inline-flex gap-0.5">
          <span className="inline-block w-2.5 h-2.5 bg-black rotate-45 transform" />
          <span className="inline-block w-2.5 h-2.5 bg-black rotate-45 transform" />
        </span>
      );
    case 'all':
      // Multi-level icons
      return (
        <span className="inline-flex items-center gap-0.5">
          <span className="inline-block w-2 h-2 rounded-full bg-green-500" />
          <span className="inline-block w-2 h-2 bg-blue-500" />
          <span className="inline-block w-2 h-2 bg-black rotate-45 transform" />
        </span>
      );
    default:
      return null;
  }
}

function getSkillLevelBadge(level: string) {
  const styles: Record<string, string> = {
    beginner: 'bg-green-500/15 text-green-400',
    intermediate: 'bg-blue-500/15 text-blue-400',
    advanced: 'bg-gray-500/15 text-gray-300',
    expert: 'bg-gray-500/15 text-gray-300',
    all: 'bg-purple-500/15 text-purple-400',
  };
  const labels: Record<string, string> = {
    beginner: 'Green',
    intermediate: 'Blue',
    advanced: 'Black',
    expert: 'Double Black',
    all: 'All Levels',
  };
  return { style: styles[level] || styles.all, label: labels[level] || 'All Levels' };
}

export default function EventsPage() {
  const router = useRouter();
  const { isAuthenticated, loading: authLoading } = useAuth();
  const [events, setEvents] = useState<Event[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'mine' | 'attending'>('all');

  useEffect(() => {
    // Don't fetch if still checking auth
    if (authLoading) return;

    async function fetchEvents() {
      setIsLoading(true);
      try {
        const params = new URLSearchParams({ upcoming: 'true' });
        if (filter === 'mine') params.set('createdByMe', 'true');
        if (filter === 'attending') params.set('attendingOnly', 'true');

        const res = await fetch(`/api/events?${params}`);
        if (res.ok) {
          const data: EventsListResponse = await res.json();
          setEvents(data.events);
        }
      } catch (error) {
        console.error('Error fetching events:', error);
      } finally {
        setIsLoading(false);
      }
    }

    fetchEvents();
  }, [filter, authLoading]);

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    });
  };

  // Show sample events for non-authenticated users
  if (!authLoading && !isAuthenticated) {
    return (
      <div className="min-h-screen bg-slate-900">
        {/* Header */}
        <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
          <div className="max-w-2xl mx-auto px-4 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Link href="/" className="text-gray-400 hover:text-white transition-colors">
                  <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                  </svg>
                </Link>
                <h1 className="text-xl font-bold text-white">Ski Events</h1>
              </div>
              <Link
                href="/auth/login?redirect=/events"
                className="px-4 py-2 bg-sky-500 hover:bg-sky-600 text-white rounded-lg text-sm font-medium transition-colors"
              >
                Sign in
              </Link>
            </div>
          </div>
        </header>

        {/* Hero Section */}
        <div className="max-w-2xl mx-auto px-4 py-8">
          <div className="bg-gradient-to-br from-sky-500/20 to-purple-500/20 rounded-2xl p-6 border border-sky-500/30">
            <div className="flex items-center gap-3 mb-3">
              <div className="p-2 bg-sky-500/20 rounded-lg">
                <svg className="w-6 h-6 text-sky-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
              <h2 className="text-lg font-semibold text-white">Plan ski trips with friends</h2>
            </div>
            <p className="text-gray-300 text-sm mb-4">
              Create events, coordinate carpools, and never miss a powder day. Sign in to join upcoming trips or create your own.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link
                href="/auth/login?redirect=/events"
                className="px-4 py-2 bg-sky-500 hover:bg-sky-600 text-white rounded-lg text-sm font-medium transition-colors"
              >
                Sign in to join events
              </Link>
              <Link
                href="/auth/signup?redirect=/events/create"
                className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg text-sm font-medium transition-colors"
              >
                Create an account
              </Link>
            </div>
          </div>
        </div>

        {/* Sample Events */}
        <div className="max-w-2xl mx-auto px-4 pb-8">
          <div className="flex items-center gap-2 mb-4">
            <h3 className="text-sm font-medium text-gray-400">Example Events</h3>
            <span className="px-2 py-0.5 bg-slate-800 rounded text-xs text-gray-500">Preview</span>
          </div>

          <div className="space-y-3">
            {SAMPLE_EVENTS.map((event) => {
              const skillBadge = getSkillLevelBadge(event.skillLevel);
              return (
                <div
                  key={event.id}
                  className="relative bg-slate-800/70 rounded-xl p-4 border border-slate-700/50"
                >
                  {/* Blur overlay with sign-in prompt on hover */}
                  <div className="absolute inset-0 rounded-xl bg-slate-900/0 hover:bg-slate-900/60 transition-all group cursor-pointer z-10"
                    onClick={() => router.push('/auth/login?redirect=/events')}
                  >
                    <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                      <span className="px-4 py-2 bg-sky-500 text-white rounded-lg text-sm font-medium shadow-lg">
                        Sign in to view & join
                      </span>
                    </div>
                  </div>

                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h3 className="font-semibold text-white">{event.title}</h3>
                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${skillBadge.style}`}>
                          <SkillLevelIcon level={event.skillLevel} />
                          {skillBadge.label}
                        </span>
                      </div>
                      <p className="text-sm text-sky-400 mt-1">
                        {event.mountainName} • {formatDate(event.eventDate)}
                      </p>
                      <div className="flex items-center gap-4 mt-2 text-sm text-gray-400">
                        <span className="flex items-center gap-1">
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                          {event.departureTime.slice(0, 5)} AM
                        </span>
                        <span className="flex items-center gap-1">
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                          </svg>
                          {event.departureLocation}
                        </span>
                      </div>
                      {event.carpoolAvailable && (
                        <div className="mt-2">
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-green-500/20 text-green-400 rounded text-xs font-medium">
                            <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                            </svg>
                            Carpool available • {event.carpoolSeats} seats
                          </span>
                        </div>
                      )}
                    </div>
                    <div className="text-right">
                      <span className="inline-flex items-center gap-1 text-sm text-gray-400">
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                        </svg>
                        {event.goingCount} going
                      </span>
                      {event.maybeCount > 0 && (
                        <span className="block text-xs text-gray-500 mt-1">
                          +{event.maybeCount} maybe
                        </span>
                      )}
                      <div className="mt-2 flex items-center justify-end gap-1">
                        <div className="w-6 h-6 rounded-full bg-gradient-to-br from-sky-500 to-purple-600 flex items-center justify-center text-white text-xs font-medium">
                          {event.organizer.avatar}
                        </div>
                        <span className="text-xs text-gray-400">{event.organizer.name}</span>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Bottom CTA */}
          <div className="mt-6 text-center">
            <p className="text-gray-400 text-sm mb-3">
              Ready to hit the slopes with friends?
            </p>
            <Link
              href="/auth/signup?redirect=/events"
              className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-sky-500 to-sky-600 hover:from-sky-600 hover:to-sky-700 text-white rounded-xl text-sm font-medium transition-all shadow-lg shadow-sky-500/25"
            >
              Get started free
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
              </svg>
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Link href="/" className="text-gray-400 hover:text-white transition-colors">
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </Link>
              <h1 className="text-xl font-bold text-white">Ski Events</h1>
            </div>
            <Link
              href="/events/create"
              className="px-4 py-2 bg-sky-500 hover:bg-sky-600 text-white rounded-lg text-sm font-medium transition-colors"
            >
              Create Event
            </Link>
          </div>
        </div>
      </header>

      {/* Filter Tabs */}
      <div className="max-w-2xl mx-auto px-4 py-4">
        <div className="flex gap-2">
          {(['all', 'mine', 'attending'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                filter === f
                  ? 'bg-sky-500 text-white'
                  : 'bg-slate-800 text-gray-400 hover:text-white'
              }`}
            >
              {f === 'all' ? 'All Events' : f === 'mine' ? 'My Events' : 'Attending'}
            </button>
          ))}
        </div>
      </div>

      {/* Events List */}
      <div className="max-w-2xl mx-auto px-4 pb-6">
        {isLoading || authLoading ? (
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="bg-slate-800 rounded-xl p-4 animate-pulse">
                <div className="h-5 bg-slate-700 rounded w-3/4 mb-2" />
                <div className="h-4 bg-slate-700 rounded w-1/2" />
              </div>
            ))}
          </div>
        ) : events.length === 0 ? (
          <div className="text-center py-12">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-slate-800 flex items-center justify-center">
              <svg className="w-8 h-8 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <p className="text-gray-400 mb-1">No upcoming events found</p>
            <p className="text-gray-500 text-sm mb-4">Be the first to plan a ski trip!</p>
            <Link
              href="/events/create"
              className="inline-flex items-center gap-2 px-4 py-2 bg-sky-500 hover:bg-sky-600 text-white rounded-lg text-sm font-medium transition-colors"
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Create an Event
            </Link>
          </div>
        ) : (
          <div className="space-y-3">
            {events.map((event) => (
              <button
                key={event.id}
                onClick={() => router.push(`/events/${event.id}`)}
                className="w-full text-left bg-slate-800 hover:bg-slate-700 rounded-xl p-4 transition-colors"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <h3 className="font-semibold text-white">{event.title}</h3>
                    <p className="text-sm text-sky-400 mt-1">
                      {event.mountainName || event.mountainId} • {formatDate(event.eventDate)}
                    </p>
                    {event.departureTime && (
                      <p className="text-sm text-gray-400 mt-1">
                        Departure: {event.departureTime.slice(0, 5)}
                      </p>
                    )}
                  </div>
                  <div className="text-right">
                    <span className="inline-flex items-center gap-1 text-sm text-gray-400">
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                      </svg>
                      {event.goingCount}
                    </span>
                    {event.isCreator && (
                      <span className="block text-xs text-sky-400 mt-1">Organizer</span>
                    )}
                  </div>
                </div>
                {event.userRSVPStatus && (
                  <div className="mt-2">
                    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${
                      event.userRSVPStatus === 'going'
                        ? 'bg-green-500/20 text-green-400'
                        : 'bg-yellow-500/20 text-yellow-400'
                    }`}>
                      {event.userRSVPStatus === 'going' ? "I'm going" : 'Maybe'}
                    </span>
                  </div>
                )}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
