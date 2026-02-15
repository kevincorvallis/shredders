'use client';

import { useState, useEffect } from 'react';
import { PhotoCard } from './PhotoCard';

interface Photo {
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
}

interface PhotoGridProps {
  mountainId: string;
  webcamId?: string;
}

export function PhotoGrid({ mountainId, webcamId }: PhotoGridProps) {
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchPhotos();
  }, [mountainId, webcamId]);

  const fetchPhotos = async () => {
    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({ limit: '20' });
      if (webcamId) {
        params.append('webcamId', webcamId);
      }

      const response = await fetch(
        `/api/mountains/${mountainId}/photos?${params}`
      );

      if (!response.ok) {
        throw new Error('Failed to fetch photos');
      }

      const data = await response.json();
      setPhotos(data.photos || []);
    } catch (err: any) {
      setError(err.message || 'Failed to load photos');
    } finally {
      setLoading(false);
    }
  };

  const handlePhotoDeleted = (photoId: string) => {
    setPhotos(photos.filter((p) => p.id !== photoId));
  };

  if (loading) {
    return (
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {[...Array(6)].map((_, i) => (
          <div
            key={i}
            className="aspect-square bg-surface-secondary rounded-lg animate-pulse"
          />
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">{error}</p>
      </div>
    );
  }

  if (photos.length === 0) {
    return (
      <div className="text-center py-12">
        <svg
          className="w-16 h-16 mx-auto mb-4 text-text-tertiary"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
        <p className="text-lg font-medium text-text-secondary mb-1">No photos yet</p>
        <p className="text-sm text-text-quaternary">
          Be the first to upload a photo!
        </p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {photos.map((photo) => (
        <PhotoCard
          key={photo.id}
          photo={photo}
          onDeleted={handlePhotoDeleted}
        />
      ))}
    </div>
  );
}
