#!/usr/bin/env tsx
/**
 * Test scraper utility
 * Usage:
 *   pnpm tsx scripts/test-scraper.ts           # Test all scrapers
 *   pnpm tsx scripts/test-scraper.ts baker     # Test specific mountain
 *   pnpm tsx scripts/test-scraper.ts --verbose # Show detailed output
 */

import { scraperOrchestrator } from '../src/lib/scraper/ScraperOrchestrator';
import { getScraperConfig, scraperConfigs } from '../src/lib/scraper/configs';

const args = process.argv.slice(2);
const mountainId = args.find((arg) => !arg.startsWith('--'));
const verbose = args.includes('--verbose') || args.includes('-v');

async function testSingle(id: string) {
  const config = getScraperConfig(id);
  if (!config) {
    console.error(`❌ No scraper config found for: ${id}`);
    process.exit(1);
  }

  console.log(`\n🏔️  Testing ${config.name} (${id})...`);
  console.log(`   URL: ${config.dataUrl || config.url}`);
  console.log(`   Type: ${config.type}`);
  console.log(`   Enabled: ${config.enabled ? '✅' : '❌'}`);

  if (!config.enabled) {
    console.log(`   ⚠️  Scraper is disabled, skipping...`);
    return;
  }

  const startTime = Date.now();
  const result = await scraperOrchestrator.scrapeMountain(id);
  const duration = Date.now() - startTime;

  if (result.success && result.data) {
    console.log(`   ✅ SUCCESS (${duration}ms)`);
    console.log(`      Open: ${result.data.isOpen ? 'YES' : 'NO'}`);
    console.log(`      Lifts: ${result.data.liftsOpen}/${result.data.liftsTotal}`);
    console.log(`      Runs: ${result.data.runsOpen}/${result.data.runsTotal}`);
    if (result.data.percentOpen) {
      console.log(`      % Open: ${result.data.percentOpen}%`);
    }
    if (result.data.message) {
      console.log(`      Message: ${result.data.message.substring(0, 60)}...`);
    }

    if (verbose) {
      console.log(`\n      Full Data:`);
      console.log(JSON.stringify(result.data, null, 2));
    }
  } else {
    console.log(`   ❌ FAILED (${duration}ms)`);
    console.log(`      Error: ${result.error}`);
  }
}

async function testAll() {
  console.log(`\n🏔️  Testing all ${scraperOrchestrator.getScraperCount()} scrapers...`);

  const results = await scraperOrchestrator.scrapeAll();

  console.log(`\n📊 Results Summary:\n`);

  let successCount = 0;
  let failedCount = 0;

  const resultsList: Array<{
    id: string;
    name: string;
    success: boolean;
    duration: number;
    error?: string;
    data?: any;
  }> = [];

  for (const [id, result] of results.entries()) {
    const config = getScraperConfig(id);
    if (!config) continue;

    resultsList.push({
      id,
      name: config.name,
      success: result.success,
      duration: result.duration,
      error: result.error,
      data: result.data,
    });

    if (result.success) {
      successCount++;
    } else {
      failedCount++;
    }
  }

  // Sort by success status (failures first), then by name
  resultsList.sort((a, b) => {
    if (a.success !== b.success) {
      return a.success ? 1 : -1;
    }
    return a.name.localeCompare(b.name);
  });

  // Print results
  for (const item of resultsList) {
    const icon = item.success ? '✅' : '❌';
    const status = item.success ? 'SUCCESS' : 'FAILED ';
    console.log(
      `${icon} ${status} | ${item.name.padEnd(25)} | ${item.duration}ms`
    );

    if (!item.success && item.error) {
      console.log(`          Error: ${item.error}`);
    }

    if (item.success && item.data && verbose) {
      console.log(
        `          Lifts: ${item.data.liftsOpen}/${item.data.liftsTotal}, Runs: ${item.data.runsOpen}/${item.data.runsTotal}`
      );
    }
  }

  const successRate = ((successCount / (successCount + failedCount)) * 100).toFixed(1);

  console.log(`\n📈 Success Rate: ${successCount}/${successCount + failedCount} (${successRate}%)`);

  if (parseFloat(successRate) < 80) {
    console.log(`⚠️  SUCCESS RATE BELOW 80% THRESHOLD!`);
    console.log(`   Alerts would be triggered in production.`);
  } else {
    console.log(`✅ Success rate above 80% threshold - healthy!`);
  }

  // Exit with error code if success rate is too low
  if (parseFloat(successRate) < 50) {
    process.exit(1);
  }
}

async function main() {
  try {
    if (mountainId) {
      await testSingle(mountainId);
    } else {
      await testAll();
    }
  } catch (error) {
    console.error('❌ Test failed:', error);
    process.exit(1);
  }
}

main();
