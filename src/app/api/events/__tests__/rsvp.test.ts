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
                    event_date: '2025-02-15',
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
        if (table === 'event_attendees') {
          return {
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
                  event_date: '2025-02-15',
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
    mockSupabase.from = vi.fn().mockReturnValue({
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
    mockSupabase.from = vi.fn().mockReturnValue({
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
      from: vi.fn().mockReturnValue({
        delete: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            eq: vi.fn().mockResolvedValue({
              data: null,
              error: null,
            }),
          }),
        }),
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdminClient);
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'user123',
      email: 'test@example.com',
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
    mockSupabase.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: eventId,
              user_id: 'user123', // Same as test user (creator)
            },
            error: null,
          }),
        }),
      }),
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
});
