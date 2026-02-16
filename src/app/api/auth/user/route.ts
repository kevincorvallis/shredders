/**
 * GET /api/auth/user
 * Get current user's profile
 *
 * PUT /api/auth/user
 * Update current user's profile
 */

import { createAdminClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

export const GET = withDualAuth(async (request, authUser) => {
  try {
    const adminClient = createAdminClient();

    // Get user profile from database
    const { data: profile, error } = await adminClient
      .from('users')
      .select('*')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (error && error.code !== 'PGRST116') {
      // PGRST116 = not found, which is ok for new users
      console.error('Error fetching user profile:', error);
    }

    return NextResponse.json({ profile });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/auth/user' });
  }
});

export const PUT = withDualAuth(async (request, authUser) => {
  try {
    const adminClient = createAdminClient();
    const updates = await request.json();

    // Update user profile
    const { data, error } = await adminClient
      .from('users')
      .update({
        display_name: updates.displayName,
        bio: updates.bio,
        avatar_url: updates.avatarUrl,
        home_mountain_id: updates.homeMountainId,
        notification_preferences: updates.notificationPreferences,
        updated_at: new Date().toISOString(),
      })
      .eq('auth_user_id', authUser.userId)
      .select()
      .single();

    if (error) {
      console.error('Error updating user profile:', error);
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({
      profile: data,
      message: 'Profile updated successfully',
    });
  } catch (error) {
    return handleError(error, { endpoint: 'PUT /api/auth/user' });
  }
});
