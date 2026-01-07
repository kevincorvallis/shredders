'use client';

import { useState, useEffect } from 'react';
import { CheckInCard } from './CheckInCard';
import { CheckInForm } from './CheckInForm';

interface CheckIn {
  id: string;
  user_id: string;
  mountain_id: string;
  check_in_time: string;
  check_out_time?: string;
  trip_report?: string;
  rating?: number;
  snow_quality?: string;
  crowd_level?: string;
  weather_conditions?: any;
  likes_count: number;
  comments_count: number;
  is_public: boolean;
  user?: {
    id: string;
    username: string;
    display_name?: string;
    avatar_url?: string;
  };
}

interface CheckInListProps {
  mountainId: string;
  limit?: number;
  showForm?: boolean;
}

export function CheckInList({
  mountainId,
  limit = 20,
  showForm = true,
}: CheckInListProps) {
  const [checkIns, setCheckIns] = useState<CheckIn[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCheckInForm, setShowCheckInForm] = useState(false);

  useEffect(() => {
    loadCheckIns();
  }, [mountainId]);

  const loadCheckIns = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        limit: limit.toString(),
      });

      const response = await fetch(
        `/api/mountains/${mountainId}/check-ins?${params.toString()}`
      );

      if (!response.ok) {
        throw new Error('Failed to load check-ins');
      }

      const data = await response.json();
      setCheckIns(data.checkIns || []);
    } catch (err) {
      console.error('Error loading check-ins:', err);
      setError('Failed to load check-ins');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCheckInCreated = (newCheckIn: CheckIn) => {
    setCheckIns((prev) => [newCheckIn, ...prev]);
    setShowCheckInForm(false);
  };

  const handleCheckInDeleted = (checkInId: string) => {
    setCheckIns((prev) => prev.filter((c) => c.id !== checkInId));
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold">Recent Check-ins</h2>
        </div>
        {[1, 2, 3].map((i) => (
          <div key={i} className="bg-white rounded-lg border border-gray-200 p-6 animate-pulse">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 bg-gray-200 rounded-full" />
              <div className="flex-1">
                <div className="h-4 bg-gray-200 rounded w-1/4 mb-2" />
                <div className="h-3 bg-gray-200 rounded w-1/3" />
              </div>
            </div>
            <div className="space-y-2">
              <div className="h-3 bg-gray-200 rounded w-full" />
              <div className="h-3 bg-gray-200 rounded w-5/6" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-6">
        <div className="flex items-center gap-3">
          <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div className="flex-1">
            <p className="text-red-600 font-medium">{error}</p>
            <button
              onClick={loadCheckIns}
              className="text-red-600 text-sm hover:underline mt-1"
            >
              Try again
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">Recent Check-ins</h2>
        {showForm && !showCheckInForm && (
          <button
            onClick={() => setShowCheckInForm(true)}
            className="
              inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white font-semibold rounded-lg
              hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
              transition-colors duration-200
            "
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Check In
          </button>
        )}
      </div>

      {/* Check-in form */}
      {showCheckInForm && (
        <CheckInForm
          mountainId={mountainId}
          onCheckInCreated={handleCheckInCreated}
          onCancel={() => setShowCheckInForm(false)}
        />
      )}

      {/* Check-ins list */}
      {checkIns.length === 0 ? (
        <div className="bg-gray-50 rounded-lg border border-gray-200 p-12 text-center">
          <svg
            className="w-16 h-16 mx-auto text-gray-400 mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
            />
          </svg>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            No check-ins yet
          </h3>
          <p className="text-gray-600 mb-4">
            Be the first to check in at this mountain!
          </p>
          {showForm && !showCheckInForm && (
            <button
              onClick={() => setShowCheckInForm(true)}
              className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700"
            >
              Check In Now
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          {checkIns.map((checkIn) => (
            <CheckInCard
              key={checkIn.id}
              checkIn={checkIn}
              onDeleted={() => handleCheckInDeleted(checkIn.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
