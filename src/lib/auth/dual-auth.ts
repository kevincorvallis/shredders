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
  userId: string;
  email: string;
  username?: string;
  authMethod: 'jwt' | 'supabase';
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
    return {
      userId: jwtUser.userId,
      email: jwtUser.email,
      username: jwtUser.username,
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
      // Fetch username from users table
      const { data: profile } = await adminClient
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
  }

  // Fallback to Supabase session cookies (for web clients)
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
