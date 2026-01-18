#!/usr/bin/env node
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://nmkavdrvgjkolreoexfe.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ta2F2ZHJ2Z2prb2xyZW9leGZlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzM1MTIyMSwiZXhwIjoyMDgyOTI3MjIxfQ.OcZYAAhvadNIeVlp0dPXvgq4wQ2xuYe8R804bPwWXjE';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

console.log('\n🔍 Testing users table structure...\n');

// Try to query the users table
const { data, error } = await supabase
  .from('users')
  .select('*')
  .limit(1);

if (error) {
  console.log('❌ Error querying users table:', error);
} else {
  console.log('✅ Users table is accessible!');
  console.log('Current rows:', data.length);
}

console.log('\n🧪 Testing signup flow simulation...\n');

// Simulate what the iOS app does during signup
try {
  // Check if we can access auth.users
  const { data: { users: authUsers }, error: authError } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1
  });

  if (authError) {
    console.log('❌ Cannot list auth users:', authError.message);
  } else {
    console.log(`✅ Auth system is working (${authUsers.length} users in auth.users)`);
  }
} catch (err) {
  console.log('❌ Error checking auth:', err.message);
}

console.log('\n✨ Test complete!\n');
