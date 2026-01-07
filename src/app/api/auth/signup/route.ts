/**
 * POST /api/auth/signup
 *
 * Create a new user account with email and password
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const { email, password, username, displayName } = await request.json();

    // Validate required fields
    if (!email || !password || !username) {
      return NextResponse.json(
        { error: 'Email, password, and username are required' },
        { status: 400 }
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
      return NextResponse.json({ error: authError.message }, { status: 400 });
    }

    if (!authData.user) {
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

    return NextResponse.json({
      user: authData.user,
      session: authData.session,
      message: 'Account created successfully',
    });
  } catch (error: any) {
    console.error('Signup error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}
