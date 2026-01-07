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
