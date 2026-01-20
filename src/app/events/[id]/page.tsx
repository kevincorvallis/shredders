'use client';

import { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import type { EventWithDetails, EventResponse, RSVPStatus } from '@/types/event';

export default function EventDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const [event, setEvent] = useState<EventWithDetails | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRSVPing, setIsRSVPing] = useState(false);
  const [shareUrl, setShareUrl] = useState('');

  useEffect(() => {
    async function fetchEvent() {
      try {
        const res = await fetch(`/api/events/${id}`);
        if (res.ok) {
          const data: EventResponse = await res.json();
          setEvent(data.event);

          // Generate share URL
          if (data.event.inviteToken) {
            setShareUrl(`${window.location.origin}/events/invite/${data.event.inviteToken}`);
          }
        } else if (res.status === 404) {
          router.push('/events');
        }
      } catch (error) {
        console.error('Error fetching event:', error);
      } finally {
        setIsLoading(false);
      }
    }

    fetchEvent();
  }, [id, router]);

  const handleRSVP = async (status: RSVPStatus) => {
    if (!event) return;
    setIsRSVPing(true);

    try {
      const res = await fetch(`/api/events/${id}/rsvp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });

      if (res.ok) {
        const data = await res.json();
        setEvent((prev) =>
          prev
            ? {
                ...prev,
                userRSVPStatus: data.attendee.status,
                goingCount: data.event.goingCount,
                maybeCount: data.event.maybeCount,
                attendeeCount: data.event.attendeeCount,
              }
            : null
        );
      }
    } catch (error) {
      console.error('Error RSVPing:', error);
    } finally {
      setIsRSVPing(false);
    }
  };

  const handleShare = async () => {
    if (navigator.share && shareUrl) {
      try {
        await navigator.share({
          title: event?.title,
          text: `Join me skiing at ${event?.mountainName} on ${formatDate(event?.eventDate || '')}!`,
          url: shareUrl,
        });
      } catch (error) {
        // User cancelled or share failed
        copyToClipboard();
      }
    } else {
      copyToClipboard();
    }
  };

  const copyToClipboard = () => {
    navigator.clipboard.writeText(shareUrl);
    alert('Invite link copied to clipboard!');
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

  if (!event) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <p className="text-gray-400">Event not found</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <Link href="/events" className="text-gray-400 hover:text-white transition-colors">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </Link>
            <h1 className="text-xl font-bold text-white">Event Details</h1>
          </div>
        </div>
      </header>

      {/* Content */}
      <div className="max-w-2xl mx-auto px-4 py-6">
        {/* Event Info Card */}
        <div className="bg-slate-800 rounded-xl p-6">
          <h2 className="text-2xl font-bold text-white">{event.title}</h2>
          <p className="text-sky-400 mt-1">{event.mountainName || event.mountainId}</p>

          <div className="mt-4 space-y-3">
            <div className="flex items-center gap-3 text-gray-300">
              <svg className="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              {formatDate(event.eventDate)}
            </div>

            {event.departureTime && (
              <div className="flex items-center gap-3 text-gray-300">
                <svg className="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Departing at {formatTime(event.departureTime)}
              </div>
            )}

            {event.departureLocation && (
              <div className="flex items-center gap-3 text-gray-300">
                <svg className="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                {event.departureLocation}
              </div>
            )}

            {event.skillLevel && (
              <div className="flex items-center gap-3 text-gray-300">
                <svg className="w-5 h-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                {event.skillLevel.charAt(0).toUpperCase() + event.skillLevel.slice(1)} level
              </div>
            )}

            {event.carpoolAvailable && (
              <div className="flex items-center gap-3 text-green-400">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                </svg>
                Carpool available ({event.carpoolSeats} seats)
              </div>
            )}
          </div>

          {event.notes && (
            <div className="mt-4 pt-4 border-t border-slate-700">
              <p className="text-gray-300 whitespace-pre-wrap">{event.notes}</p>
            </div>
          )}

          {/* Organizer */}
          <div className="mt-4 pt-4 border-t border-slate-700 flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-sky-500/20 flex items-center justify-center">
              <span className="text-sky-400 font-medium">
                {event.creator.display_name?.[0] || event.creator.username[0]}
              </span>
            </div>
            <div>
              <p className="text-sm text-gray-400">Organized by</p>
              <p className="text-white font-medium">
                {event.creator.display_name || event.creator.username}
              </p>
            </div>
          </div>
        </div>

        {/* Conditions Card */}
        {event.conditions && (
          <div className="bg-slate-800 rounded-xl p-6 mt-4">
            <h3 className="font-semibold text-white mb-3">Current Conditions</h3>
            <div className="grid grid-cols-2 gap-4">
              {event.conditions.powderScore !== undefined && (
                <div>
                  <p className="text-sm text-gray-400">Powder Score</p>
                  <p className="text-2xl font-bold text-sky-400">{event.conditions.powderScore.toFixed(1)}</p>
                </div>
              )}
              {event.conditions.snowfall24h !== undefined && (
                <div>
                  <p className="text-sm text-gray-400">24h Snowfall</p>
                  <p className="text-2xl font-bold text-white">{event.conditions.snowfall24h}"</p>
                </div>
              )}
              {event.conditions.temperature !== undefined && (
                <div>
                  <p className="text-sm text-gray-400">Temperature</p>
                  <p className="text-2xl font-bold text-white">{event.conditions.temperature}°F</p>
                </div>
              )}
              {event.conditions.snowDepth !== undefined && (
                <div>
                  <p className="text-sm text-gray-400">Snow Depth</p>
                  <p className="text-2xl font-bold text-white">{event.conditions.snowDepth}"</p>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Attendees */}
        <div className="bg-slate-800 rounded-xl p-6 mt-4">
          <h3 className="font-semibold text-white mb-3">
            Who's Going ({event.goingCount} going, {event.maybeCount} maybe)
          </h3>
          {event.attendees.length > 0 ? (
            <div className="space-y-2">
              {event.attendees.map((attendee) => (
                <div key={attendee.id} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-slate-700 flex items-center justify-center">
                      <span className="text-sm text-gray-300">
                        {attendee.user.display_name?.[0] || attendee.user.username[0]}
                      </span>
                    </div>
                    <span className="text-gray-300">
                      {attendee.user.display_name || attendee.user.username}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    {attendee.isDriver && (
                      <span className="text-xs bg-green-500/20 text-green-400 px-2 py-0.5 rounded">
                        Driver
                      </span>
                    )}
                    <span className={`text-xs px-2 py-0.5 rounded ${
                      attendee.status === 'going'
                        ? 'bg-sky-500/20 text-sky-400'
                        : 'bg-yellow-500/20 text-yellow-400'
                    }`}>
                      {attendee.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-400">No attendees yet</p>
          )}
        </div>

        {/* RSVP Buttons */}
        {!event.isCreator && (
          <div className="mt-6 flex gap-3">
            <button
              onClick={() => handleRSVP('going')}
              disabled={isRSVPing}
              className={`flex-1 py-3 rounded-xl font-medium transition-colors ${
                event.userRSVPStatus === 'going'
                  ? 'bg-green-500 text-white'
                  : 'bg-slate-800 text-gray-300 hover:bg-slate-700'
              }`}
            >
              {isRSVPing ? '...' : "I'm In!"}
            </button>
            <button
              onClick={() => handleRSVP('maybe')}
              disabled={isRSVPing}
              className={`flex-1 py-3 rounded-xl font-medium transition-colors ${
                event.userRSVPStatus === 'maybe'
                  ? 'bg-yellow-500 text-white'
                  : 'bg-slate-800 text-gray-300 hover:bg-slate-700'
              }`}
            >
              Maybe
            </button>
          </div>
        )}

        {/* Share Button */}
        {(event.isCreator || shareUrl) && (
          <button
            onClick={handleShare}
            className="w-full mt-4 py-3 bg-sky-500 hover:bg-sky-600 text-white rounded-xl font-medium transition-colors flex items-center justify-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
            </svg>
            Share Invite Link
          </button>
        )}
      </div>
    </div>
  );
}
