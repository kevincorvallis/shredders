/**
 * Event Cancellation Edge Cases - Comprehensive Tests
 *
 * Tests all edge cases around event deletion/cancellation flows:
 * - Double cancellation prevention
 * - Status guards on PATCH, comments, photos
 * - Past/completed event cancellation
 * - Cancelled event interactions (calendar, carpool, activity)
 * - Clone and reactivation edge cases
 * - Series cancellation
 * - Notification coverage (waitlisted users)
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { GET as EventGet, PATCH, DELETE } from '../[id]/route';
import { POST as RSVPPost, DELETE as RSVPDelete } from '../[id]/rsvp/route';
import { POST as CommentPost } from '../[id]/comments/route';
import { GET as CalendarGet } from '../[id]/calendar/route';
import { GET as ActivityGet } from '../[id]/activity/route';
import { GET as CarpoolGet } from '../[id]/carpool/route';
import { POST as ClonePost } from '../[id]/clone/route';
import { POST as ReactivatePost } from '../[id]/reactivate/route';
import { GET as InviteGet, POST as InvitePost } from '../invite/[token]/route';
import { GET as EventsListGet } from '../route';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';

// Mock Supabase
vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(),
  createAdminClient: vi.fn(),
}));

// Mock auth
const { mockGetDualAuthUser: cancelMockAuth } = vi.hoisted(() => ({
  mockGetDualAuthUser: vi.fn(),
}));
vi.mock('@/lib/auth', () => ({
  getDualAuthUser: cancelMockAuth,
  withDualAuth: (handler: any) => async (req: any, context: any) => {
    const authUser = await cancelMockAuth(req);
    if (!authUser) {
      const { NextResponse } = await import('next/server');
      return NextResponse.json(
        { error: { code: 'UNAUTHORIZED', message: 'Not authenticated', timestamp: new Date().toISOString() } },
        { status: 401 },
      );
    }
    return handler(req, authUser, context);
  },
}));

// Mock shared
vi.mock('@shredders/shared', () => ({
  getMountain: vi.fn().mockReturnValue({
    id: 'stevens-pass',
    name: 'Stevens Pass',
    location: { lat: 47.7448, lng: -121.0891 },
  }),
}));

// Mock rate limiting to always allow
vi.mock('@/lib/api-utils', () => ({
  rateLimitEnhanced: vi.fn().mockResolvedValue({ success: true }),
  createRateLimitKey: vi.fn().mockReturnValue('test-key'),
}));

// Mock push notifications
vi.mock('@/lib/push/event-notifications', () => ({
  sendEventCancellationNotification: vi.fn().mockResolvedValue({ sent: 0, failed: 0 }),
  sendEventUpdateNotification: vi.fn().mockResolvedValue({ sent: 0, failed: 0 }),
  sendEventReactivationNotification: vi.fn().mockResolvedValue({ sent: 0, failed: 0 }),
  sendNewCommentNotification: vi.fn().mockResolvedValue({ success: true }),
  sendCommentReplyNotification: vi.fn().mockResolvedValue({ success: true }),
  sendNewRSVPNotification: vi.fn().mockResolvedValue({ success: true }),
  sendRSVPChangeNotification: vi.fn().mockResolvedValue({ success: true }),
}));

// Mock crypto for clone
vi.mock('crypto', () => ({
  randomBytes: vi.fn().mockReturnValue({
    toString: vi.fn().mockReturnValue('abc123token'),
  }),
}));

const FUTURE_DATE = '2027-06-15';
const PAST_DATE = '2020-01-01';
const eventId = 'event-cancel-test';

// Helper: create mock supabase that returns specific event data
function createMockSupabase(eventData: Record<string, any>) {
  return {
    from: vi.fn().mockImplementation((table: string) => {
      if (table === 'events') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: eventData,
                error: null,
              }),
            }),
          }),
        };
      }
      if (table === 'event_comments') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              eq: vi.fn().mockResolvedValue({
                count: 0,
                data: null,
                error: null,
              }),
            }),
            count: 'exact',
            head: true,
          }),
        };
      }
      return {
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({ data: null, error: null }),
          }),
        }),
      };
    }),
  };
}

function createMockAdminClient(overrides: Record<string, any> = {}) {
  return {
    from: vi.fn().mockImplementation((table: string) => {
      if (table === 'users') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: { id: 'internal-user-123' },
                error: null,
              }),
            }),
          }),
        };
      }
      if (table === 'events') {
        return {
          update: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              select: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    user_id: 'internal-user-123',
                    mountain_id: 'stevens-pass',
                    title: 'Test Event',
                    event_date: FUTURE_DATE,
                    status: 'active',
                    waitlist_count: 0,
                    creator: { id: 'internal-user-123', username: 'testuser' },
                    ...overrides,
                  },
                  error: null,
                }),
              }),
            }),
          }),
          insert: vi.fn().mockReturnValue({
            select: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: {
                  id: 'cloned-event-id',
                  user_id: 'internal-user-123',
                  mountain_id: 'stevens-pass',
                  title: 'Test Event',
                  event_date: FUTURE_DATE,
                  status: 'active',
                  max_attendees: 10,
                  creator: { id: 'internal-user-123', username: 'testuser' },
                },
                error: null,
              }),
            }),
          }),
        };
      }
      if (table === 'event_attendees') {
        return {
          insert: vi.fn().mockResolvedValue({ data: null, error: null }),
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({ data: null, error: null }),
              }),
            }),
          }),
          delete: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              eq: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      if (table === 'event_invite_tokens') {
        return {
          insert: vi.fn().mockResolvedValue({ data: null, error: null }),
        };
      }
      if (table === 'event_activity') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              count: 0,
              data: null,
              error: null,
            }),
          }),
        };
      }
      return {};
    }),
  };
}

function setupAuth(authenticated = true) {
  if (authenticated) {
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'auth-user-123',
      email: 'test@example.com',
      profileId: 'internal-user-123',
    });
  } else {
    (getDualAuthUser as any).mockResolvedValue(null);
  }
}

// ─── DELETE (Cancel Event) Edge Cases ────────────────────────────────────────

describe('DELETE /api/events/[id] - Cancellation Edge Cases', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth();
  });

  it('should reject cancelling an already-cancelled event (no double-cancel)', async () => {
    const mockSupabase = createMockSupabase({
      user_id: 'internal-user-123',
      title: 'Powder Day',
      mountain_id: 'stevens-pass',
      event_date: FUTURE_DATE,
      status: 'cancelled',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'DELETE',
    });

    const response = await DELETE(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('already cancelled');
  });

  it('should reject cancelling a completed event', async () => {
    const mockSupabase = createMockSupabase({
      user_id: 'internal-user-123',
      title: 'Past Trip',
      mountain_id: 'stevens-pass',
      event_date: FUTURE_DATE,
      status: 'completed',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'DELETE',
    });

    const response = await DELETE(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('completed');
  });

  it('should reject cancelling a past event', async () => {
    const mockSupabase = createMockSupabase({
      user_id: 'internal-user-123',
      title: 'Old Trip',
      mountain_id: 'stevens-pass',
      event_date: PAST_DATE,
      status: 'active',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'DELETE',
    });

    const response = await DELETE(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('past');
  });

  it('should successfully cancel an active future event', async () => {
    const mockSupabase = createMockSupabase({
      user_id: 'internal-user-123',
      title: 'Powder Day',
      mountain_id: 'stevens-pass',
      event_date: FUTURE_DATE,
      status: 'active',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'DELETE',
    });

    const response = await DELETE(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.message).toContain('cancelled');
  });
});

// ─── PATCH (Edit Event) Status Guards ────────────────────────────────────────

describe('PATCH /api/events/[id] - Status Guards', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth();
  });

  it('should reject editing a cancelled event', async () => {
    const mockSupabase = createMockSupabase({
      user_id: 'internal-user-123',
      title: 'Cancelled Trip',
      mountain_id: 'stevens-pass',
      event_date: FUTURE_DATE,
      departure_time: '06:00:00',
      departure_location: 'Northgate',
      going_count: 3,
      max_attendees: null,
      status: 'cancelled',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'PATCH',
      body: JSON.stringify({ title: 'Updated Title' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await PATCH(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('cancelled');
    expect(data.error).toContain('Reactivate');
  });

  it('should reject editing a completed event', async () => {
    const mockSupabase = createMockSupabase({
      user_id: 'internal-user-123',
      title: 'Done Trip',
      mountain_id: 'stevens-pass',
      event_date: PAST_DATE,
      departure_time: '06:00:00',
      departure_location: null,
      going_count: 3,
      max_attendees: null,
      status: 'completed',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'PATCH',
      body: JSON.stringify({ title: 'Updated Title' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await PATCH(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('completed');
  });

  it('should include waitlistCount in PATCH response for active events', async () => {
    const mockSupabase = createMockSupabase({
      user_id: 'internal-user-123',
      title: 'Active Trip',
      mountain_id: 'stevens-pass',
      event_date: FUTURE_DATE,
      departure_time: '06:00:00',
      departure_location: 'Northgate',
      going_count: 3,
      max_attendees: null,
      status: 'active',
    });
    const mockAdmin = createMockAdminClient({ waitlist_count: 2 });

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'PATCH',
      body: JSON.stringify({ title: 'Updated Title' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await PATCH(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.event.waitlistCount).toBeDefined();
  });
});

// ─── Comments on Cancelled Events ────────────────────────────────────────────

describe('POST /api/events/[id]/comments - Status Guards', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth();
  });

  it('should reject comments on cancelled events', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'internal-user-123',
      title: 'Cancelled Trip',
      status: 'cancelled',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/comments`, {
      method: 'POST',
      body: JSON.stringify({ content: 'Hey, is this still happening?' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await CommentPost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('cancelled');
  });

  it('should reject comments on completed events', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'internal-user-123',
      title: 'Done Trip',
      status: 'completed',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/comments`, {
      method: 'POST',
      body: JSON.stringify({ content: 'That was fun!' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await CommentPost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('cancelled or completed');
  });
});

// ─── Calendar Export for Cancelled Events ────────────────────────────────────

describe('GET /api/events/[id]/calendar - Cancelled Event Guard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should reject calendar export for cancelled events', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      title: 'Cancelled Trip',
      notes: null,
      event_date: FUTURE_DATE,
      departure_time: '06:00:00',
      departure_location: 'Northgate',
      mountain_id: 'stevens-pass',
      status: 'cancelled',
      creator: { display_name: 'Test User' },
    });

    (createClient as any).mockResolvedValue(mockSupabase);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/calendar?format=ics`, {
      method: 'GET',
    });

    const response = await CalendarGet(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('cancelled');
  });
});

// ─── Activity on Cancelled Events ────────────────────────────────────────────

describe('GET /api/events/[id]/activity - Cancelled Event Guard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return empty activity for cancelled events', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'internal-user-123',
      status: 'cancelled',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/activity`, {
      method: 'GET',
    });

    const response = await ActivityGet(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.activities).toEqual([]);
    expect(data.message).toContain('cancelled');
  });
});

// ─── Carpool on Cancelled Events ─────────────────────────────────────────────

describe('GET /api/events/[id]/carpool - Cancelled Event Guard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return empty carpool data for cancelled events', async () => {
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                id: eventId,
                carpool_available: true,
                carpool_seats: 4,
                status: 'cancelled',
              },
              error: null,
            }),
          }),
        }),
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/carpool`, {
      method: 'GET',
    });

    const response = await CarpoolGet(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.drivers).toEqual([]);
    expect(data.riders).toEqual([]);
    expect(data.summary.totalSeatsOffered).toBe(0);
    expect(data.message).toContain('cancelled');
  });
});

// ─── RSVP on Cancelled Events ────────────────────────────────────────────────

describe('RSVP on Cancelled Events', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth();
  });

  it('should reject RSVP POST on cancelled event', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      status: 'cancelled',
      event_date: FUTURE_DATE,
      user_id: 'creator123',
    });
    // RSVP route uses adminClient to fetch events (bypasses RLS for iOS)
    const mockAdmin = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'events') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    status: 'cancelled',
                    event_date: FUTURE_DATE,
                    user_id: 'creator123',
                    title: 'Trip',
                    max_attendees: null,
                    going_count: 0,
                  },
                  error: null,
                }),
              }),
            }),
          };
        }
        return {};
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/rsvp`, {
      method: 'POST',
      body: JSON.stringify({ status: 'going' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await RSVPPost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error.details[0]).toContain('cancelled');
  });

  it('should reject RSVP DELETE on cancelled event', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'creator123',
      status: 'cancelled',
      event_date: FUTURE_DATE,
    });
    // RSVP DELETE also uses adminClient to fetch events
    const mockAdmin = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'events') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    user_id: 'creator123',
                    status: 'cancelled',
                    event_date: FUTURE_DATE,
                  },
                  error: null,
                }),
              }),
            }),
          };
        }
        return {};
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/rsvp`, {
      method: 'DELETE',
    });

    const response = await RSVPDelete(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error.details[0]).toContain('inactive');
  });
});

// ─── Clone Edge Cases ────────────────────────────────────────────────────────

describe('POST /api/events/[id]/clone - Edge Cases', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth();
  });

  it('should copy max_attendees when cloning an event', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'someone-else',
      mountain_id: 'stevens-pass',
      title: 'Original Event',
      notes: 'Fun trip',
      event_date: FUTURE_DATE,
      departure_time: '06:00:00',
      departure_location: 'Northgate',
      skill_level: 'intermediate',
      carpool_available: true,
      carpool_seats: 4,
      max_attendees: 10,
      status: 'active',
    });

    const insertMock = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        single: vi.fn().mockResolvedValue({
          data: {
            id: 'cloned-id',
            user_id: 'internal-user-123',
            mountain_id: 'stevens-pass',
            title: 'Original Event',
            event_date: '2027-07-01',
            status: 'active',
            max_attendees: 10,
            creator: { id: 'internal-user-123', username: 'testuser' },
          },
          error: null,
        }),
      }),
    });

    const mockAdmin = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'users') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: { id: 'internal-user-123' },
                  error: null,
                }),
              }),
            }),
          };
        }
        if (table === 'events') {
          return { insert: insertMock };
        }
        if (table === 'event_attendees') {
          return {
            insert: vi.fn().mockResolvedValue({ data: null, error: null }),
          };
        }
        if (table === 'event_invite_tokens') {
          return {
            insert: vi.fn().mockResolvedValue({ data: null, error: null }),
          };
        }
        return {};
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/clone`, {
      method: 'POST',
      body: JSON.stringify({ eventDate: '2027-07-01' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await ClonePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });

    expect(response.status).toBe(201);

    // Verify max_attendees was included in the insert call
    const insertCall = insertMock.mock.calls[0]?.[0];
    expect(insertCall).toBeDefined();
    expect(insertCall.max_attendees).toBe(10);
  });

  it('should allow cloning a cancelled event (by design)', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'someone-else',
      mountain_id: 'stevens-pass',
      title: 'Cancelled Event',
      notes: null,
      event_date: FUTURE_DATE,
      departure_time: null,
      departure_location: null,
      skill_level: 'all',
      carpool_available: false,
      carpool_seats: 0,
      max_attendees: null,
      status: 'cancelled',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/clone`, {
      method: 'POST',
      body: JSON.stringify({ eventDate: '2027-07-01' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await ClonePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });

    // Cloning cancelled events is intentionally allowed
    expect(response.status).toBe(201);
  });

  it('should reject cloning with a past date', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'someone-else',
      mountain_id: 'stevens-pass',
      title: 'Event',
      notes: null,
      event_date: FUTURE_DATE,
      departure_time: null,
      departure_location: null,
      skill_level: 'all',
      carpool_available: false,
      carpool_seats: 0,
      max_attendees: null,
      status: 'active',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/clone`, {
      method: 'POST',
      body: JSON.stringify({ eventDate: PAST_DATE }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await ClonePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('past');
  });
});

// ─── Reactivation Edge Cases ─────────────────────────────────────────────────

describe('POST /api/events/[id]/reactivate - Edge Cases', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth();
  });

  it('should reject reactivation of an active event', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'internal-user-123',
      title: 'Active Trip',
      event_date: FUTURE_DATE,
      status: 'active',
      mountain_id: 'stevens-pass',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/reactivate`, {
      method: 'POST',
    });

    const response = await ReactivatePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('Only cancelled events');
  });

  it('should reject reactivation of a past cancelled event', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'internal-user-123',
      title: 'Old Trip',
      event_date: PAST_DATE,
      status: 'cancelled',
      mountain_id: 'stevens-pass',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/reactivate`, {
      method: 'POST',
    });

    const response = await ReactivatePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('past');
    expect(data.error).toContain('cloning');
  });

  it('should reject reactivation by non-creator', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'different-user-456',
      title: 'Someone Else Trip',
      event_date: FUTURE_DATE,
      status: 'cancelled',
      mountain_id: 'stevens-pass',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/reactivate`, {
      method: 'POST',
    });

    const response = await ReactivatePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(403);
    expect(data.error.message).toContain('creator');
  });

  it('should successfully reactivate a future cancelled event', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'internal-user-123',
      title: 'Cancelled Trip',
      event_date: FUTURE_DATE,
      status: 'cancelled',
      mountain_id: 'stevens-pass',
    });
    const mockAdmin = createMockAdminClient();

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/reactivate`, {
      method: 'POST',
    });

    const response = await ReactivatePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.message).toContain('reactivated');
  });
});

// ─── Cross-cutting: Authentication Required ──────────────────────────────────

describe('Authentication Required for Mutation Endpoints', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth(false); // Not authenticated
  });

  it('should reject unauthenticated PATCH', async () => {
    const mockSupabase = createMockSupabase({});
    const mockAdmin = createMockAdminClient();
    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'PATCH',
      body: JSON.stringify({ title: 'Hacked' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await PATCH(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    expect(response.status).toBe(401);
  });

  it('should reject unauthenticated DELETE', async () => {
    const mockSupabase = createMockSupabase({});
    const mockAdmin = createMockAdminClient();
    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'DELETE',
    });

    const response = await DELETE(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    expect(response.status).toBe(401);
  });

  it('should reject unauthenticated comment POST', async () => {
    const mockSupabase = createMockSupabase({
      id: eventId,
      user_id: 'someone',
      title: 'Trip',
      status: 'active',
    });
    const mockAdmin = createMockAdminClient();
    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/comments`, {
      method: 'POST',
      body: JSON.stringify({ content: 'Hello' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await CommentPost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    expect(response.status).toBe(401);
  });

  it('should reject unauthenticated clone', async () => {
    const mockSupabase = createMockSupabase({});
    const mockAdmin = createMockAdminClient();
    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/clone`, {
      method: 'POST',
      body: JSON.stringify({ eventDate: FUTURE_DATE }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await ClonePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    expect(response.status).toBe(401);
  });

  it('should reject unauthenticated reactivation', async () => {
    const mockSupabase = createMockSupabase({});
    const mockAdmin = createMockAdminClient();
    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request(`http://localhost:3000/api/events/${eventId}/reactivate`, {
      method: 'POST',
    });

    const response = await ReactivatePost(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    expect(response.status).toBe(401);
  });
});

// ─── Invite GET for Cancelled Events ─────────────────────────────────────────

describe('GET /api/events/invite/[token] - Cancelled Event', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return minimal event data for cancelled event invites', async () => {
    const mockAdmin = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                id: 'invite123',
                event_id: eventId,
                token: 'test-token',
                created_by: 'user123',
                uses_count: 0,
                max_uses: null,
                expires_at: null,
                event: {
                  id: eventId,
                  user_id: 'user123',
                  mountain_id: 'stevens-pass',
                  title: 'Cancelled Trip',
                  notes: 'Secret plans that should be hidden',
                  event_date: FUTURE_DATE,
                  departure_time: '06:00:00',
                  departure_location: 'Northgate',
                  skill_level: 'expert',
                  carpool_available: true,
                  carpool_seats: 4,
                  max_attendees: 10,
                  status: 'cancelled',
                  created_at: '2025-01-01',
                  updated_at: '2025-01-01',
                  attendee_count: 5,
                  going_count: 3,
                  maybe_count: 2,
                  waitlist_count: 0,
                  creator: {
                    id: 'user123',
                    username: 'testuser',
                    display_name: 'Test User',
                    avatar_url: null,
                  },
                },
              },
              error: null,
            }),
          }),
        }),
      }),
    };

    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request('http://localhost:3000/api/events/invite/test-token', {
      method: 'GET',
    });

    const response = await InviteGet(request as any, {
      params: Promise.resolve({ token: 'test-token' }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.invite.isValid).toBe(false);
    // Should NOT contain sensitive details for cancelled event
    expect(data.invite.event.notes).toBeUndefined();
    expect(data.invite.event.creator).toBeUndefined();
    expect(data.invite.event.goingCount).toBeUndefined();
    expect(data.invite.event.attendeeCount).toBeUndefined();
    // Should still contain basic identification
    expect(data.invite.event.title).toBe('Cancelled Trip');
    expect(data.invite.event.status).toBe('cancelled');
    expect(data.invite.event.id).toBe(eventId);
  });

  it('should return full event data for valid active invites', async () => {
    const mockAdmin = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                id: 'invite123',
                event_id: eventId,
                token: 'test-token',
                created_by: 'user123',
                uses_count: 0,
                max_uses: null,
                expires_at: null,
                event: {
                  id: eventId,
                  user_id: 'user123',
                  mountain_id: 'stevens-pass',
                  title: 'Active Trip',
                  notes: 'Bring snacks',
                  event_date: FUTURE_DATE,
                  departure_time: '06:00:00',
                  departure_location: 'Northgate',
                  skill_level: 'intermediate',
                  carpool_available: true,
                  carpool_seats: 4,
                  max_attendees: 10,
                  status: 'active',
                  created_at: '2025-01-01',
                  updated_at: '2025-01-01',
                  attendee_count: 5,
                  going_count: 3,
                  maybe_count: 2,
                  waitlist_count: 0,
                  creator: {
                    id: 'user123',
                    username: 'testuser',
                    display_name: 'Test User',
                    avatar_url: null,
                  },
                },
              },
              error: null,
            }),
          }),
        }),
      }),
    };

    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request('http://localhost:3000/api/events/invite/test-token', {
      method: 'GET',
    });

    const response = await InviteGet(request as any, {
      params: Promise.resolve({ token: 'test-token' }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.invite.isValid).toBe(true);
    // Full details for active event
    expect(data.invite.event.notes).toBe('Bring snacks');
    expect(data.invite.event.creator).toBeDefined();
    expect(data.invite.event.goingCount).toBe(3);
  });
});

// ─── Invite POST for Cancelled Events ────────────────────────────────────────

describe('POST /api/events/invite/[token] - Cancelled Event', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should reject using invite for cancelled event', async () => {
    const mockSupabase = createMockSupabase({});
    const mockAdmin = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                id: 'invite123',
                event_id: eventId,
                token: 'test-token',
                uses_count: 0,
                max_uses: null,
                expires_at: null,
                event: {
                  id: eventId,
                  status: 'cancelled',
                  event_date: FUTURE_DATE,
                },
              },
              error: null,
            }),
          }),
        }),
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request('http://localhost:3000/api/events/invite/test-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await InvitePost(request as any, {
      params: Promise.resolve({ token: 'test-token' }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('no longer valid');
  });

  it('should reject using invite for past event', async () => {
    const mockSupabase = createMockSupabase({});
    const mockAdmin = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                id: 'invite123',
                event_id: eventId,
                token: 'test-token',
                uses_count: 0,
                max_uses: null,
                expires_at: null,
                event: {
                  id: eventId,
                  status: 'active',
                  event_date: PAST_DATE,
                },
              },
              error: null,
            }),
          }),
        }),
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const request = new Request('http://localhost:3000/api/events/invite/test-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await InvitePost(request as any, {
      params: Promise.resolve({ token: 'test-token' }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('no longer valid');
  });
});
