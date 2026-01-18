/**
 * TypeScript types for authentication database rows
 * Provides type safety for Supabase queries
 */

// ============================================
// Token Blacklist Types
// ============================================

export interface TokenBlacklistRow {
  id: string;
  jti: string;
  user_id: string;
  expires_at: string;
  revoked_at: string;
  reason: string | null;
  token_type: 'access' | 'refresh';
  created_at: string;
}

export interface TokenBlacklistInsert {
  jti: string;
  user_id: string;
  expires_at: string;
  revoked_at: string;
  reason?: string | null;
  token_type: 'access' | 'refresh';
}

// ============================================
// Token Rotation Types
// ============================================

export interface TokenRotationRow {
  id: string;
  jti: string;
  user_id: string;
  token_family: string;
  parent_jti: string | null;
  child_jti: string | null;
  created_at: string;
  used_at: string | null;
  expires_at: string;
}

export interface TokenRotationInsert {
  jti: string;
  user_id: string;
  token_family: string;
  parent_jti?: string | null;
  child_jti?: string | null;
  used_at?: string | null;
  expires_at: string;
}

// ============================================
// User Session Types
// ============================================

export interface UserSessionRow {
  id: string;
  user_id: string;
  refresh_token_jti: string;
  token_family: string;
  device_id: string | null;
  device_type: 'desktop' | 'mobile' | 'tablet' | 'unknown';
  device_name: string | null;
  browser: string | null;
  browser_version: string | null;
  os: string | null;
  os_version: string | null;
  ip_address: string;
  country: string | null;
  region: string | null;
  city: string | null;
  user_agent: string | null;
  created_at: string;
  last_activity_at: string;
  expires_at: string;
  revoked_at: string | null;
  revoke_reason: string | null;
}

export interface UserSessionInsert {
  user_id: string;
  refresh_token_jti: string;
  token_family: string;
  device_id?: string | null;
  device_type?: 'desktop' | 'mobile' | 'tablet' | 'unknown';
  device_name?: string | null;
  browser?: string | null;
  browser_version?: string | null;
  os?: string | null;
  os_version?: string | null;
  ip_address: string;
  country?: string | null;
  region?: string | null;
  city?: string | null;
  user_agent?: string | null;
  expires_at: string;
}

// ============================================
// Audit Log Types
// ============================================

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
  | 'rate_limit_exceeded'
  | 'account_deleted';

export interface AuditLogRow {
  id: string;
  user_id: string | null;
  event_type: AuditEventType;
  success: boolean;
  ip_address: string | null;
  user_agent: string | null;
  event_data: Record<string, unknown> | null;
  error_message: string | null;
  created_at: string;
}

export interface AuditLogInsert {
  user_id?: string | null;
  event_type: AuditEventType;
  success: boolean;
  ip_address?: string | null;
  user_agent?: string | null;
  event_data?: Record<string, unknown> | null;
  error_message?: string | null;
}

// ============================================
// User Profile Types
// ============================================

export interface UserRow {
  id: string;
  auth_user_id: string;
  username: string;
  email: string;
  display_name: string;
  bio: string | null;
  avatar_url: string | null;
  home_mountain_id: string | null;
  location: string | null;
  created_at: string;
  updated_at: string;
  last_login_at: string | null;
}

// ============================================
// JWT Token Payload Types
// ============================================

export interface AccessTokenPayload {
  sub: string; // User ID
  email?: string;
  jti: string; // JWT ID
  iat: number; // Issued at
  exp: number; // Expires at
  type: 'access';
}

export interface RefreshTokenPayload {
  sub: string; // User ID
  jti: string; // JWT ID
  tokenFamily: string; // For token rotation
  parentJti?: string | null; // Parent token JTI
  iat: number; // Issued at
  exp: number; // Expires at
  type: 'refresh';
}

export type TokenPayload = AccessTokenPayload | RefreshTokenPayload;

// ============================================
// API Response Types
// ============================================

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthUserResponse {
  id: string;
  email: string | null;
}

export interface LoginResponse {
  user: AuthUserResponse;
  accessToken: string;
  refreshToken: string;
  message?: string;
}

export interface SignupResponse {
  user: AuthUserResponse;
  accessToken: string;
  refreshToken: string;
  message?: string;
}

export interface RefreshResponse {
  accessToken: string;
  refreshToken: string;
}

export interface SessionStats {
  totalSessions: number;
  activeSessions: number;
  revokedSessions: number;
  expiredSessions: number;
  uniqueDevices: number;
  uniqueIPs: number;
}

export interface SuspiciousSession {
  sessionId: string;
  ipAddress: string;
  country: string;
  createdAt: Date;
  suspiciousReason: string;
}
