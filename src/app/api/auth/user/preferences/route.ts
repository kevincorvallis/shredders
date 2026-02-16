import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { withDualAuth } from '@/lib/auth';
import type { AuthenticatedUser } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

// GET - Fetch user preferences
export const GET = withDualAuth(async (request: NextRequest, authUser: AuthenticatedUser) => {
  try {
    const adminClient = createAdminClient();

    const { data: user, error } = await adminClient
      .from('users')
      .select('id, favorite_mountain_ids, units_preference')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (error || !user) {
      return handleError(Errors.resourceNotFound('User'));
    }

    return NextResponse.json({
      favoriteMountainIds: user.favorite_mountain_ids || [],
      unitsPreference: user.units_preference || 'imperial'
    });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/auth/user/preferences' });
  }
});

// PATCH - Update user preferences
export const PATCH = withDualAuth(async (request: NextRequest, authUser: AuthenticatedUser) => {
  try {
    let body;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
    }

    const { favoriteMountainIds, unitsPreference } = body;

    // Validate favoriteMountainIds
    if (favoriteMountainIds !== undefined) {
      if (!Array.isArray(favoriteMountainIds)) {
        return NextResponse.json({ error: 'favoriteMountainIds must be an array' }, { status: 400 });
      }
      if (favoriteMountainIds.length > 5) {
        return NextResponse.json({ error: 'Maximum 5 favorites allowed' }, { status: 400 });
      }
      // Ensure all items are strings
      if (!favoriteMountainIds.every(id => typeof id === 'string')) {
        return NextResponse.json({ error: 'favoriteMountainIds must contain only strings' }, { status: 400 });
      }
    }

    // Validate unitsPreference
    if (unitsPreference !== undefined && !['imperial', 'metric'].includes(unitsPreference)) {
      return NextResponse.json({ error: 'Invalid units preference' }, { status: 400 });
    }

    const adminClient = createAdminClient();

    // Build update object with only provided fields
    const updateData: Record<string, unknown> = {
      updated_at: new Date().toISOString()
    };
    if (favoriteMountainIds !== undefined) {
      updateData.favorite_mountain_ids = favoriteMountainIds;
    }
    if (unitsPreference !== undefined) {
      updateData.units_preference = unitsPreference;
    }

    const { data: user, error } = await adminClient
      .from('users')
      .update(updateData)
      .eq('auth_user_id', authUser.userId)
      .select('id, favorite_mountain_ids, units_preference')
      .single();

    if (error) {
      console.error('Error updating preferences:', error);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({
      favoriteMountainIds: user.favorite_mountain_ids || [],
      unitsPreference: user.units_preference || 'imperial'
    });
  } catch (error) {
    return handleError(error, { endpoint: 'PATCH /api/auth/user/preferences' });
  }
});
