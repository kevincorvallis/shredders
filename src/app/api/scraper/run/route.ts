import { NextResponse } from 'next/server';
import { scraperOrchestrator } from '@/lib/scraper/ScraperOrchestrator';

/**
 * Manual trigger endpoint to run the scraper
 * GET /api/scraper/run
 *
 * In production, you'd protect this with authentication
 */
export async function GET() {
  try {
    console.log('[API] Starting manual scrape (no database persistence)...');
    const startTime = Date.now();

    // Run all scrapers
    const results = await scraperOrchestrator.scrapeAll();

    // Extract successful results
    const successfulData = Array.from(results.values())
      .filter((r) => r.success && r.data)
      .map((r) => r.data!);

    const duration = Date.now() - startTime;
    const successCount = successfulData.length;
    const totalCount = results.size;
    const failedCount = totalCount - successCount;

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
      storage: 'none',
    });
  } catch (error) {
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
