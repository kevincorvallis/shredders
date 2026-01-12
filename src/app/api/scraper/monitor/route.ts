import { NextResponse } from 'next/server';
import { createClient } from '@vercel/postgres';

/**
 * Comprehensive scraper monitoring endpoint
 * GET /api/scraper/monitor
 *
 * Returns:
 * - Current health status
 * - Recent runs summary
 * - Recent failures
 * - Per-mountain success rates
 *
 * This is the main dashboard endpoint for monitoring scraper health
 */
export async function GET() {
  try {
    const db = createClient({
      connectionString: process.env.POSTGRES_URL || process.env.DATABASE_URL,
    });

    // Get overall stats (last 7 days)
    const statsResult = await db.sql`
      SELECT
        COUNT(*) as total_runs,
        AVG(successful_count) as avg_successful,
        AVG(failed_count) as avg_failed,
        AVG(duration_ms) as avg_duration_ms
      FROM scraper_runs
      WHERE started_at >= NOW() - INTERVAL '7 days'
        AND status = 'completed'
    `;

    const stats = statsResult.rows[0];
    const avgSuccessful = parseFloat(stats?.avg_successful || '0');
    const avgFailed = parseFloat(stats?.avg_failed || '0');
    const successRate =
      avgSuccessful + avgFailed > 0
        ? (avgSuccessful / (avgSuccessful + avgFailed)) * 100
        : 0;

    // Get last 5 runs
    const recentRunsResult = await db.sql`
      SELECT
        run_id,
        successful_count,
        failed_count,
        total_mountains,
        duration_ms,
        started_at,
        completed_at,
        status
      FROM scraper_runs
      ORDER BY started_at DESC
      LIMIT 5
    `;

    // Get recent failures (last 24 hours)
    const recentFailuresResult = await db.sql`
      SELECT
        mountain_id,
        error_message,
        failed_at,
        source_url
      FROM scraper_failures
      WHERE failed_at >= NOW() - INTERVAL '24 hours'
      ORDER BY failed_at DESC
      LIMIT 10
    `;

    // Get failure counts by mountain (last 7 days)
    const failuresByMountainResult = await db.sql`
      SELECT
        mountain_id,
        COUNT(*) as failure_count,
        MAX(failed_at) as last_failure
      FROM scraper_failures
      WHERE failed_at >= NOW() - INTERVAL '7 days'
      GROUP BY mountain_id
      ORDER BY failure_count DESC
    `;

    // Determine health status
    const isHealthy = successRate >= 80;
    const isDegraded = successRate >= 50 && successRate < 80;

    return NextResponse.json({
      status: isHealthy ? 'healthy' : isDegraded ? 'degraded' : 'unhealthy',
      health: {
        isHealthy,
        successRate: Math.round(successRate * 100) / 100,
        threshold: 80,
        message: isHealthy
          ? 'All systems operational'
          : isDegraded
          ? 'Performance degraded - monitoring'
          : 'Multiple failures detected',
      },
      recentRuns: recentRunsResult.rows.map((row) => ({
        runId: row.run_id,
        successful: row.successful_count,
        failed: row.failed_count,
        total: row.total_mountains,
        duration: row.duration_ms,
        startedAt: row.started_at,
        completedAt: row.completed_at,
        status: row.status,
        successRate:
          row.total_mountains > 0
            ? Math.round(
                (row.successful_count / row.total_mountains) * 100 * 100
              ) / 100
            : 0,
      })),
      recentFailures: recentFailuresResult.rows.map((row) => ({
        mountainId: row.mountain_id,
        error: row.error_message,
        sourceUrl: row.source_url,
        failedAt: row.failed_at,
      })),
      failuresByMountain: failuresByMountainResult.rows.map((row) => ({
        mountainId: row.mountain_id,
        failureCount: parseInt(row.failure_count || '0'),
        lastFailure: row.last_failure,
      })),
      stats: {
        last7Days: {
          totalRuns: parseInt(stats?.total_runs || '0'),
          avgSuccessful: Math.round(avgSuccessful * 100) / 100,
          avgFailed: Math.round(avgFailed * 100) / 100,
          avgDurationMs: Math.round(parseFloat(stats?.avg_duration_ms || '0')),
        },
      },
      alerts: {
        enabled: !!process.env.SLACK_WEBHOOK_URL,
        channels: [
          process.env.SLACK_WEBHOOK_URL ? 'slack' : null,
          process.env.ALERT_EMAIL_TO ? 'email' : null,
        ].filter(Boolean),
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('[API] Failed to get scraper monitoring data:', error);

    return NextResponse.json(
      {
        status: 'error',
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
