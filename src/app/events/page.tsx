'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import type { Event, EventsListResponse } from '@/types/event';

export default function EventsPage() {
  const router = useRouter();
  const [events, setEvents] = useState<Event[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'mine' | 'attending'>('all');

  useEffect(() => {
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
  }, [filter]);

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    });
  };

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
        {isLoading ? (
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
            <p className="text-gray-400">No upcoming events found</p>
            <Link
              href="/events/create"
              className="inline-block mt-4 px-4 py-2 bg-sky-500 hover:bg-sky-600 text-white rounded-lg text-sm font-medium transition-colors"
            >
              Create the first one
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
