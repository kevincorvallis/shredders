import { describe, it, expect, beforeEach, vi } from 'vitest';
import { POST, DELETE } from '../push/register/route';
import { createClient } from '@/lib/supabase/server';

// Mock Supabase
vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(),
}));

describe('POST /api/push/register', () => {
  let mockSupabase: any;
  let mockRequest: Request;

  beforeEach(() => {
    // Reset mocks
    vi.clearAllMocks();

    // Mock Supabase client
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
          }),
        }),
      }),
    };

    (createClient as any).mockResolvedValue(mockSupabase);
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
    expect(data.error).toContain('Platform must be');
  });

  it('should require authentication', async () => {
    mockSupabase.auth.getUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'Not authenticated' },
    });

    const requestBody = {
      deviceToken: 'abc123',
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

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });

  it('should update existing device token', async () => {
    // Mock existing token
    mockSupabase.from.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
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
    });

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
        update: vi.fn().mockReturnValue({
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
    expect(data.error).toBe('Device ID is required');
  });

  it('should require authentication for DELETE', async () => {
    mockSupabase.auth.getUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'Not authenticated' },
    });

    mockRequest = new Request(
      'http://localhost:3000/api/push/register?deviceId=device123',
      {
        method: 'DELETE',
      }
    );

    const response = await DELETE(mockRequest);
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe('Not authenticated');
  });
});
