/**
 * Authentication Helper Functions
 *
 * Utilities for common auth operations integrating Supabase with JWT tokens
 */

import { createClient } from '@/lib/supabase/server';
import { generateTokenPair, type TokenPayload } from './jwt';
import { addToBlacklist } from './token-blacklist';
import {
  isTokenUsed,
  handleTokenReuseAttack,
  recordTokenRotation,
} from './token-rotation';

/**
 * Create auth tokens for a user
 * Fetches user details from database and generates JWT token pair
 */
export async function createUserTokens(userId: string) {
  const supabase = await createClient();

  // Fetch user details from users table
  const { data: user, error } = await supabase
    .from('users')
    .select('auth_user_id, email, username')
    .eq('auth_user_id', userId)
    .single();

  if (error || !user) {
    throw new Error('User not found');
  }

  const payload: Omit<TokenPayload, 'type' | 'jti' | 'iat' | 'exp' | 'iss' | 'aud'> = {
    userId: user.auth_user_id,
    email: user.email,
    username: user.username || undefined,
  };

  return generateTokenPair(payload);
}

/**
 * Validate user credentials and return tokens
 * Combines Supabase authentication with JWT token generation
 */
export async function authenticateUser(email: string, password: string) {
  const supabase = await createClient();

  // Authenticate with Supabase
  const { data: authData, error: authError } =
    await supabase.auth.signInWithPassword({
      email,
      password,
    });

  if (authError || !authData.user) {
    throw new Error('Invalid credentials');
  }

  // Update last login timestamp
  await supabase
    .from('users')
    .update({ last_login_at: new Date().toISOString() })
    .eq('auth_user_id', authData.user.id);

  // Generate JWT tokens
  const tokens = await createUserTokens(authData.user.id);

  return {
    user: authData.user,
    tokens,
  };
}

/**
 * Refresh user session with token rotation
 * Implements refresh token rotation to detect and prevent reuse attacks
 *
 * @param oldTokenPayload - The old refresh token payload
 * @returns New token pair
 * @throws Error if token has been reused (security attack detected)
 */
export async function refreshUserSession(oldTokenPayload: TokenPayload) {
  const supabase = await createClient();

  // 1. Check if this refresh token has already been used
  const tokenUsed = await isTokenUsed(oldTokenPayload.jti);

  if (tokenUsed) {
    // TOKEN REUSE DETECTED - This is a security attack!
    // Revoke all tokens for this user to force re-authentication
    await handleTokenReuseAttack({
      jti: oldTokenPayload.jti,
      userId: oldTokenPayload.userId,
      tokenFamily: oldTokenPayload.tokenFamily || 'unknown',
    });

    throw new Error('Token reuse detected. All sessions have been revoked for security.');
  }

  // 2. Fetch user details for new tokens
  const { data: user, error } = await supabase
    .from('users')
    .select('auth_user_id, email, username')
    .eq('auth_user_id', oldTokenPayload.userId)
    .single();

  if (error || !user) {
    throw new Error('User not found');
  }

  // 3. Generate new token pair with rotation
  // Token family is inherited from the old token
  const payload: Omit<TokenPayload, 'type' | 'jti' | 'iat' | 'exp' | 'iss' | 'aud'> = {
    userId: user.auth_user_id,
    email: user.email,
    username: user.username || undefined,
    tokenFamily: oldTokenPayload.tokenFamily, // Inherit token family
  };

  const newTokens = generateTokenPair(payload, {
    parentJti: oldTokenPayload.jti, // Track parent for rotation chain
  });

  // 4. Blacklist the old refresh token
  // It can only be used once - this prevents reuse
  const expiresAt = oldTokenPayload.exp
    ? new Date(oldTokenPayload.exp * 1000)
    : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days default

  await addToBlacklist({
    jti: oldTokenPayload.jti,
    userId: oldTokenPayload.userId,
    expiresAt,
    tokenType: 'refresh',
    reason: 'Token rotated',
  });

  // 5. Record the rotation for tracking
  // This allows us to detect reuse attempts
  // Note: We decode the new refresh token to get its JTI
  const { decodeToken } = await import('./jwt');
  const newRefreshPayload = decodeToken(newTokens.refreshToken);

  if (newRefreshPayload) {
    await recordTokenRotation({
      jti: oldTokenPayload.jti,
      userId: oldTokenPayload.userId,
      tokenFamily: oldTokenPayload.tokenFamily || oldTokenPayload.jti, // Use jti as family if not set
      parentJti: oldTokenPayload.parentJti || null,
      childJti: newRefreshPayload.jti,
      expiresAt,
    });
  }

  return newTokens;
}

/**
 * Logout helper
 * Updates logout timestamp (optional - for token blacklisting if implemented)
 */
export async function logoutUser(userId: string, token?: string) {
  // If using a token blacklist (Redis, DB), add the token here
  // For now, we rely on client-side token removal

  const supabase = await createClient();

  // Optionally update logout time for tracking
  await supabase
    .from('users')
    .update({ last_logout_at: new Date().toISOString() })
    .eq('auth_user_id', userId)
    .select();

  return { success: true };
}

/**
 * Get user by ID
 * Fetches complete user profile from database
 */
export async function getUserById(userId: string) {
  const supabase = await createClient();

  const { data: user, error } = await supabase
    .from('users')
    .select('*')
    .eq('auth_user_id', userId)
    .single();

  if (error) {
    throw new Error('User not found');
  }

  return user;
}

/**
 * Check if user exists
 * Returns boolean indicating if user with given email exists
 */
export async function userExists(email: string): Promise<boolean> {
  const supabase = await createClient();

  const { data } = await supabase
    .from('users')
    .select('id')
    .eq('email', email)
    .single();

  return !!data;
}
