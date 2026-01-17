import { NextResponse } from 'next/server';
import { scraperOrchestrator } from '@/lib/scraper/ScraperOrchestrator';

/**
 * Test endpoint to verify scraper orchestrator initialization
 */
export async function GET() {
  const start = Date.now();

  try {
    // Just get info about available scrapers
    const scrapers = scraperOrchestrator.getAvailableScrapers();
    const count = scraperOrchestrator.getScraperCount();

    return NextResponse.json({
      success: true,
      duration: Date.now() - start,
      scraperCount: count,
      scrapers: scrapers.slice(0, 3), // Just first 3 for brevity
      message: 'Scraper orchestrator initialized successfully',
    });
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start,
    }, { status: 500 });
  }
}
