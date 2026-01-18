import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

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
    const supabase = createAdminClient();

    // Get overall stats (last 7 days) - with error handling
    let avgSuccessful = 0;
    let avgFailed = 0;
    let successRate = 0;
    let totalRuns = 0;
    let avgDurationMs = 0;

    try {
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const { data: statsData, error } = await supabase
        .from('scraper_runs')
        .select('successful_count, failed_count, duration_ms')
        .eq('status', 'completed')
        .gte('started_at', sevenDaysAgo.toISOString());

      if (error) throw error;

      const stats = statsData || [];
      totalRuns = stats.length;
      if (totalRuns > 0) {
        avgSuccessful = stats.reduce((sum, r) => sum + (r.successful_count || 0), 0) / totalRuns;
        avgFailed = stats.reduce((sum, r) => sum + (r.failed_count || 0), 0) / totalRuns;
        avgDurationMs = stats.reduce((sum, r) => sum + (r.duration_ms || 0), 0) / totalRuns;
        successRate = avgSuccessful + avgFailed > 0
          ? (avgSuccessful / (avgSuccessful + avgFailed)) * 100
          : 0;
      }
    } catch (error) {
      console.error('[Monitor] Error fetching stats:', error);
    }

    // Get last 5 runs - with error handling
    let recentRuns: any[] = [];
    try {
      const { data, error } = await supabase
        .from('scraper_runs')
        .select('run_id, successful_count, failed_count, total_mountains, duration_ms, started_at, completed_at, status')
        .order('started_at', { ascending: false })
        .limit(5);

      if (error) throw error;
      recentRuns = data || [];
    } catch (error) {
      console.error('[Monitor] Error fetching recent runs:', error);
    }

    // Get recent failures (last 24 hours) - with error handling
    let recentFailures: any[] = [];
    try {
      const oneDayAgo = new Date();
      oneDayAgo.setDate(oneDayAgo.getDate() - 1);

      const { data, error } = await supabase
        .from('scraper_failures')
        .select('mountain_id, error_message, failed_at, source_url')
        .gte('failed_at', oneDayAgo.toISOString())
        .order('failed_at', { ascending: false })
        .limit(10);

      if (error) throw error;
      recentFailures = data || [];
    } catch (error) {
      console.error('[Monitor] Error fetching recent failures (table may not exist yet):', error);
    }

    // Get failure counts by mountain (last 7 days) - with error handling
    let failuresByMountain: any[] = [];
    try {
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const { data, error } = await supabase
        .from('scraper_failures')
        .select('mountain_id, failed_at')
        .gte('failed_at', sevenDaysAgo.toISOString());

      if (error) throw error;

      // Group by mountain_id and count
      const grouped: Record<string, { count: number; lastFailure: string }> = {};
      for (const row of data || []) {
        if (!grouped[row.mountain_id]) {
          grouped[row.mountain_id] = { count: 0, lastFailure: row.failed_at };
        }
        grouped[row.mountain_id].count++;
        if (row.failed_at > grouped[row.mountain_id].lastFailure) {
          grouped[row.mountain_id].lastFailure = row.failed_at;
        }
      }
      failuresByMountain = Object.entries(grouped)
        .map(([id, info]) => ({ mountainId: id, failureCount: info.count, lastFailure: info.lastFailure }))
        .sort((a, b) => b.failureCount - a.failureCount);
    } catch (error) {
      console.error('[Monitor] Error fetching failures by mountain (table may not exist yet):', error);
    }

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
      recentRuns: recentRuns.map((row) => ({
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
      recentFailures: recentFailures.map((row) => ({
        mountainId: row.mountain_id,
        error: row.error_message,
        sourceUrl: row.source_url,
        failedAt: row.failed_at,
      })),
      failuresByMountain: failuresByMountain,
      stats: {
        last7Days: {
          totalRuns,
          avgSuccessful: Math.round(avgSuccessful * 100) / 100,
          avgFailed: Math.round(avgFailed * 100) / 100,
          avgDurationMs: Math.round(avgDurationMs),
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
