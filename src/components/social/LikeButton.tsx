'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';

interface LikeButtonProps {
  targetType: 'photo' | 'comment' | 'checkIn' | 'webcam';
  targetId: string;
  initialLikeCount: number;
  initialLiked?: boolean;
  onLikeChange?: (liked: boolean, newCount: number) => void;
  size?: 'sm' | 'md' | 'lg';
  showCount?: boolean;
}

export function LikeButton({
  targetType,
  targetId,
  initialLikeCount,
  initialLiked = false,
  onLikeChange,
  size = 'md',
  showCount = true,
}: LikeButtonProps) {
  const { isAuthenticated } = useAuth();
  const [liked, setLiked] = useState(initialLiked);
  const [likeCount, setLikeCount] = useState(initialLikeCount);
  const [isLoading, setIsLoading] = useState(false);

  // Check initial like status if authenticated
  useEffect(() => {
    if (isAuthenticated && !initialLiked) {
      checkLikeStatus();
    }
  }, [isAuthenticated, targetId]);

  const checkLikeStatus = async () => {
    try {
      const params = new URLSearchParams();
      params.set(`${targetType}Id`, targetId);

      const response = await fetch(`/api/likes?${params.toString()}`);
      if (response.ok) {
        const data = await response.json();
        setLiked(data.liked);
      }
    } catch (error) {
      console.error('Error checking like status:', error);
    }
  };

  const handleToggleLike = async () => {
    if (!isAuthenticated) {
      alert('Please sign in to like');
      return;
    }

    if (isLoading) return;

    setIsLoading(true);

    try {
      const body: Record<string, string> = {};
      body[`${targetType}Id`] = targetId;

      const response = await fetch('/api/likes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        throw new Error('Failed to toggle like');
      }

      const data = await response.json();
      const newLiked = data.liked;
      const newCount = newLiked ? likeCount + 1 : likeCount - 1;

      setLiked(newLiked);
      setLikeCount(newCount);
      onLikeChange?.(newLiked, newCount);
    } catch (error) {
      console.error('Error toggling like:', error);
      alert('Failed to toggle like. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const sizeClasses = {
    sm: 'text-sm',
    md: 'text-base',
    lg: 'text-lg',
  };

  const iconSizes = {
    sm: 'w-4 h-4',
    md: 'w-5 h-5',
    lg: 'w-6 h-6',
  };

  return (
    <button
      onClick={handleToggleLike}
      disabled={isLoading}
      className={`
        inline-flex items-center gap-1.5
        ${sizeClasses[size]}
        ${liked ? 'text-red-500' : 'text-text-quaternary hover:text-red-500'}
        ${isLoading ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
        transition-colors duration-200
        focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 rounded
      `}
      aria-label={liked ? 'Unlike' : 'Like'}
    >
      <svg
        className={`${iconSizes[size]} ${liked ? 'fill-current' : 'fill-none'} stroke-current`}
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        strokeWidth={2}
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
        />
      </svg>
      {showCount && (
        <span className="font-medium">
          {likeCount}
        </span>
      )}
    </button>
  );
}
