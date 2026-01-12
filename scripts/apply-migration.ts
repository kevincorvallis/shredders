/**
 * Apply Database Migration Script
 *
 * This script applies the token_blacklist and audit_logs migration to Supabase
 * Run with: npx tsx scripts/apply-migration.ts
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { join } from 'path';

// Read environment variables
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing required environment variables:');
  console.error('   - NEXT_PUBLIC_SUPABASE_URL');
  console.error('   - SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

// Create Supabase client with service role key
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

async function applyMigration() {
  console.log('🚀 Starting migration...\n');

  try {
    // Read migration SQL file
    const migrationPath = join(process.cwd(), 'migrations', '001_token_blacklist_and_audit_logs.sql');
    const sql = readFileSync(migrationPath, 'utf-8');

    console.log('📄 Migration file: 001_token_blacklist_and_audit_logs.sql');
    console.log('📊 Executing SQL...\n');

    // Execute the migration
    // Note: Supabase client doesn't support raw SQL execution directly
    // We need to use the Database REST API or split the SQL into individual statements

    console.log('⚠️  Manual Migration Required');
    console.log('━'.repeat(60));
    console.log('\nThe Supabase JS client does not support executing raw SQL files.');
    console.log('Please apply this migration manually using one of these methods:\n');

    console.log('Method 1: Supabase Dashboard (Recommended)');
    console.log('  1. Go to https://supabase.com/dashboard');
    console.log('  2. Select your project');
    console.log('  3. Navigate to SQL Editor');
    console.log('  4. Create a new query');
    console.log('  5. Copy and paste the contents of:');
    console.log('     migrations/001_token_blacklist_and_audit_logs.sql');
    console.log('  6. Run the query\n');

    console.log('Method 2: Supabase CLI');
    console.log('  1. Install Supabase CLI: brew install supabase/tap/supabase');
    console.log('  2. Link your project: supabase link --project-ref <your-ref>');
    console.log('  3. Run: supabase db push\n');

    console.log('Method 3: Direct PostgreSQL Connection');
    console.log('  1. Get your database connection string from Supabase Dashboard');
    console.log('  2. Run: psql <connection-string> -f migrations/001_token_blacklist_and_audit_logs.sql\n');

    console.log('━'.repeat(60));
    console.log('\n✅ After applying the migration, Sprint 1 will be complete!\n');

  } catch (error: any) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

applyMigration();
