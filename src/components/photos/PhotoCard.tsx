'use client';

import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import Link from 'next/link';

interface PhotoCardProps {
  photo: {
    id: string;
    cloudfront_url: string;
    caption: string | null;
    taken_at: string;
    likes_count: number;
    comments_count: number;
    users: {
      username: string;
      display_name: string | null;
      avatar_url: string | null;
    };
  };
  onDeleted?: (photoId: string) => void;
}

export function PhotoCard({ photo, onDeleted }: PhotoCardProps) {
  const { user } = useAuth();
  const [showMenu, setShowMenu] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const isOwner = user?.email === photo.users.username; // Simplified check

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this photo?')) return;

    setDeleting(true);

    try {
      const response = await fetch(`/api/photos/${photo.id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Failed to delete photo');
      }

      onDeleted?.(photo.id);
    } catch (err: any) {
      alert(err.message || 'Failed to delete photo');
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-sm overflow-hidden">
      <div className="relative aspect-square">
        <img
          src={photo.cloudfront_url}
          alt={photo.caption || 'User photo'}
          className="w-full h-full object-cover"
        />
        {isOwner && (
          <div className="absolute top-2 right-2">
            <button
              onClick={() => setShowMenu(!showMenu)}
              className="bg-black bg-opacity-50 text-text-primary p-2 rounded-full hover:bg-opacity-70"
            >
              <svg
                className="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"
                />
              </svg>
            </button>
            {showMenu && (
              <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg py-1 z-10">
                <button
                  onClick={handleDelete}
                  disabled={deleting}
                  className="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-surface-secondary disabled:opacity-50"
                >
                  {deleting ? 'Deleting...' : 'Delete Photo'}
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      <div className="p-4">
        <div className="flex items-center gap-2 mb-2">
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-text-primary font-semibold text-sm">
            {photo.users.display_name?.[0] || photo.users.username[0]}
          </div>
          <Link
            href={`/profile/${photo.users.username}`}
            className="font-medium text-text-primary hover:text-accent"
          >
            {photo.users.display_name || photo.users.username}
          </Link>
        </div>

        {photo.caption && (
          <p className="text-text-secondary text-sm mb-2">{photo.caption}</p>
        )}

        <div className="flex items-center gap-4 text-sm text-text-quaternary">
          <span className="flex items-center gap-1">
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
              />
            </svg>
            {photo.likes_count}
          </span>
          <span className="flex items-center gap-1">
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
            {photo.comments_count}
          </span>
          <span className="ml-auto">
            {new Date(photo.taken_at).toLocaleDateString()}
          </span>
        </div>
      </div>
    </div>
  );
}
