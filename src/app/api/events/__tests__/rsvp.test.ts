import { describe, it, expect, beforeEach, vi } from 'vitest';
import { POST, DELETE } from '../[id]/rsvp/route';
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

// Mock rate limiting to always allow
vi.mock('@/lib/api-utils', () => ({
  rateLimitEnhanced: vi.fn().mockResolvedValue({ success: true }),
  createRateLimitKey: vi.fn().mockReturnValue('test-key'),
}));

// Mock push notifications
vi.mock('@/lib/push/event-notifications', () => ({
  sendNewRSVPNotification: vi.fn().mockResolvedValue(undefined),
  sendRSVPChangeNotification: vi.fn().mockResolvedValue(undefined),
}));

const FUTURE_DATE = '2027-02-15';

describe('POST /api/events/[id]/rsvp', () => {
  let mockSupabase: any;
  let mockAdminClient: any;
  let mockRequest: Request;
  const eventId = 'event123';

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'events') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    status: 'active',
                    event_date: FUTURE_DATE,
                    user_id: 'creator123',
                  },
                  error: null,
                }),
              }),
            }),
          };
        }
        if (table === 'event_attendees') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                eq: vi.fn().mockReturnValue({
                  single: vi.fn().mockResolvedValue({
                    data: null, // No existing RSVP
                    error: null,
                  }),
                }),
              }),
            }),
          };
        }
        return {};
      }),
    };

    mockAdminClient = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'events') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    status: 'active',
                    event_date: FUTURE_DATE,
                    user_id: 'creator123',
                    title: 'Powder Day',
                    max_attendees: null,
                    going_count: 0,
                  },
                  error: null,
                }),
              }),
            }),
          };
        }
        if (table === 'event_attendees') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                eq: vi.fn().mockReturnValue({
                  single: vi.fn().mockResolvedValue({
                    data: null, // No existing RSVP
                    error: null,
                  }),
                }),
              }),
            }),
            insert: vi.fn().mockReturnValue({
              select: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: 'attendee123',
                    user_id: 'user123',
                    status: 'going',
                    is_driver: false,
                    needs_ride: false,
                    pickup_location: null,
                    waitlist_position: null,
                    responded_at: '2025-01-15T12:00:00Z',
                    user: {
                      id: 'user123',
                      username: 'testuser',
                      display_name: 'Test User',
                      avatar_url: null,
                    },
                  },
                  error: null,
                }),
              }),
            }),
            update: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                select: vi.fn().mockReturnValue({
                  single: vi.fn().mockResolvedValue({
                    data: {
                      id: 'attendee123',
                      user_id: 'user123',
                      status: 'going',
                      is_driver: false,
                      needs_ride: false,
                      pickup_location: null,
                      waitlist_position: null,
                      responded_at: '2025-01-15T12:00:00Z',
                      user: {
                        id: 'user123',
                        username: 'testuser',
                        display_name: 'Test User',
                        avatar_url: null,
                      },
                    },
                    error: null,
                  }),
                }),
              }),
            }),
          };
        }
        return {};
      }),
    };

    // Mock the events query for fetching updated counts
    mockSupabase.from = vi.fn().mockImplementation((table: string) => {
      if (table === 'events') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: {
                  id: eventId,
                  status: 'active',
                  event_date: FUTURE_DATE,
                  user_id: 'creator123',
                  going_count: 2,
                  maybe_count: 1,
                  attendee_count: 3,
                },
                error: null,
              }),
            }),
          }),
        };
      }
      if (table === 'event_attendees') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: null,
                  error: null,
                }),
              }),
            }),
          }),
        };
      }
      return {};
    });

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdminClient);
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'user123',
      email: 'test@example.com',
      profileId: 'user123',
    });
  });

  it('should create a new RSVP', async () => {
    const requestBody = {
      status: 'going',
    };

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.attendee).toBeDefined();
    expect(data.attendee.status).toBe('going');
  });

  it('should require authentication', async () => {
    (getDualAuthUser as any).mockResolvedValue(null);

    const requestBody = {
      status: 'going',
    };

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });

  it('should validate RSVP status', async () => {
    const requestBody = {
      status: 'invalid_status',
    };

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('Invalid RSVP status');
  });

  it('should reject RSVP for cancelled event', async () => {
    // RSVP route uses adminClient for events query
    mockAdminClient.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: eventId,
              status: 'cancelled',
              event_date: '2025-02-15',
              user_id: 'creator123',
            },
            error: null,
          }),
        }),
      }),
    });

    const requestBody = {
      status: 'going',
    };

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('cancelled');
  });

  it('should return 404 for non-existent event', async () => {
    // RSVP route uses adminClient for events query
    mockAdminClient.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: null,
            error: { code: 'PGRST116' },
          }),
        }),
      }),
    });

    const requestBody = {
      status: 'going',
    };

    mockRequest = new Request('http://localhost:3000/api/events/nonexistent/rsvp', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: 'nonexistent' }),
    });
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toBe('Event not found');
  });

  it('should accept driver info in RSVP', async () => {
    const requestBody = {
      status: 'going',
      isDriver: true,
      needsRide: false,
    };

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });

    expect(response.status).toBe(200);
  });
});

describe('POST /api/events/[id]/rsvp - edge cases', () => {
  let mockSupabase: any;
  let mockAdminClient: any;
  let mockRequest: Request;
  const eventId = 'event123';

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'events') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    status: 'active',
                    event_date: FUTURE_DATE,
                    user_id: 'creator123',
                    going_count: 2,
                    maybe_count: 1,
                    attendee_count: 3,
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

    mockAdminClient = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'events') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    status: 'active',
                    event_date: FUTURE_DATE,
                    user_id: 'creator123',
                    title: 'Powder Day',
                    max_attendees: null,
                    going_count: 2,
                    maybe_count: 1,
                    attendee_count: 3,
                  },
                  error: null,
                }),
              }),
            }),
          };
        }
        if (table === 'event_attendees') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                eq: vi.fn().mockReturnValue({
                  single: vi.fn().mockResolvedValue({
                    data: null,
                    error: null,
                  }),
                }),
              }),
            }),
            insert: vi.fn().mockReturnValue({
              select: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: 'attendee123',
                    user_id: 'user123',
                    status: 'going',
                    is_driver: false,
                    needs_ride: false,
                    pickup_location: null,
                    waitlist_position: null,
                    responded_at: '2025-01-15T12:00:00Z',
                    user: {
                      id: 'user123',
                      username: 'testuser',
                      display_name: 'Test User',
                      avatar_url: null,
                    },
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
    (createAdminClient as any).mockReturnValue(mockAdminClient);
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'user123',
      email: 'test@example.com',
      profileId: 'user123',
    });
  });

  it('should reject RSVP from event creator', async () => {
    // Set event creator to same user as authenticated user (route uses adminClient for events)
    mockAdminClient.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: eventId,
              status: 'active',
              event_date: FUTURE_DATE,
              user_id: 'user123', // Same as authenticated user
              going_count: 1,
              maybe_count: 0,
              attendee_count: 1,
            },
            error: null,
          }),
        }),
      }),
    });

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'POST',
      body: JSON.stringify({ status: 'declined' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('creator');
  });

  it('should reject RSVP for past event', async () => {
    // Route uses adminClient for events query
    mockAdminClient.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: eventId,
              status: 'active',
              event_date: '2020-01-01', // Past date
              user_id: 'creator123',
              going_count: 0,
              maybe_count: 0,
              attendee_count: 0,
            },
            error: null,
          }),
        }),
      }),
    });

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'POST',
      body: JSON.stringify({ status: 'going' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('past');
  });

  it('should auto-waitlist when event is at capacity', async () => {
    // Event at capacity: max_attendees=2, going_count=2
    // Note: the waitlist test needs special handling since adminClient.from is overridden below

    // Admin client needs to handle: events query, existing RSVP check, waitlist position query, insert
    const insertMock = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        single: vi.fn().mockResolvedValue({
          data: {
            id: 'attendee123',
            user_id: 'user123',
            status: 'waitlist',
            is_driver: false,
            needs_ride: false,
            pickup_location: null,
            waitlist_position: 1,
            responded_at: '2025-01-15T12:00:00Z',
            user: {
              id: 'user123',
              username: 'testuser',
              display_name: 'Test User',
              avatar_url: null,
            },
          },
          error: null,
        }),
      }),
    });

    let attendeeCallCount = 0;
    mockAdminClient.from = vi.fn().mockImplementation((table: string) => {
      if (table === 'events') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: {
                  id: eventId,
                  status: 'active',
                  event_date: FUTURE_DATE,
                  user_id: 'creator123',
                  title: 'Powder Day',
                  max_attendees: 2,
                  going_count: 2,
                  maybe_count: 0,
                  attendee_count: 2,
                  waitlist_count: 1,
                },
                error: null,
              }),
            }),
          }),
        };
      }
      if (table === 'event_attendees') {
        attendeeCallCount++;
        if (attendeeCallCount === 1) {
          // First call: check existing RSVP (select → eq → eq → single)
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                eq: vi.fn().mockReturnValue({
                  single: vi.fn().mockResolvedValue({
                    data: null,
                    error: null,
                  }),
                }),
              }),
            }),
          };
        } else if (attendeeCallCount === 2) {
          // Second call: INSERT new RSVP
          return { insert: insertMock };
        } else if (attendeeCallCount === 3) {
          // Third call: SELECT max waitlist position
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                eq: vi.fn().mockReturnValue({
                  neq: vi.fn().mockReturnValue({
                    order: vi.fn().mockReturnValue({
                      limit: vi.fn().mockReturnValue({
                        single: vi.fn().mockResolvedValue({
                          data: null, // No existing waitlisted users
                          error: null,
                        }),
                      }),
                    }),
                  }),
                }),
              }),
            }),
          };
        } else {
          // Fourth call: UPDATE waitlist position
          return {
            update: vi.fn().mockReturnValue({
              eq: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          };
        }
      }
      return {};
    });

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'POST',
      body: JSON.stringify({ status: 'going' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.attendee.status).toBe('waitlist');
    expect(data.wasWaitlisted).toBe(true);
    expect(data.message).toContain('waitlist');
  });
});

describe('DELETE /api/events/[id]/rsvp', () => {
  let mockSupabase: any;
  let mockAdminClient: any;
  let mockRequest: Request;
  const eventId = 'event123';

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'events') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    user_id: 'creator123', // Different from test user
                    status: 'active',
                    event_date: FUTURE_DATE,
                    going_count: 1,
                    maybe_count: 0,
                    attendee_count: 1,
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

    mockAdminClient = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'events') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: eventId,
                    user_id: 'creator123',
                    status: 'active',
                    event_date: FUTURE_DATE,
                    going_count: 1,
                    maybe_count: 0,
                    attendee_count: 1,
                  },
                  error: null,
                }),
              }),
            }),
          };
        }
        if (table === 'event_attendees') {
          const singleResult = vi.fn().mockResolvedValue({
            data: { status: 'going' },
            error: null,
          });
          // Handles both: select→eq→eq→single (existing RSVP check)
          // AND: select→eq→eq→order→limit→single (promoteFromWaitlist)
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                eq: vi.fn().mockReturnValue({
                  single: singleResult,
                  order: vi.fn().mockReturnValue({
                    limit: vi.fn().mockReturnValue({
                      single: vi.fn().mockResolvedValue({
                        data: null, // No one on waitlist
                        error: null,
                      }),
                    }),
                  }),
                }),
              }),
            }),
            delete: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                eq: vi.fn().mockResolvedValue({
                  data: null,
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
    (createAdminClient as any).mockReturnValue(mockAdminClient);
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'user123',
      email: 'test@example.com',
      profileId: 'user123',
    });
  });

  it('should remove RSVP', async () => {
    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'DELETE',
    });

    const response = await DELETE(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.message).toContain('removed');
  });

  it('should prevent event creator from removing their RSVP', async () => {
    // Route uses adminClient for events query
    mockAdminClient.from = vi.fn().mockImplementation((table: string) => {
      if (table === 'events') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: {
                  id: eventId,
                  user_id: 'user123', // Same as test user (creator)
                  status: 'active',
                  event_date: FUTURE_DATE,
                },
                error: null,
              }),
            }),
          }),
        };
      }
      return {};
    });

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'DELETE',
    });

    const response = await DELETE(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('creator');
  });

  it('should require authentication', async () => {
    (getDualAuthUser as any).mockResolvedValue(null);

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'DELETE',
    });

    const response = await DELETE(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });

  it('should reject DELETE for cancelled event', async () => {
    // Route uses adminClient for events query
    mockAdminClient.from = vi.fn().mockImplementation((table: string) => {
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
    });

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'DELETE',
    });

    const response = await DELETE(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('inactive');
  });

  it('should reject DELETE for past event', async () => {
    // Route uses adminClient for events query
    mockAdminClient.from = vi.fn().mockImplementation((table: string) => {
      if (table === 'events') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: {
                  id: eventId,
                  user_id: 'creator123',
                  status: 'active',
                  event_date: '2020-01-01', // Past date
                },
                error: null,
              }),
            }),
          }),
        };
      }
      return {};
    });

    mockRequest = new Request('http://localhost:3000/api/events/event123/rsvp', {
      method: 'DELETE',
    });

    const response = await DELETE(mockRequest as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('past');
  });
});
