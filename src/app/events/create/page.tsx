'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { getAllMountains, type MountainConfig } from '@shredders/shared';
import type { CreateEventRequest, CreateEventResponse, SkillLevel } from '@/types/event';

export default function CreateEventPage() {
  const router = useRouter();
  const mountains = getAllMountains();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [mountainId, setMountainId] = useState('');
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');
  const [eventDate, setEventDate] = useState('');
  const [departureTime, setDepartureTime] = useState('');
  const [departureLocation, setDepartureLocation] = useState('');
  const [skillLevel, setSkillLevel] = useState<SkillLevel | ''>('');
  const [carpoolAvailable, setCarpoolAvailable] = useState(false);
  const [carpoolSeats, setCarpoolSeats] = useState(0);

  const today = new Date().toISOString().split('T')[0];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!mountainId) {
      setError('Please select a mountain');
      return;
    }

    if (!title.trim() || title.trim().length < 3) {
      setError('Title must be at least 3 characters');
      return;
    }

    if (!eventDate) {
      setError('Please select a date');
      return;
    }

    setIsSubmitting(true);

    try {
      const body: CreateEventRequest = {
        mountainId,
        title: title.trim(),
        eventDate,
      };

      if (notes.trim()) body.notes = notes.trim();
      if (departureTime) body.departureTime = departureTime;
      if (departureLocation.trim()) body.departureLocation = departureLocation.trim();
      if (skillLevel) body.skillLevel = skillLevel;
      if (carpoolAvailable) {
        body.carpoolAvailable = true;
        body.carpoolSeats = carpoolSeats;
      }

      const res = await fetch('/api/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || 'Failed to create event');
      }

      const data: CreateEventResponse = await res.json();
      router.push(`/events/${data.event.id}`);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <Link href="/events" className="text-gray-400 hover:text-white transition-colors">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </Link>
            <h1 className="text-xl font-bold text-white">Create Event</h1>
          </div>
        </div>
      </header>

      {/* Form */}
      <form onSubmit={handleSubmit} className="max-w-2xl mx-auto px-4 py-6 space-y-6">
        {error && (
          <div className="bg-red-500/20 border border-red-500/50 text-red-400 px-4 py-3 rounded-xl">
            {error}
          </div>
        )}

        {/* Mountain Selection */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Mountain *</label>
          <select
            value={mountainId}
            onChange={(e) => setMountainId(e.target.value)}
            className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-sky-500"
            required
          >
            <option value="">Select a mountain</option>
            {mountains.map((m) => (
              <option key={m.id} value={m.id}>
                {m.name}
              </option>
            ))}
          </select>
        </div>

        {/* Title */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Event Title *</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g., Powder Day at Stevens!"
            className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-sky-500"
            maxLength={100}
            required
          />
        </div>

        {/* Date */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Date *</label>
          <input
            type="date"
            value={eventDate}
            onChange={(e) => setEventDate(e.target.value)}
            min={today}
            className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-sky-500"
            required
          />
        </div>

        {/* Departure Time */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Departure Time</label>
          <input
            type="time"
            value={departureTime}
            onChange={(e) => setDepartureTime(e.target.value)}
            className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-sky-500"
          />
        </div>

        {/* Departure Location */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Meeting Point</label>
          <input
            type="text"
            value={departureLocation}
            onChange={(e) => setDepartureLocation(e.target.value)}
            placeholder="e.g., Northgate Park & Ride"
            className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-sky-500"
            maxLength={255}
          />
        </div>

        {/* Skill Level */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Skill Level</label>
          <select
            value={skillLevel}
            onChange={(e) => setSkillLevel(e.target.value as SkillLevel | '')}
            className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-sky-500"
          >
            <option value="">All levels welcome</option>
            <option value="beginner">Beginner</option>
            <option value="intermediate">Intermediate</option>
            <option value="advanced">Advanced</option>
            <option value="expert">Expert</option>
            <option value="all">All Levels</option>
          </select>
        </div>

        {/* Carpool */}
        <div className="space-y-3">
          <label className="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={carpoolAvailable}
              onChange={(e) => setCarpoolAvailable(e.target.checked)}
              className="w-5 h-5 rounded bg-slate-800 border-slate-700 text-sky-500 focus:ring-sky-500"
            />
            <span className="text-gray-300">I can give rides</span>
          </label>

          {carpoolAvailable && (
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Available Seats</label>
              <input
                type="number"
                value={carpoolSeats}
                onChange={(e) => setCarpoolSeats(Math.min(8, Math.max(0, parseInt(e.target.value) || 0)))}
                min={0}
                max={8}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-sky-500"
              />
            </div>
          )}
        </div>

        {/* Notes */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">Additional Notes</label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Any other details for your group..."
            rows={4}
            className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:border-sky-500 resize-none"
            maxLength={2000}
          />
          <p className="text-xs text-gray-500 mt-1">{notes.length}/2000</p>
        </div>

        {/* Submit */}
        <button
          type="submit"
          disabled={isSubmitting}
          className="w-full py-4 bg-sky-500 hover:bg-sky-600 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-xl font-semibold transition-colors"
        >
          {isSubmitting ? 'Creating...' : 'Create Event'}
        </button>
      </form>
    </div>
  );
}
