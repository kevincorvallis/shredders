import type { ScrapedMountainStatus } from './types';

/**
 * Simple in-memory storage for scraped data
 * In production, replace with a real database (PostgreSQL, MongoDB, etc.)
 *
 * Database Schema Recommendation:
 *
 * CREATE TABLE mountain_status (
 *   id SERIAL PRIMARY KEY,
 *   mountain_id VARCHAR(50) NOT NULL,
 *   mountain_name VARCHAR(100) NOT NULL,
 *   is_open BOOLEAN NOT NULL,
 *   percent_open INTEGER,
 *   lifts_open INTEGER NOT NULL DEFAULT 0,
 *   lifts_closed INTEGER NOT NULL DEFAULT 0,
 *   lifts_total INTEGER NOT NULL DEFAULT 0,
 *   runs_open INTEGER NOT NULL DEFAULT 0,
 *   runs_closed INTEGER NOT NULL DEFAULT 0,
 *   runs_total INTEGER NOT NULL DEFAULT 0,
 *   acres_open INTEGER,
 *   acres_total INTEGER,
 *   message TEXT,
 *   source VARCHAR(255) NOT NULL,
 *   data_url VARCHAR(255) NOT NULL,
 *   scraped_at TIMESTAMP WITH TIME ZONE NOT NULL,
 *   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
 * );
 *
 * CREATE INDEX idx_mountain_status_mountain_id ON mountain_status(mountain_id);
 * CREATE INDEX idx_mountain_status_scraped_at ON mountain_status(scraped_at);
 */

class ScraperStorage {
  private storage: Map<string, ScrapedMountainStatus> = new Map();
  private history: Map<string, ScrapedMountainStatus[]> = new Map();

  /**
   * Save scraped data
   */
  save(data: ScrapedMountainStatus): void {
    // Store latest
    this.storage.set(data.mountainId, data);

    // Store in history (keep last 30 days)
    if (!this.history.has(data.mountainId)) {
      this.history.set(data.mountainId, []);
    }

    const mountainHistory = this.history.get(data.mountainId)!;
    mountainHistory.push(data);

    // Keep only last 30 entries (if scraping daily, that's 30 days)
    if (mountainHistory.length > 30) {
      mountainHistory.shift();
    }

    console.log(`[Storage] Saved status for ${data.mountainId}`);
  }

  /**
   * Save multiple scraped data
   */
  saveMany(dataArray: ScrapedMountainStatus[]): void {
    for (const data of dataArray) {
      this.save(data);
    }
  }

  /**
   * Get latest status for a mountain
   */
  get(mountainId: string): ScrapedMountainStatus | null {
    return this.storage.get(mountainId) || null;
  }

  /**
   * Get all latest statuses
   */
  getAll(): ScrapedMountainStatus[] {
    return Array.from(this.storage.values());
  }

  /**
   * Get status history for a mountain
   */
  getHistory(mountainId: string, limit = 30): ScrapedMountainStatus[] {
    const history = this.history.get(mountainId) || [];
    return history.slice(-limit);
  }

  /**
   * Clear all data
   */
  clear(): void {
    this.storage.clear();
    this.history.clear();
    console.log('[Storage] Cleared all data');
  }

  /**
   * Get storage stats
   */
  getStats() {
    const totalMountains = this.storage.size;
    const totalHistory = Array.from(this.history.values()).reduce(
      (sum, arr) => sum + arr.length,
      0
    );

    return {
      totalMountains,
      totalHistoryEntries: totalHistory,
      averageHistoryPerMountain: totalMountains > 0 ? totalHistory / totalMountains : 0,
    };
  }

  /**
   * Export data (for backing up or migrating to real DB)
   */
  exportData() {
    return {
      current: Array.from(this.storage.entries()),
      history: Array.from(this.history.entries()),
      exportedAt: new Date().toISOString(),
    };
  }

  /**
   * Import data (for restoring from backup)
   */
  importData(data: any): void {
    if (data.current) {
      this.storage = new Map(data.current);
    }
    if (data.history) {
      this.history = new Map(data.history);
    }
    console.log('[Storage] Imported data');
  }
}

// Export singleton instance
export const scraperStorage = new ScraperStorage();
