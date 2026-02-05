/**
 * POST /api/auth/forgot-password
 *
 * Send password reset email to user
 * Uses Supabase's built-in password reset functionality
 */

import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { z } from 'zod';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import { logAuthEvent } from '@/lib/auth/audit-log';
import { headers } from 'next/headers';

const forgotPasswordSchema = z.object({
  email: z
    .string()
    .email('Invalid email format')
    .max(255, 'Email must be less than 255 characters')
    .toLowerCase()
    .trim(),
});

export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Validate input
    const result = forgotPasswordSchema.safeParse(body);
    if (!result.success) {
      return NextResponse.json(
        {
          error: 'Validation failed',
          details: result.error.issues.map((i) => i.message),
        },
        { status: 400 }
      );
    }

    const { email } = result.data;

    // Rate limiting: 3 password reset requests per hour per email
    const headersList = await headers();
    const ipAddress =
      headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      headersList.get('x-real-ip') ||
      'unknown';

    const rateLimitKey = createRateLimitKey('forgot-password', email);
    const rateLimit = await rateLimitEnhanced(rateLimitKey, 'signup'); // Use signup limits (3/hour)

    if (!rateLimit.success) {
      return NextResponse.json(
        {
          error: 'Too many password reset requests',
          retryAfter: rateLimit.retryAfter,
          message: `Please try again in ${Math.ceil(rateLimit.retryAfter! / 60)} minutes`,
        },
        {
          status: 429,
          headers: {
            'Retry-After': rateLimit.retryAfter!.toString(),
          },
        }
      );
    }

    const supabase = await createClient();

    // Determine the correct redirect URL based on environment
    // In production, always use the Vercel URL
    const isProduction = process.env.NODE_ENV === 'production' ||
                         process.env.VERCEL_ENV === 'production';
    const baseUrl = isProduction
      ? 'https://shredders-bay.vercel.app'
      : (process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000');

    // Send password reset email via Supabase
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${baseUrl}/auth/reset-password`,
    });

    if (error) {
      console.error('Password reset error:', error);

      await logAuthEvent({
        eventType: 'password_change',
        success: false,
        ipAddress,
        eventData: { email, action: 'forgot_password_request' },
        errorMessage: error.message,
      });

      // Don't reveal if email exists - always return success
      // This prevents email enumeration attacks
    }

    // Log the attempt (even on error to track potential enumeration attempts)
    await logAuthEvent({
      eventType: 'password_change',
      success: true,
      ipAddress,
      eventData: { email, action: 'forgot_password_request' },
    });

    // Always return success to prevent email enumeration
    return NextResponse.json({
      message: 'If an account with that email exists, a password reset link has been sent.',
      success: true,
    });
  } catch (error: any) {
    console.error('Forgot password error:', error);

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
