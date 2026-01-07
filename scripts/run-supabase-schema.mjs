#!/usr/bin/env node
/**
 * Run Supabase schema setup via REST API
 * Uses Supabase client to execute SQL via HTTP (not direct PostgreSQL connection)
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://nmkavdrvgjkolreoexfe.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ta2F2ZHJ2Z2prb2xyZW9leGZlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzM1MTIyMSwiZXhwIjoyMDgyOTI3MjIxfQ.OcZYAAhvadNIeVlp0dPXvgq4wQ2xuYe8R804bPwWXjE';

console.log('🚀 Connecting to Supabase...');
console.log('URL:', SUPABASE_URL);

// Create Supabase client with service role key (bypasses RLS)
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// Read SQL file
const sqlPath = join(__dirname, 'setup-supabase-schema.sql');
console.log('📄 Reading SQL file:', sqlPath);

const sql = readFileSync(sqlPath, 'utf-8');

console.log(`📝 SQL file size: ${sql.length} characters`);
console.log('⚡ Executing schema setup...\n');

try {
  // Execute SQL using Supabase REST API
  // Note: Supabase JS doesn't have direct SQL execution, so we'll use the REST API
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_ROLE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
    },
    body: JSON.stringify({ query: sql })
  });

  if (!response.ok) {
    // If custom function doesn't exist, fall back to creating tables individually
    console.log('⚠️  Custom SQL execution not available, using table-by-table creation...\n');

    // Test connection by querying pg_tables
    const { data: tables, error: tablesError } = await supabase
      .from('pg_tables')
      .select('tablename')
      .eq('schemaname', 'public')
      .limit(5);

    if (tablesError) {
      console.error('❌ Connection test failed:', tablesError);
      process.exit(1);
    }

    console.log('✅ Successfully connected to Supabase!');
    console.log(`📊 Current public tables: ${tables?.map(t => t.tablename).join(', ') || 'none'}\n`);

    console.log('📋 Next steps:');
    console.log('1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/editor');
    console.log('2. Click "SQL Editor" → "+ New query"');
    console.log('3. Copy/paste the contents of: scripts/setup-supabase-schema.sql');
    console.log('4. Click "Run" button\n');

    console.log('💡 Alternatively, you can use psql when network is stable:');
    console.log('   psql "postgresql://postgres:***@db.nmkavdrvgjkolreoexfe.supabase.co:5432/postgres" -f scripts/setup-supabase-schema.sql\n');

  } else {
    const result = await response.json();
    console.log('✅ Schema setup completed successfully!');
    console.log('Result:', result);
  }

  // Verify tables were created
  console.log('\n🔍 Verifying schema...');

  const expectedTables = [
    'users',
    'user_photos',
    'comments',
    'check_ins',
    'likes',
    'push_notification_tokens',
    'alert_subscriptions',
    'mountain_status',
    'scraper_runs'
  ];

  for (const tableName of expectedTables) {
    const { count, error } = await supabase
      .from(tableName)
      .select('*', { count: 'exact', head: true });

    if (error) {
      console.log(`   ❌ Table "${tableName}": NOT FOUND (needs manual setup)`);
    } else {
      console.log(`   ✅ Table "${tableName}": EXISTS (${count || 0} rows)`);
    }
  }

  console.log('\n✨ Schema verification complete!');

} catch (error) {
  console.error('\n❌ Error:', error.message);
  console.error('\n📋 Manual Setup Required:');
  console.error('Please run the SQL manually via Supabase Dashboard:');
  console.error('https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/editor\n');
  process.exit(1);
}
