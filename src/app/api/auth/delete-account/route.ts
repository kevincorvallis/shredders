/**
 * DELETE /api/auth/delete-account
 *
 * Permanently delete user account and all associated data
 * Required for GDPR compliance and App Store requirements
 */

import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { revokeAllUserTokens } from '@/lib/auth/token-blacklist';
import { logAuthEvent } from '@/lib/auth/audit-log';
import { Errors, handleError } from '@/lib/errors';

export const DELETE = withDualAuth(async (request, authUser) => {
  try {
    const adminClient = createAdminClient();

    // Look up internal user ID
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.unauthorized('User profile not found'));
    }

    // 1. Revoke all user sessions and tokens
    await revokeAllUserTokens(authUser.userId, 'Account deletion');

    // 2. Delete user row — all social tables (check_ins, comments, likes,
    //    user_photos, event_attendees, push_notification_tokens, etc.)
    //    cascade automatically via ON DELETE CASCADE foreign keys
    const { error: deleteError } = await adminClient
      .from('users')
      .delete()
      .eq('id', userProfile.id);

    if (deleteError) {
      console.error('Error deleting user:', deleteError);
      return handleError(Errors.databaseError());
    }

    // 3. Delete the Supabase auth user
    const { error: authDeleteError } = await adminClient.auth.admin.deleteUser(authUser.userId);

    if (authDeleteError) {
      console.error('Error deleting auth user:', authDeleteError);
      // Log but don't fail — user data is already deleted
    }

    // 4. Log the account deletion event
    await logAuthEvent({
      userId: authUser.userId,
      eventType: 'logout', // Using logout as closest event type
      success: true,
      eventData: { action: 'account_deleted' },
    });

    return NextResponse.json({
      message: 'Account deleted successfully',
    });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/auth/delete-account' });
  }
});
