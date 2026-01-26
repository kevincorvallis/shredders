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
    const adminClient = createAdminClient();

    let userId: string;
    let userEmail: string;

    // Try to sign up - this will fail if user already exists
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
      // Check if the error is because user already exists
      // In that case, try to find the auth user and create missing profile
      if (authError.message?.includes('already registered') ||
          authError.message?.includes('already been registered') ||
          authError.code === 'user_already_exists') {

        // User exists in auth - check if they have a profile
        // Look up by email in our users table
        const { data: existingProfile } = await adminClient
          .from('users')
          .select('id, auth_user_id, email')
          .eq('email', email)
          .maybeSingle();

        if (existingProfile) {
          // Profile exists - tell user to sign in instead
          return NextResponse.json({
            error: 'An account with this email already exists. Please sign in instead.',
          }, { status: 409 });
        }

        // Auth user exists but no profile - we can't easily get their auth_user_id
        // without admin listUsers, so tell them to sign in with their existing method
        return NextResponse.json({
          error: 'An account with this email already exists. Please sign in with your original method (e.g., Apple Sign In).',
        }, { status: 409 });
      }

      // Other auth error
      await logSignupFailure(email, authError.message, {
        ipAddress,
        username,
        errorCode: authError.code,
        signupDuration: Date.now() - startTime,
      });

      return NextResponse.json({ error: authError.message }, { status: 400 });
    }

    // Check if signup returned a user (it might return null for existing unconfirmed users)
    if (!authData.user) {
      // This can happen when Supabase has email confirmation enabled
      // and user exists but hasn't confirmed - check for profile
      const { data: existingProfile } = await adminClient
        .from('users')
        .select('id, auth_user_id, email')
        .eq('email', email)
        .maybeSingle();

      if (existingProfile) {
        return NextResponse.json({
          error: 'An account with this email already exists. Please check your email for a confirmation link or sign in.',
        }, { status: 409 });
      }

      await logSignupFailure(email, 'Failed to create user account', {
        ipAddress,
        username,
        signupDuration: Date.now() - startTime,
      });

      return NextResponse.json(
        { error: 'Failed to create user. Please try again.' },
        { status: 500 }
      );
    }

    userId = authData.user.id;
    userEmail = authData.user.email || email;

    // Check if a profile already exists (double-check)
    const { data: existingProfile } = await adminClient
      .from('users')
      .select('id, auth_user_id, email')
      .or(`auth_user_id.eq.${userId},email.eq.${email}`)
      .maybeSingle();

    if (existingProfile) {
      // Profile exists - return success
      const tokens = await createUserTokens(userId);
      return NextResponse.json({
        user: {
          id: userId,
          email: userEmail,
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
        email: userEmail,
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
