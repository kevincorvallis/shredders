/**
 * Auth Route Integration Tests
 *
 * Tests for login, signup, refresh, and logout route handlers.
 * Does NOT modify existing auth.test.ts (which tests schemas).
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';

// ============================================
// Hoisted mocks (accessible inside vi.mock factories)
// ============================================
const {
  mockAuthenticateUser,
  mockCreateUserTokens,
  mockVerifyRefreshToken,
  mockRefreshUserSession,
  mockIsBlacklisted,
  mockExtractTokenFromHeader,
  mockDecodeTokenBarrel,
  mockDecodeToken,
  mockLogLoginSuccess,
  mockLogLoginFailure,
  mockLogSignupSuccess,
  mockLogSignupFailure,
  mockLogRefreshSuccess,
  mockLogRefreshFailure,
  mockLogLogout,
  mockLogRateLimitExceeded,
  mockAddToBlacklist,
  mockCreateSession,
  mockRateLimitEnhanced,
  mockSupabaseClient,
  mockAdminClient,
} = vi.hoisted(() => ({
  mockAuthenticateUser: vi.fn(),
  mockCreateUserTokens: vi.fn(),
  mockVerifyRefreshToken: vi.fn(),
  mockRefreshUserSession: vi.fn(),
  mockIsBlacklisted: vi.fn(),
  mockExtractTokenFromHeader: vi.fn(),
  mockDecodeTokenBarrel: vi.fn(),
  mockDecodeToken: vi.fn(),
  mockLogLoginSuccess: vi.fn().mockImplementation(() => Promise.resolve()),
  mockLogLoginFailure: vi.fn().mockImplementation(() => Promise.resolve()),
  mockLogSignupSuccess: vi.fn().mockImplementation(() => Promise.resolve()),
  mockLogSignupFailure: vi.fn().mockImplementation(() => Promise.resolve()),
  mockLogRefreshSuccess: vi.fn().mockImplementation(() => Promise.resolve()),
  mockLogRefreshFailure: vi.fn().mockImplementation(() => Promise.resolve()),
  mockLogLogout: vi.fn().mockImplementation(() => Promise.resolve()),
  mockLogRateLimitExceeded: vi.fn().mockImplementation(() => Promise.resolve()),
  mockAddToBlacklist: vi.fn().mockImplementation(() => Promise.resolve()),
  mockCreateSession: vi.fn().mockImplementation(() => Promise.resolve()),
  mockRateLimitEnhanced: vi.fn(),
  mockSupabaseClient: {
    auth: {
      signUp: vi.fn(),
      signOut: vi.fn(),
    },
    from: vi.fn(),
  } as any,
  mockAdminClient: {
    from: vi.fn(),
  } as any,
}));

// ============================================
// Mocks
// ============================================

// Mock next/headers
vi.mock('next/headers', () => ({
  headers: vi.fn(() =>
    Promise.resolve({
      get: vi.fn((key: string) => {
        if (key === 'x-forwarded-for') return '127.0.0.1';
        return null;
      }),
    })
  ),
}));

// Mock @/lib/auth barrel — mock everything, then re-export real schemas
vi.mock('@/lib/auth', async () => {
  const actualSchemas = await vi.importActual<typeof import('@/lib/auth/schemas')>('@/lib/auth/schemas');
  return {
    authenticateUser: mockAuthenticateUser,
    createUserTokens: mockCreateUserTokens,
    verifyRefreshToken: mockVerifyRefreshToken,
    refreshUserSession: mockRefreshUserSession,
    isBlacklisted: mockIsBlacklisted,
    extractTokenFromHeader: mockExtractTokenFromHeader,
    decodeToken: mockDecodeTokenBarrel,
    addToBlacklist: mockAddToBlacklist,
    logLoginSuccess: mockLogLoginSuccess,
    logLoginFailure: mockLogLoginFailure,
    logSignupSuccess: mockLogSignupSuccess,
    logSignupFailure: mockLogSignupFailure,
    logRefreshSuccess: mockLogRefreshSuccess,
    logRefreshFailure: mockLogRefreshFailure,
    logLogout: mockLogLogout,
    logRateLimitExceeded: mockLogRateLimitExceeded,
    // Real schemas
    loginSchema: actualSchemas.loginSchema,
    signupSchema: actualSchemas.signupSchema,
    refreshSchema: actualSchemas.refreshSchema,
    validateRequest: actualSchemas.validateRequest,
  };
});

// Mock @/lib/auth/jwt (login route imports decodeToken directly)
vi.mock('@/lib/auth/jwt', () => ({
  decodeToken: mockDecodeToken,
}));

// Mock @/lib/auth/session-manager
vi.mock('@/lib/auth/session-manager', () => ({
  createSession: mockCreateSession,
  updateSessionActivity: vi.fn().mockImplementation(() => Promise.resolve()),
}));

// Mock @/lib/api-utils (async per item 3)
vi.mock('@/lib/api-utils', () => ({
  rateLimitEnhanced: mockRateLimitEnhanced,
  createRateLimitKey: vi.fn((...parts: string[]) => parts.join(':')),
}));

// Mock @/lib/supabase/server
vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(() => Promise.resolve(mockSupabaseClient)),
}));

// Mock @/lib/supabase/admin
vi.mock('@/lib/supabase/admin', () => ({
  createAdminClient: vi.fn(() => mockAdminClient),
}));

// ============================================
// Imports (after mocks)
// ============================================

import { POST as loginPOST } from '../login/route';
import { POST as signupPOST } from '../signup/route';
import { POST as refreshPOST } from '../refresh/route';
import { POST as logoutPOST } from '../logout/route';

// ============================================
// Helpers
// ============================================

function createRequest(body: any, headers?: Record<string, string>): Request {
  return new Request('http://localhost:3000/api/auth/test', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });
}

// ============================================
// Tests
// ============================================

describe('POST /api/auth/login', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockRateLimitEnhanced.mockResolvedValue({ success: true, remaining: 4 });
  });

  it('should return tokens on valid credentials', async () => {
    mockAuthenticateUser.mockResolvedValue({
      user: { id: 'user-123', email: 'test@example.com' },
      tokens: { accessToken: 'access-tok', refreshToken: 'refresh-tok' },
    });
    mockDecodeToken.mockReturnValue({
      jti: 'jti-123',
      userId: 'user-123',
      tokenFamily: 'fam-123',
      exp: Math.floor(Date.now() / 1000) + 3600,
    });

    const res = await loginPOST(createRequest({
      email: 'test@example.com',
      password: 'password123',
    }));
    const data = await res.json();

    expect(res.status).toBe(200);
    expect(data.accessToken).toBe('access-tok');
    expect(data.refreshToken).toBe('refresh-tok');
    expect(data.user.email).toBe('test@example.com');
  });

  it('should return 400 for missing email', async () => {
    const res = await loginPOST(createRequest({
      password: 'password123',
    }));
    const data = await res.json();

    expect(res.status).toBe(400);
    expect(data.error).toBeDefined();
  });

  it('should return 400 for missing password', async () => {
    const res = await loginPOST(createRequest({
      email: 'test@example.com',
    }));
    const data = await res.json();

    expect(res.status).toBe(400);
    expect(data.error).toBeDefined();
  });

  it('should return 400 for bad email format', async () => {
    const res = await loginPOST(createRequest({
      email: 'not-an-email',
      password: 'password123',
    }));
    const data = await res.json();

    expect(res.status).toBe(400);
    expect(data.error).toBeDefined();
  });

  it('should return 429 when rate limited', async () => {
    mockRateLimitEnhanced.mockResolvedValue({
      success: false,
      remaining: 0,
      retryAfter: 300,
    });

    const res = await loginPOST(createRequest({
      email: 'test@example.com',
      password: 'password123',
    }));
    const data = await res.json();

    expect(res.status).toBe(429);
    expect(data.error).toBeDefined();
  });

  it('should return generic 401 on wrong password', async () => {
    mockAuthenticateUser.mockRejectedValue(new Error('Invalid credentials'));

    const res = await loginPOST(createRequest({
      email: 'test@example.com',
      password: 'wrongpassword',
    }));
    const data = await res.json();

    expect(res.status).toBe(401);
    // Should not reveal whether user exists
    expect(data.error.message).toContain('incorrect');
  });

  it('should return generic 401 on user not found', async () => {
    mockAuthenticateUser.mockRejectedValue(new Error('User not found'));

    const res = await loginPOST(createRequest({
      email: 'nonexistent@example.com',
      password: 'password123',
    }));
    const data = await res.json();

    expect(res.status).toBe(401);
    // Same generic message prevents user enumeration
    expect(data.error.message).toContain('incorrect');
  });

  it('should create session with JTI from refresh token', async () => {
    mockAuthenticateUser.mockResolvedValue({
      user: { id: 'user-123', email: 'test@example.com' },
      tokens: { accessToken: 'access-tok', refreshToken: 'refresh-tok' },
    });
    mockDecodeToken.mockReturnValue({
      jti: 'jti-456',
      userId: 'user-123',
      tokenFamily: 'fam-456',
      exp: Math.floor(Date.now() / 1000) + 3600,
    });

    await loginPOST(createRequest({
      email: 'test@example.com',
      password: 'password123',
    }));

    expect(mockCreateSession).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'user-123',
        refreshTokenJti: 'jti-456',
        tokenFamily: 'fam-456',
      })
    );
  });

  it('should log success on valid login', async () => {
    mockAuthenticateUser.mockResolvedValue({
      user: { id: 'user-123', email: 'test@example.com' },
      tokens: { accessToken: 'access-tok', refreshToken: 'refresh-tok' },
    });
    mockDecodeToken.mockReturnValue({
      jti: 'jti-789',
      userId: 'user-123',
      tokenFamily: 'fam-789',
      exp: Math.floor(Date.now() / 1000) + 3600,
    });

    await loginPOST(createRequest({
      email: 'test@example.com',
      password: 'password123',
    }));

    expect(mockLogLoginSuccess).toHaveBeenCalledWith(
      'user-123',
      expect.objectContaining({ email: 'test@example.com' })
    );
  });

  it('should log failure on invalid login', async () => {
    mockAuthenticateUser.mockRejectedValue(new Error('Invalid credentials'));

    await loginPOST(createRequest({
      email: 'test@example.com',
      password: 'wrongpassword',
    }));

    expect(mockLogLoginFailure).toHaveBeenCalledWith(
      'test@example.com',
      expect.any(String),
      expect.any(Object)
    );
  });
});

describe('POST /api/auth/signup', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockRateLimitEnhanced.mockResolvedValue({ success: true, remaining: 2 });
  });

  const validSignup = {
    email: 'new@example.com',
    password: 'StrongP@ss123!',
    username: 'newuser',
    displayName: 'New User',
  };

  it('should create account and return tokens', async () => {
    mockSupabaseClient.auth.signUp.mockResolvedValue({
      data: {
        user: {
          id: 'auth-user-1',
          email: 'new@example.com',
          email_confirmed_at: new Date().toISOString(),
        },
      },
      error: null,
    });

    // Admin client: check existing profile → null, check username → null, insert profile → ok, verify → ok
    let adminCallIdx = 0;
    mockAdminClient.from.mockImplementation(() => {
      adminCallIdx++;
      if (adminCallIdx === 1) {
        // existingProfile check (or filter)
        return {
          select: vi.fn().mockReturnValue({
            or: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      if (adminCallIdx === 2) {
        // username check
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      if (adminCallIdx === 3) {
        // insert profile
        return {
          insert: vi.fn().mockResolvedValue({ error: null }),
        };
      }
      if (adminCallIdx === 4) {
        // verify profile
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: { auth_user_id: 'auth-user-1' },
                error: null,
              }),
            }),
          }),
        };
      }
      return {};
    });

    mockCreateUserTokens.mockResolvedValue({
      accessToken: 'signup-access',
      refreshToken: 'signup-refresh',
    });

    const res = await signupPOST(createRequest(validSignup));
    const data = await res.json();

    expect(res.status).toBe(200);
    expect(data.accessToken).toBe('signup-access');
    expect(data.refreshToken).toBe('signup-refresh');
  });

  it('should return needsEmailVerification when email unconfirmed', async () => {
    mockSupabaseClient.auth.signUp.mockResolvedValue({
      data: {
        user: {
          id: 'auth-user-2',
          email: 'new@example.com',
          email_confirmed_at: null,
        },
      },
      error: null,
    });

    let adminCallIdx = 0;
    mockAdminClient.from.mockImplementation(() => {
      adminCallIdx++;
      if (adminCallIdx <= 2) {
        return {
          select: vi.fn().mockReturnValue({
            or: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
            eq: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      if (adminCallIdx === 3) {
        return { insert: vi.fn().mockResolvedValue({ error: null }) };
      }
      return {
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: { auth_user_id: 'auth-user-2' },
              error: null,
            }),
          }),
        }),
      };
    });

    const res = await signupPOST(createRequest(validSignup));
    const data = await res.json();

    expect(res.status).toBe(200);
    expect(data.needsEmailVerification).toBe(true);
    expect(data.accessToken).toBeUndefined();
  });

  it('should return 400 for weak password', async () => {
    const res = await signupPOST(createRequest({
      ...validSignup,
      password: 'weak',
    }));
    const data = await res.json();

    expect(res.status).toBe(400);
    expect(data.error).toContain('Validation');
  });

  it('should return 400 for missing username', async () => {
    const res = await signupPOST(createRequest({
      email: 'new@example.com',
      password: 'StrongP@ss123!',
    }));
    const data = await res.json();

    expect(res.status).toBe(400);
    expect(data.error).toContain('Validation');
  });

  it('should return 429 when rate limited', async () => {
    mockRateLimitEnhanced.mockResolvedValue({
      success: false,
      remaining: 0,
      retryAfter: 3600,
    });

    const res = await signupPOST(createRequest(validSignup));
    const data = await res.json();

    expect(res.status).toBe(429);
    expect(data.error).toContain('signup');
  });

  it('should return 409 when profile already exists', async () => {
    mockSupabaseClient.auth.signUp.mockResolvedValue({
      data: { user: null },
      error: { message: 'User already registered', code: 'user_already_exists' },
    });

    mockAdminClient.from.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: { id: 'existing-id', auth_user_id: 'existing-auth', email: 'new@example.com' },
            error: null,
          }),
        }),
      }),
    });

    const res = await signupPOST(createRequest(validSignup));
    const data = await res.json();

    expect(res.status).toBe(409);
    expect(data.error).toContain('already exists');
  });

  it('should return 409 for duplicate auth user without profile', async () => {
    mockSupabaseClient.auth.signUp.mockResolvedValue({
      data: { user: null },
      error: { message: 'User already registered', code: 'user_already_exists' },
    });

    mockAdminClient.from.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
        }),
      }),
    });

    const res = await signupPOST(createRequest(validSignup));
    const data = await res.json();

    expect(res.status).toBe(409);
    expect(data.error).toContain('already exists');
  });

  it('should auto-suffix username when taken', async () => {
    mockSupabaseClient.auth.signUp.mockResolvedValue({
      data: {
        user: {
          id: 'auth-user-3',
          email: 'new@example.com',
          email_confirmed_at: new Date().toISOString(),
        },
      },
      error: null,
    });

    let adminCallIdx = 0;
    const insertMock = vi.fn().mockResolvedValue({ error: null });
    mockAdminClient.from.mockImplementation(() => {
      adminCallIdx++;
      if (adminCallIdx === 1) {
        // existingProfile check
        return {
          select: vi.fn().mockReturnValue({
            or: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      if (adminCallIdx === 2) {
        // username check - taken!
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({
                data: { id: 'other-user' },
                error: null,
              }),
            }),
          }),
        };
      }
      if (adminCallIdx === 3) {
        // insert profile with suffixed username
        return { insert: insertMock };
      }
      return {
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({
              data: { auth_user_id: 'auth-user-3' },
              error: null,
            }),
          }),
        }),
      };
    });

    mockCreateUserTokens.mockResolvedValue({
      accessToken: 'a', refreshToken: 'r',
    });

    const res = await signupPOST(createRequest(validSignup));

    expect(res.status).toBe(200);
    // The insert should have been called with a suffixed username
    const insertedData = insertMock.mock.calls[0][0];
    expect(insertedData.username).toMatch(/^newuser_/);
  });

  it('should return 500 when profile creation fails', async () => {
    mockSupabaseClient.auth.signUp.mockResolvedValue({
      data: {
        user: {
          id: 'auth-user-4',
          email: 'new@example.com',
          email_confirmed_at: new Date().toISOString(),
        },
      },
      error: null,
    });

    let adminCallIdx = 0;
    mockAdminClient.from.mockImplementation(() => {
      adminCallIdx++;
      if (adminCallIdx === 1) {
        return {
          select: vi.fn().mockReturnValue({
            or: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      if (adminCallIdx === 2) {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      // Insert fails
      return {
        insert: vi.fn().mockResolvedValue({
          error: { message: 'DB error', code: 'PGRST' },
        }),
      };
    });

    const res = await signupPOST(createRequest(validSignup));
    const data = await res.json();

    expect(res.status).toBe(500);
    expect(data.error).toContain('Failed to create');
  });

  it('should return 500 when profile verify fails', async () => {
    mockSupabaseClient.auth.signUp.mockResolvedValue({
      data: {
        user: {
          id: 'auth-user-5',
          email: 'new@example.com',
          email_confirmed_at: new Date().toISOString(),
        },
      },
      error: null,
    });

    let adminCallIdx = 0;
    mockAdminClient.from.mockImplementation(() => {
      adminCallIdx++;
      if (adminCallIdx === 1) {
        return {
          select: vi.fn().mockReturnValue({
            or: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      if (adminCallIdx === 2) {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
            }),
          }),
        };
      }
      if (adminCallIdx === 3) {
        return { insert: vi.fn().mockResolvedValue({ error: null }) };
      }
      // Verify fails
      return {
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({ data: null, error: { message: 'not found' } }),
          }),
        }),
      };
    });

    const res = await signupPOST(createRequest(validSignup));
    const data = await res.json();

    expect(res.status).toBe(500);
    expect(data.error).toContain('verify');
  });

  it('should return tokens when existing profile matches auth user', async () => {
    mockSupabaseClient.auth.signUp.mockResolvedValue({
      data: {
        user: {
          id: 'auth-user-6',
          email: 'new@example.com',
          email_confirmed_at: new Date().toISOString(),
        },
      },
      error: null,
    });

    mockAdminClient.from.mockReturnValue({
      select: vi.fn().mockReturnValue({
        or: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: { id: 'profile-1', auth_user_id: 'auth-user-6', email: 'new@example.com' },
            error: null,
          }),
        }),
      }),
    });

    mockCreateUserTokens.mockResolvedValue({
      accessToken: 'existing-access', refreshToken: 'existing-refresh',
    });

    const res = await signupPOST(createRequest(validSignup));
    const data = await res.json();

    expect(res.status).toBe(200);
    expect(data.accessToken).toBe('existing-access');
    expect(data.message).toContain('already exists');
  });
});

describe('POST /api/auth/refresh', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockRateLimitEnhanced.mockResolvedValue({ success: true, remaining: 9 });
  });

  it('should return new token pair on valid refresh', async () => {
    mockVerifyRefreshToken.mockReturnValue({
      userId: 'user-123',
      jti: 'old-jti',
      tokenFamily: 'fam-123',
    });
    mockIsBlacklisted.mockResolvedValue(false);
    mockRefreshUserSession.mockResolvedValue({
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
    });
    mockDecodeTokenBarrel.mockReturnValue({
      jti: 'new-jti',
      userId: 'user-123',
      tokenFamily: 'fam-123',
      exp: Math.floor(Date.now() / 1000) + 3600,
    });

    const res = await refreshPOST(createRequest({
      refreshToken: 'valid-refresh-token',
    }));
    const data = await res.json();

    expect(res.status).toBe(200);
    expect(data.accessToken).toBe('new-access');
    expect(data.refreshToken).toBe('new-refresh');
  });

  it('should return 400 for empty token', async () => {
    const res = await refreshPOST(createRequest({
      refreshToken: '',
    }));
    const data = await res.json();

    expect(res.status).toBe(400);
    expect(data.error).toContain('Validation');
  });

  it('should return 429 when rate limited', async () => {
    mockRateLimitEnhanced.mockResolvedValue({
      success: false,
      remaining: 0,
      retryAfter: 60,
    });

    const res = await refreshPOST(createRequest({
      refreshToken: 'some-token',
    }));
    const data = await res.json();

    expect(res.status).toBe(429);
    expect(data.error).toContain('refresh');
  });

  it('should return 401 for invalid token', async () => {
    mockVerifyRefreshToken.mockReturnValue(null);

    const res = await refreshPOST(createRequest({
      refreshToken: 'invalid-token',
    }));
    const data = await res.json();

    expect(res.status).toBe(401);
    expect(data.error).toContain('Invalid');
  });

  it('should return 401 for blacklisted token', async () => {
    mockVerifyRefreshToken.mockReturnValue({
      userId: 'user-123',
      jti: 'blacklisted-jti',
      tokenFamily: 'fam-123',
    });
    mockIsBlacklisted.mockResolvedValue(true);

    const res = await refreshPOST(createRequest({
      refreshToken: 'blacklisted-token',
    }));
    const data = await res.json();

    expect(res.status).toBe(401);
    expect(data.error).toContain('revoked');
  });

  it('should create session for rotated token', async () => {
    mockVerifyRefreshToken.mockReturnValue({
      userId: 'user-123',
      jti: 'old-jti',
      tokenFamily: 'fam-123',
    });
    mockIsBlacklisted.mockResolvedValue(false);
    mockRefreshUserSession.mockResolvedValue({
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
    });
    mockDecodeTokenBarrel.mockReturnValue({
      jti: 'new-jti',
      userId: 'user-123',
      tokenFamily: 'fam-123',
      exp: Math.floor(Date.now() / 1000) + 3600,
    });

    await refreshPOST(createRequest({
      refreshToken: 'valid-refresh-token',
    }));

    expect(mockCreateSession).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'user-123',
        refreshTokenJti: 'new-jti',
      })
    );
  });

  it('should log success on valid refresh', async () => {
    mockVerifyRefreshToken.mockReturnValue({
      userId: 'user-123',
      jti: 'old-jti',
      tokenFamily: 'fam-123',
    });
    mockIsBlacklisted.mockResolvedValue(false);
    mockRefreshUserSession.mockResolvedValue({
      accessToken: 'new-a',
      refreshToken: 'new-r',
    });
    mockDecodeTokenBarrel.mockReturnValue({
      jti: 'new-jti',
      userId: 'user-123',
      exp: Math.floor(Date.now() / 1000) + 3600,
    });

    await refreshPOST(createRequest({
      refreshToken: 'valid-token',
    }));

    expect(mockLogRefreshSuccess).toHaveBeenCalledWith(
      'user-123',
      expect.objectContaining({ oldJti: 'old-jti' })
    );
  });
});

describe('POST /api/auth/logout', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockSupabaseClient.auth.signOut.mockResolvedValue({ error: null });
  });

  it('should logout with valid token', async () => {
    mockExtractTokenFromHeader.mockReturnValue('test-access-token');
    mockDecodeTokenBarrel.mockReturnValue({
      userId: 'user-123',
      jti: 'jti-123',
      exp: Math.floor(Date.now() / 1000) + 900,
      type: 'access',
    });

    const res = await logoutPOST(createRequest({}, {
      authorization: 'Bearer test-access-token',
    }));
    const data = await res.json();

    expect(res.status).toBe(200);
    expect(data.message).toContain('Logged out');
    expect(mockAddToBlacklist).toHaveBeenCalled();
  });

  it('should return 200 even without token', async () => {
    mockExtractTokenFromHeader.mockReturnValue(null);

    const res = await logoutPOST(createRequest({}));
    const data = await res.json();

    expect(res.status).toBe(200);
    expect(data.message).toContain('Logged out');
  });

  it('should continue logout even if blacklist fails', async () => {
    mockExtractTokenFromHeader.mockReturnValue('test-token');
    mockDecodeTokenBarrel.mockReturnValue({
      userId: 'user-123',
      jti: 'jti-123',
      exp: Math.floor(Date.now() / 1000) + 900,
      type: 'access',
    });
    mockAddToBlacklist.mockRejectedValue(new Error('Redis down'));

    const res = await logoutPOST(createRequest({}, {
      authorization: 'Bearer test-token',
    }));
    const data = await res.json();

    expect(res.status).toBe(200);
    expect(data.message).toContain('Logged out');
  });

  it('should return 400 when Supabase signOut errors', async () => {
    mockExtractTokenFromHeader.mockReturnValue(null);
    mockSupabaseClient.auth.signOut.mockResolvedValue({
      error: { message: 'Session not found' },
    });

    const res = await logoutPOST(createRequest({}));
    const data = await res.json();

    expect(res.status).toBe(400);
    expect(data.error).toBe('Session not found');
  });

  it('should log logout on success', async () => {
    mockExtractTokenFromHeader.mockReturnValue('test-token');
    mockDecodeTokenBarrel.mockReturnValue({
      userId: 'user-123',
      jti: 'jti-123',
      exp: Math.floor(Date.now() / 1000) + 900,
      type: 'access',
    });

    await logoutPOST(createRequest({}, {
      authorization: 'Bearer test-token',
    }));

    expect(mockLogLogout).toHaveBeenCalledWith(
      'user-123',
      expect.objectContaining({ logoutDuration: expect.any(Number) })
    );
  });
});
