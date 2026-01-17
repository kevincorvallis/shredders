import { NextResponse } from 'next/server';
import { scraperStorage } from '@/lib/scraper/storage-postgres';

/**
 * Test endpoint to verify database connection
 */
export async function GET() {
  const start = Date.now();

  try {
    // Just test getting stats from the database
    const stats = await scraperStorage.getStats();

    return NextResponse.json({
      success: true,
      duration: Date.now() - start,
      stats,
      message: 'Database connection successful',
    });
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start,
    }, { status: 500 });
  }
}
