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
import { getDualAuthUser, type AuthenticatedUser } from './dual-auth';
import { Errors, handleError } from '../errors';

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
      return handleError(Errors.tokenMissing());
    }

    const payload = verifyAccessToken(token);

    if (!payload) {
      return handleError(Errors.tokenInvalid());
    }

    // Check if token is blacklisted (revoked)
    const blacklisted = await isBlacklisted(payload.jti);
    if (blacklisted) {
      return handleError(Errors.tokenRevoked());
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
 * Middleware to verify dual auth (JWT or Supabase) and pass authenticated user to handler.
 * Returns 401 if not authenticated. Forwards route context (params) for dynamic routes.
 *
 * Usage:
 * ```typescript
 * import { withDualAuth } from '@/lib/auth';
 *
 * // Static route
 * export const POST = withDualAuth(async (req, authUser) => {
 *   // authUser is guaranteed to exist
 * });
 *
 * // Dynamic route
 * export const POST = withDualAuth(async (req, authUser, { params }) => {
 *   const { id } = await params;
 * });
 * ```
 */
export function withDualAuth<C = unknown>(
  handler: (req: NextRequest, authUser: AuthenticatedUser, context: C) => Promise<NextResponse>
) {
  return async (req: NextRequest, context: C): Promise<NextResponse> => {
    const authUser = await getDualAuthUser(req);
    if (!authUser) {
      return handleError(Errors.unauthorized('Not authenticated'));
    }
    return handler(req, authUser, context);
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
