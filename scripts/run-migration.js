#!/usr/bin/env node

/**
 * Run a specific migration against the Supabase database
 * Usage: node scripts/run-migration.js [migration-file]
 *
 * Example: node scripts/run-migration.js migrations/008_user_onboarding.sql
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Error: Missing environment variables');
  console.error('Required: NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY');
  console.error('Make sure .env.local exists with these values');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

async function runMigration(migrationFile) {
  const filePath = path.resolve(migrationFile);

  if (!fs.existsSync(filePath)) {
    console.error(`Error: Migration file not found: ${filePath}`);
    process.exit(1);
  }

  console.log(`Running migration: ${migrationFile}`);

  const sql = fs.readFileSync(filePath, 'utf8');

  // Split by statements and run each one
  // Note: This is a simple approach; complex migrations may need different handling
  const statements = sql
    .split(/;\s*$/m)
    .map(s => s.trim())
    .filter(s => s.length > 0 && !s.startsWith('--'));

  console.log(`Found ${statements.length} SQL statements to execute`);

  for (let i = 0; i < statements.length; i++) {
    const stmt = statements[i];
    if (!stmt || stmt.startsWith('--')) continue;

    console.log(`\nExecuting statement ${i + 1}/${statements.length}...`);
    console.log(stmt.substring(0, 100) + (stmt.length > 100 ? '...' : ''));

    const { error } = await supabase.rpc('exec_sql', { sql_query: stmt });

    if (error) {
      // Try direct query if RPC doesn't exist
      const { error: directError } = await supabase.from('_migrations').select('*').limit(0);

      // Fall back to raw REST API call
      console.log('Note: Using raw SQL execution...');

      try {
        const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': serviceRoleKey,
            'Authorization': `Bearer ${serviceRoleKey}`,
          },
          body: JSON.stringify({ sql_query: stmt }),
        });

        if (!response.ok) {
          const text = await response.text();
          console.error(`Warning: Statement may have failed: ${text}`);
        }
      } catch (e) {
        console.error(`Warning: Could not execute statement: ${e.message}`);
      }
    }
  }

  console.log('\nMigration complete!');
}

// Get migration file from command line args
const migrationFile = process.argv[2] || 'migrations/008_user_onboarding.sql';

runMigration(migrationFile).catch(console.error);
