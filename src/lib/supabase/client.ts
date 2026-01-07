/**
 * Supabase Browser Client
 *
 * Use this client for:
 * - Client-side React components
 * - Browser JavaScript
 * - Auth operations (login, signup, signout)
 * - Real-time subscriptions
 *
 * This client respects Row Level Security (RLS) policies.
 */

import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
