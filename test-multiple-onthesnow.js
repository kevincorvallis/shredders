/**
 * Test OnTheSnow JSON parser on multiple resorts
 */

import * as cheerio from 'cheerio';

const testUrls = [
  { name: 'Crystal Mountain', url: 'https://www.onthesnow.com/washington/crystal-mountain-wa/skireport' },
  { name: 'Stevens Pass', url: 'https://www.onthesnow.com/washington/stevens-pass-resort/skireport' },
  { name: 'Mt. Bachelor', url: 'https://www.onthesnow.com/oregon/mt-bachelor/skireport' },
];

async function testResort(name, url) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      return { name, success: false, error: `HTTP ${response.status}` };
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    const scriptContent = $('#__NEXT_DATA__').html();
    if (!scriptContent) {
      return { name, success: false, error: '__NEXT_DATA__ not found' };
    }

    const data = JSON.parse(scriptContent);
    const fullResort = data?.props?.pageProps?.fullResort;

    if (!fullResort) {
      return { name, success: false, error: 'fullResort not found' };
    }

    const liftsOpen = fullResort.lifts?.open || 0;
    const liftsTotal = fullResort.lifts?.total || 0;
    const runsOpen = fullResort.runs?.open || 0;
    const runsTotal = fullResort.runs?.total || 0;

    return {
      name,
      success: true,
      lifts: `${liftsOpen}/${liftsTotal}`,
      runs: `${runsOpen}/${runsTotal}`,
      status: fullResort.status || 'Unknown',
    };
  } catch (error) {
    return { name, success: false, error: error.message };
  }
}

async function runTests() {
  console.log('Testing OnTheSnow JSON parser on multiple resorts...\n');

  for (const { name, url } of testUrls) {
    console.log(`Testing ${name}...`);
    const result = await testResort(name, url);

    if (result.success) {
      console.log(`  ✅ SUCCESS - Lifts: ${result.lifts}, Runs: ${result.runs}, Status: ${result.status}`);
    } else {
      console.log(`  ❌ FAILED - ${result.error}`);
    }
  }

  console.log('\n✅ All tests completed!');
}

runTests();
