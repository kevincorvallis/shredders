#!/usr/bin/env node
/**
 * Verify Supabase connection and check if schema is set up
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://nmkavdrvgjkolreoexfe.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ta2F2ZHJ2Z2prb2xyZW9leGZlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzM1MTIyMSwiZXhwIjoyMDgyOTI3MjIxfQ.OcZYAAhvadNIeVlp0dPXvgq4wQ2xuYe8R804bPwWXjE';

console.log('🔍 Verifying Supabase setup...\n');

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

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

console.log('📊 Checking tables:\n');

let allTablesExist = true;
const missingTables = [];

for (const tableName of expectedTables) {
  try {
    const { count, error } = await supabase
      .from(tableName)
      .select('*', { count: 'exact', head: true });

    if (error) {
      console.log(`   ❌ ${tableName.padEnd(25)} - NOT FOUND`);
      allTablesExist = false;
      missingTables.push(tableName);
    } else {
      console.log(`   ✅ ${tableName.padEnd(25)} - EXISTS (${count || 0} rows)`);
    }
  } catch (err) {
    console.log(`   ❌ ${tableName.padEnd(25)} - ERROR: ${err.message}`);
    allTablesExist = false;
    missingTables.push(tableName);
  }
}

console.log('\n' + '='.repeat(60) + '\n');

if (allTablesExist) {
  console.log('✅ SUCCESS! All tables exist. Schema is set up correctly.\n');
  console.log('🚀 Ready to start implementing features!');
} else {
  console.log(`❌ MISSING TABLES: ${missingTables.length} of ${expectedTables.length}\n`);
  console.log('📋 TO FIX - Run the SQL schema manually:\n');
  console.log('1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/editor');
  console.log('2. Click "SQL Editor" → "+ New query"');
  console.log('3. Copy/paste contents of: scripts/setup-supabase-schema.sql');
  console.log('4. Click "Run" (bottom right)\n');
  console.log('After running, execute this script again to verify.');
}

console.log('');
