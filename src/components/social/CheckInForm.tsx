'use client';

import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';

interface CheckInFormProps {
  mountainId: string;
  onCheckInCreated?: (checkIn: any) => void;
  onCancel?: () => void;
}

export function CheckInForm({
  mountainId,
  onCheckInCreated,
  onCancel,
}: CheckInFormProps) {
  const { isAuthenticated } = useAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [tripReport, setTripReport] = useState('');
  const [rating, setRating] = useState<number | null>(null);
  const [snowQuality, setSnowQuality] = useState<string>('');
  const [crowdLevel, setCrowdLevel] = useState<string>('');
  const [isPublic, setIsPublic] = useState(true);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isAuthenticated) {
      setError('Please sign in to create a check-in');
      return;
    }

    if (tripReport.length > 5000) {
      setError('Trip report must be less than 5000 characters');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const response = await fetch('/api/check-ins', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          mountainId,
          tripReport: tripReport || null,
          rating: rating || null,
          snowQuality: snowQuality || null,
          crowdLevel: crowdLevel || null,
          isPublic,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to create check-in');
      }

      const data = await response.json();
      onCheckInCreated?.(data.checkIn);

      // Reset form
      setTripReport('');
      setRating(null);
      setSnowQuality('');
      setCrowdLevel('');
      setIsPublic(true);
    } catch (err) {
      console.error('Error creating check-in:', err);
      setError(err instanceof Error ? err.message : 'Failed to create check-in');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isAuthenticated) {
    return (
      <div className="bg-gray-50 border border-gray-200 rounded-lg p-6 text-center">
        <p className="text-gray-600">
          <a href="/auth/login" className="text-blue-600 hover:underline">
            Sign in
          </a>{' '}
          to check in at this mountain
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6 bg-white rounded-lg border border-gray-200 p-6">
      <div>
        <h3 className="text-lg font-semibold mb-4">Check In</h3>
      </div>

      {/* Rating */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Overall Rating
        </label>
        <div className="flex gap-2">
          {[1, 2, 3, 4, 5].map((value) => (
            <button
              key={value}
              type="button"
              onClick={() => setRating(value)}
              className={`
                w-12 h-12 rounded-lg border-2 font-semibold text-lg
                transition-all duration-200
                ${
                  rating === value
                    ? 'border-blue-500 bg-blue-50 text-blue-700'
                    : 'border-gray-300 hover:border-gray-400 text-gray-600'
                }
              `}
            >
              {value}
            </button>
          ))}
        </div>
      </div>

      {/* Snow Quality */}
      <div>
        <label htmlFor="snowQuality" className="block text-sm font-medium text-gray-700 mb-2">
          Snow Quality
        </label>
        <select
          id="snowQuality"
          value={snowQuality}
          onChange={(e) => setSnowQuality(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="">Select...</option>
          <option value="powder">Powder</option>
          <option value="packed-powder">Packed Powder</option>
          <option value="groomed">Groomed</option>
          <option value="hard-pack">Hard Pack</option>
          <option value="icy">Icy</option>
          <option value="slushy">Slushy</option>
          <option value="variable">Variable</option>
        </select>
      </div>

      {/* Crowd Level */}
      <div>
        <label htmlFor="crowdLevel" className="block text-sm font-medium text-gray-700 mb-2">
          Crowd Level
        </label>
        <select
          id="crowdLevel"
          value={crowdLevel}
          onChange={(e) => setCrowdLevel(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="">Select...</option>
          <option value="empty">Empty</option>
          <option value="light">Light</option>
          <option value="moderate">Moderate</option>
          <option value="busy">Busy</option>
          <option value="packed">Packed</option>
        </select>
      </div>

      {/* Trip Report */}
      <div>
        <label htmlFor="tripReport" className="block text-sm font-medium text-gray-700 mb-2">
          Trip Report (Optional)
        </label>
        <textarea
          id="tripReport"
          value={tripReport}
          onChange={(e) => setTripReport(e.target.value)}
          placeholder="Share your experience..."
          rows={6}
          maxLength={5000}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
        />
        <p className="text-xs text-gray-500 mt-1">
          {tripReport.length}/5000 characters
        </p>
      </div>

      {/* Public/Private */}
      <div className="flex items-center">
        <input
          id="isPublic"
          type="checkbox"
          checked={isPublic}
          onChange={(e) => setIsPublic(e.target.checked)}
          className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
        />
        <label htmlFor="isPublic" className="ml-2 text-sm text-gray-700">
          Make this check-in public
        </label>
      </div>

      {/* Error message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3">
          <p className="text-red-600 text-sm">{error}</p>
        </div>
      )}

      {/* Submit buttons */}
      <div className="flex items-center gap-3">
        <button
          type="submit"
          disabled={isSubmitting}
          className="
            flex-1 px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg
            hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
            disabled:bg-gray-300 disabled:cursor-not-allowed
            transition-colors duration-200
          "
        >
          {isSubmitting ? 'Checking in...' : 'Check In'}
        </button>

        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            disabled={isSubmitting}
            className="
              px-6 py-3 text-gray-600 font-semibold rounded-lg
              hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2
              disabled:opacity-50 disabled:cursor-not-allowed
              transition-colors duration-200
            "
          >
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}
