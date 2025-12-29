import { sql } from '@vercel/postgres';
import type { ScrapedMountainStatus } from './types';
import { v4 as uuidv4 } from 'uuid';

/**
 * PostgreSQL storage for scraped mountain data
 * Uses Vercel Postgres (or any PostgreSQL database with DATABASE_URL)
 */
class PostgresScraperStorage {
  private runId: string = '';

  /**
   * Start a new scraper run (for tracking)
   */
  async startRun(totalMountains: number, triggeredBy = 'manual'): Promise<string> {
    this.runId = `run-${Date.now()}-${uuidv4().slice(0, 8)}`;

    try {
      await sql`
        INSERT INTO scraper_runs (
          run_id,
          total_mountains,
          triggered_by,
          status
        ) VALUES (
          ${this.runId},
          ${totalMountains},
          ${triggeredBy},
          'running'
        )
      `;
      console.log(`[Storage] Started scraper run: ${this.runId}`);
      return this.runId;
    } catch (error) {
      console.error('[Storage] Failed to start run:', error);
      throw error;
    }
  }

  /**
   * Complete a scraper run
   */
  async completeRun(successful: number, failed: number, durationMs: number): Promise<void> {
    if (!this.runId) return;

    try {
      await sql`
        UPDATE scraper_runs
        SET
          successful_count = ${successful},
          failed_count = ${failed},
          duration_ms = ${durationMs},
          status = 'completed',
          completed_at = NOW()
        WHERE run_id = ${this.runId}
      `;
      console.log(`[Storage] Completed run ${this.runId}: ${successful}/${successful + failed} successful`);
    } catch (error) {
      console.error('[Storage] Failed to complete run:', error);
    }
  }

  /**
   * Mark a scraper run as failed
   */
  async failRun(errorMessage: string): Promise<void> {
    if (!this.runId) return;

    try {
      await sql`
        UPDATE scraper_runs
        SET
          status = 'failed',
          error_message = ${errorMessage},
          completed_at = NOW()
        WHERE run_id = ${this.runId}
      `;
      console.error(`[Storage] Failed run ${this.runId}: ${errorMessage}`);
    } catch (error) {
      console.error('[Storage] Failed to mark run as failed:', error);
    }
  }

  /**
   * Save scraped mountain data
   */
  async save(data: ScrapedMountainStatus): Promise<void> {
    try {
      await sql`
        INSERT INTO mountain_status (
          mountain_id,
          is_open,
          percent_open,
          lifts_open,
          lifts_total,
          runs_open,
          runs_total,
          message,
          conditions_message,
          source_url,
          scraped_at
        ) VALUES (
          ${data.mountainId},
          ${data.isOpen},
          ${data.percentOpen || null},
          ${data.liftsOpen},
          ${data.liftsTotal},
          ${data.runsOpen},
          ${data.runsTotal},
          ${data.message || null},
          ${data.message || null},
          ${data.source},
          ${data.lastUpdated}
        )
        ON CONFLICT (mountain_id, scraped_at)
        DO UPDATE SET
          is_open = EXCLUDED.is_open,
          percent_open = EXCLUDED.percent_open,
          lifts_open = EXCLUDED.lifts_open,
          lifts_total = EXCLUDED.lifts_total,
          runs_open = EXCLUDED.runs_open,
          runs_total = EXCLUDED.runs_total,
          message = EXCLUDED.message,
          conditions_message = EXCLUDED.conditions_message,
          source_url = EXCLUDED.source_url
      `;
      console.log(`[Storage] Saved status for ${data.mountainId}`);
    } catch (error) {
      console.error(`[Storage] Failed to save ${data.mountainId}:`, error);
      throw error;
    }
  }

  /**
   * Save multiple scraped data in a transaction
   */
  async saveMany(dataArray: ScrapedMountainStatus[]): Promise<void> {
    if (dataArray.length === 0) return;

    try {
      // Use Promise.all to insert all in parallel (PostgreSQL handles this well)
      await Promise.all(dataArray.map((data) => this.save(data)));
      console.log(`[Storage] Saved ${dataArray.length} mountain statuses`);
    } catch (error) {
      console.error('[Storage] Failed to save multiple:', error);
      throw error;
    }
  }

  /**
   * Get latest status for a mountain
   */
  async get(mountainId: string): Promise<ScrapedMountainStatus | null> {
    try {
      const result = await sql`
        SELECT
          mountain_id,
          is_open,
          percent_open,
          lifts_open,
          lifts_total,
          runs_open,
          runs_total,
          message,
          source_url,
          scraped_at
        FROM mountain_status
        WHERE mountain_id = ${mountainId}
        ORDER BY scraped_at DESC
        LIMIT 1
      `;

      if (result.rows.length === 0) return null;

      const row = result.rows[0];
      return {
        mountainId: row.mountain_id,
        isOpen: row.is_open,
        percentOpen: row.percent_open,
        liftsOpen: row.lifts_open,
        liftsTotal: row.lifts_total,
        runsOpen: row.runs_open,
        runsTotal: row.runs_total,
        message: row.message,
        source: row.source_url,
        lastUpdated: row.scraped_at,
      };
    } catch (error) {
      console.error(`[Storage] Failed to get ${mountainId}:`, error);
      return null;
    }
  }

  /**
   * Get all latest statuses
   */
  async getAll(): Promise<ScrapedMountainStatus[]> {
    try {
      const result = await sql`
        SELECT
          mountain_id,
          is_open,
          percent_open,
          lifts_open,
          lifts_total,
          runs_open,
          runs_total,
          message,
          source_url,
          scraped_at
        FROM latest_mountain_status
        ORDER BY mountain_id
      `;

      return result.rows.map((row) => ({
        mountainId: row.mountain_id,
        isOpen: row.is_open,
        percentOpen: row.percent_open,
        liftsOpen: row.lifts_open,
        liftsTotal: row.lifts_total,
        runsOpen: row.runs_open,
        runsTotal: row.runs_total,
        message: row.message,
        source: row.source_url,
        lastUpdated: row.scraped_at,
      }));
    } catch (error) {
      console.error('[Storage] Failed to get all:', error);
      return [];
    }
  }

  /**
   * Get status history for a mountain
   */
  async getHistory(mountainId: string, days = 30): Promise<ScrapedMountainStatus[]> {
    try {
      const result = await sql`
        SELECT
          mountain_id,
          is_open,
          percent_open,
          lifts_open,
          lifts_total,
          runs_open,
          runs_total,
          message,
          source_url,
          scraped_at
        FROM mountain_status
        WHERE mountain_id = ${mountainId}
          AND scraped_at >= NOW() - INTERVAL '${days} days'
        ORDER BY scraped_at DESC
      `;

      return result.rows.map((row) => ({
        mountainId: row.mountain_id,
        isOpen: row.is_open,
        percentOpen: row.percent_open,
        liftsOpen: row.lifts_open,
        liftsTotal: row.lifts_total,
        runsOpen: row.runs_open,
        runsTotal: row.runs_total,
        message: row.message,
        source: row.source_url,
        lastUpdated: row.scraped_at,
      }));
    } catch (error) {
      console.error(`[Storage] Failed to get history for ${mountainId}:`, error);
      return [];
    }
  }

  /**
   * Get storage stats
   */
  async getStats() {
    try {
      const mountainsResult = await sql`
        SELECT COUNT(DISTINCT mountain_id) as total_mountains
        FROM mountain_status
      `;

      const historyResult = await sql`
        SELECT COUNT(*) as total_history
        FROM mountain_status
      `;

      const recentRunsResult = await sql`
        SELECT
          COUNT(*) as total_runs,
          AVG(successful_count) as avg_successful,
          AVG(failed_count) as avg_failed,
          AVG(duration_ms) as avg_duration_ms
        FROM scraper_runs
        WHERE started_at >= NOW() - INTERVAL '7 days'
      `;

      return {
        totalMountains: parseInt(mountainsResult.rows[0]?.total_mountains || '0'),
        totalHistoryEntries: parseInt(historyResult.rows[0]?.total_history || '0'),
        recentRuns: {
          totalRuns: parseInt(recentRunsResult.rows[0]?.total_runs || '0'),
          avgSuccessful: parseFloat(recentRunsResult.rows[0]?.avg_successful || '0'),
          avgFailed: parseFloat(recentRunsResult.rows[0]?.avg_failed || '0'),
          avgDurationMs: parseFloat(recentRunsResult.rows[0]?.avg_duration_ms || '0'),
        },
      };
    } catch (error) {
      console.error('[Storage] Failed to get stats:', error);
      return {
        totalMountains: 0,
        totalHistoryEntries: 0,
        recentRuns: {
          totalRuns: 0,
          avgSuccessful: 0,
          avgFailed: 0,
          avgDurationMs: 0,
        },
      };
    }
  }

  /**
   * Cleanup old data (keep last 90 days)
   */
  async cleanup(): Promise<number> {
    try {
      const result = await sql`
        SELECT cleanup_old_mountain_status() as deleted_count
      `;
      const deletedCount = result.rows[0]?.deleted_count || 0;
      console.log(`[Storage] Cleaned up ${deletedCount} old records`);
      return deletedCount;
    } catch (error) {
      console.error('[Storage] Failed to cleanup:', error);
      return 0;
    }
  }
}

// Export singleton instance
export const scraperStorage = new PostgresScraperStorage();
