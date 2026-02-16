/**
 * POST /api/auth/logout
 *
 * Sign out the current user
 * Blacklists JWT tokens to prevent reuse and logs the logout event
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import {
  extractTokenFromHeader,
  decodeToken,
  addToBlacklist,
  logLogout,
} from '@/lib/auth';
import { handleError } from '@/lib/errors';

export async function POST(request: Request) {
  const startTime = Date.now();
  let userId: string | undefined;

  try {
    const supabase = await createClient();

    // Extract and blacklist JWT token if present
    const authHeader = request.headers.get('authorization');
    const token = extractTokenFromHeader(authHeader);

    if (token) {
      // Decode token to get jti and user info
      const payload = decodeToken(token);

      if (payload) {
        userId = payload.userId;

        // Add token to blacklist
        try {
          // Calculate token expiration (access tokens expire in 15 minutes)
          const expiresAt = payload.exp
            ? new Date(payload.exp * 1000)
            : new Date(Date.now() + 15 * 60 * 1000); // Default 15 min if exp not present

          await addToBlacklist({
            jti: payload.jti,
            userId: payload.userId,
            expiresAt,
            tokenType: payload.type || 'access',
            reason: 'User logout',
          });
        } catch (blacklistError) {
          console.error('Error adding token to blacklist:', blacklistError);
          // Continue with logout even if blacklisting fails
        }
      }
    }

    // Sign out from Supabase
    const { error } = await supabase.auth.signOut();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    // Log successful logout
    if (userId) {
      await logLogout(userId, {
        logoutDuration: Date.now() - startTime,
      });
    }

    return NextResponse.json({ message: 'Logged out successfully' });
  } catch (error) {
    // Still try to log the failed logout attempt if we have userId
    if (userId) {
      try {
        await logLogout(userId, {
          logoutDuration: Date.now() - startTime,
          errorMessage: error instanceof Error ? error.message : 'Unknown error',
        });
      } catch (logError) {
        console.error('Error logging failed logout:', logError);
      }
    }

    return handleError(error, { endpoint: 'POST /api/auth/logout' });
  }
}
