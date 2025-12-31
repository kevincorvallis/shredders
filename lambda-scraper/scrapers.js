const axios = require('axios');
const cheerio = require('cheerio');
const vanillaPuppeteer = require('puppeteer-core');
const chromium = require('@sparticuz/chromium');
const { parseRatio, extractPercentage } = require('./utils');

// Base Scraper Class
class BaseScraper {
  constructor(config) {
    this.config = config;
  }

  // Must be implemented by subclasses
  async scrape() {
    throw new Error('scrape() must be implemented');
  }

  // Helper methods
  parseRatio(text) {
    return parseRatio(text);
  }

  extractNumber(text) {
    const match = text?.match(/(\d+)/);
    return match ? parseInt(match[1], 10) : 0;
  }

  createResult(success, data, error, startTime) {
    return {
      success,
      data,
      error,
      duration: startTime ? Date.now() - startTime : 0,
    };
  }

  createDefaultStatus() {
    return {
      mountainId: this.config.id,
      mountainName: this.config.name,
      isOpen: false,
      liftsOpen: 0,
      liftsTotal: 0,
      runsOpen: 0,
      runsTotal: 0,
      message: null,
      sourceUrl: this.config.url,
      scrapedAt: new Date().toISOString(),
    };
  }
}

// HTTP Scraper (for static sites like OnTheSnow)
class HTTPScraper extends BaseScraper {
  async scrape() {
    const startTime = Date.now();

    try {
      const url = this.config.dataUrl || this.config.url;
      console.log(`[${this.config.id}] Fetching ${url}...`);

      const response = await axios.get(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
        timeout: 10000,
      });

      const bodyText = response.data;
      const $ = cheerio.load(bodyText);

      // Extract data using either regex patterns or CSS selectors
      let lifts, runs;

      if (this.config.selectors.liftsPattern) {
        // Method 1: Regex patterns (OnTheSnow style)
        lifts = this.extractPattern(bodyText, this.config.selectors.liftsPattern);
        runs = this.extractPattern(bodyText, this.config.selectors.runsPattern);
      } else if (this.config.selectors.liftsOpen) {
        // Method 2: CSS selectors (Mt. Baker style)
        lifts = this.extractBySelector($, this.config.selectors.liftsOpen, this.config.selectors.liftsClosed);
        runs = this.extractBySelector($, this.config.selectors.runsOpen, this.config.selectors.runsClosed);
      } else {
        lifts = { open: 0, total: 0 };
        runs = { open: 0, total: 0 };
      }

      const status = {
        mountainId: this.config.id,
        mountainName: this.config.name,
        isOpen: bodyText.toLowerCase().includes('open') && !bodyText.toLowerCase().includes('closed'),
        liftsOpen: lifts.open,
        liftsTotal: lifts.total,
        runsOpen: runs.open,
        runsTotal: runs.total,
        message: null,
        sourceUrl: this.config.url,
        scrapedAt: new Date().toISOString(),
        duration: Date.now() - startTime,
      };

      console.log(`[${this.config.id}] ✓ ${lifts.open}/${lifts.total} lifts, ${runs.open}/${runs.total} runs`);
      return this.createResult(true, status, undefined, startTime);

    } catch (error) {
      console.error(`[HTTPScraper] ${this.config.id}:`, error.message);
      const defaultStatus = this.createDefaultStatus();
      defaultStatus.duration = Date.now() - startTime;
      return this.createResult(false, defaultStatus, error.message, startTime);
    }
  }

  extractPattern(text, pattern) {
    if (!pattern) return { open: 0, total: 0 };
    // Use matchAll to get capture groups with global flag
    const matches = [...text.matchAll(pattern)];
    if (matches.length > 0 && matches[0].length >= 3) {
      return { open: parseInt(matches[0][1]), total: parseInt(matches[0][2]) };
    }
    return { open: 0, total: 0 };
  }

  extractBySelector($, openSelector, closedSelector) {
    if (!openSelector) return { open: 0, total: 0 };
    const open = $(openSelector).length;
    const closed = closedSelector ? $(closedSelector).length : 0;
    const total = open + closed;
    return { open, total };
  }
}

// Puppeteer Scraper (for JavaScript-heavy sites)
class PuppeteerScraper extends BaseScraper {
  async scrape() {
    const startTime = Date.now();
    let browser;

    try {
      console.log(`[${this.config.id}] Launching browser...`);
      browser = await this.launchBrowser();
      const page = await browser.newPage();

      await this.setupPage(page);

      console.log(`[${this.config.id}] Navigating to ${this.config.url}...`);
      await page.goto(this.config.url, {
        waitUntil: 'domcontentloaded',
        timeout: this.config.puppeteerConfig?.timeout || 45000,
      });

      await this.simulateHuman(page);
      await this.acceptCookies(page);

      console.log(`[${this.config.id}] Extracting data...`);
      const data = await this.extractData(page);

      await browser.close();

      const status = {
        mountainId: this.config.id,
        mountainName: this.config.name,
        isOpen: data.isOpen,
        liftsOpen: data.lifts.open,
        liftsTotal: data.lifts.total,
        runsOpen: data.runs.open,
        runsTotal: data.runs.total,
        message: data.message,
        sourceUrl: this.config.url,
        scrapedAt: new Date().toISOString(),
        duration: Date.now() - startTime,
      };

      console.log(`[${this.config.id}] ✓ ${status.liftsOpen}/${status.liftsTotal} lifts`);
      return this.createResult(true, status, undefined, startTime);

    } catch (error) {
      if (browser) await browser.close();
      console.error(`[PuppeteerScraper] ${this.config.id}:`, error.message);
      const defaultStatus = this.createDefaultStatus();
      defaultStatus.duration = Date.now() - startTime;
      return this.createResult(false, defaultStatus, error.message, startTime);
    }
  }

  async launchBrowser() {
    const args = [
      ...chromium.args,
      '--disable-blink-features=AutomationControlled',
      '--disable-features=IsolateOrigins,site-per-process',
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--disable-gpu',
      '--window-size=1920,1080',
      '--disable-web-security',
      '--disable-features=VizDisplayCompositor',
    ];

    return await vanillaPuppeteer.launch({
      args,
      defaultViewport: null,
      executablePath: await chromium.executablePath(),
      headless: true,
      ignoreHTTPSErrors: true,
    });
  }

  async setupPage(page) {
    // Set realistic viewport
    await page.setViewport({
      width: 1920,
      height: 1080,
      deviceScaleFactor: 1,
    });

    // Set comprehensive user agent and headers
    const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    await page.setUserAgent(userAgent);

    // Set extra HTTP headers to mimic real browser
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Cache-Control': 'max-age=0',
    });

    // Override navigator.webdriver flag
    await page.evaluateOnNewDocument(() => {
      Object.defineProperty(navigator, 'webdriver', {
        get: () => undefined,
      });

      // Override the permissions API
      const originalQuery = window.navigator.permissions.query;
      window.navigator.permissions.query = (parameters) => (
        parameters.name === 'notifications' ?
          Promise.resolve({ state: Notification.permission }) :
          originalQuery(parameters)
      );

      // Pass Chrome checks
      window.chrome = {
        runtime: {},
      };

      // Pass the plugin check
      Object.defineProperty(navigator, 'plugins', {
        get: () => [1, 2, 3, 4, 5],
      });

      // Pass the languages check
      Object.defineProperty(navigator, 'languages', {
        get: () => ['en-US', 'en'],
      });
    });
  }

  async simulateHuman(page) {
    // Mimic human behavior with random delays
    const randomDelay = () => Math.floor(Math.random() * 1000) + 1000;
    await new Promise((resolve) => setTimeout(resolve, randomDelay()));

    // Simulate human scrolling behavior
    await page.evaluate(() => {
      window.scrollTo(0, Math.floor(Math.random() * 500));
    });
    await new Promise((resolve) => setTimeout(resolve, randomDelay()));

    // Scroll back to top
    await page.evaluate(() => {
      window.scrollTo(0, 0);
    });

    // Wait for network to be mostly idle
    try {
      await page.waitForNetworkIdle({ timeout: 10000, idleTime: 500 });
    } catch (e) {
      console.log(`[${this.config.id}] Network didn't fully idle, continuing...`);
    }

    // Additional wait for JavaScript to execute
    await new Promise((resolve) => setTimeout(resolve, 5000));
  }

  async acceptCookies(page) {
    try {
      await new Promise((resolve) => setTimeout(resolve, 2000));
      const cookieAccepted = await page.evaluate(() => {
        const buttons = Array.from(document.querySelectorAll('button'));
        const acceptButton = buttons.find(btn =>
          btn.textContent.includes('Accept All') ||
          btn.textContent.includes('Accept all')
        );
        if (acceptButton) {
          acceptButton.click();
          return true;
        }
        return false;
      });
      if (cookieAccepted) {
        console.log(`[${this.config.id}] Accepted cookies`);
        await new Promise((resolve) => setTimeout(resolve, 2000));
      }
    } catch (e) {
      console.log(`[${this.config.id}] No cookie banner or already accepted`);
    }
  }

  async extractData(page) {
    const data = await page.evaluate((sel) => {
      const getText = (selector) => {
        const el = document.querySelector(selector);
        return el?.textContent?.trim() || '';
      };

      const countElements = (selector) => {
        return document.querySelectorAll(selector).length;
      };

      // Helper to extract lift/run counts
      const extractCounts = (selector, sectionName) => {
        // Method 1: Look for aria-label numerator values within section
        if (selector.includes('aria-label')) {
          const sections = Array.from(document.querySelectorAll('section, div'));
          const section = sections.find(s => s.textContent.includes(sectionName));

          if (section) {
            const numerator = section.querySelector(selector);
            const denominatorText = section.textContent.match(/of\s+(\d+)/i);

            if (numerator && denominatorText) {
              const open = parseInt(numerator.textContent.trim());
              const total = parseInt(denominatorText[1]);
              return { open, total };
            }
          }
        }

        // Method 2: Traditional text parsing
        const text = getText(selector);
        const match = text.match(/(\d+)\s*\/\s*(\d+)/);
        if (match) {
          return { open: parseInt(match[1]), total: parseInt(match[2]) };
        }

        // Method 3: Count elements
        const count = countElements(selector);
        if (count > 0) {
          return { open: count, total: count };
        }

        return { open: 0, total: 0 };
      };

      // Lifts
      const lifts = extractCounts(sel.liftsOpen, 'Lift');

      // Runs/Trails
      const runs = extractCounts(sel.runsOpen, 'Trail');

      // Status
      const statusText = sel.status ? getText(sel.status) : '';
      const isOpen =
        statusText.toUpperCase().includes('OPEN') &&
        !statusText.toUpperCase().includes('CLOSED');

      // Message
      const message = sel.message ? getText(sel.message) : '';

      return {
        lifts,
        runs,
        statusText,
        isOpen,
        message: message.substring(0, 500), // Limit message length
      };
    }, this.config.selectors);

    return data;
  }
}

// Factory function to create appropriate scraper
function createScraper(config) {
  switch (config.type) {
    case 'http':
      return new HTTPScraper(config);
    case 'puppeteer':
      return new PuppeteerScraper(config);
    default:
      throw new Error(`Unknown scraper type: ${config.type}`);
  }
}

module.exports = {
  BaseScraper,
  HTTPScraper,
  PuppeteerScraper,
  createScraper,
};
