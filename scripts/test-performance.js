#!/usr/bin/env node

/**
 * Simple performance testing script
 * Tests API response times and caching behavior
 */

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL || 'http://localhost:3000';
const MOUNTAINS = ['baker', 'stevens', 'crystal', 'snoqualmie', 'meadows'];

async function measureRequest(url, label) {
  const start = Date.now();
  try {
    const response = await fetch(url);
    const duration = Date.now() - start;
    const data = await response.json();

    return {
      success: true,
      duration,
      cached: data.cachedAt ? true : false,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    return {
      success: false,
      duration: Date.now() - start,
      error: error.message,
    };
  }
}

async function testBatchedEndpoint() {
  console.log('\n🧪 Testing Batched Endpoint Performance...\n');

  for (const mountain of MOUNTAINS) {
    const url = `${BASE_URL}/api/mountains/${mountain}/all`;

    // First call (cache miss expected)
    const result1 = await measureRequest(url, `${mountain} - First call`);
    console.log(`  ${mountain.padEnd(12)} | First:  ${result1.duration}ms ${result1.cached ? '(cached)' : '(fresh)'}`);

    // Wait 100ms
    await new Promise(resolve => setTimeout(resolve, 100));

    // Second call (cache hit expected)
    const result2 = await measureRequest(url, `${mountain} - Second call`);
    console.log(`  ${mountain.padEnd(12)} | Second: ${result2.duration}ms ${result2.cached ? '(cached)' : '(fresh)'}`);

    // Calculate improvement
    if (result1.success && result2.success) {
      const improvement = ((result1.duration - result2.duration) / result1.duration * 100).toFixed(1);
      console.log(`  ${mountain.padEnd(12)} | Improvement: ${improvement}%\n`);
    }
  }
}

async function testPrefetching() {
  console.log('\n🚀 Testing Prefetch Pattern...\n');

  // Simulate user hovering over multiple mountains
  const prefetchPromises = MOUNTAINS.slice(0, 3).map(mountain =>
    fetch(`${BASE_URL}/api/mountains/${mountain}/all`)
  );

  const start = Date.now();
  await Promise.all(prefetchPromises);
  const duration = Date.now() - start;

  console.log(`  Prefetched ${MOUNTAINS.slice(0, 3).length} mountains in ${duration}ms (parallel)`);
  console.log(`  Average: ${(duration / 3).toFixed(0)}ms per mountain\n`);
}

async function testCacheExpiration() {
  console.log('\n⏰ Testing Cache Behavior...\n');

  const mountain = 'baker';
  const url = `${BASE_URL}/api/mountains/${mountain}/all`;

  // First call
  const result1 = await measureRequest(url);
  console.log(`  Initial request: ${result1.duration}ms`);

  // Immediate second call
  const result2 = await measureRequest(url);
  console.log(`  Cached request:  ${result2.duration}ms (${((1 - result2.duration / result1.duration) * 100).toFixed(1)}% faster)`);

  // Check if cache indicator is present
  const response = await fetch(url);
  const data = await response.json();
  if (data.cachedAt) {
    console.log(`  Cache timestamp: ${new Date(data.cachedAt).toISOString()}`);
    console.log(`  ✅ Caching is working!`);
  } else {
    console.log(`  ⚠️  No cache timestamp found`);
  }
}

async function runTests() {
  console.log('='.repeat(60));
  console.log('  Shredders Performance Test Suite');
  console.log('='.repeat(60));
  console.log(`  Base URL: ${BASE_URL}`);
  console.log(`  Time: ${new Date().toLocaleString()}`);

  try {
    await testCacheExpiration();
    await testBatchedEndpoint();
    await testPrefetching();

    console.log('\n' + '='.repeat(60));
    console.log('  ✅ All tests completed!');
    console.log('='.repeat(60) + '\n');
  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  runTests();
}

module.exports = { measureRequest, runTests };
