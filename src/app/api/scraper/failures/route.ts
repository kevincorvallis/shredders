import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@vercel/postgres';

/**
 * Get recent scraper failures for debugging
 * GET /api/scraper/failures?days=7&mountainId=baker
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const days = parseInt(searchParams.get('days') || '7');
    const mountainId = searchParams.get('mountainId');

    const db = createClient({
      connectionString: process.env.POSTGRES_URL || process.env.DATABASE_URL,
    });

    let result;
    if (mountainId) {
      // Get failures for specific mountain
      result = await db.sql`
        SELECT
          f.id,
          f.run_id,
          f.mountain_id,
          f.error_message,
          f.source_url,
          f.failed_at,
          r.started_at as run_started_at,
          r.successful_count,
          r.failed_count
        FROM scraper_failures f
        LEFT JOIN scraper_runs r ON f.run_id = r.run_id
        WHERE f.mountain_id = ${mountainId}
          AND f.failed_at >= NOW() - INTERVAL '${days} days'
        ORDER BY f.failed_at DESC
        LIMIT 100
      `;
    } else {
      // Get all recent failures
      result = await db.sql`
        SELECT
          f.id,
          f.run_id,
          f.mountain_id,
          f.error_message,
          f.source_url,
          f.failed_at,
          r.started_at as run_started_at,
          r.successful_count,
          r.failed_count
        FROM scraper_failures f
        LEFT JOIN scraper_runs r ON f.run_id = r.run_id
        WHERE f.failed_at >= NOW() - INTERVAL '${days} days'
        ORDER BY f.failed_at DESC
        LIMIT 100
      `;
    }

    // Group failures by mountain for summary
    const failuresByMountain = result.rows.reduce(
      (acc, row) => {
        if (!acc[row.mountain_id]) {
          acc[row.mountain_id] = {
            mountainId: row.mountain_id,
            count: 0,
            lastFailure: row.failed_at,
            errors: [],
          };
        }
        acc[row.mountain_id].count++;
        if (acc[row.mountain_id].errors.length < 5) {
          acc[row.mountain_id].errors.push(row.error_message);
        }
        return acc;
      },
      {} as Record<
        string,
        {
          mountainId: string;
          count: number;
          lastFailure: string;
          errors: string[];
        }
      >
    );

    return NextResponse.json({
      failures: result.rows.map((row) => ({
        id: row.id,
        runId: row.run_id,
        mountainId: row.mountain_id,
        error: row.error_message,
        sourceUrl: row.source_url,
        failedAt: row.failed_at,
        runStartedAt: row.run_started_at,
        runStats: {
          successful: row.successful_count,
          failed: row.failed_count,
        },
      })),
      summary: Object.values(failuresByMountain).sort((a, b) => b.count - a.count),
      filters: {
        days,
        mountainId: mountainId || 'all',
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('[API] Failed to get scraper failures:', error);

    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : 'Failed to get failures',
      },
      { status: 500 }
    );
  }
}
