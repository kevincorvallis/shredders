import { createAdminClient } from '@/lib/supabase/server';
import { Errors } from '@/lib/errors';
import type { AuthenticatedUser } from '@/lib/auth/dual-auth';

/**
 * Resolve the internal users.id from an authenticated user.
 *
 * Uses the cached profileId from getDualAuthUser when available,
 * falling back to a database lookup by auth_user_id.
 *
 * @returns The internal users.id (NOT auth_user_id)
 * @throws Errors.resourceNotFound if the user profile doesn't exist
 */
export async function getUserProfileId(authUser: AuthenticatedUser): Promise<string> {
  // Fast path: profileId is cached in getDualAuthUser
  if (authUser.profileId) {
    return authUser.profileId;
  }

  // Fallback: database lookup
  const adminClient = createAdminClient();
  const { data: userProfile, error } = await adminClient
    .from('users')
    .select('id')
    .eq('auth_user_id', authUser.userId)
    .single();

  if (error || !userProfile) {
    throw Errors.resourceNotFound('User profile');
  }

  return userProfile.id;
}
