/**
 * Dual Authentication Helper
 *
 * Support both JWT bearer tokens and Supabase session cookies
 * for backward compatibility during migration
 */

import { NextRequest } from 'next/server';
import { getAuthUser } from './middleware';
import { createClient } from '@/lib/supabase/server';

export interface AuthenticatedUser {
  userId: string;
  email: string;
  username?: string;
  authMethod: 'jwt' | 'supabase';
}

/**
 * Get authenticated user from either JWT token or Supabase session
 * Tries JWT first, then falls back to Supabase
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
  // Try JWT first
  const jwtUser = getAuthUser(req);

  if (jwtUser) {
    return {
      userId: jwtUser.userId,
      email: jwtUser.email,
      username: jwtUser.username,
      authMethod: 'jwt',
    };
  }

  // Fallback to Supabase session
  const supabase = await createClient();
  const {
    data: { user: supabaseUser },
  } = await supabase.auth.getUser();

  if (supabaseUser) {
    // Fetch username from users table
    const { data: profile } = await supabase
      .from('users')
      .select('username')
      .eq('auth_user_id', supabaseUser.id)
      .single();

    return {
      userId: supabaseUser.id,
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
