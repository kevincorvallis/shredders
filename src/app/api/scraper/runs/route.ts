import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

/**
 * Get scraper run history
 * GET /api/scraper/runs?limit=20
 */
export async function GET(request: NextRequest) {
  try {
    const supabase = createAdminClient();
    const searchParams = request.nextUrl.searchParams;
    const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 100);

    // Get recent runs - with error handling
    let runs: any[] = [];
    try {
      const { data, error } = await supabase
        .from('scraper_runs')
        .select('run_id, total_mountains, successful_count, failed_count, duration_ms, status, triggered_by, started_at, completed_at, error_message')
        .order('started_at', { ascending: false })
        .limit(limit);

      if (error) throw error;
      runs = data || [];
    } catch (error) {
      console.error('[Runs] Error fetching runs:', error);
    }

    // Get overall stats - with error handling
    let totalRuns = 0;
    let avgSuccessful = 0;
    let avgFailed = 0;
    let successRate = 0;
    let completedRuns = 0;
    let failedRuns = 0;
    let avgDurationMs = 0;

    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const { data: statsData, error } = await supabase
        .from('scraper_runs')
        .select('successful_count, failed_count, duration_ms, status')
        .gte('started_at', thirtyDaysAgo.toISOString());

      if (error) throw error;

      const stats = statsData || [];
      totalRuns = stats.length;
      if (totalRuns > 0) {
        avgSuccessful = stats.reduce((sum, r) => sum + (r.successful_count || 0), 0) / totalRuns;
        avgFailed = stats.reduce((sum, r) => sum + (r.failed_count || 0), 0) / totalRuns;
        avgDurationMs = stats.reduce((sum, r) => sum + (r.duration_ms || 0), 0) / totalRuns;
        completedRuns = stats.filter(r => r.status === 'completed').length;
        failedRuns = stats.filter(r => r.status === 'failed').length;
        successRate = avgSuccessful + avgFailed > 0
          ? (avgSuccessful / (avgSuccessful + avgFailed)) * 100
          : 0;
      }
    } catch (error) {
      console.error('[Runs] Error fetching stats:', error);
    }

    return NextResponse.json({
      runs: runs.map((row) => ({
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
          completedRuns,
          failedRuns,
          avgSuccessful: Math.round(avgSuccessful * 100) / 100,
          avgFailed: Math.round(avgFailed * 100) / 100,
          avgDurationMs: Math.round(avgDurationMs),
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
