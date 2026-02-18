import { HTMLScraper } from './HTMLScraper';
import { APIScraper } from './APIScraper';
// PuppeteerScraper is dynamically imported to avoid loading chromium on every request
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
   * Note: PuppeteerScraper is dynamically imported to avoid loading chromium when not needed
   */
  private createScraper(config: ScraperConfig): BaseScraper | null {
    switch (config.type) {
      case 'html':
        return new HTMLScraper(config);
      case 'api':
        return new APIScraper(config);
      case 'dynamic':
        // Puppeteer scrapers are created asynchronously via createScraperAsync
        console.warn(
          `[ScraperOrchestrator] Dynamic scraper ${config.id} requires async creation - skipping sync init`
        );
        return null;
      default:
        console.error(`[ScraperOrchestrator] Unknown scraper type for ${config.id}`);
        return null;
    }
  }

  /**
   * Create scraper asynchronously (for dynamic/Puppeteer scrapers)
   * This avoids loading chromium on every request
   */
  private async createScraperAsync(config: ScraperConfig): Promise<BaseScraper | null> {
    if (config.type === 'dynamic') {
      console.log(`[ScraperOrchestrator] Dynamically loading Puppeteer scraper for ${config.id}`);
      const { PuppeteerScraper } = await import('./PuppeteerScraper');
      return new PuppeteerScraper(config);
    }
    return this.createScraper(config);
  }

  /**
   * Scrape a single mountain
   */
  async scrapeMountain(mountainId: string): Promise<ScraperResult> {
    let scraper: BaseScraper | null | undefined = this.scrapers.get(mountainId);

    // If scraper doesn't exist, check if it's a dynamic type that needs async creation
    if (!scraper) {
      const config = getScraperConfig(mountainId);
      if (config && config.type === 'dynamic') {
        scraper = await this.createScraperAsync(config);
        if (scraper) {
          this.scrapers.set(mountainId, scraper);
        }
      }
    }

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
  async scrapeBatch(batch: number): Promise<Map<string, ScraperResult>> {
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
