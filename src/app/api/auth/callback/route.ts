/**
 * GET /api/auth/callback
 *
 * Handle OAuth and email confirmation callbacks from Supabase
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function GET(request: Request) {
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get('code');
  const next = requestUrl.searchParams.get('next') || '/';
  const type = requestUrl.searchParams.get('type');

  if (code) {
    const supabase = await createClient();

    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (error) {
      console.error('Error exchanging code for session:', error);
      return NextResponse.redirect(
        new URL('/auth/login?error=auth_callback_error', requestUrl.origin)
      );
    }

    // Check if this is an email verification callback
    // Supabase uses type=signup for email confirmation
    if (type === 'signup' || type === 'email') {
      return NextResponse.redirect(new URL('/auth/verified', requestUrl.origin));
    }
  }

  // Redirect to the next URL or home page
  return NextResponse.redirect(new URL(next, requestUrl.origin));
}
