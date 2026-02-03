'use client';

import { useState, useEffect, use, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import type { EventWithDetails, EventResponse, RSVPStatus, EventComment, CommentsResponse, EventActivity, ActivityResponse } from '@/types/event';

export default function EventDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const [event, setEvent] = useState<EventWithDetails | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRSVPing, setIsRSVPing] = useState(false);
  const [shareUrl, setShareUrl] = useState('');

  // Comments state
  const [comments, setComments] = useState<EventComment[]>([]);
  const [commentCount, setCommentCount] = useState(0);
  const [isCommentsGated, setIsCommentsGated] = useState(true);
  const [gatedMessage, setGatedMessage] = useState('');
  const [isLoadingComments, setIsLoadingComments] = useState(false);
  const [newComment, setNewComment] = useState('');
  const [isPostingComment, setIsPostingComment] = useState(false);
  const [replyingTo, setReplyingTo] = useState<EventComment | null>(null);
  const commentInputRef = useRef<HTMLTextAreaElement>(null);

  // Activity state
  const [activities, setActivities] = useState<EventActivity[]>([]);
  const [isLoadingActivities, setIsLoadingActivities] = useState(false);
  const [activeTab, setActiveTab] = useState<'discussion' | 'activity'>('discussion');

  // Toast state
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

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

  // Fetch comments
  const fetchComments = async () => {
    setIsLoadingComments(true);
    try {
      const res = await fetch(`/api/events/${id}/comments`);
      if (res.ok) {
        const data: CommentsResponse = await res.json();
        setComments(data.comments);
        setCommentCount(data.commentCount);
        setIsCommentsGated(data.gated);
        setGatedMessage(data.message || '');
      }
    } catch (error) {
      console.error('Error fetching comments:', error);
    } finally {
      setIsLoadingComments(false);
    }
  };

  // Fetch activity
  const fetchActivity = async () => {
    setIsLoadingActivities(true);
    try {
      const res = await fetch(`/api/events/${id}/activity`);
      if (res.ok) {
        const data: ActivityResponse = await res.json();
        if (!data.gated) {
          setActivities(data.activities);
        }
      }
    } catch (error) {
      console.error('Error fetching activity:', error);
    } finally {
      setIsLoadingActivities(false);
    }
  };

  // Show toast helper
  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // Fetch comments and activity after event loads and when RSVP changes
  useEffect(() => {
    if (event) {
      fetchComments();
      fetchActivity();
    }
  }, [event?.userRSVPStatus, id]);

  const handlePostComment = async () => {
    if (!newComment.trim() || isPostingComment) return;

    setIsPostingComment(true);
    try {
      const res = await fetch(`/api/events/${id}/comments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          content: newComment.trim(),
          parentId: replyingTo?.id,
        }),
      });

      if (res.ok) {
        const data = await res.json();
        // Add to comments list
        if (replyingTo) {
          // Add reply to parent comment
          setComments((prev) =>
            prev.map((c) =>
              c.id === replyingTo.id
                ? { ...c, replies: [...(c.replies || []), data.comment] }
                : c
            )
          );
        } else {
          // Add new top-level comment
          setComments((prev) => [...prev, data.comment]);
        }
        setCommentCount((prev) => prev + 1);
        setNewComment('');
        setReplyingTo(null);
      }
    } catch (error) {
      console.error('Error posting comment:', error);
    } finally {
      setIsPostingComment(false);
    }
  };

  const handleReply = (comment: EventComment) => {
    setReplyingTo(comment);
    commentInputRef.current?.focus();
  };

  const cancelReply = () => {
    setReplyingTo(null);
  };

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
        showToast(status === 'going' ? "You're in! See you on the mountain" : "Marked as maybe", 'success');
      } else {
        showToast('Failed to update RSVP. Please try again.', 'error');
      }
    } catch (error) {
      console.error('Error RSVPing:', error);
      showToast('Failed to update RSVP. Check your connection.', 'error');
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
    showToast('Invite link copied!', 'success');
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
      <div className="min-h-screen bg-slate-900">
        <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
          <div className="max-w-2xl mx-auto px-4 py-4">
            <div className="flex items-center gap-3">
              <div className="w-6 h-6 bg-slate-700 rounded animate-pulse" />
              <div className="h-6 w-32 bg-slate-700 rounded animate-pulse" />
            </div>
          </div>
        </header>
        <div className="max-w-2xl mx-auto px-4 py-6 space-y-4">
          {/* Event Info Skeleton */}
          <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
            <div className="h-8 bg-slate-700 rounded w-3/4 mb-3" />
            <div className="h-5 bg-slate-700 rounded w-1/3 mb-4" />
            <div className="space-y-3">
              <div className="h-4 bg-slate-700 rounded w-2/3" />
              <div className="h-4 bg-slate-700 rounded w-1/2" />
              <div className="h-4 bg-slate-700 rounded w-1/3" />
            </div>
          </div>
          {/* Attendees Skeleton */}
          <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
            <div className="h-6 bg-slate-700 rounded w-1/2 mb-4" />
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-slate-700 rounded-full" />
                  <div className="h-4 bg-slate-700 rounded w-32" />
                </div>
              ))}
            </div>
          </div>
        </div>
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

        {/* Discussion & Activity Section */}
        <div className="bg-slate-800 rounded-xl p-6 mt-4">
          {/* Tab Switcher */}
          <div className="flex gap-1 mb-4 bg-slate-700/50 rounded-lg p-1">
            <button
              onClick={() => setActiveTab('discussion')}
              className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors flex items-center justify-center gap-2 ${
                activeTab === 'discussion'
                  ? 'bg-slate-600 text-white'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              Discussion ({commentCount})
            </button>
            <button
              onClick={() => setActiveTab('activity')}
              className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors flex items-center justify-center gap-2 ${
                activeTab === 'activity'
                  ? 'bg-slate-600 text-white'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Activity ({activities.length})
            </button>
          </div>

          {/* Activity Tab */}
          {activeTab === 'activity' ? (
            isLoadingActivities ? (
              <div className="flex items-center justify-center py-8">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-sky-500" />
              </div>
            ) : activities.length === 0 ? (
              <div className="text-center py-8">
                <p className="text-gray-400">No activity yet</p>
                <p className="text-gray-500 text-sm mt-1">Activity will appear when people RSVP or comment</p>
              </div>
            ) : (
              <div className="space-y-3">
                {activities.map((activity) => (
                  <ActivityRow key={activity.id} activity={activity} />
                ))}
              </div>
            )
          ) : isLoadingComments ? (
            <div className="flex items-center justify-center py-8">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-sky-500" />
            </div>
          ) : isCommentsGated ? (
            // Gated view for non-RSVP'd users
            <div className="text-center py-8">
              <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-slate-700/50 flex items-center justify-center">
                <svg className="w-8 h-8 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>
              <p className="text-white font-medium">{commentCount} comments</p>
              <p className="text-gray-400 text-sm mt-1">{gatedMessage || 'RSVP to join the conversation'}</p>
            </div>
          ) : (
            <>
              {/* Comments List */}
              {comments.length === 0 ? (
                <div className="text-center py-8">
                  <p className="text-gray-400">No comments yet</p>
                  <p className="text-gray-500 text-sm mt-1">Be the first to start the conversation!</p>
                </div>
              ) : (
                <div className="space-y-4 mb-4">
                  {comments.map((comment) => (
                    <div key={comment.id}>
                      {/* Main Comment */}
                      <CommentRow comment={comment} onReply={handleReply} />

                      {/* Replies */}
                      {comment.replies && comment.replies.length > 0 && (
                        <div className="ml-8 mt-2 space-y-2 border-l-2 border-slate-700 pl-4">
                          {comment.replies.map((reply) => (
                            <CommentRow key={reply.id} comment={reply} onReply={handleReply} isReply />
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}

              {/* Reply Indicator */}
              {replyingTo && (
                <div className="flex items-center gap-2 px-3 py-2 bg-slate-700/50 rounded-t-lg border-b border-slate-600">
                  <svg className="w-4 h-4 text-sky-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
                  </svg>
                  <span className="text-sm text-gray-300">
                    Replying to {replyingTo.user.display_name || replyingTo.user.username}
                  </span>
                  <button onClick={cancelReply} className="ml-auto text-gray-400 hover:text-white">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              )}

              {/* Comment Input */}
              <div className={`flex gap-2 ${replyingTo ? 'bg-slate-700/30 p-3 rounded-b-lg' : ''}`}>
                <textarea
                  ref={commentInputRef}
                  value={newComment}
                  onChange={(e) => setNewComment(e.target.value)}
                  placeholder={replyingTo ? 'Write a reply...' : 'Add a comment...'}
                  rows={1}
                  className="flex-1 bg-slate-700 text-white rounded-lg px-4 py-2 resize-none focus:outline-none focus:ring-2 focus:ring-sky-500 placeholder-gray-400"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                      e.preventDefault();
                      handlePostComment();
                    }
                  }}
                />
                <button
                  onClick={handlePostComment}
                  disabled={!newComment.trim() || isPostingComment}
                  className="px-4 py-2 bg-sky-500 hover:bg-sky-600 disabled:bg-slate-600 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
                >
                  {isPostingComment ? (
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white" />
                  ) : (
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                    </svg>
                  )}
                </button>
              </div>
            </>
          )}
        </div>

        {/* Toast Notification */}
        {toast && (
          <div
            className={`fixed bottom-24 right-6 px-4 py-3 rounded-xl shadow-lg z-50 animate-slide-up ${
              toast.type === 'success' ? 'bg-green-500' : 'bg-red-500'
            } text-white font-medium`}
          >
            {toast.message}
          </div>
        )}

        {/* Spacer for sticky footer */}
        {(!event.isCreator || shareUrl) && <div className="h-24" />}
      </div>

      {/* Sticky Footer with Action Buttons */}
      {(!event.isCreator || shareUrl) && (
        <div className="fixed bottom-0 left-0 right-0 bg-slate-900/95 backdrop-blur-sm border-t border-slate-800 px-4 py-4 z-40">
          <div className="max-w-2xl mx-auto">
            {/* RSVP Buttons */}
            {!event.isCreator && (
              <div className="flex gap-3">
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

            {/* Share Button - visible for all RSVPd users */}
            {shareUrl && (
              <button
                onClick={handleShare}
                className={`w-full py-3 bg-sky-500 hover:bg-sky-600 text-white rounded-xl font-medium transition-colors flex items-center justify-center gap-2 ${!event.isCreator ? 'mt-3' : ''}`}
              >
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
                </svg>
                Share Invite Link
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// Comment Row Component
function CommentRow({
  comment,
  onReply,
  isReply = false,
}: {
  comment: EventComment;
  onReply: (comment: EventComment) => void;
  isReply?: boolean;
}) {
  const formatRelativeTime = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  return (
    <div className={`flex gap-3 ${isReply ? 'py-1' : 'py-2'}`}>
      {/* Avatar */}
      <div
        className={`${isReply ? 'w-7 h-7' : 'w-9 h-9'} rounded-full bg-gradient-to-br from-sky-500 to-purple-500 flex items-center justify-center flex-shrink-0`}
      >
        <span className={`text-white font-medium ${isReply ? 'text-xs' : 'text-sm'}`}>
          {(comment.user.display_name || comment.user.username)[0].toUpperCase()}
        </span>
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className={`font-medium text-white ${isReply ? 'text-sm' : ''}`}>
            {comment.user.display_name || comment.user.username}
          </span>
          <span className="text-gray-500 text-xs">·</span>
          <span className="text-gray-500 text-xs">{formatRelativeTime(comment.created_at)}</span>
        </div>
        <p className={`text-gray-300 mt-0.5 ${isReply ? 'text-sm' : ''}`}>{comment.content}</p>
        <button
          onClick={() => onReply(comment)}
          className="text-gray-500 hover:text-sky-400 text-xs mt-1 flex items-center gap-1 transition-colors"
        >
          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
          </svg>
          Reply
        </button>
      </div>
    </div>
  );
}

// Activity Row Component
function ActivityRow({ activity }: { activity: EventActivity }) {
  const formatRelativeTime = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const getActivityIcon = () => {
    switch (activity.activityType) {
      case 'rsvp_going':
        return (
          <div className="w-8 h-8 rounded-full bg-green-500/20 flex items-center justify-center">
            <svg className="w-4 h-4 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
        );
      case 'rsvp_maybe':
        return (
          <div className="w-8 h-8 rounded-full bg-yellow-500/20 flex items-center justify-center">
            <svg className="w-4 h-4 text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        );
      case 'comment_posted':
        return (
          <div className="w-8 h-8 rounded-full bg-sky-500/20 flex items-center justify-center">
            <svg className="w-4 h-4 text-sky-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
          </div>
        );
      case 'milestone_reached':
        return (
          <div className="w-8 h-8 rounded-full bg-purple-500/20 flex items-center justify-center">
            <svg className="w-4 h-4 text-purple-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
            </svg>
          </div>
        );
      default:
        return (
          <div className="w-8 h-8 rounded-full bg-slate-600 flex items-center justify-center">
            <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        );
    }
  };

  const getActivityText = () => {
    const userName = activity.user?.displayName || activity.user?.username || 'Someone';
    switch (activity.activityType) {
      case 'rsvp_going':
        return <><span className="font-medium text-white">{userName}</span> is going</>;
      case 'rsvp_maybe':
        return <><span className="font-medium text-white">{userName}</span> marked as maybe</>;
      case 'rsvp_declined':
        return <><span className="font-medium text-white">{userName}</span> can't make it</>;
      case 'comment_posted':
        return (
          <>
            <span className="font-medium text-white">{userName}</span> commented
            {activity.metadata.preview && (
              <span className="text-gray-500 block text-sm truncate">"{activity.metadata.preview}"</span>
            )}
          </>
        );
      case 'milestone_reached':
        return (
          <span className="font-medium text-purple-400">
            {activity.metadata.label || `${activity.metadata.milestone} people going!`}
          </span>
        );
      case 'event_created':
        return <><span className="font-medium text-white">{userName}</span> created this event</>;
      case 'event_updated':
        return <><span className="font-medium text-white">{userName}</span> updated the event</>;
      default:
        return <span className="text-gray-400">Activity</span>;
    }
  };

  return (
    <div className="flex gap-3 py-2">
      {getActivityIcon()}
      <div className="flex-1 min-w-0">
        <p className="text-gray-300 text-sm">{getActivityText()}</p>
        <p className="text-gray-500 text-xs mt-0.5">{formatRelativeTime(activity.createdAt)}</p>
      </div>
    </div>
  );
}
