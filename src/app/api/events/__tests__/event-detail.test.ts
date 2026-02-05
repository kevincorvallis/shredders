/**
 * Event Detail API Tests (PATCH, DELETE)
 *
 * Tests for updating and cancelling events via /api/events/[id]
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { PATCH, DELETE } from '../[id]/route';
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

// Mock cache
vi.mock('@/lib/cache', () => ({
  cache: { delete: vi.fn() },
}));

const eventId = 'event123';

describe('PATCH /api/events/[id]', () => {
  let mockSupabase: any;
  let mockAdminClient: any;

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                user_id: 'internal-user-123',
                title: 'Old Title',
                mountain_id: 'stevens-pass',
                event_date: '2025-02-15',
                departure_time: '06:00:00',
                departure_location: 'Northgate',
                going_count: 3,
                max_attendees: null,
              },
              error: null,
            }),
          }),
        }),
      }),
    };

    mockAdminClient = {
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
                      title: 'Updated Title',
                      event_date: '2025-02-20',
                      status: 'active',
                      creator: {
                        id: 'internal-user-123',
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

    (createClient as any).mockResolvedValue(mockSupabase);
    (createAdminClient as any).mockReturnValue(mockAdminClient);
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'auth-user-123',
      email: 'test@example.com',
    });
  });

  it('should update event fields', async () => {
    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'PATCH',
      body: JSON.stringify({ title: 'Updated Title', eventDate: '2027-02-20' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await PATCH(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.event).toBeDefined();
    expect(data.event.title).toBe('Updated Title');
  });

  it('should require authentication', async () => {
    (getDualAuthUser as any).mockResolvedValue(null);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'PATCH',
      body: JSON.stringify({ title: 'Updated Title' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await PATCH(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });

  it('should reject non-owner updates', async () => {
    // User profile ID doesn't match event creator
    mockAdminClient.from = vi.fn().mockImplementation((table: string) => {
      if (table === 'users') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: { id: 'different-user-456' },
                error: null,
              }),
            }),
          }),
        };
      }
      return {};
    });

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'PATCH',
      body: JSON.stringify({ title: 'Hacked Title' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await PATCH(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(403);
    expect(data.error).toContain('own events');
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

    const request = new Request(`http://localhost:3000/api/events/nonexistent`, {
      method: 'PATCH',
      body: JSON.stringify({ title: 'Updated' }),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await PATCH(request as any, {
      params: Promise.resolve({ id: 'nonexistent' }),
    });
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toBe('Event not found');
  });
});

describe('DELETE /api/events/[id]', () => {
  let mockSupabase: any;
  let mockAdminClient: any;

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                user_id: 'internal-user-123',
                title: 'Powder Day!',
                mountain_id: 'stevens-pass',
                event_date: '2025-02-15',
              },
              error: null,
            }),
          }),
        }),
      }),
    };

    mockAdminClient = {
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
    (getDualAuthUser as any).mockResolvedValue({
      userId: 'auth-user-123',
      email: 'test@example.com',
    });
  });

  it('should cancel (soft delete) an event', async () => {
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

  it('should require authentication', async () => {
    (getDualAuthUser as any).mockResolvedValue(null);

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'DELETE',
    });

    const response = await DELETE(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });

  it('should reject non-owner cancellation', async () => {
    mockAdminClient.from = vi.fn().mockImplementation((table: string) => {
      if (table === 'users') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: { id: 'different-user-456' },
                error: null,
              }),
            }),
          }),
        };
      }
      return {};
    });

    const request = new Request(`http://localhost:3000/api/events/${eventId}`, {
      method: 'DELETE',
    });

    const response = await DELETE(request as any, {
      params: Promise.resolve({ id: eventId }),
    });
    const data = await response.json();

    expect(response.status).toBe(403);
    expect(data.error).toContain('own events');
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

    const request = new Request(`http://localhost:3000/api/events/nonexistent`, {
      method: 'DELETE',
    });

    const response = await DELETE(request as any, {
      params: Promise.resolve({ id: 'nonexistent' }),
    });
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toBe('Event not found');
  });
});
