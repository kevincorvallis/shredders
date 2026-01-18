#!/usr/bin/env node
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://nmkavdrvgjkolreoexfe.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ta2F2ZHJ2Z2prb2xyZW9leGZlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzM1MTIyMSwiZXhwIjoyMDgyOTI3MjIxfQ.OcZYAAhvadNIeVlp0dPXvgq4wQ2xuYe8R804bPwWXjE';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

console.log('\n🔍 Checking Supabase database tables...\n');

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
  try {
    const { count, error } = await supabase
      .from(tableName)
      .select('*', { count: 'exact', head: true });

    if (error) {
      console.log(`   ❌ Table "${tableName}": MISSING`);
    } else {
      console.log(`   ✅ Table "${tableName}": EXISTS (${count || 0} rows)`);
    }
  } catch (err) {
    console.log(`   ❌ Table "${tableName}": ERROR - ${err.message}`);
  }
}

console.log('\n✨ Table check complete!\n');
