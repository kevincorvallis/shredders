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
 * In-memory rate limiter (fallback when REDIS_URL is not set)
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

// Lazy-initialized Upstash Ratelimit instance
let _upstashRatelimiters: Map<string, import('@upstash/ratelimit').Ratelimit> | null = null;

function getUpstashRatelimiter(
  windowMs: number,
  limit: number,
): import('@upstash/ratelimit').Ratelimit | null {
  const url = process.env.REDIS_URL;
  const token = process.env.REDIS_TOKEN;
  if (!url || !token) return null;

  if (!_upstashRatelimiters) {
    _upstashRatelimiters = new Map();
  }

  const key = `${windowMs}:${limit}`;
  if (_upstashRatelimiters.has(key)) {
    return _upstashRatelimiters.get(key)!;
  }

  try {
    // Dynamic import is not needed since we installed the packages
    const { Ratelimit } = require('@upstash/ratelimit');
    const { Redis } = require('@upstash/redis');

    const redis = new Redis({ url, token });
    const ratelimiter = new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(limit, `${windowMs} ms`),
      prefix: 'shredders:rl',
    });

    _upstashRatelimiters.set(key, ratelimiter);
    return ratelimiter;
  } catch (e) {
    console.warn('Failed to initialize Upstash ratelimiter, falling back to in-memory:', e);
    return null;
  }
}

/**
 * In-memory rate limit check (used as fallback when Redis is not available)
 */
function rateLimitInMemory(
  identifier: string,
  limit: number,
  windowMs: number,
): RateLimitResult {
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
 * Enhanced rate limiter with Upstash Redis backend and in-memory fallback
 *
 * Uses Upstash Redis sliding window when REDIS_URL and REDIS_TOKEN are set.
 * Falls back to in-memory Map for local development.
 *
 * @param identifier - Unique identifier (can be composite like "ip:email")
 * @param config - Rate limit configuration or preset name
 * @returns Rate limit result with success/failure and metadata
 */
export async function rateLimitEnhanced(
  identifier: string,
  config: keyof typeof RATE_LIMITS | RateLimitConfig = 'default'
): Promise<RateLimitResult> {
  const { limit, windowMs } = typeof config === 'string' ? RATE_LIMITS[config] : config;

  const upstash = getUpstashRatelimiter(windowMs, limit);
  if (upstash) {
    try {
      const result = await upstash.limit(identifier);
      return {
        success: result.success,
        remaining: result.remaining,
        resetTime: result.reset,
        retryAfter: result.success ? undefined : Math.ceil((result.reset - Date.now()) / 1000),
      };
    } catch (e) {
      console.warn('Upstash rate limit error, falling back to in-memory:', e);
    }
  }

  // Fallback to in-memory
  return rateLimitInMemory(identifier, limit, windowMs);
}

/**
 * Legacy rate limiter (kept for backward compatibility)
 * @deprecated Use rateLimitEnhanced instead
 */
export async function rateLimit(
  identifier: string,
  limit: number = 60,
  windowMs: number = 60000
): Promise<{ success: boolean; remaining: number }> {
  const result = await rateLimitEnhanced(identifier, { limit, windowMs });
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
