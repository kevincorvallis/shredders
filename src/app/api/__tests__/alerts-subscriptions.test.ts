import { describe, it, expect, beforeEach, vi } from 'vitest';
import { NextResponse } from 'next/server';

// Mock auth user state
let mockAuthUser: any = { userId: 'auth-user-123', email: 'test@test.com', authMethod: 'jwt' };

// Mock withDualAuth to pass through with mock auth user
vi.mock('@/lib/auth', () => ({
  withDualAuth: (handler: any) => {
    return async (req: any, context?: any) => {
      if (!mockAuthUser) {
        return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
      }
      return handler(req, mockAuthUser, context);
    };
  },
}));

// Mock Supabase
vi.mock('@/lib/supabase/server', () => ({
  createAdminClient: vi.fn(),
}));

// Mock errors to use simple format matching existing tests
vi.mock('@/lib/errors', () => ({
  Errors: {
    unauthorized: (msg: string) => ({ _type: 'error', status: 401, message: msg }),
    missingField: (field: string) => ({ _type: 'error', status: 400, message: `${field} is required` }),
    validationFailed: (details: string[]) => ({ _type: 'error', status: 400, message: details.join(', ') }),
    databaseError: () => ({ _type: 'error', status: 500, message: 'Database error' }),
  },
  handleError: (error: any) => {
    if (error?._type === 'error') {
      return NextResponse.json({ error: error.message }, { status: error.status });
    }
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  },
}));

// Must import after mocks
import { GET, POST, DELETE } from '../alerts/subscriptions/route';
import { createAdminClient } from '@/lib/supabase/server';

function createMockAdminClient() {
  return {
    from: vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: { id: 'profile-uuid-123' },
            error: null,
          }),
          order: vi.fn().mockReturnValue({
            eq: vi.fn().mockResolvedValue({
              data: [
                {
                  id: 'sub123',
                  user_id: 'profile-uuid-123',
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
                    user_id: 'profile-uuid-123',
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
              user_id: 'profile-uuid-123',
              mountain_id: 'baker',
              weather_alerts: true,
              powder_alerts: true,
              powder_threshold: 6,
            },
            error: null,
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
    }),
  };
}

// Helper to call withDualAuth-wrapped handlers (they expect 2 args)
const callHandler = (handler: any, req: Request) => handler(req, undefined);

describe('GET /api/alerts/subscriptions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockAuthUser = { userId: 'auth-user-123', email: 'test@test.com', authMethod: 'jwt' };
    (createAdminClient as any).mockReturnValue(createMockAdminClient());
  });

  it('should fetch user subscriptions', async () => {
    const request = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'GET',
    });

    const response = await callHandler(GET, request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(Array.isArray(data.subscriptions)).toBe(true);
    expect(data.subscriptions[0]).toHaveProperty('mountain_id', 'baker');
    expect(data.subscriptions[0]).toHaveProperty('weather_alerts', true);
  });

  it('should filter by mountainId query param', async () => {
    const request = new Request(
      'http://localhost:3000/api/alerts/subscriptions?mountainId=baker',
      { method: 'GET' }
    );

    const response = await callHandler(GET, request);
    const data = await response.json();

    expect(response.status).toBe(200);
  });

  it('should require authentication', async () => {
    mockAuthUser = null;

    const request = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'GET',
    });

    const response = await callHandler(GET, request);
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });
});

describe('POST /api/alerts/subscriptions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockAuthUser = { userId: 'auth-user-123', email: 'test@test.com', authMethod: 'jwt' };
    (createAdminClient as any).mockReturnValue(createMockAdminClient());
  });

  it('should create a new subscription', async () => {
    const requestBody = {
      mountainId: 'baker',
      weatherAlerts: true,
      powderAlerts: true,
      powderThreshold: 8,
    };

    const request = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await callHandler(POST, request);
    const data = await response.json();

    expect(response.status).toBe(201);
    expect(data.subscription).toHaveProperty('id');
    expect(data.subscription.mountain_id).toBe('baker');
    expect(data.subscription.weather_alerts).toBe(true);
  });

  it('should validate powder threshold range', async () => {
    const requestBody = {
      mountainId: 'baker',
      powderThreshold: 150,
    };

    const request = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await callHandler(POST, request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toContain('threshold');
  });

  it('should require mountainId', async () => {
    const request = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'POST',
      body: JSON.stringify({}),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await callHandler(POST, request);
    const data = await response.json();

    expect(response.status).toBe(400);
  });
});

describe('DELETE /api/alerts/subscriptions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockAuthUser = { userId: 'auth-user-123', email: 'test@test.com', authMethod: 'jwt' };
    (createAdminClient as any).mockReturnValue(createMockAdminClient());
  });

  it('should delete subscription', async () => {
    const request = new Request(
      'http://localhost:3000/api/alerts/subscriptions?mountainId=baker',
      { method: 'DELETE' }
    );

    const response = await callHandler(DELETE, request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
  });

  it('should require mountainId parameter', async () => {
    const request = new Request('http://localhost:3000/api/alerts/subscriptions', {
      method: 'DELETE',
    });

    const response = await callHandler(DELETE, request);
    const data = await response.json();

    expect(response.status).toBe(400);
  });
});
