/**
 * POST /api/auth/signup
 *
 * Create a new user account with email and password
 * Includes JWT token generation, rate limiting, validation, and audit logging
 */

import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
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

    // Debug logging
    console.log('[SIGNUP] Received body:', JSON.stringify(body, null, 2));

    // Validate input with Zod
    const validation = validateRequest(signupSchema, body);
    if (!validation.success) {
      console.log('[SIGNUP] Validation failed:', validation.errors);
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

    // Ensure user ID is a string for consistent database operations
    const userId = String(authData.user.id);

    // Create user profile in our database using admin client to bypass RLS
    const adminClient = createAdminClient();

    // First, check if a profile already exists for this auth user or email
    const { data: existingProfile } = await adminClient
      .from('users')
      .select('id, auth_user_id, email')
      .or(`auth_user_id.eq.${userId},email.eq.${email}`)
      .maybeSingle();

    if (existingProfile) {
      // Profile already exists - this could happen if:
      // 1. User signed up before but didn't complete
      // 2. Email already registered
      if (existingProfile.email === email && existingProfile.auth_user_id !== userId) {
        return NextResponse.json(
          { error: 'An account with this email already exists. Please sign in instead.' },
          { status: 409 }
        );
      }
      // Profile exists for this auth user - just return success
      const tokens = await createUserTokens(userId);
      return NextResponse.json({
        user: {
          id: userId,
          email: authData.user.email,
        },
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        message: 'Account already exists',
      });
    }

    // Check if username is taken
    const { data: existingUsername } = await adminClient
      .from('users')
      .select('id')
      .eq('username', username)
      .maybeSingle();

    const finalUsername = existingUsername
      ? `${username}_${Date.now().toString(36).slice(-4)}`
      : username;

    const { error: profileError } = await adminClient.from('users').insert({
      auth_user_id: userId,
      username: finalUsername,
      email,
      display_name: displayName || username,
    });

    if (profileError) {
      console.error('Error creating user profile:', profileError);
      // Log failed signup due to profile creation
      await logSignupFailure(email, `Profile creation failed: ${profileError.message}`, {
        ipAddress,
        username,
        errorCode: profileError.code,
        signupDuration: Date.now() - startTime,
      });

      // Check for unique constraint violation on username
      if (profileError.code === '23505') {
        return NextResponse.json(
          { error: 'Username already taken. Please choose a different one.' },
          { status: 409 }
        );
      }

      return NextResponse.json(
        { error: 'Failed to create user profile. Please try again.' },
        { status: 500 }
      );
    }

    // Verify the profile was created successfully
    const { data: verifyProfile, error: verifyError } = await adminClient
      .from('users')
      .select('auth_user_id')
      .eq('auth_user_id', userId)
      .single();

    if (verifyError || !verifyProfile) {
      console.error('Profile verification failed:', verifyError);
      await logSignupFailure(email, 'Profile verification failed after insert', {
        ipAddress,
        username,
        signupDuration: Date.now() - startTime,
      });

      return NextResponse.json(
        { error: 'Failed to verify user profile. Please try again.' },
        { status: 500 }
      );
    }

    // Generate JWT tokens for the new user
    const tokens = await createUserTokens(userId);

    // Log successful signup
    await logSignupSuccess(userId, email, {
      username,
      ipAddress,
      signupDuration: Date.now() - startTime,
    });

    return NextResponse.json({
      user: {
        id: userId,
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
