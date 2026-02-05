/**
 * Supabase Admin Client
 *
 * Use this client for:
 * - Admin operations that bypass RLS
 * - Background jobs and cron tasks
 * - System-level operations
 * - Lambda/serverless functions
 *
 * ⚠️ WARNING: This client bypasses ALL security policies!
 * Only use in trusted server-side code. NEVER expose to client.
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';

let _adminClient: SupabaseClient | null = null;

export function createAdminClient(): SupabaseClient {
  if (_adminClient) return _adminClient;

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY is not set');
  }

  _adminClient = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );

  return _adminClient;
}
