/**
 * Token Rotation System
 *
 * Implements refresh token rotation to detect and prevent token reuse attacks
 * Tracks token families and parent-child relationships
 */

import { createClient } from '@/lib/supabase/server';
import { addToBlacklist, revokeAllUserTokens } from './token-blacklist';

export interface TokenRotationEntry {
  jti: string;
  userId: string;
  tokenFamily: string;
  parentJti: string | null;
  childJti: string | null;
  createdAt: Date;
  usedAt: Date | null;
  expiresAt: Date;
}

/**
 * Record a refresh token usage
 * Tracks when a refresh token is used to generate a new token pair
 *
 * @param params - Rotation parameters
 * @returns The rotation entry
 */
export async function recordTokenRotation(params: {
  jti: string;
  userId: string;
  tokenFamily: string;
  parentJti: string | null;
  childJti: string;
  expiresAt: Date;
}): Promise<void> {
  const supabase = await createClient();

  const { error } = await supabase.from('token_rotations').insert({
    jti: params.jti,
    user_id: params.userId,
    token_family: params.tokenFamily,
    parent_jti: params.parentJti,
    child_jti: params.childJti,
    used_at: new Date().toISOString(),
    expires_at: params.expiresAt.toISOString(),
  });

  if (error) {
    console.error('Error recording token rotation:', error);
    throw new Error('Failed to record token rotation');
  }
}

/**
 * Check if a refresh token has already been used (has a child token)
 * If it has, this indicates a token reuse attack
 *
 * @param jti - JWT ID to check
 * @returns True if the token has been used
 */
export async function isTokenUsed(jti: string): Promise<boolean> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('token_rotations')
    .select('child_jti')
    .eq('jti', jti)
    .single();

  if (error) {
    // Token not found in rotation table - not used yet
    return false;
  }

  return data?.child_jti !== null;
}

/**
 * Detect and handle token reuse attack
 * If a refresh token is reused, revoke all tokens in that family
 *
 * @param jti - JWT ID that was reused
 * @param userId - User ID
 * @param tokenFamily - Token family UUID
 */
export async function handleTokenReuseAttack(params: {
  jti: string;
  userId: string;
  tokenFamily: string;
}): Promise<void> {
  console.warn('[SECURITY] Token reuse detected:', {
    jti: params.jti,
    userId: params.userId,
    tokenFamily: params.tokenFamily,
  });

  // Revoke all tokens for this user
  // This forces the user to re-authenticate
  await revokeAllUserTokens(params.userId);

  // Log the security event
  // (This would integrate with your audit logging system)
  console.error('[SECURITY] All tokens revoked for user due to token reuse:', params.userId);
}

/**
 * Get all tokens in a token family
 *
 * @param tokenFamily - Token family UUID
 * @returns Array of token rotation entries
 */
export async function getTokenFamily(
  tokenFamily: string
): Promise<TokenRotationEntry[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('token_rotations')
    .select('*')
    .eq('token_family', tokenFamily)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching token family:', error);
    return [];
  }

  return (data || []).map((row) => ({
    jti: row.jti,
    userId: row.user_id,
    tokenFamily: row.token_family,
    parentJti: row.parent_jti,
    childJti: row.child_jti,
    createdAt: new Date(row.created_at),
    usedAt: row.used_at ? new Date(row.used_at) : null,
    expiresAt: new Date(row.expires_at),
  }));
}

/**
 * Clean up expired token rotation records
 * Should be run periodically (e.g., daily cron job)
 *
 * @returns Number of records deleted
 */
export async function cleanupExpiredRotations(): Promise<number> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('token_rotations')
    .delete()
    .lt('expires_at', new Date().toISOString())
    .select('jti');

  if (error) {
    console.error('Error cleaning up expired rotations:', error);
    return 0;
  }

  return data?.length || 0;
}

/**
 * Get rotation statistics for monitoring
 */
export async function getRotationStats(): Promise<{
  totalRotations: number;
  activeRotations: number;
  usedRotations: number;
}> {
  const supabase = await createClient();

  const [total, active, used] = await Promise.all([
    supabase.from('token_rotations').select('jti', { count: 'exact', head: true }),
    supabase
      .from('token_rotations')
      .select('jti', { count: 'exact', head: true })
      .gt('expires_at', new Date().toISOString()),
    supabase
      .from('token_rotations')
      .select('jti', { count: 'exact', head: true })
      .not('child_jti', 'is', null),
  ]);

  return {
    totalRotations: total.count || 0,
    activeRotations: active.count || 0,
    usedRotations: used.count || 0,
  };
}
