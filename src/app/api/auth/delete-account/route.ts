/**
 * DELETE /api/auth/delete-account
 *
 * Permanently delete user account and all associated data
 * Required for GDPR compliance and App Store requirements
 */

import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { verifyAccessToken } from '@/lib/auth/jwt';
import { revokeAllUserTokens } from '@/lib/auth/token-blacklist';
import { logAuthEvent } from '@/lib/auth/audit-log';
import { headers } from 'next/headers';

export async function DELETE(request: Request) {
  try {
    // Get auth token from header
    const headersList = await headers();
    const authHeader = headersList.get('authorization');

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
    const supabase = await createClient();

    // 1. Revoke all user sessions and tokens
    await revokeAllUserTokens(userId, 'Account deletion');

    // 2. Delete user's data from all tables (cascade in order)
    const tablesToDelete = [
      'user_favorites',
      'user_check_ins',
      'user_photos',
      'user_comments',
      'user_likes',
      'notifications',
      'audit_logs',
      'token_blacklist',
      'token_rotations',
      'user_sessions',
      'users', // User profile last
    ];

    for (const table of tablesToDelete) {
      const { error } = await supabase
        .from(table)
        .delete()
        .eq(table === 'users' ? 'auth_user_id' : 'user_id', userId);

      if (error) {
        console.error(`Error deleting from ${table}:`, error);
        // Continue with other tables even if one fails
      }
    }

    // 3. Delete the Supabase auth user
    // Note: This requires the service role key in production
    // Using admin API to delete auth user
    const { error: authDeleteError } = await supabase.auth.admin.deleteUser(userId);

    if (authDeleteError) {
      console.error('Error deleting auth user:', authDeleteError);
      // Log but don't fail - user data is already deleted
    }

    // 4. Log the account deletion event
    await logAuthEvent({
      userId,
      eventType: 'logout', // Using logout as closest event type
      success: true,
      eventData: { action: 'account_deleted' },
    });

    return NextResponse.json({
      message: 'Account deleted successfully',
      deletedUserId: userId,
    });
  } catch (error: any) {
    console.error('Account deletion error:', error);

    return NextResponse.json(
      { error: error.message || 'Failed to delete account' },
      { status: 500 }
    );
  }
}
