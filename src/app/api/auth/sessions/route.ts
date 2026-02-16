/**
 * GET /api/auth/sessions
 * List all active sessions for the authenticated user
 *
 * DELETE /api/auth/sessions
 * Revoke all sessions except the current one
 */

import { NextRequest, NextResponse } from 'next/server';
import { getDualAuthUser } from '@/lib/auth/dual-auth';
import {
  getUserSessions,
  revokeAllUserSessions,
  getSessionStats,
} from '@/lib/auth/session-manager';
import { Errors, handleError } from '@/lib/errors';
import { decodeToken } from '@/lib/auth/jwt';

/**
 * GET /api/auth/sessions
 * List all active sessions with device and location information
 */
export async function GET(request: NextRequest) {
  try {
    // Authenticate user (supports both JWT and Supabase auth)
    const user = await getDualAuthUser(request);
    if (!user) {
      throw Errors.unauthorized();
    }

    // Get current session JTI from Authorization header
    const authHeader = request.headers.get('authorization');
    let currentJti: string | undefined;
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      const payload = decodeToken(token);
      currentJti = payload?.jti;
    }

    // Get all active sessions
    const sessions = await getUserSessions(user.userId, currentJti);

    // Get session statistics
    const stats = await getSessionStats(user.userId);

    return NextResponse.json({
      sessions: sessions.map((session) => ({
        id: session.id,
        device: {
          type: session.deviceInfo.deviceType,
          name: session.deviceInfo.deviceName,
          browser: session.deviceInfo.browser
            ? `${session.deviceInfo.browser} ${session.deviceInfo.browserVersion || ''}`
            : undefined,
          os: session.deviceInfo.os
            ? `${session.deviceInfo.os} ${session.deviceInfo.osVersion || ''}`
            : undefined,
        },
        location: {
          ip: session.locationInfo.ipAddress,
          city: session.locationInfo.city,
          region: session.locationInfo.region,
          country: session.locationInfo.country,
        },
        createdAt: session.createdAt.toISOString(),
        lastActivityAt: session.lastActivityAt.toISOString(),
        expiresAt: session.expiresAt.toISOString(),
        isCurrent: session.isCurrentSession,
      })),
      stats: {
        total: stats.totalSessions,
        active: stats.activeSessions,
        revoked: stats.revokedSessions,
        uniqueDevices: stats.uniqueDevices,
        uniqueIPs: stats.uniqueIPs,
      },
    });
  } catch (error) {
    return handleError(error, { endpoint: 'sessions-list' });
  }
}

/**
 * DELETE /api/auth/sessions
 * Revoke all sessions except the current one
 */
export async function DELETE(request: NextRequest) {
  try {
    // Authenticate user (supports both JWT and Supabase auth)
    const user = await getDualAuthUser(request);
    if (!user) {
      throw Errors.unauthorized();
    }

    // Get current session ID from request body (optional)
    const body = await request.json().catch(() => ({}));
    const { currentSessionId } = body;

    // Revoke all sessions except current
    const revokedCount = await revokeAllUserSessions(
      user.userId,
      'User revoked all sessions',
      currentSessionId
    );

    return NextResponse.json({
      message: 'All sessions revoked successfully',
      revokedCount,
    });
  } catch (error) {
    return handleError(error, { endpoint: 'sessions-revoke-all' });
  }
}
