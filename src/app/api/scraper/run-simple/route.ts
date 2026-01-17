import { NextResponse } from 'next/server';
import { scraperOrchestrator } from '@/lib/scraper/ScraperOrchestrator';
import { getConfigsByBatch } from '@/lib/scraper/configs';

/**
 * Simple scraper endpoint that doesn't require database
 * GET /api/scraper/run-simple?batch=1  - Run batch 1 only (5 mountains)
 * GET /api/scraper/run-simple?batch=2  - Run batch 2 only (5 mountains)
 * GET /api/scraper/run-simple?batch=3  - Run batch 3 only (5 mountains)
 */
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const batchParam = searchParams.get('batch');
    const batch = batchParam ? (parseInt(batchParam, 10) as 1 | 2 | 3) : null;

    // Validate batch parameter
    if (batch === null || ![1, 2, 3].includes(batch)) {
      return NextResponse.json(
        { success: false, error: 'Invalid batch parameter. Must be 1, 2, or 3.' },
        { status: 400 }
      );
    }

    const startTime = Date.now();

    // Run scrapers (batch only, no database storage)
    const results = await scraperOrchestrator.scrapeBatch(batch);

    // Extract successful results
    const successfulData = Array.from(results.values())
      .filter((r) => r.success && r.data)
      .map((r) => r.data!);

    const duration = Date.now() - startTime;
    const successCount = successfulData.length;
    const totalCount = results.size;
    const failedCount = totalCount - successCount;

    // Get failed mountain details
    const failedMountains = Array.from(results.entries())
      .filter(([_, r]) => !r.success)
      .map(([id, r]) => ({ id, error: r.error }));

    console.log(`[API] Simple scrape completed: ${successCount}/${totalCount} successful in ${duration}ms (batch: ${batch})`);

    return NextResponse.json({
      success: true,
      message: `Scraped ${successCount}/${totalCount} mountains`,
      batch,
      duration,
      results: {
        total: totalCount,
        successful: successCount,
        failed: failedCount,
      },
      data: successfulData,
      failedMountains,
      timestamp: new Date().toISOString(),
      note: 'Results NOT saved to database (use /api/scraper/run for full functionality)',
    });
  } catch (error) {
    console.error('[API] Simple scraper run failed:', error);

    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
