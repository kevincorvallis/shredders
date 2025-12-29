import { BaseScraper } from './BaseScraper';
import type { ScraperResult, ScrapedMountainStatus } from './types';
import * as cheerio from 'cheerio';

/**
 * HTML-based scraper using Cheerio (for static pages)
 * Fast and efficient for resorts with server-rendered HTML
 */
export class HTMLScraper extends BaseScraper {
  async scrape(): Promise<ScraperResult> {
    const startTime = Date.now();

    if (!this.isEnabled()) {
      return this.createResult(false, undefined, 'Scraper disabled', startTime);
    }

    try {
      const url = this.config.dataUrl || this.config.url;
      const response = await this.fetchWithTimeout(url);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const html = await response.text();
      const $ = cheerio.load(html);

      // Extract data using configured selectors
      const selectors = this.config.selectors || {};

      const liftsText = selectors.liftsOpen ? $(selectors.liftsOpen).text().trim() : '';
      const liftsRatio = this.parseRatio(liftsText);

      const runsText = selectors.runsOpen ? $(selectors.runsOpen).text().trim() : '';
      const runsRatio = this.parseRatio(runsText);

      const percentText = selectors.percentOpen
        ? $(selectors.percentOpen).text().trim()
        : '';
      const percentOpen = this.extractPercentage(percentText);

      const acresText = selectors.acresOpen ? $(selectors.acresOpen).text().trim() : '';
      const acresOpen = this.extractNumber(acresText);

      const statusText = selectors.status ? $(selectors.status).text().trim() : '';
      const isOpen = statusText.toLowerCase().includes('open');

      const message = selectors.message ? $(selectors.message).text().trim() : undefined;

      const status: ScrapedMountainStatus = {
        mountainId: this.config.id,
        mountainName: this.config.name,
        isOpen,
        percentOpen,
        liftsOpen: liftsRatio.open,
        liftsClosed: liftsRatio.total - liftsRatio.open,
        liftsTotal: liftsRatio.total,
        runsOpen: runsRatio.open,
        runsClosed: runsRatio.total - runsRatio.open,
        runsTotal: runsRatio.total,
        acresOpen: acresOpen > 0 ? acresOpen : null,
        acresTotal: null,
        lastUpdated: new Date().toISOString(),
        message,
        source: this.config.url,
        dataUrl: url,
      };

      return this.createResult(true, status, undefined, startTime);
    } catch (error) {
      console.error(`[HTMLScraper] Error scraping ${this.config.id}:`, error);
      return this.createResult(
        false,
        this.createDefaultStatus(),
        error instanceof Error ? error.message : 'Unknown error',
        startTime
      );
    }
  }
}
