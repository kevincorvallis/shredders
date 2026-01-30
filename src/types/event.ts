/**
 * TypeScript types for ski events social feature
 */

// ============================================
// Enums / Literal Types
// ============================================

export type EventStatus = 'active' | 'cancelled' | 'completed';

export type SkillLevel = 'beginner' | 'intermediate' | 'advanced' | 'expert' | 'all';

export type RSVPStatus = 'invited' | 'going' | 'maybe' | 'declined';

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
  status: EventStatus;
  created_at: string;
  updated_at: string;
  attendee_count: number;
  going_count: number;
  maybe_count: number;
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
  status: EventStatus;
  createdAt: string;
  updatedAt: string;
  attendeeCount: number;
  goingCount: number;
  maybeCount: number;
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
  };
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
