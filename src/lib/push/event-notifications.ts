import { sendPushNotification, sendBulkPushNotifications } from './apns';
import { createAdminClient } from '@/lib/supabase/server';

/**
 * Event Notification Service
 *
 * Sends push notifications for event-related activities:
 * - Event updates (date/time/location changes)
 * - Event cancellations
 * - New RSVPs
 * - New comments
 */

/**
 * Get device tokens for users who should receive notifications
 */
async function getDeviceTokensForUsers(userIds: string[]): Promise<string[]> {
  if (userIds.length === 0) return [];

  const supabase = createAdminClient();

  const { data: tokens, error } = await supabase
    .from('push_notification_tokens')
    .select('device_token')
    .in('user_id', userIds)
    .eq('is_active', true)
    .eq('platform', 'ios');

  if (error) {
    console.error('Error fetching device tokens:', error);
    return [];
  }

  return tokens?.map((t) => t.device_token) || [];
}

/**
 * Get attendee user IDs for an event (going or maybe)
 */
async function getEventAttendeeIds(eventId: string, excludeUserId?: string): Promise<string[]> {
  const supabase = createAdminClient();

  let query = supabase
    .from('event_attendees')
    .select('user_id')
    .eq('event_id', eventId)
    .in('status', ['going', 'maybe']);

  if (excludeUserId) {
    query = query.neq('user_id', excludeUserId);
  }

  const { data: attendees, error } = await query;

  if (error) {
    console.error('Error fetching attendees:', error);
    return [];
  }

  return attendees?.map((a) => a.user_id) || [];
}

/**
 * Send notification when an event is updated
 */
export async function sendEventUpdateNotification(options: {
  eventId: string;
  eventTitle: string;
  mountainName: string;
  changeDescription: string; // e.g., "Date changed to Feb 15" or "Time updated to 7:00 AM"
  updatedByUserId: string;
}): Promise<{ sent: number; failed: number }> {
  // Get all attendees except the person who made the update
  const attendeeIds = await getEventAttendeeIds(options.eventId, options.updatedByUserId);

  if (attendeeIds.length === 0) {
    return { sent: 0, failed: 0 };
  }

  const deviceTokens = await getDeviceTokensForUsers(attendeeIds);

  if (deviceTokens.length === 0) {
    return { sent: 0, failed: 0 };
  }

  const result = await sendBulkPushNotifications(deviceTokens, {
    title: `Event Updated: ${options.eventTitle}`,
    body: `${options.changeDescription} - ${options.mountainName}`,
    category: 'event-update',
    sound: 'default',
    data: {
      type: 'event-update',
      eventId: options.eventId,
    },
    threadId: `event-${options.eventId}`,
  });

  console.log(`Event update notifications: ${result.sent} sent, ${result.failed} failed`);
  return { sent: result.sent, failed: result.failed };
}

/**
 * Send notification when an event is cancelled
 */
export async function sendEventCancellationNotification(options: {
  eventId: string;
  eventTitle: string;
  mountainName: string;
  eventDate: string;
  cancelledByUserId: string;
}): Promise<{ sent: number; failed: number }> {
  // Get all attendees except the person who cancelled
  const attendeeIds = await getEventAttendeeIds(options.eventId, options.cancelledByUserId);

  if (attendeeIds.length === 0) {
    return { sent: 0, failed: 0 };
  }

  const deviceTokens = await getDeviceTokensForUsers(attendeeIds);

  if (deviceTokens.length === 0) {
    return { sent: 0, failed: 0 };
  }

  const result = await sendBulkPushNotifications(deviceTokens, {
    title: `Event Cancelled`,
    body: `"${options.eventTitle}" at ${options.mountainName} on ${options.eventDate} has been cancelled`,
    category: 'event-cancelled',
    sound: 'default',
    data: {
      type: 'event-cancelled',
      eventId: options.eventId,
    },
    threadId: `event-${options.eventId}`,
  });

  console.log(`Event cancellation notifications: ${result.sent} sent, ${result.failed} failed`);
  return { sent: result.sent, failed: result.failed };
}

/**
 * Send notification to event creator when someone RSVPs
 */
export async function sendNewRSVPNotification(options: {
  eventId: string;
  eventTitle: string;
  creatorUserId: string;
  attendeeName: string;
  rsvpStatus: 'going' | 'maybe';
}): Promise<{ success: boolean; error?: string }> {
  const deviceTokens = await getDeviceTokensForUsers([options.creatorUserId]);

  if (deviceTokens.length === 0) {
    return { success: false, error: 'No device tokens found for creator' };
  }

  const statusText = options.rsvpStatus === 'going' ? 'is going' : 'might join';

  const result = await sendPushNotification(deviceTokens[0], {
    title: `New RSVP: ${options.eventTitle}`,
    body: `${options.attendeeName} ${statusText}!`,
    category: 'new-rsvp',
    sound: 'default',
    badge: 1,
    data: {
      type: 'new-rsvp',
      eventId: options.eventId,
    },
    threadId: `event-${options.eventId}`,
  });

  return result;
}

/**
 * Send notification to event creator when RSVP status changes
 */
export async function sendRSVPChangeNotification(options: {
  eventId: string;
  eventTitle: string;
  creatorUserId: string;
  attendeeName: string;
  oldStatus: string;
  newStatus: string;
}): Promise<{ success: boolean; error?: string }> {
  const deviceTokens = await getDeviceTokensForUsers([options.creatorUserId]);

  if (deviceTokens.length === 0) {
    return { success: false, error: 'No device tokens found for creator' };
  }

  let body: string;
  if (options.newStatus === 'not_going') {
    body = `${options.attendeeName} can no longer make it`;
  } else if (options.newStatus === 'going' && options.oldStatus === 'maybe') {
    body = `${options.attendeeName} confirmed they're going!`;
  } else if (options.newStatus === 'maybe' && options.oldStatus === 'going') {
    body = `${options.attendeeName} changed to maybe`;
  } else {
    body = `${options.attendeeName} updated their RSVP`;
  }

  const result = await sendPushNotification(deviceTokens[0], {
    title: `RSVP Update: ${options.eventTitle}`,
    body,
    category: 'rsvp-change',
    sound: 'default',
    data: {
      type: 'rsvp-change',
      eventId: options.eventId,
    },
    threadId: `event-${options.eventId}`,
  });

  return result;
}

/**
 * Send notification when someone comments on an event
 */
export async function sendNewCommentNotification(options: {
  eventId: string;
  eventTitle: string;
  creatorUserId: string;
  commenterUserId: string;
  commenterName: string;
  commentPreview: string; // First ~50 chars of comment
}): Promise<{ success: boolean; error?: string }> {
  // Don't notify if the creator is commenting on their own event
  if (options.creatorUserId === options.commenterUserId) {
    return { success: true };
  }

  const deviceTokens = await getDeviceTokensForUsers([options.creatorUserId]);

  if (deviceTokens.length === 0) {
    return { success: false, error: 'No device tokens found for creator' };
  }

  const result = await sendPushNotification(deviceTokens[0], {
    title: `New Comment: ${options.eventTitle}`,
    body: `${options.commenterName}: ${options.commentPreview}`,
    category: 'event-comment',
    sound: 'default',
    badge: 1,
    data: {
      type: 'event-comment',
      eventId: options.eventId,
    },
    threadId: `event-${options.eventId}`,
  });

  return result;
}

/**
 * Send notification when someone replies to a comment
 */
export async function sendCommentReplyNotification(options: {
  eventId: string;
  eventTitle: string;
  parentCommentAuthorId: string;
  replierUserId: string;
  replierName: string;
  replyPreview: string;
}): Promise<{ success: boolean; error?: string }> {
  // Don't notify if replying to own comment
  if (options.parentCommentAuthorId === options.replierUserId) {
    return { success: true };
  }

  const deviceTokens = await getDeviceTokensForUsers([options.parentCommentAuthorId]);

  if (deviceTokens.length === 0) {
    return { success: false, error: 'No device tokens found for comment author' };
  }

  const result = await sendPushNotification(deviceTokens[0], {
    title: `Reply to your comment`,
    body: `${options.replierName}: ${options.replyPreview}`,
    category: 'comment-reply',
    sound: 'default',
    badge: 1,
    data: {
      type: 'comment-reply',
      eventId: options.eventId,
    },
    threadId: `event-${options.eventId}`,
  });

  return result;
}
