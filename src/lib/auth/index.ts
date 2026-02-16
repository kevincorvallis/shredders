/**
 * Auth Module Exports
 *
 * Central export for all authentication utilities
 * Import from this file for a clean API: import { withAuth, generateTokenPair } from '@/lib/auth'
 */

// JWT utilities
export {
  generateAccessToken,
  generateRefreshToken,
  generateTokenPair,
  verifyAccessToken,
  verifyRefreshToken,
  extractTokenFromHeader,
  decodeToken,
  type TokenPayload,
  type JWTConfig,
} from './jwt';

// Middleware
export {
  withAuth,
  withOptionalAuth,
  withDualAuth,
  getAuthUserAsync,
  requireAuth,
  type AuthenticatedRequest,
} from './middleware';

// Helpers
export {
  createUserTokens,
  authenticateUser,
  refreshUserSession,
  logoutUser,
  getUserById,
  userExists,
} from './helpers';

// Dual Auth (JWT + Supabase)
export {
  getDualAuthUser,
  requireDualAuth,
  type AuthenticatedUser,
} from './dual-auth';

// Token Blacklist
export {
  addToBlacklist,
  isBlacklisted,
  revokeAllUserTokens,
  cleanupExpiredTokens,
  getBlacklistStats,
  type BlacklistEntry,
} from './token-blacklist';

// Token Rotation
export {
  recordTokenRotation,
  isTokenUsed,
  handleTokenReuseAttack,
  getTokenFamily,
  cleanupExpiredRotations,
  getRotationStats,
  type TokenRotationEntry,
} from './token-rotation';

// Audit Logging
export {
  logAuthEvent,
  // Note: getClientInfo is exported from session-manager instead (more comprehensive)
  logLoginSuccess,
  logLoginFailure,
  logSignupSuccess,
  logSignupFailure,
  logRefreshSuccess,
  logRefreshFailure,
  logLogout,
  logUnauthorizedAccess,
  logRateLimitExceeded,
  getUserAuditLogs,
  getFailedLoginsByIP,
  detectSuspiciousActivity,
  type AuditEventType,
  type AuditLogParams,
} from './audit-log';

// Validation Schemas
export {
  loginSchema,
  signupSchema,
  refreshSchema,
  updateProfileSchema,
  createCommentSchema,
  createCheckInSchema,
  createLikeSchema,
  validateRequest,
  validateOrThrow,
  type LoginInput,
  type SignupInput,
  type RefreshInput,
  type UpdateProfileInput,
  type CreateCommentInput,
  type CreateCheckInInput,
  type CreateLikeInput,
} from './schemas';

// Session Management
export {
  createSession,
  updateSessionActivity,
  getUserSessions,
  getSessionById,
  revokeSession,
  revokeAllUserSessions,
  cleanupExpiredSessions,
  getSessionStats,
  detectSuspiciousSessions,
  parseUserAgent,
  getClientInfo,
  type UserSession,
  type DeviceInfo,
  type LocationInfo,
} from './session-manager';
