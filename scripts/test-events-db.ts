#!/usr/bin/env tsx
/**
 * Test script to verify Events feature database integration
 *
 * This script tests:
 * 1. Database schema and tables existence
 * 2. Events API GET endpoint (unauthenticated)
 * 3. Events API GET endpoint (authenticated)
 * 4. Database query performance
 * 5. RLS policies
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://nmkavdrvgjkolreoexfe.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ta2F2ZHJ2Z2prb2xyZW9leGZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNTEyMjEsImV4cCI6MjA4MjkyNzIyMX0.VlmkBrD3i7eFfMg7SuZHACqa29r0GHZiU4FFzfB6P7Q';
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

interface TestResult {
  name: string;
  passed: boolean;
  message: string;
  duration?: number;
}

const results: TestResult[] = [];

function logTest(name: string, passed: boolean, message: string, duration?: number) {
  const emoji = passed ? '✅' : '❌';
  const durationStr = duration ? ` (${duration}ms)` : '';
  console.log(`${emoji} ${name}${durationStr}`);
  if (!passed || process.env.VERBOSE) {
    console.log(`   ${message}`);
  }
  results.push({ name, passed, message, duration });
}

async function testDatabaseSchema() {
  console.log('\n📊 Testing Database Schema...\n');

  // Test events table exists
  const start1 = Date.now();
  const { data: events, error: eventsError } = await supabase
    .from('events')
    .select('id')
    .limit(1);

  logTest(
    'Events table accessible',
    !eventsError,
    eventsError?.message || 'Table exists and is queryable',
    Date.now() - start1
  );

  // Test event_attendees table exists
  const start2 = Date.now();
  const { data: attendees, error: attendeesError } = await supabase
    .from('event_attendees')
    .select('id')
    .limit(1);

  logTest(
    'Event attendees table accessible',
    !attendeesError,
    attendeesError?.message || 'Table exists and is queryable',
    Date.now() - start2
  );

  // Test event_invite_tokens table exists
  const start3 = Date.now();
  const { data: tokens, error: tokensError } = await supabase
    .from('event_invite_tokens')
    .select('id')
    .limit(1);

  logTest(
    'Event invite tokens table accessible',
    !tokensError,
    tokensError?.message || 'Table exists and is queryable',
    Date.now() - start3
  );
}

async function testEventsQuery() {
  console.log('\n🔍 Testing Events Queries...\n');

  // Test basic events query
  const start1 = Date.now();
  const { data: allEvents, error: allError, count } = await supabase
    .from('events')
    .select('*', { count: 'exact' })
    .eq('status', 'active')
    .limit(10);

  logTest(
    'Fetch active events',
    !allError && Array.isArray(allEvents),
    allError?.message || `Found ${count} active events, fetched ${allEvents?.length || 0}`,
    Date.now() - start1
  );

  // Test upcoming events query
  const start2 = Date.now();
  const today = new Date().toISOString().split('T')[0];
  const { data: upcomingEvents, error: upcomingError } = await supabase
    .from('events')
    .select('*')
    .eq('status', 'active')
    .gte('event_date', today)
    .order('event_date', { ascending: true })
    .limit(20);

  logTest(
    'Fetch upcoming events',
    !upcomingError && Array.isArray(upcomingEvents),
    upcomingError?.message || `Found ${upcomingEvents?.length || 0} upcoming events`,
    Date.now() - start2
  );

  // Test events with creator info
  const start3 = Date.now();
  const { data: eventsWithCreator, error: creatorError } = await supabase
    .from('events')
    .select(`
      *,
      creator:user_id (
        id,
        username,
        display_name,
        avatar_url
      )
    `)
    .eq('status', 'active')
    .limit(5);

  logTest(
    'Fetch events with creator info (JOIN)',
    !creatorError && Array.isArray(eventsWithCreator),
    creatorError?.message || `Successfully joined creator data for ${eventsWithCreator?.length || 0} events`,
    Date.now() - start3
  );

  // Test mountain filter
  const start4 = Date.now();
  const { data: mountainEvents, error: mountainError } = await supabase
    .from('events')
    .select('*')
    .eq('status', 'active')
    .eq('mountain_id', 'stevens')
    .limit(10);

  logTest(
    'Filter events by mountain',
    !mountainError,
    mountainError?.message || `Found ${mountainEvents?.length || 0} events for Stevens Pass`,
    Date.now() - start4
  );
}

async function testEventAttendees() {
  console.log('\n👥 Testing Event Attendees...\n');

  // Get an event to test with
  const { data: events } = await supabase
    .from('events')
    .select('id')
    .eq('status', 'active')
    .limit(1);

  if (!events || events.length === 0) {
    logTest(
      'Event attendees query structure',
      true,
      'No active events found (empty database - this is OK for fresh installs)'
    );
    return;
  }

  const eventId = events[0].id;

  // Test attendees query
  const start1 = Date.now();
  const { data: attendees, error: attendeesError } = await supabase
    .from('event_attendees')
    .select('*')
    .eq('event_id', eventId);

  logTest(
    'Fetch event attendees',
    !attendeesError,
    attendeesError?.message || `Found ${attendees?.length || 0} attendees for event ${eventId.substring(0, 8)}...`,
    Date.now() - start1
  );

  // Test attendees count query
  const start2 = Date.now();
  const { count, error: countError } = await supabase
    .from('event_attendees')
    .select('*', { count: 'exact', head: true })
    .eq('event_id', eventId)
    .in('status', ['going', 'maybe']);

  logTest(
    'Count event attendees',
    !countError,
    countError?.message || `${count || 0} people attending event`,
    Date.now() - start2
  );
}

async function testAPIEndpoint() {
  console.log('\n🌐 Testing API Endpoints...\n');

  // Test unauthenticated GET /api/events
  try {
    const start1 = Date.now();
    const response = await fetch(`${API_BASE_URL}/api/events?upcoming=true&limit=10`);
    const data = await response.json();

    logTest(
      'GET /api/events (unauthenticated)',
      response.ok && data.events && Array.isArray(data.events),
      response.ok
        ? `Received ${data.events.length} events with pagination info`
        : `Failed with status ${response.status}: ${data.error || 'Unknown error'}`,
      Date.now() - start1
    );

    if (response.ok && data.events.length > 0) {
      const event = data.events[0];
      const hasRequiredFields =
        event.id &&
        event.title &&
        event.mountainId &&
        event.eventDate &&
        event.status;

      logTest(
        'Event data structure',
        hasRequiredFields,
        hasRequiredFields
          ? 'All required fields present in event object'
          : `Missing fields. Event: ${JSON.stringify(event).substring(0, 100)}...`
      );
    }
  } catch (error: any) {
    logTest(
      'GET /api/events (unauthenticated)',
      false,
      `Network error: ${error.message}. Is the dev server running on ${API_BASE_URL}?`
    );
  }

  // Test mountain filter
  try {
    const start2 = Date.now();
    const response = await fetch(`${API_BASE_URL}/api/events?mountainId=stevens&upcoming=true`);
    const data = await response.json();

    logTest(
      'GET /api/events with mountain filter',
      response.ok && Array.isArray(data.events),
      response.ok
        ? `Filtered to ${data.events.length} Stevens Pass events`
        : `Failed with status ${response.status}`,
      Date.now() - start2
    );
  } catch (error: any) {
    logTest(
      'GET /api/events with mountain filter',
      false,
      `Network error: ${error.message}`
    );
  }
}

async function testRLSPolicies() {
  console.log('\n🔒 Testing Row Level Security...\n');

  // Test that only active events are visible
  const start1 = Date.now();
  const { data: activeOnly, error: activeError } = await supabase
    .from('events')
    .select('id, status');

  const hasNonActive = activeOnly?.some(e => e.status !== 'active');

  logTest(
    'RLS: Only active events visible',
    !activeError && !hasNonActive,
    hasNonActive
      ? `Found non-active events visible to anon role: ${activeOnly?.filter(e => e.status !== 'active').length}`
      : 'Only active events are visible (RLS working)',
    Date.now() - start1
  );

  // Test that unauthenticated users cannot create events
  const start2 = Date.now();
  const { error: insertError } = await supabase
    .from('events')
    .insert({
      user_id: '00000000-0000-0000-0000-000000000000',
      mountain_id: 'test',
      title: 'Test Event',
      event_date: '2099-12-31',
    });

  logTest(
    'RLS: Unauthenticated insert blocked',
    insertError !== null,
    insertError
      ? 'Insert correctly blocked by RLS policy'
      : 'WARNING: Unauthenticated insert succeeded (RLS may be misconfigured)',
    Date.now() - start2
  );
}

async function testPerformance() {
  console.log('\n⚡ Testing Query Performance...\n');

  // Test query performance with limit
  const iterations = 5;
  const times: number[] = [];

  for (let i = 0; i < iterations; i++) {
    const start = Date.now();
    await supabase
      .from('events')
      .select('*, creator:user_id(id, username, display_name)')
      .eq('status', 'active')
      .gte('event_date', new Date().toISOString().split('T')[0])
      .order('event_date', { ascending: true })
      .limit(20);
    times.push(Date.now() - start);
  }

  const avgTime = times.reduce((a, b) => a + b, 0) / times.length;
  const maxTime = Math.max(...times);
  const minTime = Math.min(...times);

  logTest(
    'Query performance',
    avgTime < 1000,
    `Average: ${avgTime.toFixed(0)}ms, Min: ${minTime}ms, Max: ${maxTime}ms (over ${iterations} queries)`,
    avgTime
  );
}

async function printSummary() {
  console.log('\n' + '='.repeat(60));
  console.log('📋 TEST SUMMARY');
  console.log('='.repeat(60) + '\n');

  const passed = results.filter(r => r.passed).length;
  const failed = results.filter(r => !r.passed).length;
  const total = results.length;

  console.log(`Total Tests: ${total}`);
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`Success Rate: ${((passed / total) * 100).toFixed(1)}%`);

  if (failed > 0) {
    console.log('\n' + '⚠️  FAILED TESTS:'.padEnd(60, ' '));
    console.log('-'.repeat(60));
    results.filter(r => !r.passed).forEach(r => {
      console.log(`\n${r.name}`);
      console.log(`  ${r.message}`);
    });
  }

  console.log('\n' + '='.repeat(60) + '\n');

  process.exit(failed > 0 ? 1 : 0);
}

async function main() {
  console.log('🧪 Events Feature - Database Integration Test');
  console.log('='.repeat(60));
  console.log(`Supabase URL: ${SUPABASE_URL}`);
  console.log(`API Base URL: ${API_BASE_URL}`);
  console.log('='.repeat(60));

  try {
    await testDatabaseSchema();
    await testEventsQuery();
    await testEventAttendees();
    await testRLSPolicies();
    await testPerformance();
    await testAPIEndpoint();
  } catch (error: any) {
    console.error('\n❌ Fatal error during tests:', error.message);
    console.error(error.stack);
    process.exit(1);
  }

  await printSummary();
}

main();
