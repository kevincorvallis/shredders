import { NextResponse } from 'next/server';
import { scraperOrchestrator } from '@/lib/scraper/ScraperOrchestrator';

// Use PostgreSQL storage if DATABASE_URL is set, otherwise use in-memory
const usePostgres = !!process.env.DATABASE_URL;
const storage = usePostgres
  ? await import('@/lib/scraper/storage-postgres').then((m) => m.scraperStorage)
  : await import('@/lib/scraper/storage').then((m) => m.scraperStorage);

/**
 * Manual trigger endpoint to run the scraper
 * GET /api/scraper/run
 *
 * In production, you'd protect this with authentication
 */
export async function GET() {
  try {
    console.log(`[API] Starting manual scrape (${usePostgres ? 'PostgreSQL' : 'in-memory'})...`);
    const startTime = Date.now();

    // Start tracking run if using PostgreSQL
    if (usePostgres && 'startRun' in storage) {
      await storage.startRun(3, 'manual'); // 3 mountains for testing (Baker, Crystal, Snoqualmie)
    }

    // Run all scrapers
    const results = await scraperOrchestrator.scrapeAll();

    // Save successful results to storage
    const successfulData = Array.from(results.values())
      .filter((r) => r.success && r.data)
      .map((r) => r.data!);

    const duration = Date.now() - startTime;
    const successCount = successfulData.length;
    const totalCount = results.size;
    const failedCount = totalCount - successCount;

    // Save data
    if (usePostgres && 'saveMany' in storage) {
      await storage.saveMany(successfulData);
      if ('completeRun' in storage) {
        await storage.completeRun(successCount, failedCount, duration);
      }
    } else if ('saveMany' in storage) {
      storage.saveMany(successfulData);
    }

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
      storage: usePostgres ? 'postgresql' : 'in-memory',
    });
  } catch (error) {
    console.error('[API] Scraper run failed:', error);

    // Mark run as failed if using PostgreSQL
    if (usePostgres && 'failRun' in storage) {
      await storage.failRun(error instanceof Error ? error.message : 'Unknown error');
    }

    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
