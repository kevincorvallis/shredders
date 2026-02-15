/**
 * TypeScript types for ski events social feature
 */

// ============================================
// Enums / Literal Types
// ============================================

export type EventStatus = 'active' | 'cancelled' | 'completed';

export type SkillLevel = 'beginner' | 'intermediate' | 'advanced' | 'expert' | 'all';

export type RSVPStatus = 'invited' | 'going' | 'maybe' | 'declined' | 'waitlist';

// ============================================
// Database Row Types
// ============================================

export interface EventRow {
  id: string;
  user_id: string;
  mountain_id: string;
  title: string;
  notes: string | null;
  event_date: string; // DATE as ISO string
  departure_time: string | null; // TIME as string (HH:MM:SS)
  departure_location: string | null;
  skill_level: SkillLevel | null;
  carpool_available: boolean;
  carpool_seats: number | null;
  max_attendees: number | null;
  status: EventStatus;
  created_at: string;
  updated_at: string;
  attendee_count: number;
  going_count: number;
  maybe_count: number;
  waitlist_count: number;
}

export interface EventAttendeeRow {
  id: string;
  event_id: string;
  user_id: string;
  status: RSVPStatus;
  is_driver: boolean;
  needs_ride: boolean;
  pickup_location: string | null;
  passengers_count: number;
  waitlist_position: number | null;
  responded_at: string | null;
  invited_at: string;
  created_at: string;
  updated_at: string;
}

export interface EventInviteTokenRow {
  id: string;
  event_id: string;
  token: string;
  created_by: string;
  uses_count: number;
  max_uses: number | null;
  expires_at: string | null;
  created_at: string;
}

// ============================================
// Insert Types (for creating new records)
// ============================================

export interface EventInsert {
  user_id: string;
  mountain_id: string;
  title: string;
  notes?: string | null;
  event_date: string;
  departure_time?: string | null;
  departure_location?: string | null;
  skill_level?: SkillLevel | null;
  carpool_available?: boolean;
  carpool_seats?: number | null;
  max_attendees?: number | null;
}

export interface EventAttendeeInsert {
  event_id: string;
  user_id: string;
  status?: RSVPStatus;
  is_driver?: boolean;
  needs_ride?: boolean;
  pickup_location?: string | null;
  passengers_count?: number;
}

export interface EventInviteTokenInsert {
  event_id: string;
  token: string;
  created_by: string;
  max_uses?: number | null;
  expires_at?: string | null;
}

// ============================================
// Update Types (for modifying records)
// ============================================

export interface EventUpdate {
  title?: string;
  notes?: string | null;
  event_date?: string;
  departure_time?: string | null;
  departure_location?: string | null;
  skill_level?: SkillLevel | null;
  carpool_available?: boolean;
  carpool_seats?: number | null;
  max_attendees?: number | null;
  status?: EventStatus;
}

export interface EventAttendeeUpdate {
  status?: RSVPStatus;
  is_driver?: boolean;
  needs_ride?: boolean;
  pickup_location?: string | null;
  passengers_count?: number;
  responded_at?: string;
}

// ============================================
// API Request Types
// ============================================

export interface CreateEventRequest {
  mountainId: string;
  title: string;
  notes?: string;
  eventDate: string; // ISO date string (YYYY-MM-DD)
  departureTime?: string; // HH:MM format
  departureLocation?: string;
  skillLevel?: SkillLevel;
  carpoolAvailable?: boolean;
  carpoolSeats?: number;
  maxAttendees?: number; // Optional capacity limit (1-1000)
}

export interface UpdateEventRequest {
  title?: string;
  notes?: string | null;
  eventDate?: string;
  departureTime?: string | null;
  departureLocation?: string | null;
  skillLevel?: SkillLevel | null;
  carpoolAvailable?: boolean;
  carpoolSeats?: number | null;
  maxAttendees?: number | null; // Optional capacity limit (1-1000, null = unlimited)
}

export interface RSVPRequest {
  status: 'going' | 'maybe' | 'declined';
  isDriver?: boolean;
  needsRide?: boolean;
  pickupLocation?: string;
}

// ============================================
// API Response Types
// ============================================

export interface EventUser {
  id: string;
  username: string;
  display_name: string | null;
  avatar_url: string | null;
}

export interface EventAttendee {
  id: string;
  userId: string;
  status: RSVPStatus;
  isDriver: boolean;
  needsRide: boolean;
  pickupLocation: string | null;
  waitlistPosition: number | null;
  respondedAt: string | null;
  user: EventUser;
}

export interface EventConditions {
  temperature?: number;
  snowfall24h?: number;
  snowDepth?: number;
  powderScore?: number;
  forecast?: {
    high: number;
    low: number;
    snowfall: number;
    conditions: string;
  };
}

export interface Event {
  id: string;
  creatorId: string;
  mountainId: string;
  mountainName?: string;
  title: string;
  notes: string | null;
  eventDate: string;
  departureTime: string | null;
  departureLocation: string | null;
  skillLevel: SkillLevel | null;
  carpoolAvailable: boolean;
  carpoolSeats: number | null;
  maxAttendees: number | null;
  status: EventStatus;
  createdAt: string;
  updatedAt: string;
  attendeeCount: number;
  goingCount: number;
  maybeCount: number;
  waitlistCount: number;
  commentCount?: number;
  photoCount?: number;
  creator: EventUser;
  userRSVPStatus?: RSVPStatus | null;
  isCreator?: boolean;
}

export interface EventWithDetails extends Event {
  attendees: EventAttendee[];
  conditions?: EventConditions;
  inviteToken?: string;
}

export interface EventsListResponse {
  events: Event[];
  pagination: {
    total: number;
    limit: number;
    offset: number;
    hasMore: boolean;
  };
}

export interface EventResponse {
  event: EventWithDetails;
}

export interface CreateEventResponse {
  event: Event;
  inviteToken: string;
  inviteUrl: string;
}

export interface RSVPResponse {
  attendee: EventAttendee;
  event: {
    id: string;
    goingCount: number;
    maybeCount: number;
    attendeeCount: number;
    waitlistCount?: number;
    maxAttendees?: number | null;
  };
  message?: string;
  wasWaitlisted?: boolean;
}

// ============================================
// Invite Link Types
// ============================================

export interface InviteInfo {
  event: Event;
  conditions?: EventConditions;
  isValid: boolean;
  isExpired: boolean;
  requiresAuth: boolean;
}

export interface InviteResponse {
  invite: InviteInfo;
}

// ============================================
// Push Notification Types
// ============================================

export interface EventReminderPayload {
  eventId: string;
  eventTitle: string;
  mountainId: string;
  mountainName: string;
  eventDate: string;
  departureTime: string | null;
  goingCount: number;
  conditions?: EventConditions;
}

// ============================================
// Date Polling Types
// ============================================

export type DateVoteChoice = 'available' | 'maybe' | 'unavailable';

export type DatePollStatus = 'open' | 'closed';

export interface DatePollOption {
  id: string;
  proposedDate: string; // YYYY-MM-DD
  proposedBy: string;
  votes: DatePollVote[];
  availableCount: number;
  maybeCount: number;
  unavailableCount: number;
}

export interface DatePollVote {
  userId: string;
  vote: DateVoteChoice;
  user?: EventUser;
}

export interface DatePoll {
  id: string;
  eventId: string;
  status: DatePollStatus;
  createdAt: string;
  closedAt: string | null;
  options: DatePollOption[];
}

export interface DatePollResponse {
  poll: DatePoll;
}

export interface CreateDatePollRequest {
  dates: string[]; // Array of YYYY-MM-DD strings (2-5 dates)
}

export interface CastDateVoteRequest {
  optionId: string;
  vote: DateVoteChoice;
}

export interface ResolveDatePollRequest {
  optionId: string; // The winning date option
}

// ============================================
// Query Parameters Types
// ============================================

export interface EventsQueryParams {
  mountainId?: string;
  status?: EventStatus;
  upcoming?: boolean;
  createdByMe?: boolean;
  attendingOnly?: boolean;
  limit?: number;
  offset?: number;
}

// ============================================
// Comment Types
// ============================================

export interface EventComment {
  id: string;
  event_id: string;
  user_id: string;
  content: string;
  parent_id: string | null;
  created_at: string;
  updated_at: string;
  user: EventUser;
  replies?: EventComment[];
}

export interface CommentsResponse {
  comments: EventComment[];
  commentCount: number;
  gated: boolean;
  message?: string;
}

export interface CreateCommentRequest {
  content: string;
  parentId?: string;
}

export interface CreateCommentResponse {
  comment: EventComment;
}

// ============================================
// Activity Types
// ============================================

export type ActivityType =
  | 'rsvp_going'
  | 'rsvp_maybe'
  | 'rsvp_declined'
  | 'comment_posted'
  | 'milestone_reached'
  | 'event_created'
  | 'event_updated';

export interface ActivityMetadata {
  milestone?: number;
  label?: string;
  comment_id?: string;
  preview?: string;
  is_reply?: boolean;
  previous_status?: string;
}

export interface EventActivity {
  id: string;
  eventId: string;
  userId: string | null;
  activityType: ActivityType;
  metadata: ActivityMetadata;
  createdAt: string;
  user?: {
    id: string;
    username: string;
    displayName: string | null;
    avatarUrl: string | null;
  } | null;
}

export interface ActivityResponse {
  activities: EventActivity[];
  activityCount: number;
  gated: boolean;
  message?: string;
  pagination?: {
    limit: number;
    offset: number;
    hasMore: boolean;
  };
}
