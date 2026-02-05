/**
 * POST /api/auth/refresh
 *
 * Refresh access token using refresh token
 * Includes validation, rate limiting, blacklist checking, and audit logging
 */

import { NextResponse } from 'next/server';
import { headers } from 'next/headers';
import {
  verifyRefreshToken,
  refreshUserSession,
  refreshSchema,
  validateRequest,
  isBlacklisted,
  logRefreshSuccess,
  logRefreshFailure,
  logRateLimitExceeded,
  decodeToken,
} from '@/lib/auth';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import { createSession, updateSessionActivity } from '@/lib/auth/session-manager';

export async function POST(request: Request) {
  const startTime = Date.now();
  let userId: string | undefined;

  try {
    // Parse request body
    const body = await request.json();

    // Validate input with Zod
    const validation = validateRequest(refreshSchema, body);
    if (!validation.success) {
      return NextResponse.json(
        {
          error: 'Validation failed',
          details: validation.errors,
        },
        { status: 400 }
      );
    }

    const { refreshToken } = validation.data;

    // Rate limiting: IP-based (10 attempts per minute)
    const headersList = await headers();
    const ipAddress =
      headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      headersList.get('x-real-ip') ||
      'unknown';

    const rateLimitKey = createRateLimitKey('refresh', ipAddress);
    const rateLimit = await rateLimitEnhanced(rateLimitKey, 'refresh');

    if (!rateLimit.success) {
      // Log rate limit exceeded
      await logRateLimitExceeded('refresh', undefined, {
        ipAddress,
        attemptsRemaining: rateLimit.remaining,
      });

      return NextResponse.json(
        {
          error: 'Too many refresh attempts',
          retryAfter: rateLimit.retryAfter,
          message: `Please try again in ${rateLimit.retryAfter} seconds`,
        },
        {
          status: 429,
          headers: {
            'Retry-After': rateLimit.retryAfter!.toString(),
          },
        }
      );
    }

    // Verify refresh token
    const payload = verifyRefreshToken(refreshToken);

    if (!payload) {
      await logRefreshFailure('Invalid or expired refresh token', {
        ipAddress,
        refreshDuration: Date.now() - startTime,
      });

      return NextResponse.json(
        { error: 'Invalid or expired refresh token' },
        { status: 401 }
      );
    }

    userId = payload.userId;

    // Check if refresh token is blacklisted
    const blacklisted = await isBlacklisted(payload.jti);
    if (blacklisted) {
      await logRefreshFailure('Refresh token has been revoked', {
        userId,
        ipAddress,
        jti: payload.jti,
        refreshDuration: Date.now() - startTime,
      });

      return NextResponse.json(
        { error: 'Refresh token has been revoked' },
        { status: 401 }
      );
    }

    // Generate new tokens with rotation
    // Pass the entire payload so rotation can track token family
    const tokens = await refreshUserSession(payload);

    // Decode new refresh token to get JTI and expiration
    const newRefreshPayload = decodeToken(tokens.refreshToken);
    if (newRefreshPayload) {
      // Create new session for rotated token
      await createSession({
        userId: payload.userId,
        refreshTokenJti: newRefreshPayload.jti,
        tokenFamily: newRefreshPayload.tokenFamily || payload.tokenFamily || newRefreshPayload.jti,
        expiresAt: new Date((newRefreshPayload.exp || 0) * 1000),
      });
    }

    // Log successful refresh
    await logRefreshSuccess(payload.userId, {
      ipAddress,
      oldJti: payload.jti,
      refreshDuration: Date.now() - startTime,
    });

    return NextResponse.json({
      ...tokens,
      message: 'Token refreshed successfully',
    });
  } catch (error: any) {
    console.error('Token refresh error:', error);

    // Log failed refresh
    await logRefreshFailure(error.message || 'Internal server error', {
      userId,
      errorType: error.constructor.name,
      refreshDuration: Date.now() - startTime,
    });

    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}
