const puppeteer = require('puppeteer-core');
const fs = require('fs');

// Mountain configurations
const mountains = {
  crystal: {
    id: 'crystal',
    name: 'Crystal Mountain',
    url: 'https://www.crystalmountainresort.com/the-mountain/mountain-report/',
    selectors: {
      liftsOpen: '.lift-status.open, [class*="lift"][class*="open"]',
      runsOpen: '.trail-status.open, [class*="run"][class*="open"]',
      status: 'h1, h2, [class*="status"]',
      message: '[class*="conditions"], [class*="message"]',
    },
  },
  snoqualmie: {
    id: 'snoqualmie',
    name: 'Summit at Snoqualmie',
    url: 'https://www.summitatsnoqualmie.com/mountain-report',
    selectors: {
      liftsOpen: '[aria-label*="Lift"], .lift-status',
      runsOpen: '[aria-label*="Trail"], .trail-status',
      status: 'h1, h2',
      message: '[class*="daily"], [class*="conditions"]',
    },
  },
};

async function testScrape(mountainId) {
  const config = mountains[mountainId];
  console.log(`\n${'='.repeat(60)}`);
  console.log(`Testing: ${config.name}`);
  console.log(`${'='.repeat(60)}\n`);

  let browser;
  try {
    // Launch local Chrome
    browser = await puppeteer.launch({
      headless: false, // Show browser for debugging
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
      executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    });

    const page = await browser.newPage();

    // Set user agent
    await page.setUserAgent(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    );

    console.log(`Navigating to ${config.url}...`);

    await page.goto(config.url, {
      waitUntil: 'networkidle2',
      timeout: 30000,
    });

    console.log('Waiting for content to load...');

    // Try to accept cookies on Snoqualmie
    if (mountainId === 'snoqualmie') {
      try {
        // Wait a bit for cookie banner to appear
        await new Promise((resolve) => setTimeout(resolve, 2000));

        // Click cookie accept button
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
          console.log('Accepted cookies');
          await new Promise((resolve) => setTimeout(resolve, 2000));
        } else {
          console.log('No cookie banner found');
        }
      } catch (e) {
        console.log('Error handling cookies:', e.message);
      }
    }

    await new Promise((resolve) => setTimeout(resolve, 5000));

    // Take screenshot BEFORE
    await page.screenshot({ path: `/tmp/${mountainId}-screenshot-before.png` });

    // Scroll down to trigger lazy loading
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await new Promise((resolve) => setTimeout(resolve, 3000));

    // Take screenshot AFTER
    await page.screenshot({ path: `/tmp/${mountainId}-screenshot.png` });
    console.log(`Screenshot saved to /tmp/${mountainId}-screenshot.png`);

    // Get page HTML
    const html = await page.content();
    console.log(`\nPage HTML length: ${html.length} characters`);

    // Try to find lift/run data with various selectors
    console.log('\n--- Testing Selectors ---\n');

    const tests = [
      // Lifts
      { name: 'Configured lifts selector', selector: config.selectors.liftsOpen },
      { name: 'Any element with "lift" in class', selector: '[class*="lift" i]' },
      { name: 'Any element with "Lift" in ID', selector: '[id*="lift" i]' },

      // Runs
      { name: 'Configured runs selector', selector: config.selectors.runsOpen },
      { name: 'Any element with "trail" in class', selector: '[class*="trail" i]' },
      { name: 'Any element with "run" in class', selector: '[class*="run" i]' },
    ];

    for (const test of tests) {
      const result = await page.evaluate((sel, testName) => {
        const elements = document.querySelectorAll(sel);
        const count = elements.length;
        const samples = Array.from(elements).slice(0, 3).map(el => ({
          tag: el.tagName,
          class: el.className,
          text: el.textContent?.trim().substring(0, 100),
        }));
        return { count, samples };
      }, test.selector, test.name);

      console.log(`${test.name}:`);
      console.log(`  Count: ${result.count}`);
      if (result.samples.length > 0) {
        console.log(`  Samples:`);
        result.samples.forEach((s, i) => {
          console.log(`    ${i + 1}. <${s.tag} class="${s.class}">${s.text}</>`);
        });
      }
      console.log();
    }

    // Look for any text mentioning lifts/runs with numbers
    console.log('\n--- Searching for Lift/Run Counts ---\n');

    const textSearch = await page.evaluate(() => {
      const allText = document.body.innerText;

      // Search for patterns like "8/10 lifts", "5 lifts open", etc.
      const liftPatterns = [
        /(\d+)\s*\/\s*(\d+)\s*lifts?/gi,
        /(\d+)\s*lifts?\s*open/gi,
        /lifts?\s*open[:\s]*(\d+)/gi,
      ];

      const runPatterns = [
        /(\d+)\s*\/\s*(\d+)\s*(runs?|trails?)/gi,
        /(\d+)\s*(runs?|trails?)\s*open/gi,
        /(runs?|trails?)\s*open[:\s]*(\d+)/gi,
      ];

      const liftMatches = [];
      const runMatches = [];

      liftPatterns.forEach(pattern => {
        const matches = [...allText.matchAll(pattern)];
        liftMatches.push(...matches.map(m => m[0]));
      });

      runPatterns.forEach(pattern => {
        const matches = [...allText.matchAll(pattern)];
        runMatches.push(...matches.map(m => m[0]));
      });

      return {
        liftMatches: [...new Set(liftMatches)],
        runMatches: [...new Set(runMatches)],
      };
    });

    console.log('Lift text found:', textSearch.liftMatches);
    console.log('Run text found:', textSearch.runMatches);

    // Save HTML for inspection
    fs.writeFileSync(`/tmp/${mountainId}-page.html`, html);
    console.log(`\nFull HTML saved to /tmp/${mountainId}-page.html`);

    await browser.close();

  } catch (error) {
    if (browser) await browser.close();
    console.error(`Error:`, error.message);
  }
}

// Run tests
(async () => {
  await testScrape('crystal');
  await testScrape('snoqualmie');
})();
