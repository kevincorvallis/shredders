/**
 * Auth Middleware for API Routes
 *
 * Use this middleware to protect API routes requiring authentication
 * Pattern inspired by IWBH's authenticateToken and optionalAuth middleware
 */

import { NextRequest, NextResponse } from 'next/server';
import {
  extractTokenFromHeader,
  verifyAccessToken,
  type TokenPayload,
} from './jwt';
import { isBlacklisted } from './token-blacklist';

export interface AuthenticatedRequest extends NextRequest {
  user?: TokenPayload;
}

/**
 * Middleware to verify JWT token and attach user to request
 * Returns 401 if token missing, 403 if invalid
 *
 * Usage:
 * ```typescript
 * import { withAuth } from '@/lib/auth';
 *
 * async function handler(req: AuthenticatedRequest) {
 *   const userId = req.user?.userId;
 *   // ... your logic
 * }
 *
 * export const GET = withAuth(handler);
 * ```
 */
export function withAuth(
  handler: (req: AuthenticatedRequest) => Promise<NextResponse>
) {
  return async (req: NextRequest): Promise<NextResponse> => {
    const authHeader = req.headers.get('authorization');
    const token = extractTokenFromHeader(authHeader);

    if (!token) {
      return NextResponse.json(
        { error: 'Missing authentication token' },
        { status: 401 }
      );
    }

    const payload = verifyAccessToken(token);

    if (!payload) {
      return NextResponse.json(
        { error: 'Invalid or expired token' },
        { status: 403 }
      );
    }

    // Check if token is blacklisted (revoked)
    const blacklisted = await isBlacklisted(payload.jti);
    if (blacklisted) {
      return NextResponse.json(
        { error: 'Token has been revoked' },
        { status: 401 }
      );
    }

    // Attach user info to request
    const authenticatedReq = req as AuthenticatedRequest;
    authenticatedReq.user = payload;

    return handler(authenticatedReq);
  };
}

/**
 * Middleware that optionally verifies token (doesn't fail if missing)
 * Sets req.user if valid token present, but allows request to proceed either way
 *
 * Usage:
 * ```typescript
 * import { withOptionalAuth } from '@/lib/auth';
 *
 * async function handler(req: AuthenticatedRequest) {
 *   if (req.user) {
 *     // User is authenticated
 *   } else {
 *     // Anonymous user
 *   }
 * }
 *
 * export const GET = withOptionalAuth(handler);
 * ```
 */
export function withOptionalAuth(
  handler: (req: AuthenticatedRequest) => Promise<NextResponse>
) {
  return async (req: NextRequest): Promise<NextResponse> => {
    const authHeader = req.headers.get('authorization');
    const token = extractTokenFromHeader(authHeader);

    if (token) {
      const payload = verifyAccessToken(token);
      if (payload) {
        // Check if token is blacklisted
        const blacklisted = await isBlacklisted(payload.jti);
        if (!blacklisted) {
          const authenticatedReq = req as AuthenticatedRequest;
          authenticatedReq.user = payload;
        }
      }
    }

    return handler(req as AuthenticatedRequest);
  };
}

/**
 * Helper to get authenticated user from request
 * Returns null if no valid token present or if token is blacklisted
 */
export async function getAuthUserAsync(req: NextRequest): Promise<TokenPayload | null> {
  const authHeader = req.headers.get('authorization');
  const token = extractTokenFromHeader(authHeader);

  if (!token) {
    return null;
  }

  const payload = verifyAccessToken(token);
  if (!payload) {
    return null;
  }

  // Check blacklist
  const blacklisted = await isBlacklisted(payload.jti);
  if (blacklisted) {
    return null;
  }

  return payload;
}

/**
 * @deprecated SECURITY: This sync version does NOT check the token blacklist.
 * Use getAuthUserAsync() instead, which properly checks for revoked tokens.
 * This function will be removed in a future release.
 */
export function getAuthUser(req: NextRequest): TokenPayload | null {
  const authHeader = req.headers.get('authorization');
  const token = extractTokenFromHeader(authHeader);

  if (!token) {
    return null;
  }

  return verifyAccessToken(token);
}

/**
 * Helper to require authenticated user
 * Throws error if user not authenticated or token is blacklisted
 */
export async function requireAuth(req: NextRequest): Promise<TokenPayload> {
  const user = await getAuthUserAsync(req);

  if (!user) {
    throw new Error('Authentication required');
  }

  return user;
}
