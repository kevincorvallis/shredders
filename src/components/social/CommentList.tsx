'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { CommentInput } from './CommentInput';
import { LikeButton } from './LikeButton';

interface CommentUser {
  id: string;
  username: string;
  display_name?: string;
  avatar_url?: string;
}

interface Comment {
  id: string;
  user_id: string;
  content: string;
  created_at: string;
  updated_at: string;
  is_deleted: boolean;
  likes_count: number;
  parent_comment_id?: string;
  user?: CommentUser;
}

interface CommentListProps {
  targetType: 'mountain' | 'webcam' | 'photo' | 'checkIn';
  targetId: string;
  limit?: number;
  showReplies?: boolean;
}

export function CommentList({
  targetType,
  targetId,
  limit = 50,
  showReplies = true,
}: CommentListProps) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [replyingTo, setReplyingTo] = useState<string | null>(null);

  useEffect(() => {
    loadComments();
  }, [targetType, targetId]);

  const loadComments = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams();
      params.set(`${targetType}Id`, targetId);
      params.set('limit', limit.toString());

      const response = await fetch(`/api/comments?${params.toString()}`);
      if (!response.ok) {
        throw new Error('Failed to load comments');
      }

      const data = await response.json();
      setComments(data.comments || []);
    } catch (err) {
      console.error('Error loading comments:', err);
      setError('Failed to load comments');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCommentAdded = (newComment: Comment) => {
    setComments((prev) => [newComment, ...prev]);
    setReplyingTo(null);
  };

  const handleReplyAdded = (newReply: Comment) => {
    setComments((prev) => [newReply, ...prev]);
    setReplyingTo(null);
  };

  const handleDeleteComment = async (commentId: string) => {
    if (!confirm('Are you sure you want to delete this comment?')) {
      return;
    }

    try {
      const response = await fetch(`/api/comments/${commentId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Failed to delete comment');
      }

      // Update local state
      setComments((prev) =>
        prev.map((comment) =>
          comment.id === commentId
            ? { ...comment, is_deleted: true, content: '[deleted]' }
            : comment
        )
      );
    } catch (err) {
      console.error('Error deleting comment:', err);
      alert('Failed to delete comment. Please try again.');
    }
  };

  // Organize comments into parent and replies
  const parentComments = comments.filter((c) => !c.parent_comment_id);
  const getReplies = (parentId: string) =>
    comments.filter((c) => c.parent_comment_id === parentId);

  if (isLoading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="animate-pulse flex gap-3">
            <div className="w-8 h-8 bg-gray-200 rounded-full" />
            <div className="flex-1 space-y-2">
              <div className="h-4 bg-gray-200 rounded w-1/4" />
              <div className="h-3 bg-gray-200 rounded w-3/4" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4">
        <p className="text-red-600 text-sm">{error}</p>
        <button
          onClick={loadComments}
          className="mt-2 text-red-600 text-sm font-medium hover:underline"
        >
          Try again
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Comment input */}
      <CommentInput
        targetType={targetType}
        targetId={targetId}
        onCommentAdded={handleCommentAdded}
      />

      {/* Comments list */}
      {comments.length === 0 ? (
        <div className="text-center py-8">
          <p className="text-gray-500 text-sm">
            No comments yet. Be the first to comment!
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {parentComments.map((comment) => (
            <CommentItem
              key={comment.id}
              comment={comment}
              replies={showReplies ? getReplies(comment.id) : []}
              isReplyingTo={replyingTo === comment.id}
              onReply={() => setReplyingTo(comment.id)}
              onCancelReply={() => setReplyingTo(null)}
              onReplyAdded={handleReplyAdded}
              onDelete={handleDeleteComment}
              targetType={targetType}
              targetId={targetId}
            />
          ))}
        </div>
      )}
    </div>
  );
}

interface CommentItemProps {
  comment: Comment;
  replies: Comment[];
  isReplyingTo: boolean;
  onReply: () => void;
  onCancelReply: () => void;
  onReplyAdded: (reply: Comment) => void;
  onDelete: (commentId: string) => void;
  targetType: string;
  targetId: string;
}

function CommentItem({
  comment,
  replies,
  isReplyingTo,
  onReply,
  onCancelReply,
  onReplyAdded,
  onDelete,
  targetType,
  targetId,
}: CommentItemProps) {
  const { user } = useAuth();
  const isOwner = user?.id === comment.user_id;
  const displayName = comment.user?.display_name || comment.user?.username || 'Unknown';

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 60) return 'just now';
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
    if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`;
    return date.toLocaleDateString();
  };

  return (
    <div className="flex gap-3">
      {/* User avatar */}
      <div className="flex-shrink-0">
        {comment.user?.avatar_url ? (
          <img
            src={comment.user.avatar_url}
            alt={displayName}
            className="w-8 h-8 rounded-full object-cover"
          />
        ) : (
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
            <span className="text-white text-sm font-semibold">
              {displayName[0].toUpperCase()}
            </span>
          </div>
        )}
      </div>

      {/* Comment content */}
      <div className="flex-1 min-w-0">
        {/* Header */}
        <div className="flex items-center gap-2 mb-1">
          <span className="font-medium text-sm text-gray-900">
            {displayName}
          </span>
          <span className="text-xs text-gray-500">
            {formatDate(comment.created_at)}
          </span>
          {comment.updated_at !== comment.created_at && (
            <span className="text-xs text-gray-400">(edited)</span>
          )}
        </div>

        {/* Content */}
        <p className={`text-sm text-gray-700 mb-2 whitespace-pre-wrap ${comment.is_deleted ? 'italic text-gray-400' : ''}`}>
          {comment.content}
        </p>

        {/* Actions */}
        {!comment.is_deleted && (
          <div className="flex items-center gap-4">
            <LikeButton
              targetType="comment"
              targetId={comment.id}
              initialLikeCount={comment.likes_count}
              size="sm"
            />

            <button
              onClick={onReply}
              className="text-xs text-gray-600 hover:text-gray-900 font-medium"
            >
              Reply
            </button>

            {isOwner && (
              <button
                onClick={() => onDelete(comment.id)}
                className="text-xs text-red-600 hover:text-red-700 font-medium"
              >
                Delete
              </button>
            )}
          </div>
        )}

        {/* Reply input */}
        {isReplyingTo && (
          <div className="mt-3">
            <CommentInput
              targetType={targetType as any}
              targetId={targetId}
              parentCommentId={comment.id}
              onCommentAdded={onReplyAdded}
              onCancel={onCancelReply}
              placeholder={`Reply to ${displayName}...`}
              autoFocus
            />
          </div>
        )}

        {/* Replies */}
        {replies.length > 0 && (
          <div className="mt-4 space-y-4 pl-4 border-l-2 border-gray-200">
            {replies.map((reply) => (
              <CommentItem
                key={reply.id}
                comment={reply}
                replies={[]}
                isReplyingTo={false}
                onReply={() => {}}
                onCancelReply={() => {}}
                onReplyAdded={onReplyAdded}
                onDelete={onDelete}
                targetType={targetType}
                targetId={targetId}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
