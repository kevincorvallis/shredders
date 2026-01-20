import { describe, it, expect, beforeEach, vi } from 'vitest';
import { GET, POST } from '../invite/[token]/route';
import { createClient, createAdminClient } from '@/lib/supabase/server';

// Mock Supabase
vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(),
  createAdminClient: vi.fn(),
}));

// Mock shared
vi.mock('@shredders/shared', () => ({
  getMountain: vi.fn().mockReturnValue({
    id: 'stevens-pass',
    name: 'Stevens Pass',
    location: { lat: 47.7448, lng: -121.0891 },
  }),
}));

describe('GET /api/events/invite/[token]', () => {
  let mockAdminClient: any;
  let mockRequest: Request;
  const validToken = 'valid_invite_token_123';

  beforeEach(() => {
    vi.clearAllMocks();

    mockAdminClient = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                id: 'invite123',
                event_id: 'event123',
                token: validToken,
                created_by: 'user123',
                uses_count: 0,
                max_uses: null,
                expires_at: null,
                event: {
                  id: 'event123',
                  user_id: 'user123',
                  mountain_id: 'stevens-pass',
                  title: 'Powder Day!',
                  notes: 'Lets go!',
                  event_date: '2025-02-15',
                  departure_time: '06:00:00',
                  departure_location: 'Northgate',
                  skill_level: 'intermediate',
                  carpool_available: true,
                  carpool_seats: 3,
                  status: 'active',
                  attendee_count: 5,
                  going_count: 3,
                  maybe_count: 2,
                  created_at: '2025-01-15T12:00:00Z',
                  updated_at: '2025-01-15T12:00:00Z',
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

    (createAdminClient as any).mockReturnValue(mockAdminClient);
  });

  it('should return invite info for valid token', async () => {
    mockRequest = new Request(
      `http://localhost:3000/api/events/invite/${validToken}`,
      { method: 'GET' }
    );

    const response = await GET(mockRequest as any, {
      params: Promise.resolve({ token: validToken }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.invite).toBeDefined();
    expect(data.invite.event.title).toBe('Powder Day!');
    expect(data.invite.isValid).toBe(true);
    expect(data.invite.requiresAuth).toBe(true);
  });

  it('should return 404 for invalid token', async () => {
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

    mockRequest = new Request(
      'http://localhost:3000/api/events/invite/invalid_token',
      { method: 'GET' }
    );

    const response = await GET(mockRequest as any, {
      params: Promise.resolve({ token: 'invalid_token' }),
    });
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toContain('Invalid');
  });

  it('should mark expired invite as invalid', async () => {
    mockAdminClient.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'invite123',
              event_id: 'event123',
              token: validToken,
              expires_at: '2020-01-01T00:00:00Z', // Expired
              uses_count: 0,
              max_uses: null,
              event: {
                id: 'event123',
                status: 'active',
                event_date: '2025-02-15',
                user_id: 'user123',
                mountain_id: 'stevens-pass',
                title: 'Powder Day!',
                attendee_count: 3,
                going_count: 2,
                maybe_count: 1,
                created_at: '2025-01-15T12:00:00Z',
                updated_at: '2025-01-15T12:00:00Z',
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
    });

    mockRequest = new Request(
      `http://localhost:3000/api/events/invite/${validToken}`,
      { method: 'GET' }
    );

    const response = await GET(mockRequest as any, {
      params: Promise.resolve({ token: validToken }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.invite.isValid).toBe(false);
    expect(data.invite.isExpired).toBe(true);
  });

  it('should mark max uses exceeded as invalid', async () => {
    mockAdminClient.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'invite123',
              event_id: 'event123',
              token: validToken,
              expires_at: null,
              uses_count: 10,
              max_uses: 5, // Max exceeded
              event: {
                id: 'event123',
                status: 'active',
                event_date: '2025-02-15',
                user_id: 'user123',
                mountain_id: 'stevens-pass',
                title: 'Powder Day!',
                attendee_count: 3,
                going_count: 2,
                maybe_count: 1,
                created_at: '2025-01-15T12:00:00Z',
                updated_at: '2025-01-15T12:00:00Z',
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
    });

    mockRequest = new Request(
      `http://localhost:3000/api/events/invite/${validToken}`,
      { method: 'GET' }
    );

    const response = await GET(mockRequest as any, {
      params: Promise.resolve({ token: validToken }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.invite.isValid).toBe(false);
  });

  it('should mark cancelled event invite as invalid', async () => {
    mockAdminClient.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'invite123',
              event_id: 'event123',
              token: validToken,
              expires_at: null,
              uses_count: 0,
              max_uses: null,
              event: {
                id: 'event123',
                status: 'cancelled', // Event cancelled
                event_date: '2025-02-15',
                user_id: 'user123',
                mountain_id: 'stevens-pass',
                title: 'Powder Day!',
                attendee_count: 3,
                going_count: 2,
                maybe_count: 1,
                created_at: '2025-01-15T12:00:00Z',
                updated_at: '2025-01-15T12:00:00Z',
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
    });

    mockRequest = new Request(
      `http://localhost:3000/api/events/invite/${validToken}`,
      { method: 'GET' }
    );

    const response = await GET(mockRequest as any, {
      params: Promise.resolve({ token: validToken }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.invite.isValid).toBe(false);
  });
});

describe('POST /api/events/invite/[token]', () => {
  let mockSupabase: any;
  let mockAdminClient: any;
  let mockRequest: Request;
  const validToken = 'valid_invite_token_123';

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {};

    mockAdminClient = {
      from: vi.fn().mockImplementation((table: string) => {
        if (table === 'event_invite_tokens') {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                single: vi.fn().mockResolvedValue({
                  data: {
                    id: 'invite123',
                    event_id: 'event123',
                    token: validToken,
                    uses_count: 0,
                    max_uses: null,
                    expires_at: null,
                    event: {
                      id: 'event123',
                      status: 'active',
                      event_date: '2025-02-15',
                    },
                  },
                  error: null,
                }),
              }),
            }),
            update: vi.fn().mockReturnValue({
              eq: vi.fn().mockResolvedValue({
                data: null,
                error: null,
              }),
            }),
          };
        }
        return {};
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdminClient);
  });

  it('should validate invite and return event ID', async () => {
    mockRequest = new Request(
      `http://localhost:3000/api/events/invite/${validToken}`,
      { method: 'POST' }
    );

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ token: validToken }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.eventId).toBe('event123');
    expect(data.message).toContain('validated');
  });

  it('should return 404 for invalid token', async () => {
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

    mockRequest = new Request(
      'http://localhost:3000/api/events/invite/invalid_token',
      { method: 'POST' }
    );

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ token: 'invalid_token' }),
    });
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toContain('Invalid');
  });

  it('should return 400 for expired invite', async () => {
    mockAdminClient.from = vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'invite123',
              event_id: 'event123',
              token: validToken,
              uses_count: 0,
              max_uses: null,
              expires_at: '2020-01-01T00:00:00Z', // Expired
              event: {
                id: 'event123',
                status: 'active',
                event_date: '2025-02-15',
              },
            },
            error: null,
          }),
        }),
      }),
    });

    mockRequest = new Request(
      `http://localhost:3000/api/events/invite/${validToken}`,
      { method: 'POST' }
    );

    const response = await POST(mockRequest as any, {
      params: Promise.resolve({ token: validToken }),
    });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('no longer valid');
  });
});
