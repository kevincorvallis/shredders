import { HTMLScraper } from './HTMLScraper';
import { APIScraper } from './APIScraper';
import { PuppeteerScraper } from './PuppeteerScraper';
import { getEnabledConfigs, getScraperConfig, getConfigsByBatch } from './configs';
import type { BaseScraper } from './BaseScraper';
import type { ScraperResult, ScraperConfig } from './types';

/**
 * Orchestrates all mountain scrapers
 * Manages concurrent scraping, rate limiting, and result aggregation
 */
export class ScraperOrchestrator {
  private scrapers: Map<string, BaseScraper> = new Map();

  constructor() {
    this.initializeScrapers();
  }

  /**
   * Initialize scrapers for all enabled mountains
   */
  private initializeScrapers() {
    const configs = getEnabledConfigs();

    for (const config of configs) {
      const scraper = this.createScraper(config);
      if (scraper) {
        this.scrapers.set(config.id, scraper);
      }
    }

    console.log(`[ScraperOrchestrator] Initialized ${this.scrapers.size} scrapers`);
  }

  /**
   * Create appropriate scraper based on config type
   */
  private createScraper(config: ScraperConfig): BaseScraper | null {
    switch (config.type) {
      case 'html':
        return new HTMLScraper(config);
      case 'api':
        return new APIScraper(config);
      case 'dynamic':
        // Use Puppeteer for dynamic/JavaScript-heavy sites
        console.log(
          `[ScraperOrchestrator] Using Puppeteer scraper for ${config.id}`
        );
        return new PuppeteerScraper(config);
      default:
        console.error(`[ScraperOrchestrator] Unknown scraper type for ${config.id}`);
        return null;
    }
  }

  /**
   * Scrape a single mountain
   */
  async scrapeMountain(mountainId: string): Promise<ScraperResult> {
    const scraper = this.scrapers.get(mountainId);

    if (!scraper) {
      return {
        success: false,
        error: `No scraper found for ${mountainId}`,
        timestamp: new Date().toISOString(),
        duration: 0,
      };
    }

    console.log(`[ScraperOrchestrator] Scraping ${mountainId}...`);
    const result = await scraper.scrape();
    console.log(
      `[ScraperOrchestrator] ${mountainId}: ${result.success ? 'SUCCESS' : 'FAILED'} (${result.duration}ms)`
    );

    return result;
  }

  /**
   * Scrape all enabled mountains in parallel
   */
  async scrapeAll(): Promise<Map<string, ScraperResult>> {
    console.log(`[ScraperOrchestrator] Starting scrape of ${this.scrapers.size} mountains...`);
    const startTime = Date.now();

    const results = new Map<string, ScraperResult>();

    // Scrape all mountains in parallel
    const promises = Array.from(this.scrapers.keys()).map(async (mountainId) => {
      const result = await this.scrapeMountain(mountainId);
      return { mountainId, result };
    });

    const settled = await Promise.allSettled(promises);

    // Collect results
    for (const item of settled) {
      if (item.status === 'fulfilled') {
        results.set(item.value.mountainId, item.value.result);
      } else {
        console.error(`[ScraperOrchestrator] Scraping failed:`, item.reason);
      }
    }

    const duration = Date.now() - startTime;
    const successCount = Array.from(results.values()).filter((r) => r.success).length;

    console.log(
      `[ScraperOrchestrator] Completed: ${successCount}/${results.size} successful (${duration}ms)`
    );

    return results;
  }

  /**
   * Scrape mountains by batch number
   * Used for distributed scraping to avoid Vercel function timeouts
   */
  async scrapeBatch(batch: 1 | 2 | 3): Promise<Map<string, ScraperResult>> {
    const configs = getConfigsByBatch(batch);
    console.log(`[ScraperOrchestrator] Starting batch ${batch} scrape of ${configs.length} mountains...`);
    const startTime = Date.now();

    const results = new Map<string, ScraperResult>();

    // Ensure scrapers exist for batch configs
    for (const config of configs) {
      if (!this.scrapers.has(config.id)) {
        const scraper = this.createScraper(config);
        if (scraper) {
          this.scrapers.set(config.id, scraper);
        }
      }
    }

    // Scrape batch mountains in parallel
    const promises = configs.map(async (config) => {
      const result = await this.scrapeMountain(config.id);
      return { mountainId: config.id, result };
    });

    const settled = await Promise.allSettled(promises);

    // Collect results
    for (const item of settled) {
      if (item.status === 'fulfilled') {
        results.set(item.value.mountainId, item.value.result);
      } else {
        console.error(`[ScraperOrchestrator] Batch ${batch} scraping failed:`, item.reason);
      }
    }

    const duration = Date.now() - startTime;
    const successCount = Array.from(results.values()).filter((r) => r.success).length;

    console.log(
      `[ScraperOrchestrator] Batch ${batch} completed: ${successCount}/${results.size} successful (${duration}ms)`
    );

    return results;
  }

  /**
   * Scrape mountains by region
   */
  async scrapeRegion(region: 'washington' | 'oregon' | 'idaho'): Promise<Map<string, ScraperResult>> {
    const configs = getEnabledConfigs().filter((c) => {
      const config = getScraperConfig(c.id);
      // You'd need to add region info to ScraperConfig
      // For now, this is a placeholder
      return true;
    });

    const results = new Map<string, ScraperResult>();

    for (const config of configs) {
      const result = await this.scrapeMountain(config.id);
      results.set(config.id, result);
    }

    return results;
  }

  /**
   * Get list of all available scrapers
   */
  getAvailableScrapers() {
    return Array.from(this.scrapers.values()).map((scraper) => scraper.getInfo());
  }

  /**
   * Check if a specific scraper exists
   */
  hasScraper(mountainId: string): boolean {
    return this.scrapers.has(mountainId);
  }

  /**
   * Get scraper count
   */
  getScraperCount(): number {
    return this.scrapers.size;
  }
}

// Export singleton instance
export const scraperOrchestrator = new ScraperOrchestrator();
