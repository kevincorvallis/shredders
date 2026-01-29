/**
 * Script to confirm test user's email for UI testing
 * Run with: node scripts/confirm-test-user.js
 */

const fs = require('fs');
const path = require('path');

// Manual .env.local parsing
const envPath = path.join(__dirname, '..', '.env.local');
const envContent = fs.readFileSync(envPath, 'utf8');
envContent.split('\n').forEach(line => {
  const trimmed = line.trim();
  if (trimmed && !trimmed.startsWith('#')) {
    const [key, ...valueParts] = trimmed.split('=');
    const value = valueParts.join('=');
    if (key && value) {
      process.env[key] = value;
    }
  }
});

const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function run() {
  console.log('Fetching users...');

  const { data: authUsers, error } = await supabase.auth.admin.listUsers({ perPage: 20 });
  if (error) {
    console.error('Error fetching users:', error);
    return;
  }

  console.log(`Found ${authUsers.users.length} users:\n`);
  authUsers.users.forEach(u => {
    const confirmed = u.email_confirmed_at ? '✓' : '✗';
    console.log(`  ${confirmed} ${u.email}`);
  });

  // Find and confirm testuser123@gmail.com
  const testEmail = 'testuser123@gmail.com';
  const testUser = authUsers.users.find(u => u.email === testEmail);

  if (!testUser) {
    console.log(`\nTest user ${testEmail} not found.`);
    return;
  }

  if (testUser.email_confirmed_at) {
    console.log(`\n${testEmail} is already confirmed!`);
  } else {
    console.log(`\nConfirming email for ${testEmail}...`);
    const { error: updateError } = await supabase.auth.admin.updateUserById(testUser.id, {
      email_confirm: true
    });

    if (updateError) {
      console.error('Failed to confirm:', updateError);
    } else {
      console.log('Email confirmed successfully!');
    }
  }

  // Test login after confirmation
  console.log('\nTesting Supabase login...');
  const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
    email: testEmail,
    password: 'TestPassword123!'
  });

  if (loginError) {
    console.error('Login failed:', loginError.message);
  } else {
    console.log('Login successful! User ID:', loginData.user.id);
  }

  // Check if user profile exists
  console.log('\nChecking user profile in users table...');
  const { data: profile, error: profileError } = await supabase
    .from('users')
    .select('*')
    .eq('email', testEmail)
    .single();

  if (profileError) {
    console.error('Profile not found:', profileError.message);
    console.log('Profile may be missing - this could cause login API to fail');
  } else {
    console.log('Profile found:', profile.username, '| auth_user_id:', profile.auth_user_id);
  }
}

run().catch(console.error);
