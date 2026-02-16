'use client';

import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';

interface CommentInputProps {
  targetType: 'mountain' | 'webcam' | 'photo';
  targetId: string;
  parentCommentId?: string;
  onCommentAdded?: (comment: any) => void;
  onCancel?: () => void;
  placeholder?: string;
  autoFocus?: boolean;
}

export function CommentInput({
  targetType,
  targetId,
  parentCommentId,
  onCommentAdded,
  onCancel,
  placeholder = 'Add a comment...',
  autoFocus = false,
}: CommentInputProps) {
  const { isAuthenticated, user, profile } = useAuth();
  const [content, setContent] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isAuthenticated) {
      alert('Please sign in to comment');
      return;
    }

    if (!content.trim()) {
      setError('Comment cannot be empty');
      return;
    }

    if (content.length > 2000) {
      setError('Comment must be less than 2000 characters');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const body: Record<string, string> = {
        content: content.trim(),
      };

      // Add target ID
      body[`${targetType}Id`] = targetId;

      // Add parent comment if replying
      if (parentCommentId) {
        body.parentCommentId = parentCommentId;
      }

      const response = await fetch('/api/comments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to post comment');
      }

      const data = await response.json();
      setContent('');
      onCommentAdded?.(data.comment);
    } catch (err) {
      console.error('Error posting comment:', err);
      setError(err instanceof Error ? err.message : 'Failed to post comment');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    // Submit with Cmd+Enter or Ctrl+Enter
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      handleSubmit(e);
    }
  };

  if (!isAuthenticated) {
    return (
      <div className="bg-surface-primary border border-border-secondary rounded-lg p-4 text-center">
        <p className="text-text-quaternary text-sm">
          <a href="/auth/login" className="text-accent hover:underline">
            Sign in
          </a>{' '}
          to leave a comment
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-2">
      <div className="flex gap-3">
        {/* User avatar */}
        <div className="flex-shrink-0 mt-1">
          {profile?.avatar_url ? (
            <img
              src={profile.avatar_url}
              alt={profile.display_name || profile.username}
              className="w-8 h-8 rounded-full object-cover"
            />
          ) : (
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <span className="text-text-primary text-sm font-semibold">
                {(profile?.display_name || profile?.username || 'U')[0].toUpperCase()}
              </span>
            </div>
          )}
        </div>

        {/* Comment textarea */}
        <div className="flex-1">
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            autoFocus={autoFocus}
            disabled={isSubmitting}
            className="
              w-full px-3 py-2 border border-border-primary rounded-lg
              focus:outline-none focus:ring-2 focus:ring-accent focus:border-transparent
              disabled:bg-surface-secondary disabled:cursor-not-allowed
              resize-none
            "
            rows={parentCommentId ? 2 : 3}
            maxLength={2000}
          />

          {/* Error message */}
          {error && (
            <p className="text-red-500 text-sm mt-1">{error}</p>
          )}

          {/* Character count */}
          <div className="flex items-center justify-between mt-1">
            <p className="text-text-tertiary text-xs">
              {content.length}/2000
              {!parentCommentId && (
                <span className="ml-2">
                  Tip: Press Cmd+Enter to submit
                </span>
              )}
            </p>
          </div>

          {/* Action buttons */}
          <div className="flex items-center gap-2 mt-2">
            <button
              type="submit"
              disabled={isSubmitting || !content.trim()}
              className="
                px-4 py-1.5 bg-accent text-text-primary text-sm font-medium rounded-lg
                hover:bg-accent-hover focus:outline-none focus:ring-2 focus:ring-accent focus:ring-offset-2
                disabled:bg-surface-secondary disabled:cursor-not-allowed
                transition-colors duration-200
              "
            >
              {isSubmitting ? 'Posting...' : parentCommentId ? 'Reply' : 'Comment'}
            </button>

            {parentCommentId && onCancel && (
              <button
                type="button"
                onClick={onCancel}
                disabled={isSubmitting}
                className="
                  px-4 py-1.5 text-text-quaternary text-sm font-medium rounded-lg
                  hover:bg-surface-secondary focus:outline-none focus:ring-2 focus:ring-border-primary focus:ring-offset-2
                  disabled:opacity-50 disabled:cursor-not-allowed
                  transition-colors duration-200
                "
              >
                Cancel
              </button>
            )}
          </div>
        </div>
      </div>
    </form>
  );
}
