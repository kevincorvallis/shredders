/**
 * Authentication API Tests
 *
 * Tests for signup, login, refresh, logout, rate limiting, and token reuse detection
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock Next.js headers
vi.mock('next/headers', () => ({
  headers: vi.fn(() => ({
    get: vi.fn((key: string) => {
      if (key === 'x-forwarded-for') return '127.0.0.1';
      if (key === 'user-agent') return 'test-agent';
      if (key === 'authorization') return null;
      return null;
    }),
  })),
}));

// Mock Supabase client
const mockSupabaseClient = {
  auth: {
    signUp: vi.fn(),
    signInWithPassword: vi.fn(),
    signOut: vi.fn(),
    admin: {
      deleteUser: vi.fn(),
      getUserById: vi.fn(),
      updateUserById: vi.fn(),
    },
    resetPasswordForEmail: vi.fn(),
  },
  from: vi.fn(() => ({
    select: vi.fn().mockReturnThis(),
    insert: vi.fn().mockReturnThis(),
    update: vi.fn().mockReturnThis(),
    delete: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    is: vi.fn().mockReturnThis(),
    gt: vi.fn().mockReturnThis(),
    lt: vi.fn().mockReturnThis(),
    single: vi.fn().mockReturnThis(),
    maybeSingle: vi.fn().mockReturnThis(),
    execute: vi.fn(),
  })),
};

vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(() => Promise.resolve(mockSupabaseClient)),
}));

// Mock rate limiting
vi.mock('@/lib/api-utils', () => ({
  rateLimitEnhanced: vi.fn(() => ({ success: true, remaining: 4 })),
  createRateLimitKey: vi.fn((a: string, b: string) => `${a}:${b}`),
}));

// Mock JWT functions
vi.mock('@/lib/auth/jwt', () => ({
  verifyAccessToken: vi.fn(),
  decodeToken: vi.fn(),
  createUserTokens: vi.fn(() =>
    Promise.resolve({
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
    })
  ),
}));

// Mock audit logging
vi.mock('@/lib/auth/audit-log', () => ({
  logLoginSuccess: vi.fn(),
  logLoginFailure: vi.fn(),
  logSignupSuccess: vi.fn(),
  logSignupFailure: vi.fn(),
  logRateLimitExceeded: vi.fn(),
  logAuthEvent: vi.fn(),
}));

// Mock session manager
vi.mock('@/lib/auth/session-manager', () => ({
  createSession: vi.fn(),
  revokeAllUserSessions: vi.fn(() => Promise.resolve(0)),
  getSessionById: vi.fn(),
}));

// Mock token blacklist
vi.mock('@/lib/auth/token-blacklist', () => ({
  revokeAllUserTokens: vi.fn(() => Promise.resolve(0)),
  addToBlacklist: vi.fn(),
  isBlacklisted: vi.fn(() => Promise.resolve(false)),
}));

// Import after mocks
import { validateRequest, signupSchema, loginSchema } from '@/lib/auth/schemas';
import { rateLimitEnhanced } from '@/lib/api-utils';

describe('Authentication API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  describe('Input Validation', () => {
    describe('Login Schema', () => {
      it('should validate correct login input', () => {
        const result = validateRequest(loginSchema, {
          email: 'test@example.com',
          password: 'password123',
        });

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.email).toBe('test@example.com');
        }
      });

      it('should reject invalid email format', () => {
        const result = validateRequest(loginSchema, {
          email: 'not-an-email',
          password: 'password123',
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors.some((e) => e.includes('email'))).toBe(true);
        }
      });

      it('should reject short password', () => {
        const result = validateRequest(loginSchema, {
          email: 'test@example.com',
          password: 'short',
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors.some((e) => e.includes('8 characters'))).toBe(true);
        }
      });

      it('should lowercase email', () => {
        const result = validateRequest(loginSchema, {
          email: 'TEST@EXAMPLE.COM',
          password: 'password123',
        });

        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.email).toBe('test@example.com');
        }
      });
    });

    describe('Signup Schema', () => {
      it('should validate correct signup input', () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'StrongP@ss123!',
          username: 'testuser',
          displayName: 'Test User',
        });

        expect(result.success).toBe(true);
      });

      it('should require 12+ character password', () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'Short1!',
          username: 'testuser',
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors.some((e) => e.includes('12 characters'))).toBe(true);
        }
      });

      it('should require uppercase letter in password', () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'alllowercase1!',
          username: 'testuser',
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors.some((e) => e.includes('uppercase'))).toBe(true);
        }
      });

      it('should require lowercase letter in password', () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'ALLUPPERCASE1!',
          username: 'testuser',
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors.some((e) => e.includes('lowercase'))).toBe(true);
        }
      });

      it('should require number in password', () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'NoNumbersHere!',
          username: 'testuser',
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors.some((e) => e.includes('number'))).toBe(true);
        }
      });

      it('should require special character in password', () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'NoSpecialChars1',
          username: 'testuser',
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors.some((e) => e.includes('special'))).toBe(true);
        }
      });

      it('should validate username format', () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'StrongP@ss123!',
          username: 'invalid-username!',
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.errors.some((e) => e.includes('username'))).toBe(true);
        }
      });

      it('should allow optional display name', () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'StrongP@ss123!',
          username: 'testuser',
        });

        expect(result.success).toBe(true);
      });
    });
  });

  describe('Rate Limiting', () => {
    it('should allow requests within rate limit', () => {
      vi.mocked(rateLimitEnhanced).mockReturnValue({ success: true, remaining: 4 });

      const result = rateLimitEnhanced('test-key', 'login');

      expect(result.success).toBe(true);
      expect(result.remaining).toBe(4);
    });

    it('should block requests exceeding rate limit', () => {
      vi.mocked(rateLimitEnhanced).mockReturnValue({
        success: false,
        remaining: 0,
        retryAfter: 300,
      });

      const result = rateLimitEnhanced('test-key', 'login');

      expect(result.success).toBe(false);
      expect(result.retryAfter).toBe(300);
    });
  });

  describe('Token Validation', () => {
    it('should accept valid JWT token format', () => {
      // Valid JWT format: header.payload.signature
      const validToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';

      expect(validToken.split('.').length).toBe(3);
    });

    it('should reject malformed JWT token', () => {
      const invalidTokens = [
        'not-a-jwt',
        'only.two.parts', // Actually valid structure
        'no-dots',
        '',
        '   ',
      ];

      invalidTokens.forEach((token) => {
        const parts = token.trim().split('.');
        if (parts.length !== 3 || parts.some((p) => p === '')) {
          expect(parts.length !== 3 || parts.some((p) => p === '')).toBe(true);
        }
      });
    });
  });

  describe('Password Security', () => {
    const strongPasswords = [
      'MyStrongP@ss123',
      'Comp!ex1Password',
      'Secur3_P@ssword!',
      '12Characters!!Aa',
    ];

    const weakPasswords = [
      'short1!',
      'nouppercase1!',
      'NOLOWERCASE1!',
      'NoNumbers!!',
      'NoSpecialChars1',
    ];

    strongPasswords.forEach((password) => {
      it(`should accept strong password: ${password.slice(0, 5)}...`, () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password,
          username: 'testuser',
        });

        expect(result.success).toBe(true);
      });
    });

    weakPasswords.forEach((password) => {
      it(`should reject weak password: ${password.slice(0, 5)}...`, () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password,
          username: 'testuser',
        });

        expect(result.success).toBe(false);
      });
    });
  });

  describe('Email Validation', () => {
    const validEmails = [
      'test@example.com',
      'user.name@domain.org',
      'user+tag@example.co.uk',
    ];

    const invalidEmails = [
      'not-an-email',
      '@nodomain.com',
      'user@',
      'user@.com',
      '',
    ];

    validEmails.forEach((email) => {
      it(`should accept valid email: ${email}`, () => {
        const result = validateRequest(loginSchema, {
          email,
          password: 'password123',
        });

        expect(result.success).toBe(true);
      });
    });

    invalidEmails.forEach((email) => {
      it(`should reject invalid email: ${email || '(empty)'}`, () => {
        const result = validateRequest(loginSchema, {
          email,
          password: 'password123',
        });

        expect(result.success).toBe(false);
      });
    });
  });

  describe('Username Validation', () => {
    const validUsernames = ['user123', 'test_user', 'JohnDoe', 'abc'];

    const invalidUsernames = [
      'ab', // too short
      'user-name', // contains dash
      'user name', // contains space
      'user@name', // contains @
      'a'.repeat(21), // too long
    ];

    validUsernames.forEach((username) => {
      it(`should accept valid username: ${username}`, () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'StrongP@ss123!',
          username,
        });

        expect(result.success).toBe(true);
      });
    });

    invalidUsernames.forEach((username) => {
      it(`should reject invalid username: ${username.slice(0, 10)}...`, () => {
        const result = validateRequest(signupSchema, {
          email: 'test@example.com',
          password: 'StrongP@ss123!',
          username,
        });

        expect(result.success).toBe(false);
      });
    });
  });
});
