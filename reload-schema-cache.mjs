#!/usr/bin/env node
/**
 * Reload Supabase PostgREST schema cache
 * This tells the REST API layer to refresh its knowledge of database tables
 */

const SUPABASE_URL = 'https://nmkavdrvgjkolreoexfe.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ta2F2ZHJ2Z2prb2xyZW9leGZlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzM1MTIyMSwiZXhwIjoyMDgyOTI3MjIxfQ.OcZYAAhvadNIeVlp0dPXvgq4wQ2xuYe8R804bPwWXjE';

console.log('\n🔄 Reloading Supabase PostgREST schema cache...\n');

try {
  // Method 1: Send NOTIFY command via RPC
  console.log('Method 1: Attempting to send NOTIFY pgrst signal...');

  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/reload_schema`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_ROLE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
    },
    body: JSON.stringify({})
  });

  if (response.ok) {
    console.log('✅ Schema cache reload signal sent successfully!\n');
  } else {
    const errorText = await response.text();
    console.log(`⚠️  Method 1 failed (${response.status}): ${errorText}\n`);

    // Method 2: Make a GET request to trigger schema introspection
    console.log('Method 2: Triggering schema introspection via OPTIONS request...');

    const optionsResponse = await fetch(`${SUPABASE_URL}/rest/v1/`, {
      method: 'OPTIONS',
      headers: {
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Prefer': 'schema-reload'
      }
    });

    if (optionsResponse.ok) {
      console.log('✅ Schema introspection triggered!\n');
    } else {
      console.log(`⚠️  Method 2 failed (${optionsResponse.status})\n`);
    }
  }

  // Wait a moment for cache to refresh
  console.log('⏳ Waiting 3 seconds for cache refresh...\n');
  await new Promise(resolve => setTimeout(resolve, 3000));

  // Test if it worked
  console.log('🧪 Testing if schema cache is now updated...\n');

  const testResponse = await fetch(`${SUPABASE_URL}/rest/v1/users?limit=0`, {
    headers: {
      'apikey': SUPABASE_SERVICE_ROLE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      'Prefer': 'count=exact'
    }
  });

  if (testResponse.ok) {
    const countHeader = testResponse.headers.get('Content-Range');
    console.log('✅ SUCCESS! Users table is now accessible via REST API!');
    console.log(`   Schema cache has been refreshed successfully.`);
    if (countHeader) {
      console.log(`   ${countHeader}\n`);
    }
  } else {
    const errorText = await testResponse.text();
    console.log('❌ Schema cache still not updated:', errorText);
    console.log('\n📋 Manual fix required:');
    console.log('1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/settings/general');
    console.log('2. Click "Pause project" then "Resume project"');
    console.log('3. This will force a complete schema cache reload\n');
  }

} catch (error) {
  console.error('❌ Error:', error.message);
  console.log('\n📋 Manual fix required:');
  console.log('1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/settings/general');
  console.log('2. Click "Pause project" then "Resume project"');
  console.log('3. This will force a complete schema cache reload\n');
}
