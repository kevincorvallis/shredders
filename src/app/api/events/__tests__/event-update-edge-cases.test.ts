/**
 * Event Update Edge Cases - Validation Tests
 *
 * Tests PATCH field validation (~15 checks in the route handler)
 * and POST edge cases not covered by events.test.ts.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { PATCH } from '../[id]/route';
import { POST } from '../route';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { getDualAuthUser } from '@/lib/auth';

// Mock Supabase
vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(),
  createAdminClient: vi.fn(),
}));

// Mock auth
vi.mock('@/lib/auth', () => ({
  getDualAuthUser: vi.fn(),
}));

// Mock shared
vi.mock('@shredders/shared', () => ({
  getMountain: vi.fn().mockImplementation((id: string) => {
    if (id === 'stevens-pass') {
      return { id: 'stevens-pass', name: 'Stevens Pass', location: { lat: 47.7448, lng: -121.0891 } };
    }
    return undefined;
  }),
}));

// Mock rate limiting
vi.mock('@/lib/api-utils', () => ({
  rateLimitEnhanced: vi.fn().mockResolvedValue({ success: true }),
  createRateLimitKey: vi.fn().mockReturnValue('test-key'),
}));

// Mock push notifications
vi.mock('@/lib/push/event-notifications', () => ({
  sendEventCancellationNotification: vi.fn().mockResolvedValue({ sent: 0, failed: 0 }),
  sendEventUpdateNotification: vi.fn().mockResolvedValue({ sent: 0, failed: 0 }),
}));

// Mock crypto
vi.mock('crypto', () => ({
  randomBytes: vi.fn().mockReturnValue({
    toString: vi.fn().mockReturnValue('abc123token'),
  }),
}));

const FUTURE_DATE = '2027-06-15';
const eventId = 'event-update-test';

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

// Mock supabase that returns an active future event owned by the test user
function createMockSupabase(eventOverrides: Record<string, any> = {}) {
  return {
    from: vi.fn().mockImplementation((table: string) => {
      if (table === 'events') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: {
                  user_id: 'internal-user-123',
                  title: 'Test Event',
                  mountain_id: 'stevens-pass',
                  event_date: FUTURE_DATE,
                  departure_time: '06:00:00',
                  departure_location: 'Northgate',
                  going_count: 3,
                  max_attendees: null,
                  status: 'active',
                  ...eventOverrides,
                },
                error: null,
              }),
            }),
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

function createMockAdminClient(updateOverrides: Record<string, any> = {}) {
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
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: { attendee_count: 1, going_count: 1, maybe_count: 0 },
                error: null,
              }),
            }),
          }),
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
                    ...updateOverrides,
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
                  id: 'new-event-id',
                  user_id: 'internal-user-123',
                  mountain_id: 'stevens-pass',
                  title: 'Test Event',
                  event_date: FUTURE_DATE,
                  status: 'active',
                  max_attendees: null,
                  attendee_count: 0,
                  going_count: 0,
                  maybe_count: 0,
                  waitlist_count: 0,
                  creator: { id: 'internal-user-123', username: 'testuser' },
                  ...updateOverrides,
                },
                error: null,
              }),
            }),
          }),
        };
      }
      if (table === 'event_invite_tokens') {
        return {
          insert: vi.fn().mockResolvedValue({ data: null, error: null }),
        };
      }
      if (table === 'event_attendees') {
        return {
          insert: vi.fn().mockResolvedValue({ data: null, error: null }),
        };
      }
      return {};
    }),
  };
}

function makePatchRequest(body: Record<string, any>) {
  return new Request(`http://localhost:3000/api/events/${eventId}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  });
}

function makePostRequest(body: Record<string, any>) {
  return new Request('http://localhost:3000/api/events', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  });
}

// ─── PATCH Field Validation ──────────────────────────────────────────────────

describe('PATCH /api/events/[id] - Field Validation', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth();
  });

  it('should reject title shorter than 3 characters', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ title: 'Ab' }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('at least 3 characters');
  });

  it('should reject title longer than 100 characters', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const longTitle = 'A'.repeat(101);
    const response = await PATCH(makePatchRequest({ title: longTitle }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('less than 100');
  });

  it('should reject whitespace-only title', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ title: '   ' }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('at least 3 characters');
  });

  it('should reject notes longer than 2000 characters', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const longNotes = 'N'.repeat(2001);
    const response = await PATCH(makePatchRequest({ notes: longNotes }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('less than 2000');
  });

  it('should reject past event date', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ eventDate: '2020-01-01' }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('past');
  });

  it('should reject invalid departure time format', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ departureTime: '6am' }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('HH:MM');
  });

  it('should reject invalid skill level', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ skillLevel: 'pro' }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('Invalid skill level');
  });

  it('should reject carpool seats below 0', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ carpoolSeats: -1 }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('between 0 and 8');
  });

  it('should reject carpool seats above 8', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ carpoolSeats: 9 }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('between 0 and 8');
  });

  it('should reject maxAttendees below 1', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ maxAttendees: 0 }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('between 1 and 1000');
  });

  it('should reject maxAttendees above 1000', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ maxAttendees: 1001 }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('between 1 and 1000');
  });

  it('should reject maxAttendees below current going count', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase({ going_count: 5 }));
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({ maxAttendees: 3 }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('below current attendees');
    expect(data.error).toContain('5 going');
  });

  it('should reject empty update (no fields provided)', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await PATCH(makePatchRequest({}) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('No valid fields');
  });

  it('should accept valid single-field update', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient({ title: 'Updated Title' }));

    const response = await PATCH(makePatchRequest({ title: 'Updated Title' }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.event).toBeDefined();
  });

  it('should accept clearing optional fields (notes to null)', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient({ notes: null }));

    const response = await PATCH(makePatchRequest({ notes: null }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.event).toBeDefined();
  });

  it('should accept title at exactly 3 characters', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient({ title: 'Ski' }));

    const response = await PATCH(makePatchRequest({ title: 'Ski' }) as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
  });

  it('should accept maxAttendees at boundary value 1', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase({ going_count: 1 }));
    (createAdminClient as any).mockReturnValue(createMockAdminClient({ max_attendees: 1 }));

    const response = await PATCH(makePatchRequest({ maxAttendees: 1 }) as any, {
      params: Promise.resolve({ id: eventId }),
    });

    expect(response.status).toBe(200);
  });
});

// ─── POST Edge Cases ─────────────────────────────────────────────────────────

describe('POST /api/events - Edge Cases', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupAuth();
  });

  const validEvent = {
    mountainId: 'stevens-pass',
    title: 'Powder Day',
    eventDate: FUTURE_DATE,
  };

  it('should reject whitespace-only title', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await POST(makePostRequest({ ...validEvent, title: '   ' }) as any);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('at least 3 characters');
  });

  it('should reject notes over 2000 characters', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await POST(
      makePostRequest({ ...validEvent, notes: 'X'.repeat(2001) }) as any,
    );
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('less than 2000');
  });

  it('should reject invalid mountain ID with 404', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const response = await POST(
      makePostRequest({ ...validEvent, mountainId: 'nonexistent-mountain' }) as any,
    );
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toContain('not found');
  });

  it('should accept title at exactly 3 characters', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient({ title: 'Ski' }));

    const response = await POST(makePostRequest({ ...validEvent, title: 'Ski' }) as any);

    expect(response.status).toBe(201);
  });

  it('should accept maxAttendees at boundary values 1 and 1000', async () => {
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient({ max_attendees: 1 }));

    const res1 = await POST(makePostRequest({ ...validEvent, maxAttendees: 1 }) as any);
    expect(res1.status).toBe(201);

    vi.clearAllMocks();
    setupAuth();
    (createClient as any).mockResolvedValue(createMockSupabase());
    (createAdminClient as any).mockReturnValue(createMockAdminClient({ max_attendees: 1000 }));

    const res2 = await POST(makePostRequest({ ...validEvent, maxAttendees: 1000 }) as any);
    expect(res2.status).toBe(201);
  });
});
