/**
 * Session Management System
 *
 * Tracks user sessions across devices with device fingerprinting and location tracking
 * Enables users to view and revoke specific sessions for security
 */

import { createClient } from '@/lib/supabase/server';
import { headers } from 'next/headers';

export interface DeviceInfo {
  deviceId?: string;
  deviceType: 'desktop' | 'mobile' | 'tablet' | 'unknown';
  deviceName?: string;
  browser?: string;
  browserVersion?: string;
  os?: string;
  osVersion?: string;
}

export interface LocationInfo {
  ipAddress: string;
  country?: string;
  region?: string;
  city?: string;
}

export interface UserSession {
  id: string;
  userId: string;
  refreshTokenJti: string;
  tokenFamily: string;
  deviceInfo: DeviceInfo;
  locationInfo: LocationInfo;
  userAgent?: string;
  createdAt: Date;
  lastActivityAt: Date;
  expiresAt: Date;
  revokedAt?: Date;
  revokeReason?: string;
  isCurrentSession?: boolean;
}

/**
 * Parse user agent string to extract device information
 */
export function parseUserAgent(userAgent: string): DeviceInfo {
  const ua = userAgent.toLowerCase();

  // Detect device type
  let deviceType: DeviceInfo['deviceType'] = 'unknown';
  if (ua.includes('mobile')) {
    deviceType = 'mobile';
  } else if (ua.includes('tablet') || ua.includes('ipad')) {
    deviceType = 'tablet';
  } else if (ua.includes('mozilla') || ua.includes('chrome') || ua.includes('safari')) {
    deviceType = 'desktop';
  }

  // Detect browser
  let browser: string | undefined;
  let browserVersion: string | undefined;
  if (ua.includes('edg/')) {
    browser = 'Edge';
    browserVersion = ua.match(/edg\/([\d.]+)/)?.[1];
  } else if (ua.includes('chrome/')) {
    browser = 'Chrome';
    browserVersion = ua.match(/chrome\/([\d.]+)/)?.[1];
  } else if (ua.includes('safari/') && !ua.includes('chrome')) {
    browser = 'Safari';
    browserVersion = ua.match(/version\/([\d.]+)/)?.[1];
  } else if (ua.includes('firefox/')) {
    browser = 'Firefox';
    browserVersion = ua.match(/firefox\/([\d.]+)/)?.[1];
  }

  // Detect OS
  let os: string | undefined;
  let osVersion: string | undefined;
  if (ua.includes('win')) {
    os = 'Windows';
    if (ua.includes('windows nt 10.0')) osVersion = '10';
    else if (ua.includes('windows nt 6.3')) osVersion = '8.1';
    else if (ua.includes('windows nt 6.2')) osVersion = '8';
  } else if (ua.includes('mac os x')) {
    os = 'macOS';
    osVersion = ua.match(/mac os x ([\d._]+)/)?.[1]?.replace(/_/g, '.');
  } else if (ua.includes('android')) {
    os = 'Android';
    osVersion = ua.match(/android ([\d.]+)/)?.[1];
  } else if (ua.includes('iphone') || ua.includes('ipad')) {
    os = 'iOS';
    osVersion = ua.match(/os ([\d_]+)/)?.[1]?.replace(/_/g, '.');
  } else if (ua.includes('linux')) {
    os = 'Linux';
  }

  // Device name (simplified)
  let deviceName: string | undefined;
  if (ua.includes('iphone')) deviceName = 'iPhone';
  else if (ua.includes('ipad')) deviceName = 'iPad';
  else if (ua.includes('macintosh')) deviceName = 'Mac';
  else if (os === 'Windows') deviceName = 'Windows PC';
  else if (os === 'Android') deviceName = 'Android Device';

  return {
    deviceType,
    deviceName,
    browser,
    browserVersion,
    os,
    osVersion,
  };
}

/**
 * Get client IP address and location information from headers
 */
export async function getClientInfo(): Promise<LocationInfo> {
  const headersList = await headers();

  const ipAddress =
    headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    headersList.get('x-real-ip') ||
    headersList.get('cf-connecting-ip') || // Cloudflare
    'unknown';

  // Location from Cloudflare headers (if available)
  const country = headersList.get('cf-ipcountry') || undefined;
  const region = headersList.get('cf-region') || undefined;
  const city = headersList.get('cf-ipcity') || undefined;

  return {
    ipAddress,
    country,
    region,
    city,
  };
}

/**
 * Create a new session record
 */
export async function createSession(params: {
  userId: string;
  refreshTokenJti: string;
  tokenFamily: string;
  expiresAt: Date;
  deviceId?: string;
}): Promise<void> {
  const supabase = await createClient();
  const headersList = await headers();

  // Get user agent
  const userAgent = headersList.get('user-agent') || 'Unknown';

  // Parse device info
  const deviceInfo = parseUserAgent(userAgent);

  // Get location info
  const locationInfo = await getClientInfo();

  const { error } = await supabase.from('user_sessions').insert({
    user_id: params.userId,
    refresh_token_jti: params.refreshTokenJti,
    token_family: params.tokenFamily,
    device_id: params.deviceId,
    device_type: deviceInfo.deviceType,
    device_name: deviceInfo.deviceName,
    browser: deviceInfo.browser,
    browser_version: deviceInfo.browserVersion,
    os: deviceInfo.os,
    os_version: deviceInfo.osVersion,
    ip_address: locationInfo.ipAddress,
    country: locationInfo.country,
    region: locationInfo.region,
    city: locationInfo.city,
    user_agent: userAgent,
    expires_at: params.expiresAt.toISOString(),
  });

  if (error) {
    console.error('Error creating session:', error);
    throw new Error('Failed to create session');
  }
}

/**
 * Update session last activity timestamp
 */
export async function updateSessionActivity(refreshTokenJti: string): Promise<void> {
  const supabase = await createClient();

  const { error } = await supabase
    .from('user_sessions')
    .update({ last_activity_at: new Date().toISOString() })
    .eq('refresh_token_jti', refreshTokenJti);

  if (error) {
    console.error('Error updating session activity:', error);
    // Don't throw - this is not critical
  }
}

/**
 * Get all active sessions for a user
 */
export async function getUserSessions(userId: string, currentJti?: string): Promise<UserSession[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('user_sessions')
    .select('*')
    .eq('user_id', userId)
    .is('revoked_at', null)
    .gt('expires_at', new Date().toISOString())
    .order('last_activity_at', { ascending: false });

  if (error) {
    console.error('Error fetching user sessions:', error);
    return [];
  }

  return (data || []).map((row: any) => ({
    id: row.id,
    userId: row.user_id,
    refreshTokenJti: row.refresh_token_jti,
    tokenFamily: row.token_family,
    deviceInfo: {
      deviceId: row.device_id,
      deviceType: row.device_type || 'unknown',
      deviceName: row.device_name,
      browser: row.browser,
      browserVersion: row.browser_version,
      os: row.os,
      osVersion: row.os_version,
    },
    locationInfo: {
      ipAddress: row.ip_address,
      country: row.country,
      region: row.region,
      city: row.city,
    },
    userAgent: row.user_agent,
    createdAt: new Date(row.created_at),
    lastActivityAt: new Date(row.last_activity_at),
    expiresAt: new Date(row.expires_at),
    revokedAt: row.revoked_at ? new Date(row.revoked_at) : undefined,
    revokeReason: row.revoke_reason,
    isCurrentSession: currentJti ? row.refresh_token_jti === currentJti : false,
  }));
}

/**
 * Get a specific session by ID
 */
export async function getSessionById(sessionId: string): Promise<UserSession | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('user_sessions')
    .select('*')
    .eq('id', sessionId)
    .single();

  if (error || !data) {
    return null;
  }

  return {
    id: data.id,
    userId: data.user_id,
    refreshTokenJti: data.refresh_token_jti,
    tokenFamily: data.token_family,
    deviceInfo: {
      deviceId: data.device_id,
      deviceType: data.device_type || 'unknown',
      deviceName: data.device_name,
      browser: data.browser,
      browserVersion: data.browser_version,
      os: data.os,
      osVersion: data.os_version,
    },
    locationInfo: {
      ipAddress: data.ip_address,
      country: data.country,
      region: data.region,
      city: data.city,
    },
    userAgent: data.user_agent,
    createdAt: new Date(data.created_at),
    lastActivityAt: new Date(data.last_activity_at),
    expiresAt: new Date(data.expires_at),
    revokedAt: data.revoked_at ? new Date(data.revoked_at) : undefined,
    revokeReason: data.revoke_reason,
  };
}

/**
 * Revoke a specific session
 */
export async function revokeSession(
  sessionId: string,
  reason: string = 'User revoked'
): Promise<boolean> {
  const supabase = await createClient();

  const { error } = await supabase
    .from('user_sessions')
    .update({
      revoked_at: new Date().toISOString(),
      revoke_reason: reason,
    })
    .eq('id', sessionId)
    .is('revoked_at', null);

  if (error) {
    console.error('Error revoking session:', error);
    return false;
  }

  return true;
}

/**
 * Revoke all sessions for a user (except optionally the current one)
 */
export async function revokeAllUserSessions(
  userId: string,
  reason: string = 'User requested',
  exceptSessionId?: string
): Promise<number> {
  const supabase = await createClient();

  let query = supabase
    .from('user_sessions')
    .update({
      revoked_at: new Date().toISOString(),
      revoke_reason: reason,
    })
    .eq('user_id', userId)
    .is('revoked_at', null)
    .gt('expires_at', new Date().toISOString());

  if (exceptSessionId) {
    query = query.neq('id', exceptSessionId);
  }

  const { data, error } = await query.select('id');

  if (error) {
    console.error('Error revoking user sessions:', error);
    return 0;
  }

  return data?.length || 0;
}

/**
 * Clean up expired sessions
 */
export async function cleanupExpiredSessions(): Promise<number> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('user_sessions')
    .delete()
    .lt('expires_at', new Date().toISOString())
    .is('revoked_at', null)
    .select('id');

  if (error) {
    console.error('Error cleaning up expired sessions:', error);
    return 0;
  }

  return data?.length || 0;
}

/**
 * Get session statistics for a user
 */
export async function getSessionStats(userId: string): Promise<{
  totalSessions: number;
  activeSessions: number;
  revokedSessions: number;
  expiredSessions: number;
  uniqueDevices: number;
  uniqueIPs: number;
}> {
  const supabase = await createClient();

  const { data, error } = await supabase.rpc('get_session_stats', {
    p_user_id: userId,
  });

  if (error || !data || data.length === 0) {
    return {
      totalSessions: 0,
      activeSessions: 0,
      revokedSessions: 0,
      expiredSessions: 0,
      uniqueDevices: 0,
      uniqueIPs: 0,
    };
  }

  const stats = data[0];
  return {
    totalSessions: parseInt(stats.total_sessions || 0),
    activeSessions: parseInt(stats.active_sessions || 0),
    revokedSessions: parseInt(stats.revoked_sessions || 0),
    expiredSessions: parseInt(stats.expired_sessions || 0),
    uniqueDevices: parseInt(stats.unique_devices || 0),
    uniqueIPs: parseInt(stats.unique_ips || 0),
  };
}

/**
 * Detect suspicious sessions for a user
 */
export async function detectSuspiciousSessions(
  userId: string,
  hours: number = 24
): Promise<Array<{
  sessionId: string;
  ipAddress: string;
  country: string;
  createdAt: Date;
  suspiciousReason: string;
}>> {
  const supabase = await createClient();

  const { data, error } = await supabase.rpc('detect_suspicious_sessions', {
    p_user_id: userId,
    p_hours: hours,
  });

  if (error || !data) {
    console.error('Error detecting suspicious sessions:', error);
    return [];
  }

  return data.map((row: any) => ({
    sessionId: row.session_id,
    ipAddress: row.ip_address,
    country: row.country,
    createdAt: new Date(row.created_at),
    suspiciousReason: row.suspicious_reason,
  }));
}
