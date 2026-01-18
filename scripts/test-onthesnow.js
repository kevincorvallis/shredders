/**
 * Quick test script for OnTheSnow JSON parser
 * Tests the new JSON parsing logic on Crystal Mountain
 */

import * as cheerio from 'cheerio';

async function testOnTheSnow() {
  const url = 'https://www.onthesnow.com/washington/crystal-mountain-wa/skireport';

  console.log('Testing OnTheSnow JSON parser...');
  console.log(`URL: ${url}\n`);

  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    // Find the __NEXT_DATA__ script tag
    const scriptContent = $('#__NEXT_DATA__').html();
    if (!scriptContent) {
      throw new Error('__NEXT_DATA__ script not found');
    }

    const data = JSON.parse(scriptContent);
    const pageProps = data?.props?.pageProps;

    if (!pageProps) {
      throw new Error('PageProps not found in JSON');
    }

    const fullResort = pageProps.fullResort;

    if (!fullResort) {
      throw new Error('fullResort not found in JSON');
    }

    // Extract the data from fullResort
    const liftsOpen = fullResort.lifts?.open || 0;
    const liftsTotal = fullResort.lifts?.total || 0;
    const runsOpen = fullResort.runs?.open || fullResort.trails?.open || 0;
    const runsTotal = fullResort.runs?.total || fullResort.trails?.total || 0;
    const isOpen = fullResort.status === 'Open' || liftsOpen > 0;

    console.log('✅ Successfully parsed OnTheSnow JSON!\n');
    console.log('Resort:', fullResort.title);
    console.log(`Lifts: ${liftsOpen}/${liftsTotal} open`);
    console.log(`Runs: ${runsOpen}/${runsTotal} open`);
    console.log(`Acres Open: ${fullResort.terrain?.acres?.open || 'N/A'}`);
    console.log(`Status: ${isOpen ? 'OPEN' : 'CLOSED'}`);

    if (fullResort.depths) {
      console.log('\nSnow Depths:');
      console.log(`  Base: ${fullResort.depths.base || 'N/A'}"`);
      console.log(`  Mid: ${fullResort.depths.mid || 'N/A'}"`);
      console.log(`  Summit: ${fullResort.depths.summit || 'N/A'}"`);
    }

    console.log('\n✅ OnTheSnow JSON parser working correctly!');

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

testOnTheSnow();
