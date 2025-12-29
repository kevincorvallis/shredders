import { BaseScraper } from './BaseScraper';
import type { ScraperResult, ScrapedMountainStatus } from './types';
import puppeteer from 'puppeteer-core';
import chromium from '@sparticuz/chromium';

/**
 * Puppeteer-based scraper for dynamic JavaScript-rendered pages
 * Handles sites like Crystal Mountain (Incapsula) and Snoqualmie (Next.js)
 */
export class PuppeteerScraper extends BaseScraper {
  async scrape(): Promise<ScraperResult> {
    const startTime = Date.now();

    if (!this.isEnabled()) {
      return this.createResult(false, undefined, 'Scraper disabled', startTime);
    }

    let browser;
    try {
      const url = this.config.dataUrl || this.config.url;

      // Launch browser (different config for local vs Vercel)
      const isDev = process.env.NODE_ENV === 'development';

      if (isDev) {
        // Local development - use local Chrome
        browser = await puppeteer.launch({
          headless: true,
          args: ['--no-sandbox', '--disable-setuid-sandbox'],
          executablePath:
            process.platform === 'darwin'
              ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
              : process.platform === 'linux'
              ? '/usr/bin/google-chrome'
              : 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
        });
      } else {
        // Production (Vercel) - use chromium from layer
        browser = await puppeteer.launch({
          args: chromium.args,
          defaultViewport: { width: 1920, height: 1080 },
          executablePath: await chromium.executablePath(),
          headless: true,
        });
      }

      const page = await browser.newPage();

      // Set user agent to avoid bot detection
      await page.setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      );

      // Navigate to page with timeout
      await page.goto(url, {
        waitUntil: 'networkidle2',
        timeout: 30000,
      });

      // Wait a bit for dynamic content to load
      await new Promise((resolve) => setTimeout(resolve, 3000));

      // Extract data using configured selectors
      const selectors = this.config.selectors || {};

      const data = await page.evaluate((sel) => {
        const getText = (selector: string): string => {
          const el = document.querySelector(selector);
          return el?.textContent?.trim() || '';
        };

        const countElements = (selector: string): number => {
          return document.querySelectorAll(selector).length;
        };

        const extractNumber = (text: string): number => {
          const match = text.match(/(\d+)/);
          return match ? parseInt(match[1], 10) : 0;
        };

        const parseRatio = (text: string): { open: number; total: number } => {
          const match = text.match(/(\d+)\s*\/\s*(\d+)/);
          return match
            ? { open: parseInt(match[1], 10), total: parseInt(match[2], 10) }
            : { open: 0, total: 0 };
        };

        // Lifts
        const liftsText = sel.liftsOpen ? getText(sel.liftsOpen) : '';
        let liftsRatio = parseRatio(liftsText);
        if (liftsRatio.total === 0 && sel.liftsOpen) {
          const count = countElements(sel.liftsOpen);
          if (count > 0) {
            liftsRatio = { open: count, total: count };
          }
        }

        // Runs
        const runsText = sel.runsOpen ? getText(sel.runsOpen) : '';
        let runsRatio = parseRatio(runsText);
        if (runsRatio.total === 0 && sel.runsOpen) {
          const count = countElements(sel.runsOpen);
          if (count > 0) {
            runsRatio = { open: count, total: count };
          }
        }

        // Status
        const statusText = sel.status ? getText(sel.status) : '';
        const isOpen =
          statusText.toUpperCase().includes('OPEN') &&
          !statusText.toUpperCase().includes('CLOSED');

        // Message
        const message = sel.message ? getText(sel.message) : '';

        // Percent
        const percentText = sel.percentOpen ? getText(sel.percentOpen) : '';
        const percentMatch = percentText.match(/(\d+)%/);
        const percentOpen = percentMatch ? parseInt(percentMatch[1], 10) : null;

        return {
          liftsRatio,
          runsRatio,
          statusText,
          isOpen,
          message,
          percentOpen,
        };
      }, selectors);

      await browser.close();

      const status: ScrapedMountainStatus = {
        mountainId: this.config.id,
        mountainName: this.config.name,
        isOpen: data.isOpen,
        percentOpen: data.percentOpen,
        liftsOpen: data.liftsRatio.open,
        liftsClosed: data.liftsRatio.total - data.liftsRatio.open,
        liftsTotal: data.liftsRatio.total,
        runsOpen: data.runsRatio.open,
        runsClosed: data.runsRatio.total - data.runsRatio.open,
        runsTotal: data.runsRatio.total,
        acresOpen: null,
        acresTotal: null,
        lastUpdated: new Date().toISOString(),
        message: data.message || undefined,
        source: this.config.url,
        dataUrl: url,
      };

      return this.createResult(true, status, undefined, startTime);
    } catch (error) {
      if (browser) {
        await browser.close();
      }
      console.error(`[PuppeteerScraper] Error scraping ${this.config.id}:`, error);
      return this.createResult(
        false,
        this.createDefaultStatus(),
        error instanceof Error ? error.message : 'Unknown error',
        startTime
      );
    }
  }
}
