'use client';

import { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import type { InviteInfo, InviteResponse } from '@/types/event';

export default function InvitePage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = use(params);
  const router = useRouter();
  const [invite, setInvite] = useState<InviteInfo | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRSVPing, setIsRSVPing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchInvite() {
      try {
        const res = await fetch(`/api/events/invite/${token}`);
        const data: InviteResponse = await res.json();

        if (data.invite) {
          setInvite(data.invite);
        } else {
          setError('Invalid or expired invite link');
        }
      } catch (err) {
        setError('Failed to load invite');
      } finally {
        setIsLoading(false);
      }
    }

    fetchInvite();
  }, [token]);

  const handleRSVP = async (status: 'going' | 'maybe') => {
    if (!invite?.event) return;
    setIsRSVPing(true);
    setError(null);

    try {
      // First validate the invite token
      const validateRes = await fetch(`/api/events/invite/${token}`, {
        method: 'POST',
      });

      if (!validateRes.ok) {
        const data = await validateRes.json();
        throw new Error(data.error || 'Invalid invite');
      }

      const validateData = await validateRes.json();

      // Then RSVP to the event
      const rsvpRes = await fetch(`/api/events/${validateData.eventId}/rsvp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });

      if (!rsvpRes.ok) {
        const data = await rsvpRes.json();
        if (rsvpRes.status === 401) {
          // User needs to sign in
          router.push(`/auth/login?redirect=/events/invite/${token}`);
          return;
        }
        throw new Error(data.error || 'Failed to RSVP');
      }

      // Success - redirect to event page
      router.push(`/events/${validateData.eventId}`);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsRSVPing(false);
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatTime = (timeStr: string | null) => {
    if (!timeStr) return null;
    const [hours, minutes] = timeStr.split(':');
    const h = parseInt(hours);
    const ampm = h >= 12 ? 'PM' : 'AM';
    const h12 = h % 12 || 12;
    return `${h12}:${minutes} ${ampm}`;
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-sky-500" />
      </div>
    );
  }

  if (error && !invite) {
    return (
      <div className="min-h-screen bg-slate-900 flex flex-col items-center justify-center px-4">
        <div className="text-center">
          <svg className="w-16 h-16 text-gray-600 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h1 className="text-xl font-bold text-white mb-2">Invalid Invite</h1>
          <p className="text-gray-400 mb-6">{error}</p>
          <Link
            href="/events"
            className="inline-block px-6 py-3 bg-sky-500 hover:bg-sky-600 text-white rounded-xl font-medium transition-colors"
          >
            Browse Events
          </Link>
        </div>
      </div>
    );
  }

  if (!invite?.event) {
    return null;
  }

  const event = invite.event;

  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="bg-slate-900/95 border-b border-slate-800">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center justify-center">
            <h1 className="text-lg font-semibold text-white">You're Invited!</h1>
          </div>
        </div>
      </header>

      {/* Content */}
      <div className="max-w-2xl mx-auto px-4 py-8">
        {/* Event Card */}
        <div className="bg-slate-800 rounded-xl p-6 text-center">
          <div className="w-16 h-16 bg-sky-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-sky-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>

          <h2 className="text-2xl font-bold text-white">{event.title}</h2>
          <p className="text-sky-400 mt-1">{event.mountainName || event.mountainId}</p>

          <div className="mt-6 space-y-2 text-gray-300">
            <p className="text-lg">{formatDate(event.eventDate)}</p>
            {event.departureTime && (
              <p>Departing at {formatTime(event.departureTime)}</p>
            )}
            {event.departureLocation && (
              <p className="text-gray-400">from {event.departureLocation}</p>
            )}
          </div>

          {/* Organizer */}
          <div className="mt-6 pt-6 border-t border-slate-700">
            <p className="text-sm text-gray-400">Organized by</p>
            <p className="text-white font-medium">
              {event.creator.display_name || event.creator.username}
            </p>
          </div>

          {/* Attendee count */}
          <div className="mt-4 flex items-center justify-center gap-2 text-gray-400">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <span>{event.goingCount} going</span>
            {event.maybeCount > 0 && <span>• {event.maybeCount} maybe</span>}
          </div>
        </div>

        {/* Conditions */}
        {invite.conditions && (
          <div className="bg-slate-800 rounded-xl p-6 mt-4">
            <h3 className="font-semibold text-white mb-3 text-center">Current Conditions</h3>
            <div className="grid grid-cols-2 gap-4 text-center">
              {invite.conditions.powderScore !== undefined && (
                <div>
                  <p className="text-sm text-gray-400">Powder Score</p>
                  <p className="text-2xl font-bold text-sky-400">{invite.conditions.powderScore.toFixed(1)}</p>
                </div>
              )}
              {invite.conditions.snowfall24h !== undefined && (
                <div>
                  <p className="text-sm text-gray-400">24h Snowfall</p>
                  <p className="text-2xl font-bold text-white">{invite.conditions.snowfall24h}"</p>
                </div>
              )}
            </div>

            {/* Forecast Preview */}
            {invite.conditions.forecast && (
              <div className="mt-4 pt-4 border-t border-slate-700">
                <h4 className="text-sm text-gray-400 mb-3 text-center">Forecast</h4>
                <div className="grid grid-cols-3 gap-4 text-center">
                  <div>
                    <p className="text-xl font-bold">
                      <span className="text-orange-400">{invite.conditions.forecast.high}°</span>
                      <span className="text-gray-400 mx-1">/</span>
                      <span className="text-blue-400">{invite.conditions.forecast.low}°</span>
                    </p>
                    <p className="text-xs text-gray-500">High / Low</p>
                  </div>
                  <div>
                    <p className="text-xl font-bold text-cyan-400">
                      {invite.conditions.forecast.snowfall}"
                      {invite.conditions.forecast.snowfall >= 6 && ' ❄️'}
                    </p>
                    <p className="text-xs text-gray-500">Expected Snow</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-300">{invite.conditions.forecast.conditions}</p>
                    <p className="text-xs text-gray-500">Conditions</p>
                  </div>
                </div>
                {invite.conditions.forecast.snowfall >= 6 && (
                  <div className="mt-3 py-2 px-3 bg-cyan-500/20 border border-cyan-500/30 rounded-lg text-center">
                    <span className="text-cyan-400 text-sm font-medium">🎿 Powder Day Alert!</span>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* Error message */}
        {error && (
          <div className="mt-4 bg-red-500/20 border border-red-500/50 text-red-400 px-4 py-3 rounded-xl text-center">
            {error}
          </div>
        )}

        {/* RSVP Buttons */}
        {invite.isValid ? (
          <div className="mt-6 space-y-3">
            <button
              onClick={() => handleRSVP('going')}
              disabled={isRSVPing}
              className="w-full py-4 bg-green-500 hover:bg-green-600 disabled:opacity-50 text-white rounded-xl font-semibold transition-colors"
            >
              {isRSVPing ? 'Joining...' : "I'm In!"}
            </button>
            <button
              onClick={() => handleRSVP('maybe')}
              disabled={isRSVPing}
              className="w-full py-4 bg-slate-700 hover:bg-slate-600 disabled:opacity-50 text-white rounded-xl font-semibold transition-colors"
            >
              Maybe
            </button>
          </div>
        ) : (
          <div className="mt-6 text-center">
            <p className="text-gray-400 mb-4">
              {invite.isExpired ? 'This event has already passed.' : 'This invite is no longer valid.'}
            </p>
            <Link
              href="/events"
              className="inline-block px-6 py-3 bg-sky-500 hover:bg-sky-600 text-white rounded-xl font-medium transition-colors"
            >
              Browse Other Events
            </Link>
          </div>
        )}

        {/* Open in App button */}
        <div className="mt-6">
          <a
            href={`powdertracker://events/invite/${token}`}
            className="block w-full py-4 bg-sky-500 hover:bg-sky-600 text-white rounded-xl font-semibold text-center transition-colors"
          >
            <span className="flex items-center justify-center gap-2">
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
              </svg>
              Open in App
            </span>
          </a>
        </div>

        {/* App download prompt for non-users */}
        <div className="mt-8 text-center">
          <p className="text-gray-500 text-sm">
            Don't have the app? Get PowderTracker for iOS
          </p>
          <div className="mt-3 flex justify-center gap-4">
            <a
              href="https://apps.apple.com/app/powdertracker"
              className="inline-flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              App Store
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
