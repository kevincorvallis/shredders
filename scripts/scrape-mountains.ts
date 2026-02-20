/**
 * Standalone mountain scraper script for GitHub Actions
 * Runs all mountains directly (no Vercel, no batching needed)
 * Writes results to Supabase PostgreSQL
 *
 * Usage: pnpm tsx scripts/scrape-mountains.ts
 */

import { scraperOrchestrator } from '../src/lib/scraper/ScraperOrchestrator';
import { scraperStorage } from '../src/lib/scraper/storage-postgres';
import { getScraperConfig, getEnabledConfigs } from '../src/lib/scraper/configs';
import { sendScraperAlert } from '../src/lib/alerts/scraper-alerts';

async function main() {
  const startTime = Date.now();
  const configs = getEnabledConfigs();
  console.log(`[Scraper] Starting scrape of ${configs.length} mountains...`);

  const runId = await scraperStorage.startRun(configs.length, 'github-actions');

  try {
    const results = await scraperOrchestrator.scrapeAll();

    const successfulData = Array.from(results.values())
      .filter((r) => r.success && r.data)
      .map((r) => r.data!);

    if (successfulData.length > 0) {
      await scraperStorage.saveMany(successfulData);
    }

    // Log failures
    for (const [mountainId, result] of results.entries()) {
      if (!result.success && result.error) {
        const config = getScraperConfig(mountainId);
        if (config) {
          await scraperStorage.saveFail(runId, mountainId, result.error, config.url);
        }
      }
    }

    const duration = Date.now() - startTime;
    const successCount = successfulData.length;
    const totalCount = results.size;
    const failedCount = totalCount - successCount;

    await scraperStorage.completeRun(runId, successCount, failedCount, duration);

    // Alert if degraded
    const successRate = totalCount > 0 ? (successCount / totalCount) * 100 : 0;
    if (successRate < 80) {
      const failedMountains = Array.from(results.entries())
        .filter(([_, r]) => !r.success)
        .map(([id]) => id);

      await sendScraperAlert({
        type: successRate < 50 ? 'failure' : 'degraded',
        successRate,
        failedMountains,
        runId,
      });
    }

    console.log(`[Scraper] Done: ${successCount}/${totalCount} successful in ${duration}ms`);

    if (failedCount > 0) {
      const failed = Array.from(results.entries())
        .filter(([_, r]) => !r.success)
        .map(([id, r]) => `  ${id}: ${r.error}`);
      console.log(`[Scraper] Failures:\n${failed.join('\n')}`);
    }

    process.exit(failedCount > 0 && successRate < 50 ? 1 : 0);
  } catch (error) {
    await scraperStorage.failRun(runId, error instanceof Error ? error.message : 'Unknown error');
    console.error('[Scraper] Fatal error:', error);
    process.exit(1);
  }
}

main();
