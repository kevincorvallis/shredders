import { NextResponse } from 'next/server';
import { scraperOrchestrator } from '@/lib/scraper/ScraperOrchestrator';
import { scraperStorage } from '@/lib/scraper/storage-postgres';
import { getScraperConfig } from '@/lib/scraper/configs';
import { sendScraperAlert } from '@/lib/alerts/scraper-alerts';

/**
 * Manual trigger endpoint to run the scraper
 * GET /api/scraper/run
 *
 * In production, you'd protect this with authentication
 */
export async function GET() {
  let runId: string | undefined;

  try {
    const startTime = Date.now();

    // START database tracking
    runId = await scraperStorage.startRun(15, 'manual');
    console.log(`[API] Started scraper run: ${runId}`);

    // Run all scrapers
    const results = await scraperOrchestrator.scrapeAll();

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

    console.log(`[API] Scrape completed: ${successCount}/${totalCount} successful in ${duration}ms`);

    return NextResponse.json({
      success: true,
      message: `Scraped ${successCount}/${totalCount} mountains`,
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
