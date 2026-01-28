/**
 * Audit Logging System
 *
 * Tracks all authentication and security events for compliance,
 * troubleshooting, and breach detection
 */

import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { headers } from 'next/headers';

export type AuditEventType =
  | 'login'
  | 'login_failed'
  | 'signup'
  | 'signup_failed'
  | 'refresh'
  | 'refresh_failed'
  | 'logout'
  | 'update_profile'
  | 'password_change'
  | 'token_revoked'
  | 'unauthorized_access'
  | 'rate_limit_exceeded';

export interface AuditLogParams {
  userId?: string; // Null for failed events without user
  eventType: AuditEventType;
  success: boolean;
  ipAddress?: string;
  userAgent?: string;
  eventData?: Record<string, any>; // Additional context
  errorMessage?: string;
}

/**
 * Log an authentication event
 *
 * @param params - Event parameters
 *
 * @example
 * await logAuthEvent({
 *   userId: user.id,
 *   eventType: 'login',
 *   success: true,
 *   ipAddress: req.headers.get('x-forwarded-for'),
 *   eventData: { method: 'password' }
 * });
 */
export async function logAuthEvent(params: AuditLogParams): Promise<void> {
  try {
    // Use admin client to bypass RLS - audit logs are system operations
    const supabase = createAdminClient();

    const { error } = await supabase.from('audit_logs').insert({
      user_id: params.userId || null,
      event_type: params.eventType,
      success: params.success,
      ip_address: params.ipAddress || null,
      user_agent: params.userAgent || null,
      event_data: params.eventData || null,
      error_message: params.errorMessage || null,
    });

    if (error) {
      console.error('Failed to write audit log:', error);
      // Don't throw - audit logging failure shouldn't break the app
      // In production, send to external monitoring service
    }
  } catch (error) {
    console.error('Audit log error:', error);
    // Fail gracefully - don't block auth flow
  }
}

/**
 * Extract client information from request
 * Helper to get IP and user agent from Next.js request
 */
export async function getClientInfo(): Promise<{
  ipAddress?: string;
  userAgent?: string;
}> {
  try {
    const headersList = await headers();

    // Try various IP headers (Vercel, Cloudflare, etc.)
    const ipAddress =
      headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      headersList.get('x-real-ip') ||
      headersList.get('cf-connecting-ip') ||
      undefined;

    const userAgent = headersList.get('user-agent') || undefined;

    return { ipAddress, userAgent };
  } catch (error) {
    console.error('Error getting client info:', error);
    return {};
  }
}

/**
 * Log successful login
 */
export async function logLoginSuccess(
  userId: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    userId,
    eventType: 'login',
    success: true,
    ...clientInfo,
    eventData: additionalData,
  });
}

/**
 * Log failed login attempt
 */
export async function logLoginFailure(
  email: string,
  errorMessage: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    eventType: 'login_failed',
    success: false,
    ...clientInfo,
    errorMessage,
    eventData: { email, ...additionalData },
  });
}

/**
 * Log successful signup
 */
export async function logSignupSuccess(
  userId: string,
  email: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    userId,
    eventType: 'signup',
    success: true,
    ...clientInfo,
    eventData: { email, ...additionalData },
  });
}

/**
 * Log failed signup attempt
 */
export async function logSignupFailure(
  email: string,
  errorMessage: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    eventType: 'signup_failed',
    success: false,
    ...clientInfo,
    errorMessage,
    eventData: { email, ...additionalData },
  });
}

/**
 * Log successful token refresh
 */
export async function logRefreshSuccess(
  userId: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    userId,
    eventType: 'refresh',
    success: true,
    ...clientInfo,
    eventData: additionalData,
  });
}

/**
 * Log failed token refresh
 */
export async function logRefreshFailure(
  errorMessage: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    eventType: 'refresh_failed',
    success: false,
    ...clientInfo,
    errorMessage,
    eventData: additionalData,
  });
}

/**
 * Log logout
 */
export async function logLogout(
  userId: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    userId,
    eventType: 'logout',
    success: true,
    ...clientInfo,
    eventData: additionalData,
  });
}

/**
 * Log unauthorized access attempt
 */
export async function logUnauthorizedAccess(
  path: string,
  userId?: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    userId,
    eventType: 'unauthorized_access',
    success: false,
    ...clientInfo,
    eventData: { path, ...additionalData },
  });
}

/**
 * Log rate limit exceeded
 */
export async function logRateLimitExceeded(
  endpoint: string,
  userId?: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const clientInfo = await getClientInfo();

  await logAuthEvent({
    userId,
    eventType: 'rate_limit_exceeded',
    success: false,
    ...clientInfo,
    eventData: { endpoint, ...additionalData },
  });
}

/**
 * Get recent audit logs for a user
 * Useful for security dashboards
 */
export async function getUserAuditLogs(
  userId: string,
  limit: number = 50
): Promise<Array<{
  id: string;
  user_id: string | null;
  event_type: AuditEventType;
  success: boolean;
  ip_address: string | null;
  user_agent: string | null;
  event_data: Record<string, unknown> | null;
  error_message: string | null;
  created_at: string;
}>> {
  try {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from('audit_logs')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      console.error('Error fetching audit logs:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Error in getUserAuditLogs:', error);
    return [];
  }
}

/**
 * Get failed login attempts for an IP
 * Useful for detecting brute force attacks
 */
export async function getFailedLoginsByIP(
  ipAddress: string,
  sinceMinutes: number = 15
): Promise<number> {
  try {
    const supabase = await createClient();
    const since = new Date(Date.now() - sinceMinutes * 60 * 1000).toISOString();

    const { count, error } = await supabase
      .from('audit_logs')
      .select('*', { count: 'exact', head: true })
      .eq('event_type', 'login_failed')
      .eq('ip_address', ipAddress)
      .gte('created_at', since);

    if (error) {
      console.error('Error counting failed logins:', error);
      return 0;
    }

    return count || 0;
  } catch (error) {
    console.error('Error in getFailedLoginsByIP:', error);
    return 0;
  }
}

/**
 * Detect suspicious login patterns
 * Returns true if pattern looks suspicious
 */
export async function detectSuspiciousActivity(
  userId: string,
  ipAddress?: string
): Promise<boolean> {
  try {
    const supabase = await createClient();
    const last24Hours = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

    // Check for multiple failed logins followed by success
    const { data: recentLogs } = await supabase
      .from('audit_logs')
      .select('event_type, success, ip_address')
      .eq('user_id', userId)
      .gte('created_at', last24Hours)
      .order('created_at', { ascending: false })
      .limit(10);

    if (!recentLogs || recentLogs.length === 0) {
      return false;
    }

    const failedAttempts = recentLogs.filter(
      (log) => log.event_type === 'login_failed'
    ).length;

    // Suspicious if more than 3 failed attempts in last 10 events
    if (failedAttempts > 3) {
      return true;
    }

    // Suspicious if login from new IP that's very different from usual
    // TODO: Implement IP geolocation checking in future

    return false;
  } catch (error) {
    console.error('Error detecting suspicious activity:', error);
    return false;
  }
}
