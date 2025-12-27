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

export function rateLimit(
  identifier: string,
  limit: number = 60,
  windowMs: number = 60000
): { success: boolean; remaining: number } {
  const now = Date.now();
  const record = rateLimitMap.get(identifier);

  if (!record || now > record.resetTime) {
    rateLimitMap.set(identifier, {
      count: 1,
      resetTime: now + windowMs,
    });
    return { success: true, remaining: limit - 1 };
  }

  if (record.count >= limit) {
    return { success: false, remaining: 0 };
  }

  record.count++;
  return { success: true, remaining: limit - record.count };
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
