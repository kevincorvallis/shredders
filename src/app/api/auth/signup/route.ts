/**
 * POST /api/auth/signup
 *
 * Create a new user account with email and password
 * Includes JWT token generation, rate limiting, validation, and audit logging
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { headers } from 'next/headers';
import {
  createUserTokens,
  signupSchema,
  validateRequest,
  logSignupSuccess,
  logSignupFailure,
  logRateLimitExceeded,
} from '@/lib/auth';
import { rateLimitEnhanced, createRateLimitKey } from '@/lib/api-utils';

export async function POST(request: Request) {
  const startTime = Date.now();
  let email: string | undefined;

  try {
    // Parse request body
    const body = await request.json();

    // Validate input with Zod
    const validation = validateRequest(signupSchema, body);
    if (!validation.success) {
      return NextResponse.json(
        {
          error: 'Validation failed',
          details: validation.errors,
        },
        { status: 400 }
      );
    }

    const { email: validatedEmail, password, username, displayName } = validation.data;
    email = validatedEmail;

    // Rate limiting: IP-based (3 attempts per hour)
    const headersList = await headers();
    const ipAddress =
      headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      headersList.get('x-real-ip') ||
      'unknown';

    const rateLimitKey = createRateLimitKey('signup', ipAddress);
    const rateLimit = rateLimitEnhanced(rateLimitKey, 'signup');

    if (!rateLimit.success) {
      // Log rate limit exceeded
      await logRateLimitExceeded('signup', undefined, {
        email,
        ipAddress,
        attemptsRemaining: rateLimit.remaining,
      });

      return NextResponse.json(
        {
          error: 'Too many signup attempts',
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

    // Sign up with Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          username,
          display_name: displayName || username,
        },
      },
    });

    if (authError) {
      // Log failed signup
      await logSignupFailure(email, authError.message, {
        ipAddress,
        username,
        errorCode: authError.code,
        signupDuration: Date.now() - startTime,
      });

      return NextResponse.json({ error: authError.message }, { status: 400 });
    }

    if (!authData.user) {
      await logSignupFailure(email, 'Failed to create user account', {
        ipAddress,
        username,
        signupDuration: Date.now() - startTime,
      });

      return NextResponse.json(
        { error: 'Failed to create user' },
        { status: 500 }
      );
    }

    // Create user profile in our database
    const { error: profileError } = await supabase.from('users').insert({
      auth_user_id: authData.user.id,
      username,
      email,
      display_name: displayName || username,
    });

    if (profileError) {
      console.error('Error creating user profile:', profileError);
      // Don't fail signup if profile creation fails - user can complete later
    }

    // Generate JWT tokens for the new user
    const tokens = await createUserTokens(authData.user.id);

    // Log successful signup
    await logSignupSuccess(authData.user.id, email, {
      username,
      ipAddress,
      signupDuration: Date.now() - startTime,
    });

    return NextResponse.json({
      user: {
        id: authData.user.id,
        email: authData.user.email,
      },
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      message: 'Account created successfully',
    });
  } catch (error: any) {
    console.error('Signup error:', error);

    // Log failed signup attempt
    if (email) {
      await logSignupFailure(email, error.message || 'Internal server error', {
        errorType: error.constructor.name,
        signupDuration: Date.now() - startTime,
      });
    }

    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}
