/**
 * POST /api/auth/change-password
 *
 * Change password while logged in
 * Verifies current password, updates to new password, revokes other sessions
 */

import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { z } from 'zod';
import { verifyAccessToken, decodeToken } from '@/lib/auth/jwt';
import { revokeAllUserTokens } from '@/lib/auth/token-blacklist';
import { revokeAllUserSessions, getSessionById } from '@/lib/auth/session-manager';
import { logAuthEvent } from '@/lib/auth/audit-log';
import { headers } from 'next/headers';

const changePasswordSchema = z.object({
  currentPassword: z
    .string()
    .min(1, 'Current password is required'),
  newPassword: z
    .string()
    .min(12, 'Password must be at least 12 characters')
    .max(128, 'Password must be less than 128 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number')
    .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character'),
  revokeOtherSessions: z
    .boolean()
    .default(true)
    .optional(),
});

export async function POST(request: Request) {
  try {
    // Get auth token from header
    const headersList = await headers();
    const authHeader = headersList.get('authorization');
    const ipAddress =
      headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      headersList.get('x-real-ip') ||
      'unknown';

    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json(
        { error: 'Unauthorized - no token provided' },
        { status: 401 }
      );
    }

    const token = authHeader.slice(7);
    const payload = verifyAccessToken(token);

    if (!payload) {
      return NextResponse.json(
        { error: 'Unauthorized - invalid token' },
        { status: 401 }
      );
    }

    const userId = payload.userId;
    const currentSessionJti = payload.jti;

    // Parse and validate request body
    const body = await request.json();
    const result = changePasswordSchema.safeParse(body);

    if (!result.success) {
      return NextResponse.json(
        {
          error: 'Validation failed',
          details: result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`),
        },
        { status: 400 }
      );
    }

    const { currentPassword, newPassword, revokeOtherSessions = true } = result.data;

    const supabase = await createClient();

    // Get user's email to verify current password
    const { data: userData, error: userError } = await supabase.auth.admin.getUserById(userId);

    if (userError || !userData.user?.email) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    // Verify current password by attempting sign in
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: userData.user.email,
      password: currentPassword,
    });

    if (signInError) {
      await logAuthEvent({
        userId,
        eventType: 'password_change',
        success: false,
        ipAddress,
        errorMessage: 'Invalid current password',
      });

      return NextResponse.json(
        { error: 'Current password is incorrect' },
        { status: 401 }
      );
    }

    // Update password
    const { error: updateError } = await supabase.auth.admin.updateUserById(userId, {
      password: newPassword,
    });

    if (updateError) {
      console.error('Password update error:', updateError);

      await logAuthEvent({
        userId,
        eventType: 'password_change',
        success: false,
        ipAddress,
        errorMessage: updateError.message,
      });

      return NextResponse.json(
        { error: 'Failed to update password' },
        { status: 500 }
      );
    }

    // Revoke other sessions if requested (default: true)
    let revokedCount = 0;
    if (revokeOtherSessions) {
      // Get current session ID to exclude
      const { data: sessions } = await supabase
        .from('user_sessions')
        .select('id')
        .eq('user_id', userId)
        .eq('refresh_token_jti', currentSessionJti)
        .single();

      const currentSessionId = sessions?.id;

      revokedCount = await revokeAllUserSessions(
        userId,
        'Password changed',
        currentSessionId
      );
    }

    // Log successful password change
    await logAuthEvent({
      userId,
      eventType: 'password_change',
      success: true,
      ipAddress,
      eventData: {
        revokedSessions: revokedCount,
        revokeOtherSessions,
      },
    });

    return NextResponse.json({
      message: 'Password changed successfully',
      revokedSessions: revokedCount,
    });
  } catch (error: any) {
    console.error('Change password error:', error);

    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}
