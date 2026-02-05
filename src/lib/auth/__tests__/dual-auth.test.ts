/**
 * Dual Authentication Tests
 *
 * Tests for getDualAuthUser which supports JWT, Supabase Bearer, and session cookies.
 * Covers the three auth paths, profile caching, and fallback behavior.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { NextRequest } from 'next/server';

// Mock getAuthUserAsync (JWT path)
const mockGetAuthUserAsync = vi.fn();
vi.mock('../middleware', () => ({
  getAuthUserAsync: (...args: any[]) => mockGetAuthUserAsync(...args),
}));

// Mock extractTokenFromHeader
const mockExtractToken = vi.fn();
vi.mock('../jwt', () => ({
  extractTokenFromHeader: (...args: any[]) => mockExtractToken(...args),
}));

// Mock Supabase clients
const mockAdminAuth = {
  getUser: vi.fn(),
};
const mockAdminFrom = vi.fn();
const mockAdminClient = {
  auth: mockAdminAuth,
  from: mockAdminFrom,
};

const mockSupabaseAuth = {
  getUser: vi.fn(),
};
const mockSupabaseFrom = vi.fn();
const mockSupabaseClient = {
  auth: mockSupabaseAuth,
  from: mockSupabaseFrom,
};

vi.mock('@/lib/supabase/admin', () => ({
  createAdminClient: () => mockAdminClient,
}));

vi.mock('@/lib/supabase/server', () => ({
  createClient: () => Promise.resolve(mockSupabaseClient),
}));

import { getDualAuthUser, requireDualAuth, clearUserProfileCache } from '../dual-auth';

function makeRequest(headers: Record<string, string> = {}): NextRequest {
  const req = new NextRequest('http://localhost/api/test', {
    headers: new Headers(headers),
  });
  return req;
}

function mockProfileQuery(client: any, profile: { id: string; username?: string } | null) {
  const chain = {
    select: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    single: vi.fn().mockResolvedValue({ data: profile, error: null }),
  };
  client.mockReturnValue(chain);
  return chain;
}

describe('getDualAuthUser', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // Clear the in-memory profile cache between tests
    clearUserProfileCache('jwt-user-id');
    clearUserProfileCache('apple-user-id');
    clearUserProfileCache('session-user-id');
  });

  describe('JWT auth path', () => {
    it('should authenticate via JWT token and return user with profile', async () => {
      mockGetAuthUserAsync.mockResolvedValue({
        userId: 'jwt-user-id',
        email: 'jwt@example.com',
        username: 'jwtuser',
      });

      mockProfileQuery(mockAdminFrom, { id: 'profile-123', username: 'jwtuser' });

      const req = makeRequest({ authorization: 'Bearer some-jwt-token' });
      const user = await getDualAuthUser(req);

      expect(user).not.toBeNull();
      expect(user!.userId).toBe('jwt-user-id');
      expect(user!.email).toBe('jwt@example.com');
      expect(user!.profileId).toBe('profile-123');
      expect(user!.authMethod).toBe('jwt');
    });

    it('should return user without profileId if profile lookup fails', async () => {
      mockGetAuthUserAsync.mockResolvedValue({
        userId: 'jwt-user-id',
        email: 'jwt@example.com',
        username: 'jwtuser',
      });

      mockProfileQuery(mockAdminFrom, null);

      const req = makeRequest({ authorization: 'Bearer some-jwt-token' });
      const user = await getDualAuthUser(req);

      expect(user).not.toBeNull();
      expect(user!.userId).toBe('jwt-user-id');
      expect(user!.profileId).toBeUndefined();
      expect(user!.authMethod).toBe('jwt');
    });

    it('should use cached profile on second call', async () => {
      mockGetAuthUserAsync.mockResolvedValue({
        userId: 'jwt-user-id',
        email: 'jwt@example.com',
        username: 'jwtuser',
      });

      mockProfileQuery(mockAdminFrom, { id: 'profile-123', username: 'jwtuser' });

      const req = makeRequest({ authorization: 'Bearer some-jwt-token' });

      // First call - cache miss
      await getDualAuthUser(req);
      expect(mockAdminFrom).toHaveBeenCalledTimes(1);

      // Second call - should use cache
      const user2 = await getDualAuthUser(req);
      expect(user2!.profileId).toBe('profile-123');
      // adminFrom called once for first lookup, not again for cached
      expect(mockAdminFrom).toHaveBeenCalledTimes(1);
    });
  });

  describe('Supabase Bearer token path (Apple Sign In)', () => {
    it('should authenticate via Supabase Bearer token', async () => {
      // JWT path returns null
      mockGetAuthUserAsync.mockResolvedValue(null);
      mockExtractToken.mockReturnValue('supabase-bearer-token');

      mockAdminAuth.getUser.mockResolvedValue({
        data: { user: { id: 'apple-user-id', email: 'apple@example.com' } },
        error: null,
      });

      mockProfileQuery(mockAdminFrom, { id: 'profile-456', username: 'appleuser' });

      const req = makeRequest({ authorization: 'Bearer supabase-bearer-token' });
      const user = await getDualAuthUser(req);

      expect(user).not.toBeNull();
      expect(user!.userId).toBe('apple-user-id');
      expect(user!.email).toBe('apple@example.com');
      expect(user!.profileId).toBe('profile-456');
      expect(user!.authMethod).toBe('supabase');
    });

    it('should fall through if Supabase token verification fails', async () => {
      mockGetAuthUserAsync.mockResolvedValue(null);
      mockExtractToken.mockReturnValue('bad-token');

      mockAdminAuth.getUser.mockResolvedValue({
        data: { user: null },
        error: { message: 'Invalid token' },
      });

      // Session cookie fallback also fails
      mockSupabaseAuth.getUser.mockResolvedValue({
        data: { user: null },
      });

      const req = makeRequest({ authorization: 'Bearer bad-token' });
      const user = await getDualAuthUser(req);

      expect(user).toBeNull();
    });
  });

  describe('Session cookie path (web clients)', () => {
    it('should authenticate via Supabase session cookies', async () => {
      // JWT path returns null
      mockGetAuthUserAsync.mockResolvedValue(null);
      // No Bearer token
      mockExtractToken.mockReturnValue(null);

      mockSupabaseAuth.getUser.mockResolvedValue({
        data: { user: { id: 'session-user-id', email: 'web@example.com' } },
      });

      mockProfileQuery(mockSupabaseFrom, { id: 'profile-789', username: 'webuser' });

      const req = makeRequest();
      const user = await getDualAuthUser(req);

      expect(user).not.toBeNull();
      expect(user!.userId).toBe('session-user-id');
      expect(user!.email).toBe('web@example.com');
      expect(user!.profileId).toBe('profile-789');
      expect(user!.authMethod).toBe('supabase');
    });
  });

  describe('No authentication', () => {
    it('should return null when no auth method succeeds', async () => {
      mockGetAuthUserAsync.mockResolvedValue(null);
      mockExtractToken.mockReturnValue(null);
      mockSupabaseAuth.getUser.mockResolvedValue({ data: { user: null } });

      const req = makeRequest();
      const user = await getDualAuthUser(req);

      expect(user).toBeNull();
    });
  });

  describe('Auth priority', () => {
    it('should prefer JWT over Supabase Bearer', async () => {
      // JWT succeeds
      mockGetAuthUserAsync.mockResolvedValue({
        userId: 'jwt-user-id',
        email: 'jwt@example.com',
      });

      mockProfileQuery(mockAdminFrom, { id: 'profile-jwt' });

      const req = makeRequest({ authorization: 'Bearer some-token' });
      const user = await getDualAuthUser(req);

      // Should use JWT, not call Supabase Bearer verification
      expect(user!.authMethod).toBe('jwt');
      expect(mockAdminAuth.getUser).not.toHaveBeenCalled();
    });
  });
});

describe('requireDualAuth', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    clearUserProfileCache('jwt-user-id');
  });

  it('should return user when authenticated', async () => {
    mockGetAuthUserAsync.mockResolvedValue({
      userId: 'jwt-user-id',
      email: 'jwt@example.com',
    });

    mockProfileQuery(mockAdminFrom, { id: 'profile-123' });

    const req = makeRequest({ authorization: 'Bearer token' });
    const user = await requireDualAuth(req);

    expect(user.userId).toBe('jwt-user-id');
  });

  it('should throw when not authenticated', async () => {
    mockGetAuthUserAsync.mockResolvedValue(null);
    mockExtractToken.mockReturnValue(null);
    mockSupabaseAuth.getUser.mockResolvedValue({ data: { user: null } });

    const req = makeRequest();

    await expect(requireDualAuth(req)).rejects.toThrow('Authentication required');
  });
});
