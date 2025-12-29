/**
 * Cron job configuration for automated scraping
 *
 * Options for running automated scrapes:
 *
 * 1. Vercel Cron Jobs (Recommended for Vercel deployments)
 *    - Add to vercel.json:
 *    {
 *      "crons": [{
 *        "path": "/api/scraper/run",
 *        "schedule": "0 6,18 * * *"  // Run at 6 AM and 6 PM daily
 *      }]
 *    }
 *
 * 2. Node-cron (For self-hosted)
 *    - npm install node-cron
 *    - Run this file as a separate process
 *
 * 3. GitHub Actions (Free option)
 *    - Create .github/workflows/scraper.yml
 *    - Schedule using cron syntax
 *    - Make HTTP request to /api/scraper/run
 *
 * 4. External cron service (cron-job.org, etc.)
 *    - Configure to hit /api/scraper/run endpoint
 */

import cron from 'node-cron';
import { scraperOrchestrator } from './ScraperOrchestrator';
import { scraperStorage } from './storage';

/**
 * Run scraper on a schedule
 * This is for self-hosted deployments
 */
export function startCronJob() {
  // Run every day at 6 AM and 6 PM
  cron.schedule('0 6,18 * * *', async () => {
    console.log('[Cron] Starting scheduled scrape...');

    try {
      const results = await scraperOrchestrator.scrapeAll();

      const successfulData = Array.from(results.values())
        .filter((r) => r.success && r.data)
        .map((r) => r.data!);

      scraperStorage.saveMany(successfulData);

      console.log(`[Cron] Completed: ${successfulData.length} mountains scraped`);
    } catch (error) {
      console.error('[Cron] Scraping failed:', error);
    }
  });

  console.log('[Cron] Scheduler started - will run at 6 AM and 6 PM daily');
}

/**
 * Run scraper once immediately (for testing)
 */
export async function runOnce() {
  console.log('[Manual] Running scraper once...');

  try {
    const results = await scraperOrchestrator.scrapeAll();

    const successfulData = Array.from(results.values())
      .filter((r) => r.success && r.data)
      .map((r) => r.data!);

    scraperStorage.saveMany(successfulData);

    console.log(`[Manual] Completed: ${successfulData.length} mountains scraped`);

    return {
      success: true,
      count: successfulData.length,
      data: successfulData,
    };
  } catch (error) {
    console.error('[Manual] Scraping failed:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}
