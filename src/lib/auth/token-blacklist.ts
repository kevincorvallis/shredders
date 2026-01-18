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
 * @returns Number of sessions revoked
 */
export async function revokeAllUserTokens(
  userId: string,
  reason?: string
): Promise<number> {
  try {
    const supabase = await createClient();
    const revokeReason = reason || 'All tokens revoked';
    const now = new Date().toISOString();

    // 1. Get all active sessions for this user
    const { data: sessions, error: sessionsError } = await supabase
      .from('user_sessions')
      .select('id, refresh_token_jti, expires_at')
      .eq('user_id', userId)
      .is('revoked_at', null)
      .gt('expires_at', now);

    if (sessionsError) {
      console.error('Error fetching user sessions:', sessionsError);
      throw new Error('Failed to fetch user sessions');
    }

    if (!sessions || sessions.length === 0) {
      console.log(`No active sessions found for user ${userId}`);
      return 0;
    }

    // 2. Blacklist all refresh tokens from active sessions
    const blacklistPromises = sessions.map((session) =>
      addToBlacklist({
        jti: session.refresh_token_jti,
        userId,
        expiresAt: new Date(session.expires_at),
        tokenType: 'refresh',
        reason: revokeReason,
      })
    );

    await Promise.all(blacklistPromises);

    // 3. Mark all sessions as revoked
    const { error: revokeError } = await supabase
      .from('user_sessions')
      .update({
        revoked_at: now,
        revoke_reason: revokeReason,
      })
      .eq('user_id', userId)
      .is('revoked_at', null);

    if (revokeError) {
      console.error('Error revoking sessions:', revokeError);
      throw new Error('Failed to revoke sessions');
    }

    // 4. Invalidate all token rotations for this user
    const { error: rotationError } = await supabase
      .from('token_rotations')
      .delete()
      .eq('user_id', userId)
      .gt('expires_at', now);

    if (rotationError) {
      console.error('Error clearing token rotations:', rotationError);
      // Don't throw - this is non-critical
    }

    console.log(`Revoked ${sessions.length} sessions for user ${userId}: ${revokeReason}`);
    return sessions.length;
  } catch (error) {
    console.error('Error revoking all user tokens:', error);
    return 0;
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
