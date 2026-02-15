'use client';

import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { LikeButton } from './LikeButton';

interface CheckInUser {
  id: string;
  username: string;
  display_name?: string;
  avatar_url?: string;
}

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
  user?: CheckInUser;
}

interface CheckInCardProps {
  checkIn: CheckIn;
  onDeleted?: () => void;
  showActions?: boolean;
}

export function CheckInCard({
  checkIn,
  onDeleted,
  showActions = true,
}: CheckInCardProps) {
  const { user } = useAuth();
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  const isOwner = user?.id === checkIn.user_id;
  const displayName = checkIn.user?.display_name || checkIn.user?.username || 'Unknown';

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
    if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`;
    return date.toLocaleDateString();
  };

  const handleDelete = async () => {
    if (!isOwner) return;

    setIsDeleting(true);

    try {
      const response = await fetch(`/api/check-ins/${checkIn.id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Failed to delete check-in');
      }

      onDeleted?.();
    } catch (error) {
      console.error('Error deleting check-in:', error);
      alert('Failed to delete check-in. Please try again.');
    } finally {
      setIsDeleting(false);
      setShowDeleteConfirm(false);
    }
  };

  return (
    <div className="bg-white rounded-lg border border-border-secondary p-6 space-y-4">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          {/* User avatar */}
          {checkIn.user?.avatar_url ? (
            <img
              src={checkIn.user.avatar_url}
              alt={displayName}
              className="w-12 h-12 rounded-full object-cover"
            />
          ) : (
            <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <span className="text-text-primary text-lg font-semibold">
                {displayName[0].toUpperCase()}
              </span>
            </div>
          )}

          <div>
            <div className="flex items-center gap-2">
              <span className="font-semibold text-text-primary">{displayName}</span>
              {!checkIn.is_public && (
                <span className="text-xs bg-surface-secondary text-text-quaternary px-2 py-0.5 rounded">
                  Private
                </span>
              )}
            </div>
            <p className="text-sm text-text-quaternary">
              Checked in {formatDate(checkIn.check_in_time)}
            </p>
          </div>
        </div>

        {/* Rating */}
        {checkIn.rating && (
          <div className="flex items-center gap-1 bg-blue-50 px-3 py-1.5 rounded-lg">
            <svg
              className="w-5 h-5 text-yellow-400 fill-current"
              viewBox="0 0 20 20"
            >
              <path d="M10 15l-5.878 3.09 1.123-6.545L.489 6.91l6.572-.955L10 0l2.939 5.955 6.572.955-4.756 4.635 1.123 6.545z" />
            </svg>
            <span className="font-semibold text-text-primary">{checkIn.rating}/5</span>
          </div>
        )}
      </div>

      {/* Conditions */}
      {(checkIn.snow_quality || checkIn.crowd_level) && (
        <div className="flex flex-wrap gap-2">
          {checkIn.snow_quality && (
            <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-surface-secondary text-text-secondary text-sm rounded-full">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
              </svg>
              {checkIn.snow_quality.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
            </span>
          )}
          {checkIn.crowd_level && (
            <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-surface-secondary text-text-secondary text-sm rounded-full">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              {checkIn.crowd_level.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
            </span>
          )}
        </div>
      )}

      {/* Trip Report */}
      {checkIn.trip_report && (
        <div className="prose max-w-none">
          <p className="text-text-secondary whitespace-pre-wrap">{checkIn.trip_report}</p>
        </div>
      )}

      {/* Actions */}
      {showActions && (
        <div className="flex items-center justify-between pt-4 border-t border-border-secondary">
          <div className="flex items-center gap-4">
            <LikeButton
              targetType="checkIn"
              targetId={checkIn.id}
              initialLikeCount={checkIn.likes_count}
              size="sm"
            />

            <button className="inline-flex items-center gap-1.5 text-sm text-text-quaternary hover:text-text-primary">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              <span>{checkIn.comments_count}</span>
            </button>
          </div>

          {isOwner && (
            <div>
              {!showDeleteConfirm ? (
                <button
                  onClick={() => setShowDeleteConfirm(true)}
                  className="text-sm text-red-600 hover:text-red-700 font-medium"
                >
                  Delete
                </button>
              ) : (
                <div className="flex items-center gap-2">
                  <span className="text-sm text-text-quaternary">Are you sure?</span>
                  <button
                    onClick={handleDelete}
                    disabled={isDeleting}
                    className="text-sm text-red-600 hover:text-red-700 font-medium disabled:opacity-50"
                  >
                    {isDeleting ? 'Deleting...' : 'Yes'}
                  </button>
                  <button
                    onClick={() => setShowDeleteConfirm(false)}
                    disabled={isDeleting}
                    className="text-sm text-text-quaternary hover:text-text-primary font-medium disabled:opacity-50"
                  >
                    No
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
