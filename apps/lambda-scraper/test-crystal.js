const puppeteer = require('puppeteer-core');

async function testCrystal() {
  console.log('Testing Crystal Mountain with enhanced stealth...\n');

  let browser;
  try {
    // Enhanced browser args to evade detection
    const args = [
      '--disable-blink-features=AutomationControlled',
      '--disable-features=IsolateOrigins,site-per-process',
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--window-size=1920,1080',
    ];

    browser = await puppeteer.launch({
      headless: false, // Show browser for debugging
      args,
      defaultViewport: null,
      executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      ignoreHTTPSErrors: true,
    });

    const page = await browser.newPage();

    // Set realistic viewport
    await page.setViewport({
      width: 1920,
      height: 1080,
      deviceScaleFactor: 1,
    });

    // Set comprehensive user agent and headers
    const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    await page.setUserAgent(userAgent);

    // Set extra HTTP headers
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

    // Override navigator.webdriver and other bot detection signals
    await page.evaluateOnNewDocument(() => {
      Object.defineProperty(navigator, 'webdriver', {
        get: () => undefined,
      });

      // Override permissions API
      const originalQuery = window.navigator.permissions.query;
      window.navigator.permissions.query = (parameters) => (
        parameters.name === 'notifications' ?
          Promise.resolve({ state: Notification.permission }) :
          originalQuery(parameters)
      );

      // Add chrome runtime
      window.chrome = {
        runtime: {},
      };

      // Mock plugins
      Object.defineProperty(navigator, 'plugins', {
        get: () => [1, 2, 3, 4, 5],
      });

      // Mock languages
      Object.defineProperty(navigator, 'languages', {
        get: () => ['en-US', 'en'],
      });
    });

    console.log('Navigating to Crystal Mountain...');
    const url = 'https://www.crystalmountainresort.com/the-mountain/mountain-report-and-webcams';

    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout: 45000,
    });

    console.log('Page loaded, waiting and simulating human behavior...');

    // Random delay
    await new Promise((resolve) => setTimeout(resolve, 2000 + Math.random() * 2000));

    // Scroll like a human
    await page.evaluate(() => {
      window.scrollTo(0, 300);
    });
    await new Promise((resolve) => setTimeout(resolve, 1500));

    await page.evaluate(() => {
      window.scrollTo(0, 0);
    });

    // Wait for content
    await new Promise((resolve) => setTimeout(resolve, 5000));

    // Take screenshot
    await page.screenshot({ path: '/tmp/crystal-stealth-test.png' });
    console.log('Screenshot saved to /tmp/crystal-stealth-test.png');

    // Check what we got
    const htmlLength = (await page.content()).length;
    console.log(`\nHTML content length: ${htmlLength} characters`);

    // Check for bot detection
    const title = await page.title();
    console.log(`Page title: ${title}`);

    // Look for lift data
    const liftData = await page.evaluate(() => {
      const body = document.body.innerText;

      // Search for lift mentions
      const liftMatches = body.match(/\d+\s*(lifts?|chairs?)\s*(open|operating)/gi);
      const runMatches = body.match(/\d+\s*(runs?|trails?)\s*open/gi);

      return {
        bodyTextLength: body.length,
        liftMatches: liftMatches || [],
        runMatches: runMatches || [],
        bodyPreview: body.substring(0, 500),
      };
    });

    console.log(`\nBody text length: ${liftData.bodyTextLength} characters`);
    console.log(`Lift matches found: ${liftData.liftMatches.length}`);
    console.log(`Run matches found: ${liftData.runMatches.length}`);
    console.log(`\nBody preview:\n${liftData.bodyPreview}`);

    if (liftData.liftMatches.length > 0) {
      console.log(`\nLift data found: ${liftData.liftMatches}`);
    }

    if (liftData.runMatches.length > 0) {
      console.log(`Run data found: ${liftData.runMatches}`);
    }

    // Keep browser open for inspection
    console.log('\nBrowser will stay open for 30 seconds for manual inspection...');
    await new Promise((resolve) => setTimeout(resolve, 30000));

    await browser.close();

  } catch (error) {
    console.error('Error:', error);
    if (browser) await browser.close();
  }
}

testCrystal();
