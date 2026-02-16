import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createAdminClient } from '@/lib/supabase/server';

// Mock withDualAuth to pass through with a fake auth user
const mockAuthUser = {
  userId: 'user123',
  email: 'test@example.com',
  authMethod: 'jwt' as const,
};

vi.mock('@/lib/auth', () => ({
  withDualAuth: vi.fn((handler: any) => {
    return async (request: Request) => {
      if (mockAuthUser.userId) {
        return handler(request, mockAuthUser);
      }
      const { NextResponse } = await import('next/server');
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    };
  }),
}));

// Mock Supabase
vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(),
  createAdminClient: vi.fn(),
}));

// Helper to create a mock admin client that resolves user profile lookup
function createMockAdminClient() {
  return {
    from: vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: { id: 'profile-uuid-123' },
            error: null,
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
              id: 'token123',
              device_token: 'abc123',
              platform: 'ios',
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
                id: 'token123',
                device_token: 'abc123',
                platform: 'ios',
              },
              error: null,
            }),
          }),
          eq: vi.fn().mockResolvedValue({
            data: null,
            error: null,
          }),
        }),
      }),
    }),
  };
}

describe('POST /api/push/register', () => {
  let POST: any;
  let mockRequest: Request;

  beforeEach(async () => {
    vi.clearAllMocks();
    mockAuthUser.userId = 'user123';
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    // Re-import to get fresh module with mocks applied
    const mod = await import('../push/register/route');
    POST = mod.POST;
  });

  it('should register a new device token', async () => {
    const requestBody = {
      deviceToken: 'abc123',
      platform: 'ios',
      deviceId: 'device123',
      appVersion: '1.0.0',
      osVersion: '17.0',
    };

    mockRequest = new Request('http://localhost:3000/api/push/register', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(201);
    expect(data.token).toHaveProperty('id');
    expect(data.token.device_token).toBe('abc123');
    expect(data.token.platform).toBe('ios');
  });

  it('should reject invalid platform', async () => {
    const requestBody = {
      deviceToken: 'abc123',
      platform: 'android', // Invalid platform
      deviceId: 'device123',
    };

    mockRequest = new Request('http://localhost:3000/api/push/register', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error.code).toBe('VALIDATION_ERROR');
  });

  it('should update existing device token', async () => {
    // Mock admin client with existing token
    const mockAdmin = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: { id: 'profile-uuid-123' },
              error: null,
            }),
            eq: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({
                data: {
                  id: 'existing123',
                  device_token: 'old_token',
                  platform: 'ios',
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
                  device_token: 'new_token',
                  platform: 'ios',
                },
                error: null,
              }),
            }),
          }),
        }),
      }),
    };
    (createAdminClient as any).mockReturnValue(mockAdmin);

    const requestBody = {
      deviceToken: 'new_token',
      platform: 'ios',
      deviceId: 'device123',
    };

    mockRequest = new Request('http://localhost:3000/api/push/register', {
      method: 'POST',
      body: JSON.stringify(requestBody),
      headers: { 'Content-Type': 'application/json' },
    });

    const response = await POST(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.token.device_token).toBe('new_token');
  });
});

describe('DELETE /api/push/register', () => {
  let DELETE: any;
  let mockRequest: Request;

  beforeEach(async () => {
    vi.clearAllMocks();
    mockAuthUser.userId = 'user123';
    (createAdminClient as any).mockReturnValue(createMockAdminClient());

    const mod = await import('../push/register/route');
    DELETE = mod.DELETE;
  });

  it('should unregister a device token', async () => {
    mockRequest = new Request(
      'http://localhost:3000/api/push/register?deviceId=device123',
      {
        method: 'DELETE',
      }
    );

    const response = await DELETE(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
  });

  it('should require deviceId parameter', async () => {
    mockRequest = new Request('http://localhost:3000/api/push/register', {
      method: 'DELETE',
    });

    const response = await DELETE(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error.code).toBe('VALIDATION_ERROR');
  });
});
