/**
 * JWT Authentication Utilities
 *
 * Handles JWT token generation, verification, and refresh logic
 * Inspired by IWBH backend auth structure, adapted for Next.js
 */

import jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';
import { jwtConfig, appConfig } from '@/lib/config';

// Token types
export interface TokenPayload {
  userId: string;
  email: string;
  username?: string;
  type: 'access' | 'refresh';
  jti: string; // JWT ID for blacklist/revocation
  iat?: number; // Issued at (added automatically by jwt.sign)
  exp?: number; // Expiration (added automatically by jwt.sign)
  iss?: string; // Issuer (your app URL)
  aud?: string; // Audience (your app URL)
  tokenFamily?: string; // Token family UUID for rotation tracking
  parentJti?: string; // Parent token JTI (for refresh token rotation)
}

export interface JWTConfig {
  accessTokenSecret: string;
  refreshTokenSecret: string;
  accessTokenExpiry: string;
  refreshTokenExpiry: string;
}

// Get JWT configuration from validated config
const getJWTConfig = (): JWTConfig => {
  return {
    accessTokenSecret: jwtConfig.accessSecret,
    refreshTokenSecret: jwtConfig.refreshSecret,
    accessTokenExpiry: jwtConfig.accessExpiry,
    refreshTokenExpiry: jwtConfig.refreshExpiry,
  };
};

/**
 * Get issuer and audience for JWT claims
 * Uses validated config
 */
const getIssuerAudience = (): { issuer: string; audience: string } => {
  return {
    issuer: appConfig.siteUrl,
    audience: appConfig.siteUrl,
  };
};

/**
 * Generate an access token
 */
export function generateAccessToken(
  payload: Omit<TokenPayload, 'type' | 'jti' | 'iat' | 'exp' | 'iss' | 'aud'>
): string {
  const config = getJWTConfig();
  const { issuer, audience } = getIssuerAudience();

  return jwt.sign(
    {
      ...payload,
      type: 'access',
      jti: randomUUID(), // Unique token ID for revocation
      iss: issuer,
      aud: audience,
    },
    config.accessTokenSecret,
    { expiresIn: config.accessTokenExpiry }
  );
}

/**
 * Generate a refresh token
 * @param payload - Token payload
 * @param options - Optional parent JTI for token rotation
 */
export function generateRefreshToken(
  payload: Omit<TokenPayload, 'type' | 'jti' | 'iat' | 'exp' | 'iss' | 'aud'>,
  options?: { parentJti?: string }
): string {
  const config = getJWTConfig();
  const { issuer, audience } = getIssuerAudience();

  // Generate new token family ID if this is a new family (no parent)
  // Otherwise inherit the token family from parent
  const tokenFamily = payload.tokenFamily || randomUUID();

  return jwt.sign(
    {
      ...payload,
      type: 'refresh',
      jti: randomUUID(), // Unique token ID for revocation
      iss: issuer,
      aud: audience,
      tokenFamily,
      parentJti: options?.parentJti, // Track parent for rotation
    },
    config.refreshTokenSecret,
    { expiresIn: config.refreshTokenExpiry }
  );
}

/**
 * Generate both access and refresh tokens
 * @param payload - Token payload
 * @param options - Optional parent JTI for refresh token rotation
 */
export function generateTokenPair(
  payload: Omit<TokenPayload, 'type' | 'jti' | 'iat' | 'exp' | 'iss' | 'aud'>,
  options?: { parentJti?: string }
) {
  return {
    accessToken: generateAccessToken(payload),
    refreshToken: generateRefreshToken(payload, options),
  };
}

/**
 * Verify an access token
 */
export function verifyAccessToken(token: string): TokenPayload | null {
  try {
    const config = getJWTConfig();
    const { issuer, audience } = getIssuerAudience();

    const decoded = jwt.verify(token, config.accessTokenSecret, {
      issuer,
      audience,
    }) as TokenPayload;

    if (decoded.type !== 'access') {
      return null;
    }

    return decoded;
  } catch (error) {
    return null;
  }
}

/**
 * Verify a refresh token
 */
export function verifyRefreshToken(token: string): TokenPayload | null {
  try {
    const config = getJWTConfig();
    const { issuer, audience } = getIssuerAudience();

    const decoded = jwt.verify(token, config.refreshTokenSecret, {
      issuer,
      audience,
    }) as TokenPayload;

    if (decoded.type !== 'refresh') {
      return null;
    }

    return decoded;
  } catch (error) {
    return null;
  }
}

/**
 * Extract token from Authorization header
 * Expected format: "Bearer <token>"
 */
export function extractTokenFromHeader(
  authHeader: string | null
): string | null {
  if (!authHeader) {
    return null;
  }

  const parts = authHeader.split(' ');

  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return null;
  }

  return parts[1];
}

/**
 * Decode token without verification (use cautiously)
 * Useful for debugging or extracting non-sensitive claims
 */
export function decodeToken(token: string): TokenPayload | null {
  try {
    return jwt.decode(token) as TokenPayload;
  } catch (error) {
    return null;
  }
}
