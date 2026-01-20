/**
 * Supabase Server Client
 *
 * Use this client for:
 * - Server components
 * - API routes
 * - Server-side data fetching
 * - Middleware
 *
 * This client reads auth cookies and respects RLS policies.
 */

import { createServerClient } from '@supabase/ssr';
import { createClient as createSupabaseClient } from '@supabase/supabase-js';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) => {
              cookieStore.set(name, value, options);
            });
          } catch (error) {
            // Cookie setting can fail in middleware
            // This is expected when the response is already sent
          }
        },
      },
    }
  );
}

/**
 * Create a Supabase admin client that bypasses RLS
 *
 * Use this client sparingly for:
 * - Creating records that trigger automatic related inserts
 * - Admin operations that need to bypass row-level security
 *
 * This client uses the service role key and should NEVER be exposed client-side.
 */
export function createAdminClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error('Missing Supabase admin credentials');
  }

  return createSupabaseClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
