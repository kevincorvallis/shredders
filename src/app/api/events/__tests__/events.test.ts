import { describe, it, expect, beforeEach, vi } from 'vitest';
import { GET, POST } from '../route';
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
  getMountain: vi.fn().mockReturnValue({
    id: 'stevens-pass',
    name: 'Stevens Pass',
    location: { lat: 47.7448, lng: -121.0891 },
  }),
}));

describe('GET /api/events', () => {
  let mockSupabase: any;
  let mockRequest: Request;

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnThis(),
          gte: vi.fn().mockReturnThis(),
          order: vi.fn().mockReturnThis(),
          range: vi.fn().mockResolvedValue({
            data: [
              {
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
            ],
            error: null,
            count: 1,
          }),
        }),
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
    (getDualAuthUser as any).mockResolvedValue(null);
  });

  it('should fetch upcoming events', async () => {
    mockRequest = new Request('http://localhost:3000/api/events', {
      method: 'GET',
    });

    const response = await GET(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.events).toHaveLength(1);
    expect(data.events[0].title).toBe('Powder Day!');
    expect(data.events[0].mountainName).toBe('Stevens Pass');
    expect(data.pagination).toBeDefined();
  });

  it('should filter by mountainId', async () => {
    mockRequest = new Request(
      'http://localhost:3000/api/events?mountainId=stevens-pass',
      { method: 'GET' }
    );

    const response = await GET(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(mockSupabase.from).toHaveBeenCalledWith('events');
  });

  it('should require auth for createdByMe filter', async () => {
    mockRequest = new Request(
      'http://localhost:3000/api/events?createdByMe=true',
      { method: 'GET' }
    );

    const response = await GET(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toContain('Authentication');
  });

  it('should return events created by user when authenticated', async () => {
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'user123',
      email: 'test@example.com',
    });

    mockRequest = new Request(
      'http://localhost:3000/api/events?createdByMe=true',
      { method: 'GET' }
    );

    const response = await GET(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.events).toBeDefined();
  });
});

describe('POST /api/events', () => {
  let mockSupabase: any;
  let mockAdminClient: any;
  let mockRequest: Request;

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      from: vi.fn(),
    };

    mockAdminClient = {
      from: vi.fn().mockReturnValue({
        insert: vi.fn().mockReturnValue({
          select: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                id: 'newevent123',
                user_id: 'user123',
                mountain_id: 'stevens-pass',
                title: 'Powder Day!',
                notes: null,
                event_date: '2025-02-15',
                departure_time: '06:00:00',
                departure_location: null,
                skill_level: null,
                carpool_available: false,
                carpool_seats: null,
                status: 'active',
                attendee_count: 1,
                going_count: 1,
                maybe_count: 0,
                created_at: '2025-01-15T12:00:00Z',
                updated_at: '2025-01-15T12:00:00Z',
                creator: {
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

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdminClient);
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'user123',
      email: 'test@example.com',
    });
  });

  it('should create a new event', async () => {
    const requestBody = {
      mountainId: 'stevens-pass',
      title: 'Powder Day!',
      eventDate: '2025-02-15',
      departureTime: '06:00',
    };

    mockRequest = new Request('http://localhost:3000/api/events', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(201);
    expect(data.event).toBeDefined();
    expect(data.event.title).toBe('Powder Day!');
    expect(data.inviteToken).toBeDefined();
    expect(data.inviteUrl).toContain('/events/invite/');
  });

  it('should require authentication', async () => {
    (getDualAuthUser as any).mockResolvedValue(null);

    const requestBody = {
      mountainId: 'stevens-pass',
      title: 'Powder Day!',
      eventDate: '2025-02-15',
    };

    mockRequest = new Request('http://localhost:3000/api/events', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });

  it('should require mountainId', async () => {
    const requestBody = {
      title: 'Powder Day!',
      eventDate: '2025-02-15',
    };

    mockRequest = new Request('http://localhost:3000/api/events', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('Mountain');
  });

  it('should validate title length', async () => {
    const requestBody = {
      mountainId: 'stevens-pass',
      title: 'ab', // Too short
      eventDate: '2025-02-15',
    };

    mockRequest = new Request('http://localhost:3000/api/events', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('Title');
  });

  it('should validate event date is not in the past', async () => {
    const requestBody = {
      mountainId: 'stevens-pass',
      title: 'Powder Day!',
      eventDate: '2020-01-01', // Past date
    };

    mockRequest = new Request('http://localhost:3000/api/events', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('past');
  });

  it('should validate carpool seats range', async () => {
    const requestBody = {
      mountainId: 'stevens-pass',
      title: 'Powder Day!',
      eventDate: '2025-02-15',
      carpoolAvailable: true,
      carpoolSeats: 10, // Too many
    };

    mockRequest = new Request('http://localhost:3000/api/events', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('seats');
  });

  it('should validate departure time format', async () => {
    const requestBody = {
      mountainId: 'stevens-pass',
      title: 'Powder Day!',
      eventDate: '2025-02-15',
      departureTime: 'invalid', // Invalid format
    };

    mockRequest = new Request('http://localhost:3000/api/events', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest as any);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('time');
  });
});
