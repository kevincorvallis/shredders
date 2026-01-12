/**
 * POST /api/auth/login
 *
 * Sign in with email and password
 * Includes JWT token generation, rate limiting, validation, and audit logging
 */

import { NextResponse } from 'next/server';
import { headers } from 'next/headers';
import {
  authenticateUser,
  loginSchema,
  validateRequest,
  logLoginSuccess,
  logLoginFailure,
  logRateLimitExceeded,
} from '@/lib/auth';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import { Errors, handleError } from '@/lib/errors';
import { createSession } from '@/lib/auth/session-manager';
import { decodeToken } from '@/lib/auth/jwt';

export async function POST(request: Request) {
  const startTime = Date.now();
  let email: string | undefined;

  try {
    // Parse request body
    const body = await request.json();

    // Validate input with Zod
    const validation = validateRequest(loginSchema, body);
    if (!validation.success) {
      throw Errors.validationFailed(validation.errors);
    }

    const { email: validatedEmail, password } = validation.data;
    email = validatedEmail;

    // Rate limiting: IP + email composite key (5 attempts per 5 minutes)
    const headersList = await headers();
    const ipAddress =
      headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      headersList.get('x-real-ip') ||
      'unknown';

    const rateLimitKey = createRateLimitKey(ipAddress, email);
    const rateLimit = rateLimitEnhanced(rateLimitKey, 'login');

    if (!rateLimit.success) {
      // Log rate limit exceeded
      await logRateLimitExceeded('login', undefined, {
        email,
        ipAddress,
        attemptsRemaining: rateLimit.remaining,
      });

      throw Errors.tooManyLoginAttempts(rateLimit.retryAfter!);
    }

    // Authenticate user and generate JWT tokens
    const result = await authenticateUser(email, password);

    // Decode refresh token to get JTI and token family
    const refreshPayload = decodeToken(result.tokens.refreshToken);
    if (!refreshPayload) {
      throw new Error('Failed to decode refresh token');
    }

    // Create session tracking
    await createSession({
      userId: result.user.id,
      refreshTokenJti: refreshPayload.jti,
      tokenFamily: refreshPayload.tokenFamily || refreshPayload.jti,
      expiresAt: new Date((refreshPayload.exp || 0) * 1000),
    });

    // Log successful login
    await logLoginSuccess(result.user.id, {
      email,
      ipAddress,
      loginDuration: Date.now() - startTime,
    });

    return NextResponse.json({
      user: {
        id: result.user.id,
        email: result.user.email,
      },
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
      message: 'Logged in successfully',
    });
  } catch (error: any) {
    // Log failed login attempt
    if (email) {
      await logLoginFailure(email, error.message || 'Authentication failed', {
        errorType: error.constructor.name,
        loginDuration: Date.now() - startTime,
      });
    }

    // For authentication failures, return generic error to prevent user enumeration
    if (error.message?.includes('Invalid credentials') || error.message?.includes('User not found')) {
      return handleError(Errors.invalidCredentials(), { userId: undefined, endpoint: 'login' });
    }

    // Handle all other errors with standard error handler
    return handleError(error, { userId: undefined, endpoint: 'login' });
  }
}
