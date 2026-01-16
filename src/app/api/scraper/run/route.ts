import { NextResponse } from 'next/server';
import { scraperOrchestrator } from '@/lib/scraper/ScraperOrchestrator';
import { scraperStorage } from '@/lib/scraper/storage-postgres';
import { getScraperConfig, getConfigsByBatch } from '@/lib/scraper/configs';
import { sendScraperAlert } from '@/lib/alerts/scraper-alerts';

/**
 * Manual trigger endpoint to run the scraper
 * GET /api/scraper/run          - Run all scrapers (may timeout on Vercel)
 * GET /api/scraper/run?batch=1  - Run batch 1 only (5 mountains)
 * GET /api/scraper/run?batch=2  - Run batch 2 only (5 mountains)
 * GET /api/scraper/run?batch=3  - Run batch 3 only (5 mountains)
 *
 * Batched scraping is recommended for Vercel to avoid function timeouts.
 * Each batch should complete in under 30 seconds.
 */
export async function GET(request: Request) {
  let runId: string | undefined;

  try {
    const { searchParams } = new URL(request.url);
    const batchParam = searchParams.get('batch');
    const batch = batchParam ? (parseInt(batchParam, 10) as 1 | 2 | 3) : null;

    // Validate batch parameter
    if (batch !== null && ![1, 2, 3].includes(batch)) {
      return NextResponse.json(
        { success: false, error: 'Invalid batch parameter. Must be 1, 2, or 3.' },
        { status: 400 }
      );
    }

    const startTime = Date.now();

    // Determine how many mountains we're scraping
    const mountainCount = batch
      ? getConfigsByBatch(batch).length
      : 15; // All mountains

    // START database tracking
    const triggeredBy = batch ? `cron-batch-${batch}` : 'manual';
    runId = await scraperStorage.startRun(mountainCount, triggeredBy);
    console.log(`[API] Started scraper run: ${runId} (batch: ${batch || 'all'})`);

    // Run scrapers (batch or all)
    const results = batch
      ? await scraperOrchestrator.scrapeBatch(batch)
      : await scraperOrchestrator.scrapeAll();

    // Extract successful results
    const successfulData = Array.from(results.values())
      .filter((r) => r.success && r.data)
      .map((r) => r.data!);

    // SAVE to database
    if (successfulData.length > 0) {
      await scraperStorage.saveMany(successfulData);
    }

    // LOG failures for monitoring
    for (const [mountainId, result] of results.entries()) {
      if (!result.success && result.error) {
        const config = getScraperConfig(mountainId);
        if (config) {
          await scraperStorage.saveFail(mountainId, result.error, config.url);
        }
      }
    }

    const duration = Date.now() - startTime;
    const successCount = successfulData.length;
    const totalCount = results.size;
    const failedCount = totalCount - successCount;

    // COMPLETE database tracking
    await scraperStorage.completeRun(successCount, failedCount, duration);

    // SEND alerts if performance is degraded or failed
    const successRate = totalCount > 0 ? (successCount / totalCount) * 100 : 0;
    const failedMountains = Array.from(results.entries())
      .filter(([_, r]) => !r.success)
      .map(([id]) => id);

    if (successRate < 80) {
      await sendScraperAlert({
        type: successRate < 50 ? 'failure' : 'degraded',
        successRate,
        failedMountains,
        runId: runId!,
      });
    }

    console.log(`[API] Scrape completed: ${successCount}/${totalCount} successful in ${duration}ms (batch: ${batch || 'all'})`);

    return NextResponse.json({
      success: true,
      message: `Scraped ${successCount}/${totalCount} mountains`,
      batch: batch || 'all',
      duration,
      results: {
        total: totalCount,
        successful: successCount,
        failed: failedCount,
      },
      data: successfulData,
      timestamp: new Date().toISOString(),
      storage: 'postgres',
      runId,
    });
  } catch (error) {
    // FAIL database tracking
    if (runId) {
      await scraperStorage.failRun(
        error instanceof Error ? error.message : 'Unknown error'
      );
    }

    console.error('[API] Scraper run failed:', error);

    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
