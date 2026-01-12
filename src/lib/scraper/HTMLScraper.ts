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

      // Check if this is an OnTheSnow page and parse JSON if so
      if (this.isOnTheSnow(url)) {
        return this.parseOnTheSnow($, url, startTime);
      }

      // Extract data using configured selectors
      const selectors = this.config.selectors || {};

      let liftsRatio = { open: 0, total: 0 };
      let runsRatio = { open: 0, total: 0 };

      // Try regex patterns first (for OnTheSnow-style text extraction)
      if (selectors.liftsPattern || selectors.runsPattern) {
        liftsRatio = this.extractPattern(html, selectors.liftsPattern);
        runsRatio = this.extractPattern(html, selectors.runsPattern);
      }

      // Fallback to CSS selectors if patterns didn't find anything
      if (liftsRatio.total === 0 && selectors.liftsOpen) {
        const liftsText = $(selectors.liftsOpen).text().trim();
        liftsRatio = this.parseRatio(liftsText);

        // If no ratio found, count matching elements (e.g., multiple .status-open)
        if (liftsRatio.total === 0) {
          const openLifts = $(selectors.liftsOpen).length;
          if (openLifts > 0) {
            liftsRatio = { open: openLifts, total: openLifts };
          }
        }
      }

      // Handle runs similarly
      if (runsRatio.total === 0 && selectors.runsOpen) {
        const runsText = $(selectors.runsOpen).text().trim();
        runsRatio = this.parseRatio(runsText);

        if (runsRatio.total === 0) {
          const openRuns = $(selectors.runsOpen).length;
          if (openRuns > 0) {
            runsRatio = { open: openRuns, total: openRuns };
          }
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

  /**
   * Check if URL is from OnTheSnow.com
   */
  private isOnTheSnow(url: string): boolean {
    try {
      const urlObj = new URL(url);
      return urlObj.hostname.includes('onthesnow.com');
    } catch {
      return false;
    }
  }

  /**
   * Parse OnTheSnow's __NEXT_DATA__ JSON for resort data
   * OnTheSnow uses Next.js and embeds all data in a JSON script tag
   */
  private parseOnTheSnow($: cheerio.CheerioAPI, url: string, startTime: number): ScraperResult {
    try {
      // Find the __NEXT_DATA__ script tag
      const scriptContent = $('#__NEXT_DATA__').html();
      if (!scriptContent) {
        throw new Error('__NEXT_DATA__ script not found on OnTheSnow page');
      }

      const data = JSON.parse(scriptContent);
      const pageProps = data?.props?.pageProps;

      if (!pageProps) {
        throw new Error('PageProps not found in __NEXT_DATA__ JSON');
      }

      // OnTheSnow stores lift/run data in fullResort object
      const fullResort = pageProps.fullResort;
      if (!fullResort) {
        throw new Error('fullResort data not found in __NEXT_DATA__ JSON');
      }

      // Extract lift and run counts from fullResort
      const liftsOpen = fullResort.lifts?.open || 0;
      const liftsTotal = fullResort.lifts?.total || 0;
      const runsOpen = fullResort.runs?.open || fullResort.trails?.open || 0;
      const runsTotal = fullResort.runs?.total || fullResort.trails?.total || 0;

      // Determine if resort is open
      const isOpen = fullResort.status === 'Open' || liftsOpen > 0;

      // Extract snow depths if available
      const baseDepth = fullResort.depths?.base || fullResort.snow?.base || null;

      const status: ScrapedMountainStatus = {
        mountainId: this.config.id,
        mountainName: this.config.name,
        isOpen,
        percentOpen: runsTotal > 0 ? Math.round((runsOpen / runsTotal) * 100) : null,
        liftsOpen,
        liftsClosed: liftsTotal - liftsOpen,
        liftsTotal,
        runsOpen,
        runsClosed: runsTotal - runsOpen,
        runsTotal,
        acresOpen: fullResort.terrain?.acres?.open || null,
        acresTotal: fullResort.terrain?.acres?.total || null,
        lastUpdated: new Date().toISOString(),
        message: fullResort.comment || undefined,
        source: this.config.url,
        dataUrl: url,
      };

      console.log(`[HTMLScraper] OnTheSnow JSON parsed for ${this.config.id}: ${liftsOpen}/${liftsTotal} lifts, ${runsOpen}/${runsTotal} runs`);

      return this.createResult(true, status, undefined, startTime);
    } catch (error) {
      console.error(`[HTMLScraper] Failed to parse OnTheSnow JSON for ${this.config.id}:`, error);
      return this.createResult(
        false,
        this.createDefaultStatus(),
        error instanceof Error ? error.message : 'OnTheSnow JSON parsing failed',
        startTime
      );
    }
  }

  /**
   * Extract lift/run ratios using regex patterns (for text-based extraction)
   * Matches patterns like "5 of 8 lifts" or "10/15 runs"
   */
  private extractPattern(text: string, pattern: RegExp | undefined): { open: number; total: number } {
    if (!pattern) {
      return { open: 0, total: 0 };
    }

    const matches = [...text.matchAll(pattern)];
    if (matches.length > 0 && matches[0].length >= 3) {
      const open = parseInt(matches[0][1], 10);
      const total = parseInt(matches[0][2], 10);

      // Validate numbers are reasonable
      if (!isNaN(open) && !isNaN(total) && total > 0 && open >= 0 && open <= total) {
        return { open, total };
      }
    }

    return { open: 0, total: 0 };
  }
}
