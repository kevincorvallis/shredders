/**
 * POST /api/auth/change-password
 *
 * Change password while logged in
 * Verifies current password, updates to new password, revokes other sessions
 */

import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { z } from 'zod';
import { decodeToken } from '@/lib/auth/jwt';
import { revokeAllUserTokens } from '@/lib/auth/token-blacklist';
import { revokeAllUserSessions } from '@/lib/auth/session-manager';
import { logAuthEvent } from '@/lib/auth/audit-log';
import { Errors, handleError } from '@/lib/errors';
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

export const POST = withDualAuth(async (request, authUser) => {
  try {
    const headersList = await headers();
    const ipAddress =
      headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      headersList.get('x-real-ip') ||
      'unknown';

    // Parse and validate request body
    const body = await request.json();
    const result = changePasswordSchema.safeParse(body);

    if (!result.success) {
      return handleError(Errors.validationFailed(
        result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`)
      ));
    }

    const { currentPassword, newPassword, revokeOtherSessions = true } = result.data;

    const adminClient = createAdminClient();

    // Get user's email to verify current password
    const { data: userData, error: userError } = await adminClient.auth.admin.getUserById(authUser.userId);

    if (userError || !userData.user?.email) {
      return handleError(Errors.resourceNotFound('User'));
    }

    // Verify current password by attempting sign in
    const { error: signInError } = await adminClient.auth.signInWithPassword({
      email: userData.user.email,
      password: currentPassword,
    });

    if (signInError) {
      await logAuthEvent({
        userId: authUser.userId,
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
    const { error: updateError } = await adminClient.auth.admin.updateUserById(authUser.userId, {
      password: newPassword,
    });

    if (updateError) {
      console.error('Password update error:', updateError);

      await logAuthEvent({
        userId: authUser.userId,
        eventType: 'password_change',
        success: false,
        ipAddress,
        errorMessage: updateError.message,
      });

      return handleError(Errors.internalError('Failed to update password'));
    }

    // Revoke other sessions if requested (default: true)
    let revokedCount = 0;
    if (revokeOtherSessions) {
      // Get current session JTI from the auth header
      const authHeader = request.headers.get('authorization');
      let currentJti: string | undefined;
      if (authHeader) {
        const token = authHeader.replace('Bearer ', '');
        const payload = decodeToken(token);
        currentJti = payload?.jti;
      }

      // Find current session by JTI
      const { data: sessions } = await adminClient
        .from('user_sessions')
        .select('id')
        .eq('user_id', authUser.userId)
        .eq('refresh_token_jti', currentJti || '')
        .single();

      const currentSessionId = sessions?.id;

      revokedCount = await revokeAllUserSessions(
        authUser.userId,
        'Password changed',
        currentSessionId
      );
    }

    // Log successful password change
    await logAuthEvent({
      userId: authUser.userId,
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
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/auth/change-password' });
  }
});
