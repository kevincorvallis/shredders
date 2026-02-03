/**
 * Dual Authentication Helper
 *
 * Support both JWT bearer tokens and Supabase session cookies
 * for backward compatibility during migration
 */

import { NextRequest } from 'next/server';
import { getAuthUser } from './middleware';
import { extractTokenFromHeader } from './jwt';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';

export interface AuthenticatedUser {
  userId: string;        // auth_user_id (from Supabase Auth or JWT)
  profileId?: string;    // users.id (internal database ID) - OPTIMIZATION: included to avoid repeated lookups
  email: string;
  username?: string;
  authMethod: 'jwt' | 'supabase';
}

// OPTIMIZATION: In-memory cache for auth_user_id -> users.id mapping
// This avoids repeated database lookups for the same user
const userProfileCache = new Map<string, { profileId: string; username?: string; cachedAt: number }>();
const PROFILE_CACHE_TTL = 5 * 60 * 1000; // 5 minutes

function getCachedProfile(authUserId: string): { profileId: string; username?: string } | null {
  const cached = userProfileCache.get(authUserId);
  if (cached && Date.now() - cached.cachedAt < PROFILE_CACHE_TTL) {
    return { profileId: cached.profileId, username: cached.username };
  }
  if (cached) {
    userProfileCache.delete(authUserId); // Expired
  }
  return null;
}

function setCachedProfile(authUserId: string, profileId: string, username?: string): void {
  userProfileCache.set(authUserId, { profileId, username, cachedAt: Date.now() });
}

/**
 * Clear cached profile for a user (call on profile updates)
 */
export function clearUserProfileCache(authUserId: string): void {
  userProfileCache.delete(authUserId);
}

/**
 * Get authenticated user from either JWT token or Supabase session
 * Tries in order:
 * 1. Custom JWT (email/password login)
 * 2. Supabase Bearer token (Apple Sign In)
 * 3. Supabase session cookies (web clients)
 *
 * @param req - Next.js request object
 * @returns Authenticated user or null if not authenticated
 *
 * @example
 * ```typescript
 * const user = await getDualAuthUser(req);
 * if (!user) {
 *   return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
 * }
 * // Use user.userId for database queries
 * ```
 */
export async function getDualAuthUser(
  req: NextRequest
): Promise<AuthenticatedUser | null> {
  // Try custom JWT first (for email/password login via backend)
  const jwtUser = getAuthUser(req);

  if (jwtUser) {
    // OPTIMIZATION: Check cache first for profile lookup
    const cached = getCachedProfile(jwtUser.userId);
    if (cached) {
      return {
        userId: jwtUser.userId,
        profileId: cached.profileId,
        email: jwtUser.email,
        username: cached.username || jwtUser.username,
        authMethod: 'jwt',
      };
    }

    // Cache miss - fetch from database
    const adminClient = createAdminClient();
    const { data: profile } = await adminClient
      .from('users')
      .select('id, username')
      .eq('auth_user_id', jwtUser.userId)
      .single();

    if (profile) {
      setCachedProfile(jwtUser.userId, profile.id, profile.username);
    }

    return {
      userId: jwtUser.userId,
      profileId: profile?.id,
      email: jwtUser.email,
      username: profile?.username || jwtUser.username,
      authMethod: 'jwt',
    };
  }

  // Try to extract Bearer token and verify as Supabase token (for Apple Sign In)
  const authHeader = req.headers.get('authorization');
  const bearerToken = extractTokenFromHeader(authHeader);

  if (bearerToken) {
    // Use admin client to verify the Supabase JWT token
    const adminClient = createAdminClient();
    const { data: { user: supabaseUser }, error } = await adminClient.auth.getUser(bearerToken);

    if (supabaseUser && !error) {
      // OPTIMIZATION: Check cache first
      const cached = getCachedProfile(supabaseUser.id);
      if (cached) {
        return {
          userId: supabaseUser.id,
          profileId: cached.profileId,
          email: supabaseUser.email || '',
          username: cached.username,
          authMethod: 'supabase',
        };
      }

      // Cache miss - fetch from database
      const { data: profile } = await adminClient
        .from('users')
        .select('id, username')
        .eq('auth_user_id', supabaseUser.id)
        .single();

      if (profile) {
        setCachedProfile(supabaseUser.id, profile.id, profile.username);
      }

      return {
        userId: supabaseUser.id,
        profileId: profile?.id,
        email: supabaseUser.email || '',
        username: profile?.username,
        authMethod: 'supabase',
      };
    }
  }

  // Fallback to Supabase session cookies (for web clients)
  const supabase = await createClient();
  const {
    data: { user: supabaseUser },
  } = await supabase.auth.getUser();

  if (supabaseUser) {
    // OPTIMIZATION: Check cache first
    const cached = getCachedProfile(supabaseUser.id);
    if (cached) {
      return {
        userId: supabaseUser.id,
        profileId: cached.profileId,
        email: supabaseUser.email || '',
        username: cached.username,
        authMethod: 'supabase',
      };
    }

    // Cache miss - fetch from database
    const { data: profile } = await supabase
      .from('users')
      .select('id, username')
      .eq('auth_user_id', supabaseUser.id)
      .single();

    if (profile) {
      setCachedProfile(supabaseUser.id, profile.id, profile.username);
    }

    return {
      userId: supabaseUser.id,
      profileId: profile?.id,
      email: supabaseUser.email || '',
      username: profile?.username,
      authMethod: 'supabase',
    };
  }

  return null;
}

/**
 * Require authenticated user from either JWT or Supabase
 * Throws error if not authenticated
 *
 * @param req - Next.js request object
 * @returns Authenticated user
 * @throws Error if user not authenticated
 *
 * @example
 * ```typescript
 * try {
 *   const user = await requireDualAuth(req);
 *   // User is guaranteed to exist here
 * } catch (error) {
 *   return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
 * }
 * ```
 */
export async function requireDualAuth(
  req: NextRequest
): Promise<AuthenticatedUser> {
  const user = await getDualAuthUser(req);

  if (!user) {
    throw new Error('Authentication required');
  }

  return user;
}
