/**
 * POST /api/auth/resend-verification
 *
 * Resend email verification link to user
 * Uses Supabase's built-in resend functionality
 */

import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { z } from 'zod';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';
import { logAuthEvent } from '@/lib/auth/audit-log';
import { headers } from 'next/headers';

const resendVerificationSchema = z.object({
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
    const result = resendVerificationSchema.safeParse(body);
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

    // Rate limiting: 3 resend requests per hour per email
    const headersList = await headers();
    const ipAddress =
      headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      headersList.get('x-real-ip') ||
      'unknown';

    const rateLimitKey = createRateLimitKey('resend-verification', email);
    const rateLimit = rateLimitEnhanced(rateLimitKey, 'signup'); // Use signup limits (3/hour)

    if (!rateLimit.success) {
      return NextResponse.json(
        {
          error: 'Too many resend requests',
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

    // Resend the verification email
    const { error } = await supabase.auth.resend({
      type: 'signup',
      email,
    });

    if (error) {
      console.error('Resend verification error:', error);

      await logAuthEvent({
        eventType: 'signup',
        success: false,
        ipAddress,
        eventData: { email, action: 'resend_verification' },
        errorMessage: error.message,
      });

      // Don't reveal if email exists - always return success
      // This prevents email enumeration attacks
    }

    // Log the attempt
    await logAuthEvent({
      eventType: 'signup',
      success: true,
      ipAddress,
      eventData: { email, action: 'resend_verification' },
    });

    // Always return success to prevent email enumeration
    return NextResponse.json({
      message: 'If an account with that email exists, a verification link has been sent.',
      success: true,
    });
  } catch (error: any) {
    console.error('Resend verification error:', error);

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
