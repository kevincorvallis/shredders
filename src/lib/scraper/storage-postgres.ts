import { createAdminClient } from '@/lib/supabase/admin';
import type { ScrapedMountainStatus } from './types';
import { v4 as uuidv4 } from 'uuid';
import { getMountain } from '@shredders/shared';

/**
 * PostgreSQL storage for scraped mountain data
 * Uses Supabase client for database operations
 */
class PostgresScraperStorage {
  private runId: string = '';

  /**
   * Get Supabase admin client (created fresh each time to avoid stale connections)
   */
  private getClient() {
    return createAdminClient();
  }

  /**
   * Helper to map database row to ScrapedMountainStatus
   */
  private mapRowToStatus(row: any): ScrapedMountainStatus {
    const mountain = getMountain(row.mountain_id);
    const liftsOpen = row.lifts_open || 0;
    const liftsTotal = row.lifts_total || 0;
    const runsOpen = row.runs_open || 0;
    const runsTotal = row.runs_total || 0;

    return {
      mountainId: row.mountain_id,
      mountainName: mountain?.name || row.mountain_id,
      isOpen: row.is_open,
      percentOpen: row.percent_open,
      liftsOpen,
      liftsClosed: liftsTotal - liftsOpen,
      liftsTotal,
      runsOpen,
      runsClosed: runsTotal - runsOpen,
      runsTotal,
      acresOpen: null,
      acresTotal: null,
      message: row.message,
      source: row.source_url,
      dataUrl: row.source_url,
      lastUpdated: row.scraped_at,
    };
  }

  /**
   * Start a new scraper run (for tracking)
   */
  async startRun(totalMountains: number, triggeredBy = 'manual'): Promise<string> {
    this.runId = `run-${Date.now()}-${uuidv4().slice(0, 8)}`;

    try {
      const supabase = this.getClient();
      const { error } = await supabase.from('scraper_runs').insert({
        run_id: this.runId,
        total_mountains: totalMountains,
        triggered_by: triggeredBy,
        status: 'running',
      });

      if (error) throw error;
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
      const supabase = this.getClient();
      const { error } = await supabase
        .from('scraper_runs')
        .update({
          successful_count: successful,
          failed_count: failed,
          duration_ms: durationMs,
          status: 'completed',
          completed_at: new Date().toISOString(),
        })
        .eq('run_id', this.runId);

      if (error) throw error;
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
      const supabase = this.getClient();
      const { error } = await supabase
        .from('scraper_runs')
        .update({
          status: 'failed',
          error_message: errorMessage,
          completed_at: new Date().toISOString(),
        })
        .eq('run_id', this.runId);

      if (error) throw error;
      console.error(`[Storage] Failed run ${this.runId}: ${errorMessage}`);
    } catch (error) {
      console.error('[Storage] Failed to mark run as failed:', error);
    }
  }

  /**
   * Save scraped mountain data
   * Uses insert instead of upsert to avoid needing unique constraint
   */
  async save(data: ScrapedMountainStatus): Promise<void> {
    try {
      const supabase = this.getClient();
      const { error } = await supabase.from('mountain_status').insert({
        mountain_id: data.mountainId,
        is_open: data.isOpen,
        percent_open: data.percentOpen || null,
        lifts_open: data.liftsOpen,
        lifts_total: data.liftsTotal,
        runs_open: data.runsOpen,
        runs_total: data.runsTotal,
        message: data.message || null,
        conditions_message: data.message || null,
        source_url: data.source,
        scraped_at: data.lastUpdated,
      });

      if (error) {
        // Ignore duplicate key errors (23505) - data already exists
        if (error.code === '23505') {
          console.log(`[Storage] Duplicate entry for ${data.mountainId}, skipping`);
          return;
        }
        throw error;
      }
      console.log(`[Storage] Saved status for ${data.mountainId}`);
    } catch (error) {
      console.error(`[Storage] Failed to save ${data.mountainId}:`, error);
      throw error;
    }
  }

  /**
   * Save multiple scraped data in a batch
   * Uses individual inserts to handle duplicates gracefully
   */
  async saveMany(dataArray: ScrapedMountainStatus[]): Promise<void> {
    if (dataArray.length === 0) return;

    let savedCount = 0;
    let skippedCount = 0;

    // Use Promise.allSettled to insert all records, handling duplicates gracefully
    const results = await Promise.allSettled(
      dataArray.map((data) => this.save(data))
    );

    for (const result of results) {
      if (result.status === 'fulfilled') {
        savedCount++;
      } else {
        skippedCount++;
        console.error('[Storage] Failed to save:', result.reason);
      }
    }

    console.log(`[Storage] Saved ${savedCount}/${dataArray.length} mountain statuses (${skippedCount} failed)`);
  }

  /**
   * Save scraper failure details
   * Silently fails if scraper_failures table doesn't exist
   */
  async saveFail(mountainId: string, error: string, url: string): Promise<void> {
    try {
      const supabase = this.getClient();
      const { error: insertError } = await supabase.from('scraper_failures').insert({
        run_id: this.runId,
        mountain_id: mountainId,
        error_message: error,
        source_url: url,
        failed_at: new Date().toISOString(),
      });

      if (insertError) {
        // Silently skip if table doesn't exist
        if (insertError.message?.includes('scraper_failures')) {
          console.log(`[Storage] scraper_failures table not found, skipping failure log for ${mountainId}`);
          return;
        }
        throw insertError;
      }
      console.log(`[Storage] Logged failure for ${mountainId}: ${error}`);
    } catch (err) {
      // Silently log but don't throw - failure logging is optional
      console.warn(`[Storage] Could not log failure for ${mountainId}:`, err);
    }
  }

  /**
   * Get latest status for a mountain
   */
  async get(mountainId: string): Promise<ScrapedMountainStatus | null> {
    try {
      const supabase = this.getClient();
      const { data, error } = await supabase
        .from('mountain_status')
        .select('*')
        .eq('mountain_id', mountainId)
        .order('scraped_at', { ascending: false })
        .limit(1)
        .single();

      if (error) {
        if (error.code === 'PGRST116') return null; // No rows found
        throw error;
      }

      return this.mapRowToStatus(data);
    } catch (error) {
      console.error(`[Storage] Failed to get ${mountainId}:`, error);
      return null;
    }
  }

  /**
   * Get all latest statuses
   * Uses a subquery approach instead of relying on view
   */
  async getAll(): Promise<ScrapedMountainStatus[]> {
    try {
      const supabase = this.getClient();

      // First try the view if it exists
      const { data: viewData, error: viewError } = await supabase
        .from('latest_mountain_status')
        .select('*')
        .order('mountain_id');

      if (!viewError && viewData) {
        return viewData.map((row) => this.mapRowToStatus(row));
      }

      // Fallback: Get all unique mountain_ids, then get latest for each
      console.log('[Storage] View not available, using fallback query');

      // Get all records ordered by scraped_at desc, then dedupe in code
      const { data, error } = await supabase
        .from('mountain_status')
        .select('*')
        .order('scraped_at', { ascending: false });

      if (error) throw error;

      // Dedupe by mountain_id (keep first = most recent)
      const seen = new Set<string>();
      const latest = (data || []).filter((row) => {
        if (seen.has(row.mountain_id)) return false;
        seen.add(row.mountain_id);
        return true;
      });

      return latest.map((row) => this.mapRowToStatus(row));
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
      const supabase = this.getClient();
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);

      const { data, error } = await supabase
        .from('mountain_status')
        .select('*')
        .eq('mountain_id', mountainId)
        .gte('scraped_at', cutoffDate.toISOString())
        .order('scraped_at', { ascending: false });

      if (error) throw error;
      return (data || []).map((row) => this.mapRowToStatus(row));
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
      const supabase = this.getClient();

      // Get distinct mountain count
      const { count: mountainCount, error: mountainsError } = await supabase
        .from('mountain_status')
        .select('mountain_id', { count: 'exact', head: true });

      if (mountainsError) throw mountainsError;

      // Get total history count
      const { count: historyCount, error: historyError } = await supabase
        .from('mountain_status')
        .select('*', { count: 'exact', head: true });

      if (historyError) throw historyError;

      // Get recent runs stats
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 7);

      const { data: recentRuns, error: runsError } = await supabase
        .from('scraper_runs')
        .select('successful_count, failed_count, duration_ms')
        .gte('started_at', cutoffDate.toISOString());

      if (runsError) throw runsError;

      const totalRuns = recentRuns?.length || 0;
      const avgSuccessful =
        totalRuns > 0
          ? recentRuns.reduce((sum, r) => sum + (r.successful_count || 0), 0) / totalRuns
          : 0;
      const avgFailed =
        totalRuns > 0
          ? recentRuns.reduce((sum, r) => sum + (r.failed_count || 0), 0) / totalRuns
          : 0;
      const avgDurationMs =
        totalRuns > 0
          ? recentRuns.reduce((sum, r) => sum + (r.duration_ms || 0), 0) / totalRuns
          : 0;

      return {
        totalMountains: mountainCount || 0,
        totalHistoryEntries: historyCount || 0,
        recentRuns: {
          totalRuns,
          avgSuccessful,
          avgFailed,
          avgDurationMs,
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
      const supabase = this.getClient();
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 90);

      const { data, error } = await supabase
        .from('mountain_status')
        .delete()
        .lt('scraped_at', cutoffDate.toISOString())
        .select('id');

      if (error) throw error;
      const deletedCount = data?.length || 0;
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
