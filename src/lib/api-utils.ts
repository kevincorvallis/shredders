import { NextResponse } from 'next/server';

/**
 * API Error Response Helper
 */
export function apiError(
  message: string,
  status: number = 500,
  details?: unknown
) {
  console.error('API Error:', { message, status, details });

  return NextResponse.json(
    {
      error: message,
      ...(process.env.NODE_ENV === 'development' && details ? { details } : {}),
    },
    { status }
  );
}

/**
 * API Success Response Helper
 */
export function apiSuccess<T>(data: T, status: number = 200) {
  return NextResponse.json(data, { status });
}

/**
 * Simple in-memory rate limiter
 * For production, consider using Redis or a dedicated rate limiting service
 */
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();

export interface RateLimitConfig {
  limit: number; // Max requests allowed
  windowMs: number; // Time window in milliseconds
}

export interface RateLimitResult {
  success: boolean;
  remaining: number;
  resetTime?: number; // When the limit resets
  retryAfter?: number; // Seconds until retry (when rate limited)
}

/**
 * Rate limit configurations for different endpoints
 */
export const RATE_LIMITS = {
  login: { limit: 5, windowMs: 5 * 60 * 1000 }, // 5 attempts per 5 minutes
  signup: { limit: 3, windowMs: 60 * 60 * 1000 }, // 3 attempts per hour
  refresh: { limit: 10, windowMs: 60 * 1000 }, // 10 attempts per minute
  passwordReset: { limit: 3, windowMs: 60 * 60 * 1000 }, // 3 attempts per hour
  default: { limit: 60, windowMs: 60 * 1000 }, // 60 requests per minute
  // Event-related rate limits (Phase 5: Security)
  createEvent: { limit: 10, windowMs: 60 * 60 * 1000 }, // 10 events per hour
  rsvpEvent: { limit: 20, windowMs: 60 * 60 * 1000 }, // 20 RSVPs per hour
  postComment: { limit: 30, windowMs: 60 * 60 * 1000 }, // 30 comments per hour
};

/**
 * Enhanced rate limiter with composite key support
 *
 * @param identifier - Unique identifier (can be composite like "ip:email")
 * @param config - Rate limit configuration or preset name
 * @returns Rate limit result with success/failure and metadata
 *
 * @example
 * // Using preset
 * const result = rateLimitEnhanced('user@example.com', 'login');
 *
 * // Using composite key
 * const result = rateLimitEnhanced(`${ip}:${email}`, { limit: 5, windowMs: 300000 });
 *
 * // Check result
 * if (!result.success) {
 *   return NextResponse.json(
 *     { error: 'Too many attempts', retryAfter: result.retryAfter },
 *     { status: 429, headers: { 'Retry-After': result.retryAfter!.toString() } }
 *   );
 * }
 */
export function rateLimitEnhanced(
  identifier: string,
  config: keyof typeof RATE_LIMITS | RateLimitConfig = 'default'
): RateLimitResult {
  const { limit, windowMs } = typeof config === 'string' ? RATE_LIMITS[config] : config;

  const now = Date.now();
  const record = rateLimitMap.get(identifier);

  if (!record || now > record.resetTime) {
    const resetTime = now + windowMs;
    rateLimitMap.set(identifier, {
      count: 1,
      resetTime,
    });
    return {
      success: true,
      remaining: limit - 1,
      resetTime,
    };
  }

  if (record.count >= limit) {
    const retryAfter = Math.ceil((record.resetTime - now) / 1000);
    return {
      success: false,
      remaining: 0,
      resetTime: record.resetTime,
      retryAfter,
    };
  }

  record.count++;
  return {
    success: true,
    remaining: limit - record.count,
    resetTime: record.resetTime,
  };
}

/**
 * Legacy rate limiter (kept for backward compatibility)
 */
export function rateLimit(
  identifier: string,
  limit: number = 60,
  windowMs: number = 60000
): { success: boolean; remaining: number } {
  const result = rateLimitEnhanced(identifier, { limit, windowMs });
  return { success: result.success, remaining: result.remaining };
}

/**
 * Create a composite rate limit key
 * Useful for limiting by IP + email, IP + user ID, etc.
 */
export function createRateLimitKey(...parts: (string | undefined)[]): string {
  return parts.filter(Boolean).join(':');
}

/**
 * Clean up old rate limit entries (call periodically)
 */
if (typeof window === 'undefined') {
  setInterval(() => {
    const now = Date.now();
    for (const [key, record] of rateLimitMap.entries()) {
      if (now > record.resetTime) {
        rateLimitMap.delete(key);
      }
    }
  }, 60000); // Clean up every minute
}

/**
 * Validate required environment variables
 */
export function validateEnv(vars: string[]): boolean {
  const missing = vars.filter((v) => !process.env[v]);
  if (missing.length > 0) {
    console.error('Missing required environment variables:', missing);
    return false;
  }
  return true;
}
