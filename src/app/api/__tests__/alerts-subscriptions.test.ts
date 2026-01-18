import { describe, it, expect, beforeEach, vi } from 'vitest';
import { GET, POST, DELETE } from '../alerts/subscriptions/route';
import { createClient } from '@/lib/supabase/server';

// Mock Supabase
vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(),
}));

describe('GET /api/alerts/subscriptions', () => {
  let mockSupabase: any;
  let mockRequest: Request;

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      auth: {
        getUser: vi.fn().mockResolvedValue({
          data: { user: { id: 'user123' } },
          error: null,
        }),
      },
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            order: vi.fn().mockReturnValue({
              eq: vi.fn().mockResolvedValue({
                data: [
                  {
                    id: 'sub123',
                    user_id: 'user123',
                    mountain_id: 'baker',
                    weather_alerts: true,
                    powder_alerts: true,
                    powder_threshold: 6,
                  },
                ],
                error: null,
              }),
              then: function(resolve: any) {
                return resolve({
                  data: [
                    {
                      id: 'sub123',
                      user_id: 'user123',
                      mountain_id: 'baker',
                      weather_alerts: true,
                      powder_alerts: true,
                      powder_threshold: 6,
                    },
                  ],
                  error: null,
                });
              },
            }),
          }),
        }),
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
  });

  it('should fetch user subscriptions', async () => {
    mockRequest = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'GET',
    });

    const response = await GET(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(Array.isArray(data.subscriptions)).toBe(true);
    expect(data.subscriptions[0]).toHaveProperty('mountain_id', 'baker');
    expect(data.subscriptions[0]).toHaveProperty('weather_alerts', true);
  });

  it('should filter by mountainId query param', async () => {
    mockRequest = new Request(
      'http://localhost:3000/api/alerts/subscriptions?mountainId=baker',
      { method: 'GET' }
    );

    const response = await GET(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(mockSupabase.from).toHaveBeenCalledWith('alert_subscriptions');
  });

  it('should require authentication', async () => {
    mockSupabase.auth.getUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'Not authenticated' },
    });

    mockRequest = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'GET',
    });

    const response = await GET(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });
});

describe('POST /api/alerts/subscriptions', () => {
  let mockSupabase: any;
  let mockRequest: Request;

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      auth: {
        getUser: vi.fn().mockResolvedValue({
          data: { user: { id: 'user123' } },
          error: null,
        }),
      },
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({
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
                id: 'sub123',
                user_id: 'user123',
                mountain_id: 'baker',
                weather_alerts: true,
                powder_alerts: true,
                powder_threshold: 6,
              },
              error: null,
            }),
          }),
        }),
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
  });

  it('should create a new subscription', async () => {
    const requestBody = {
      mountainId: 'baker',
      weatherAlerts: true,
      powderAlerts: true,
      powderThreshold: 8,
    };

    mockRequest = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(201);
    expect(data.subscription).toHaveProperty('id');
    expect(data.subscription.mountain_id).toBe('baker');
    expect(data.subscription.weather_alerts).toBe(true);
  });

  it('should validate powder threshold range', async () => {
    const requestBody = {
      mountainId: 'baker',
      powderThreshold: 150, // Invalid: too high
    };

    mockRequest = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('threshold');
  });

  it('should update existing subscription', async () => {
    // Mock existing subscription
    mockSupabase.from.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            maybeSingle: vi.fn().mockResolvedValue({
              data: {
                id: 'existing123',
                user_id: 'user123',
                mountain_id: 'baker',
                weather_alerts: false,
                powder_alerts: false,
              },
              error: null,
            }),
          }),
        }),
      }),
      update: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          select: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: {
                id: 'existing123',
                user_id: 'user123',
                mountain_id: 'baker',
                weather_alerts: true,
                powder_alerts: true,
                powder_threshold: 10,
              },
              error: null,
            }),
          }),
        }),
      }),
    });

    const requestBody = {
      mountainId: 'baker',
      weatherAlerts: true,
      powderAlerts: true,
      powderThreshold: 10,
    };

    mockRequest = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.subscription.powder_threshold).toBe(10);
  });
});

describe('DELETE /api/alerts/subscriptions', () => {
  let mockSupabase: any;
  let mockRequest: Request;

  beforeEach(() => {
    vi.clearAllMocks();

    mockSupabase = {
      auth: {
        getUser: vi.fn().mockResolvedValue({
          data: { user: { id: 'user123' } },
          error: null,
        }),
      },
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
  });

  it('should delete subscription', async () => {
    mockRequest = new Request(
      'http://localhost:3000/api/alerts/subscriptions?mountainId=baker',
      { method: 'DELETE' }
    );

    const response = await DELETE(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
  });

  it('should require mountainId parameter', async () => {
    mockRequest = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'DELETE',
    });

    const response = await DELETE(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe('Mountain ID is required');
  });
});
