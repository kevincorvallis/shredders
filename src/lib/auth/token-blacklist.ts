/**
 * Token Blacklist System
 *
 * Manages revoked JWT tokens to prevent reuse after logout or compromise
 * Uses database for persistence (can be upgraded to Redis for production)
 */

import { createClient } from '@/lib/supabase/server';

export interface BlacklistEntry {
  jti: string;
  userId: string;
  expiresAt: Date;
  revokedAt: Date;
  reason?: string;
  tokenType: 'access' | 'refresh';
}

/**
 * Add a token to the blacklist
 *
 * @param jti - JWT ID from token payload
 * @param userId - User who owns the token
 * @param expiresAt - When the token naturally expires
 * @param tokenType - Type of token (access or refresh)
 * @param reason - Optional reason for revocation
 */
export async function addToBlacklist(params: {
  jti: string;
  userId: string;
  expiresAt: Date;
  tokenType: 'access' | 'refresh';
  reason?: string;
}): Promise<void> {
  try {
    const supabase = await createClient();

    const { error } = await supabase
      .from('token_blacklist')
      .insert({
        jti: params.jti,
        user_id: params.userId,
        expires_at: params.expiresAt.toISOString(),
        revoked_at: new Date().toISOString(),
        reason: params.reason || null,
        token_type: params.tokenType,
      });

    if (error) {
      console.error('Error adding token to blacklist:', error);
      throw new Error('Failed to blacklist token');
    }
  } catch (error) {
    console.error('Blacklist error:', error);
    // Don't throw - blacklist failure shouldn't break auth flow
    // In production, log to monitoring service
  }
}

/**
 * Check if a token is blacklisted
 *
 * @param jti - JWT ID from token payload
 * @returns true if token is blacklisted, false otherwise
 */
export async function isBlacklisted(jti: string): Promise<boolean> {
  try {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from('token_blacklist')
      .select('jti')
      .eq('jti', jti)
      .maybeSingle();

    if (error) {
      console.error('Error checking blacklist:', error);
      // Fail open - don't block valid tokens due to DB errors
      return false;
    }

    return !!data;
  } catch (error) {
    console.error('Blacklist check error:', error);
    // Fail open - don't block valid tokens
    return false;
  }
}

/**
 * Revoke all tokens for a user
 * Useful for security events like password change or account compromise
 *
 * @param userId - User ID
 * @param reason - Reason for revocation
 */
export async function revokeAllUserTokens(
  userId: string,
  reason?: string
): Promise<void> {
  try {
    const supabase = await createClient();

    // This requires tracking active tokens in a sessions table
    // For now, we'll just add a marker to indicate user needs re-auth
    // TODO: Implement when session tracking is added in Sprint 2

    console.log(`Revoke all tokens for user ${userId}: ${reason || 'No reason provided'}`);
  } catch (error) {
    console.error('Error revoking all user tokens:', error);
  }
}

/**
 * Cleanup expired tokens from blacklist
 * Should be run as a scheduled job (cron/background task)
 *
 * Removes tokens that have naturally expired and are no longer needed
 */
export async function cleanupExpiredTokens(): Promise<number> {
  try {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from('token_blacklist')
      .delete()
      .lt('expires_at', new Date().toISOString())
      .select('jti');

    if (error) {
      console.error('Error cleaning up expired tokens:', error);
      return 0;
    }

    const count = data?.length || 0;
    console.log(`Cleaned up ${count} expired tokens from blacklist`);
    return count;
  } catch (error) {
    console.error('Cleanup error:', error);
    return 0;
  }
}

/**
 * Get blacklist statistics
 * Useful for monitoring and debugging
 */
export async function getBlacklistStats(): Promise<{
  total: number;
  access: number;
  refresh: number;
  expired: number;
}> {
  try {
    const supabase = await createClient();
    const now = new Date().toISOString();

    const { data: all } = await supabase
      .from('token_blacklist')
      .select('token_type, expires_at');

    if (!all) {
      return { total: 0, access: 0, refresh: 0, expired: 0 };
    }

    const stats = {
      total: all.length,
      access: all.filter(t => t.token_type === 'access').length,
      refresh: all.filter(t => t.token_type === 'refresh').length,
      expired: all.filter(t => t.expires_at < now).length,
    };

    return stats;
  } catch (error) {
    console.error('Error getting blacklist stats:', error);
    return { total: 0, access: 0, refresh: 0, expired: 0 };
  }
}
