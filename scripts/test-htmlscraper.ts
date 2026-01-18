/**
 * Test HTMLScraper with OnTheSnow JSON parser
 */

import { HTMLScraper } from '../src/lib/scraper/HTMLScraper';
import { scraperConfigs } from '../src/lib/scraper/configs';

async function testHTMLScraper() {
  console.log('Testing HTMLScraper with OnTheSnow JSON parser...\n');

  // Test 3 OnTheSnow scrapers
  const testIds = ['crystal', 'stevens', 'bachelor'];

  for (const mountainId of testIds) {
    const config = scraperConfigs[mountainId];
    if (!config) {
      console.log(`❌ Config not found for ${mountainId}`);
      continue;
    }

    console.log(`Testing ${config.name}...`);
    const scraper = new HTMLScraper(config);

    try {
      const result = await scraper.scrape();

      if (result.success && result.data) {
        console.log(`  ✅ SUCCESS`);
        console.log(`     Lifts: ${result.data.liftsOpen}/${result.data.liftsTotal}`);
        console.log(`     Runs: ${result.data.runsOpen}/${result.data.runsTotal}`);
        console.log(`     Status: ${result.data.isOpen ? 'OPEN' : 'CLOSED'}`);
      } else {
        console.log(`  ❌ FAILED: ${result.error}`);
      }
    } catch (error) {
      console.log(`  ❌ ERROR: ${error instanceof Error ? error.message : String(error)}`);
    }

    console.log('');
  }
}

testHTMLScraper();
