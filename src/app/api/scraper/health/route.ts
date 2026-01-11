import { NextResponse } from 'next/server';
import { scraperStorage } from '@/lib/scraper/storage-postgres';

/**
 * Health monitoring endpoint for scraper system
 * GET /api/scraper/health
 *
 * Returns:
 * - Overall health status (healthy if success rate >= 80%)
 * - Stats about mountains and history
 * - Last 7 days performance metrics
 */
export async function GET() {
  try {
    const stats = await scraperStorage.getStats();

    // Calculate health metrics
    const successRate = stats.recentRuns.totalRuns > 0
      ? (stats.recentRuns.avgSuccessful / (stats.recentRuns.avgSuccessful + stats.recentRuns.avgFailed)) * 100
      : 0;

    const isHealthy = successRate >= 80; // 80% threshold

    return NextResponse.json({
      healthy: isHealthy,
      stats: {
        totalMountains: stats.totalMountains,
        totalHistoryEntries: stats.totalHistoryEntries,
        last7Days: {
          totalRuns: stats.recentRuns.totalRuns,
          avgSuccessful: Math.round(stats.recentRuns.avgSuccessful * 100) / 100,
          avgFailed: Math.round(stats.recentRuns.avgFailed * 100) / 100,
          avgDurationMs: Math.round(stats.recentRuns.avgDurationMs),
          successRate: Math.round(successRate * 100) / 100,
        },
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('[Health] Failed to get health status:', error);

    return NextResponse.json(
      {
        healthy: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
