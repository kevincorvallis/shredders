/**
 * DELETE /api/auth/sessions/[id]
 * Revoke a specific session by ID
 */

import { NextRequest, NextResponse } from 'next/server';
import { getDualAuthUser } from '@/lib/auth/dual-auth';
import { getSessionById, revokeSession } from '@/lib/auth/session-manager';
import { Errors, handleError } from '@/lib/errors';
import { addToBlacklist } from '@/lib/auth/token-blacklist';

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    // Authenticate user
    const user = await getDualAuthUser(request);
    if (!user) {
      throw Errors.unauthorized();
    }

    const resolvedParams = await params;
    const sessionId = resolvedParams.id;

    // Get the session to verify ownership
    const session = await getSessionById(sessionId);
    if (!session) {
      throw Errors.resourceNotFound('Session');
    }

    // Verify user owns this session
    if (session.userId !== user.userId) {
      throw Errors.forbidden('You can only revoke your own sessions');
    }

    // Check if already revoked
    if (session.revokedAt) {
      return NextResponse.json(
        { message: 'Session already revoked' },
        { status: 200 }
      );
    }

    // Revoke the session
    await revokeSession(sessionId, 'User revoked session');

    // Blacklist the refresh token associated with this session
    await addToBlacklist({
      jti: session.refreshTokenJti,
      userId: session.userId,
      expiresAt: session.expiresAt,
      tokenType: 'refresh',
      reason: 'Session revoked by user',
    });

    return NextResponse.json({
      message: 'Session revoked successfully',
      sessionId,
    });
  } catch (error) {
    return handleError(error, { endpoint: 'session-revoke' });
  }
}
