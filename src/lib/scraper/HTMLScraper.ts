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

      // Handle lifts: could be text like "8/10" or multiple elements to count
      const liftsText = selectors.liftsOpen ? $(selectors.liftsOpen).text().trim() : '';
      let liftsRatio = this.parseRatio(liftsText);

      // If no ratio found, count matching elements (e.g., multiple .status-open)
      if (liftsRatio.total === 0 && selectors.liftsOpen) {
        const openLifts = $(selectors.liftsOpen).length;
        if (openLifts > 0) {
          liftsRatio = { open: openLifts, total: openLifts };
        }
      }

      // Handle runs similarly
      const runsText = selectors.runsOpen ? $(selectors.runsOpen).text().trim() : '';
      let runsRatio = this.parseRatio(runsText);

      if (runsRatio.total === 0 && selectors.runsOpen) {
        const openRuns = $(selectors.runsOpen).length;
        if (openRuns > 0) {
          runsRatio = { open: openRuns, total: openRuns };
        }
      }

      const percentText = selectors.percentOpen
        ? $(selectors.percentOpen).text().trim()
        : '';
      const percentOpen = this.extractPercentage(percentText);

      const acresText = selectors.acresOpen ? $(selectors.acresOpen).text().trim() : '';
      const acresOpen = this.extractNumber(acresText);

      const statusText = selectors.status ? $(selectors.status).text().trim() : '';
      // Check for "OPEN" in status (not just "open" which might be in messages)
      const isOpen = statusText.toUpperCase().includes('OPEN') && !statusText.toUpperCase().includes('CLOSED');

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
