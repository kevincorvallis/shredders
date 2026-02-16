/**
 * GET /api/auth/user
 * Get current user's profile
 *
 * PUT /api/auth/user
 * Update current user's profile
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { Errors, handleError } from '@/lib/errors';

export async function GET(request: Request) {
  try {
    const supabase = await createClient();

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    // Get user profile from database
    const { data: profile, error } = await supabase
      .from('users')
      .select('*')
      .eq('auth_user_id', user.id)
      .single();

    if (error && error.code !== 'PGRST116') {
      // PGRST116 = not found, which is ok for new users
      console.error('Error fetching user profile:', error);
    }

    return NextResponse.json({
      user,
      profile,
    });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/auth/user' });
  }
}

export async function PUT(request: Request) {
  try {
    const supabase = await createClient();

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    const updates = await request.json();

    // Update user profile
    const { data, error } = await supabase
      .from('users')
      .update({
        display_name: updates.displayName,
        bio: updates.bio,
        avatar_url: updates.avatarUrl,
        home_mountain_id: updates.homeMountainId,
        notification_preferences: updates.notificationPreferences,
        updated_at: new Date().toISOString(),
      })
      .eq('auth_user_id', user.id)
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
}
