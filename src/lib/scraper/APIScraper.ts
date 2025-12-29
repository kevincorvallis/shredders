import { BaseScraper } from './BaseScraper';
import type { ScraperResult, ScrapedMountainStatus } from './types';

/**
 * API-based scraper for resorts that provide JSON endpoints
 * More reliable than HTML scraping when available
 */
export class APIScraper extends BaseScraper {
  async scrape(): Promise<ScraperResult> {
    const startTime = Date.now();

    if (!this.isEnabled()) {
      return this.createResult(false, undefined, 'Scraper disabled', startTime);
    }

    if (!this.config.apiConfig) {
      return this.createResult(false, undefined, 'API config missing', startTime);
    }

    try {
      const { endpoint, method, headers, transform } = this.config.apiConfig;

      const response = await this.fetchWithTimeout(endpoint, {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();

      // Use the transform function to convert API response to our format
      const partialStatus = transform(data);

      // Build complete status object
      const status: ScrapedMountainStatus = {
        mountainId: this.config.id,
        mountainName: this.config.name,
        isOpen: partialStatus.isOpen ?? false,
        percentOpen: partialStatus.percentOpen ?? null,
        liftsOpen: partialStatus.liftsOpen ?? 0,
        liftsClosed: partialStatus.liftsClosed ?? 0,
        liftsTotal: partialStatus.liftsTotal ?? 0,
        runsOpen: partialStatus.runsOpen ?? 0,
        runsClosed: partialStatus.runsClosed ?? 0,
        runsTotal: partialStatus.runsTotal ?? 0,
        acresOpen: partialStatus.acresOpen ?? null,
        acresTotal: partialStatus.acresTotal ?? null,
        lastUpdated: new Date().toISOString(),
        message: partialStatus.message,
        source: this.config.url,
        dataUrl: endpoint,
      };

      return this.createResult(true, status, undefined, startTime);
    } catch (error) {
      console.error(`[APIScraper] Error scraping ${this.config.id}:`, error);
      return this.createResult(
        false,
        this.createDefaultStatus(),
        error instanceof Error ? error.message : 'Unknown error',
        startTime
      );
    }
  }
}
