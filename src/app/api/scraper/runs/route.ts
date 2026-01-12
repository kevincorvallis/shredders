import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@vercel/postgres';

/**
 * Get scraper run history
 * GET /api/scraper/runs?limit=20
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 100);

    const db = createClient({
      connectionString: process.env.POSTGRES_URL || process.env.DATABASE_URL,
    });

    // Get recent runs
    const runsResult = await db.sql`
      SELECT
        run_id,
        total_mountains,
        successful_count,
        failed_count,
        duration_ms,
        status,
        triggered_by,
        started_at,
        completed_at,
        error_message
      FROM scraper_runs
      ORDER BY started_at DESC
      LIMIT ${limit}
    `;

    // Get overall stats
    const statsResult = await db.sql`
      SELECT
        COUNT(*) as total_runs,
        AVG(successful_count) as avg_successful,
        AVG(failed_count) as avg_failed,
        AVG(duration_ms) as avg_duration_ms,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_runs,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_runs
      FROM scraper_runs
      WHERE started_at >= NOW() - INTERVAL '30 days'
    `;

    const stats = statsResult.rows[0];
    const totalRuns = parseInt(stats?.total_runs || '0');
    const avgSuccessful = parseFloat(stats?.avg_successful || '0');
    const avgFailed = parseFloat(stats?.avg_failed || '0');
    const successRate =
      avgSuccessful + avgFailed > 0
        ? (avgSuccessful / (avgSuccessful + avgFailed)) * 100
        : 0;

    return NextResponse.json({
      runs: runsResult.rows.map((row) => ({
        runId: row.run_id,
        totalMountains: row.total_mountains,
        successful: row.successful_count,
        failed: row.failed_count,
        duration: row.duration_ms,
        status: row.status,
        triggeredBy: row.triggered_by,
        startedAt: row.started_at,
        completedAt: row.completed_at,
        error: row.error_message,
        successRate:
          row.total_mountains > 0
            ? Math.round(
                (row.successful_count / row.total_mountains) * 100 * 100
              ) / 100
            : 0,
      })),
      stats: {
        last30Days: {
          totalRuns,
          completedRuns: parseInt(stats?.completed_runs || '0'),
          failedRuns: parseInt(stats?.failed_runs || '0'),
          avgSuccessful: Math.round(avgSuccessful * 100) / 100,
          avgFailed: Math.round(avgFailed * 100) / 100,
          avgDurationMs: Math.round(parseFloat(stats?.avg_duration_ms || '0')),
          overallSuccessRate: Math.round(successRate * 100) / 100,
        },
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('[API] Failed to get scraper runs:', error);

    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : 'Failed to get runs',
      },
      { status: 500 }
    );
  }
}
