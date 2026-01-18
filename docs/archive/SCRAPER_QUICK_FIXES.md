# Shredders Scraper - Quick Fix Guide
**Priority Actions to Get Scrapers Working**

---

## Current State
- **Working:** 1/15 scrapers (6.7%) - Mt. Baker only
- **Broken:** 14/15 scrapers (93.3%)
- **Root Cause:** Invalid OnTheSnow.com selectors and 404 URLs

---

## Quick Fix #1: Inspect OnTheSnow HTML Structure (2 hours)

### Problem
All scrapers except Mt. Baker use OnTheSnow.com, but the CSS selectors don't match:

```typescript
// Current config (WRONG):
selectors: {
  liftsOpen: '[data-testid="lifts-status"], .lift-status, .lifts',
  runsOpen: '[data-testid="trails-status"], .trail-status, .trails',
  status: '.conditions-header, .status',
}
```

### Action Steps

1. **Visit a working OnTheSnow page:**
   ```
   https://www.onthesnow.com/washington/crystal-mountain-wa/skireport
   ```

2. **Open Chrome DevTools** (F12 or Cmd+Option+I)

3. **Inspect the lifts/runs section:**
   - Right-click the "Lifts: 8/10" text
   - Click "Inspect"
   - Note the actual HTML structure

4. **Find the correct selectors:**
   - Look for unique class names or IDs
   - Check parent containers
   - Verify selectors work across multiple resort pages

5. **Update `/src/lib/scraper/configs.ts`:**
   ```typescript
   // Example (use actual selectors you find):
   selectors: {
     liftsOpen: '.actual-lifts-selector',  // Replace with real selector
     runsOpen: '.actual-runs-selector',     // Replace with real selector
     status: '.actual-status-selector',     // Replace with real selector
   }
   ```

6. **Test with verification:**
   ```bash
   npm run verify -- --mountain=stevens
   ```

7. **If successful, apply to all OnTheSnow scrapers**

**Expected Outcome:** 4-7 scrapers working (stevens, crystal, snoqualmie, timberline, missionridge)

---

## Quick Fix #2: Fix OnTheSnow 404 URLs (1 hour)

### Problem
9 scrapers return HTTP 404 because the URLs are wrong:

```
❌ https://www.onthesnow.com/washington/white-pass/skireport
❌ https://www.onthesnow.com/oregon/mt-hood-meadows/skireport
❌ https://www.onthesnow.com/oregon/mt-bachelor/skireport
... (6 more)
```

### Action Steps

1. **Search for each resort on OnTheSnow.com:**
   - Go to https://www.onthesnow.com
   - Use search bar to find resort
   - Copy the correct URL from the address bar

2. **Update URLs in `/src/lib/scraper/configs.ts`:**
   ```typescript
   whitepass: {
     dataUrl: 'https://www.onthesnow.com/[CORRECT-URL-HERE]/skireport',
   }
   ```

3. **Test each one:**
   ```bash
   npm run verify -- --mountain=whitepass
   npm run verify -- --mountain=meadows
   # etc.
   ```

**Expected Outcome:** 9 more scrapers could work (if selectors are also fixed)

---

## Quick Fix #3: Enable Database Persistence (30 minutes)

### Problem
Scrapers run but results are NOT saved to the database:

```typescript
// Current code in /api/scraper/run/route.ts:
console.log('[API] Starting manual scrape (no database persistence)...');
```

### Action Steps

1. **Edit `/src/app/api/scraper/run/route.ts`:**

   Replace the current implementation with:

   ```typescript
   import { NextResponse } from 'next/server';
   import { scraperOrchestrator } from '@/lib/scraper/ScraperOrchestrator';
   import { scraperStorage } from '@/lib/scraper/storage-postgres';

   export async function GET() {
     try {
       console.log('[API] Starting manual scrape WITH database persistence...');
       const startTime = Date.now();

       // Start tracking this run
       const enabledCount = scraperOrchestrator.getScraperCount();
       const runId = await scraperStorage.startRun(enabledCount, 'manual');

       // Run all scrapers
       const results = await scraperOrchestrator.scrapeAll();

       // Extract successful results
       const successfulData = Array.from(results.values())
         .filter((r) => r.success && r.data)
         .map((r) => r.data!);

       const duration = Date.now() - startTime;
       const successCount = successfulData.length;
       const totalCount = results.size;
       const failedCount = totalCount - successCount;

       // Save to database
       if (successfulData.length > 0) {
         await scraperStorage.saveMany(successfulData);
       }

       // Mark run as complete
       await scraperStorage.completeRun(successCount, failedCount, duration);

       console.log(`[API] Scrape completed: ${successCount}/${totalCount} successful in ${duration}ms`);
       console.log(`[API] Saved to database: ${successfulData.length} records`);

       return NextResponse.json({
         success: true,
         message: `Scraped ${successCount}/${totalCount} mountains`,
         duration,
         results: {
           total: totalCount,
           successful: successCount,
           failed: failedCount,
         },
         data: successfulData,
         timestamp: new Date().toISOString(),
         storage: 'postgresql',
         runId,
       });
     } catch (error) {
       console.error('[API] Scraper run failed:', error);

       return NextResponse.json(
         {
           success: false,
           error: error instanceof Error ? error.message : 'Unknown error',
         },
         { status: 500 }
       );
     }
   }
   ```

2. **Test it:**
   ```bash
   curl http://localhost:3000/api/scraper/run
   ```

3. **Verify data was saved:**
   ```bash
   curl http://localhost:3000/api/scraper/status
   ```

**Expected Outcome:** Every successful scrape is now saved to PostgreSQL with full history

---

## Quick Fix #4: Alternative - Use Mt. Baker as Template (4 hours)

### Problem
OnTheSnow approach isn't working. Go back to scraping resort sites directly.

### Action Steps

1. **For each priority resort (Stevens, Crystal):**

   a. Visit the resort's snow report page
   b. Check if it's simple HTML or requires JavaScript
   c. If simple HTML:
      - Inspect and find selectors (like Mt. Baker)
      - Update config to use resort's URL
   d. If dynamic (JavaScript required):
      - Change type to 'dynamic' to use Puppeteer
      - Test with Puppeteer scraper

2. **Example for Stevens Pass:**
   ```typescript
   stevens: {
     id: 'stevens',
     name: 'Stevens Pass',
     url: 'https://www.stevenspass.com',
     dataUrl: 'https://www.stevenspass.com/the-mountain/mountain-conditions.aspx',
     type: 'dynamic',  // Use Puppeteer for JavaScript-rendered page
     enabled: true,
     selectors: {
       // Find actual selectors after page loads
       liftsOpen: '.actual-selector-after-js-loads',
       runsOpen: '.actual-runs-selector',
       status: '.status-selector',
     },
   }
   ```

**Expected Outcome:** More reliable, but slower (Puppeteer takes 3-5s per scrape)

---

## Testing Commands

```bash
# Test single scraper
npm run verify -- --mountain=baker

# Test all scrapers (takes ~5 minutes)
npm run verify

# Test only scrapers (skip APIs/webcams)
npm run verify -- --type=scraper

# Quick test
npm run verify -- --quick

# View reports
ls -lah verification-reports/
cat verification-reports/verification-report-*.md
```

---

## Priority Order

**Do these in order for fastest impact:**

1. ✅ **Fix OnTheSnow selectors** (2 hours) → 50% working
2. ✅ **Enable database persistence** (30 min) → Data tracking enabled
3. ✅ **Fix OnTheSnow URLs** (1 hour) → 70% working
4. ✅ **Switch Stevens & Crystal to native sites** (4 hours) → 85% working

**Total Time to 70% working:** ~3.5 hours
**Total Time to 85% working:** ~7.5 hours

---

## What Success Looks Like

### After Quick Fix #1 & #2 (OnTheSnow fixed)
```
✅ Mt. Baker (native site)
✅ Stevens Pass (OnTheSnow)
✅ Crystal Mountain (OnTheSnow)
✅ Snoqualmie (OnTheSnow)
✅ White Pass (OnTheSnow)
✅ Mt. Hood Meadows (OnTheSnow)
✅ Timberline Lodge (OnTheSnow)
✅ Mt. Bachelor (OnTheSnow)
✅ Mission Ridge (OnTheSnow)
✅ 49 Degrees North (OnTheSnow)
✅ Schweitzer (OnTheSnow)
✅ Lookout Pass (OnTheSnow)
✅ Mt. Ashland (OnTheSnow)
✅ Willamette Pass (OnTheSnow)
✅ Hoodoo (OnTheSnow)

Working: 15/15 (100%) 🎉
```

### After Quick Fix #3 (Database enabled)
```bash
# Query latest data
curl http://localhost:3000/api/scraper/status

# Response:
{
  "success": true,
  "count": 15,
  "data": [...],
  "stats": {
    "totalMountains": 15,
    "totalHistoryEntries": 450,
    "recentRuns": {
      "totalRuns": 30,
      "avgSuccessful": 14.8,
      "avgFailed": 0.2,
      "avgDurationMs": 8500
    }
  },
  "storage": "postgresql"
}
```

---

## Next Steps After Quick Fixes

Once scrapers are working and saving data:

1. **Add monitoring:** Daily verification runs with Slack alerts
2. **Build dashboard:** Real-time scraper health UI
3. **Add caching:** Cache results for 30 minutes to reduce load
4. **Implement fallbacks:** If scraper fails, fall back to cached data
5. **API discovery:** Find official APIs for major resorts

---

## Need Help?

**Files to Edit:**
- `/src/lib/scraper/configs.ts` - Scraper configurations
- `/src/app/api/scraper/run/route.ts` - API endpoint for running scrapers

**Tools to Use:**
- Chrome DevTools (F12) - Inspect HTML structure
- `npm run verify` - Test scrapers
- `curl http://localhost:3000/api/scraper/run` - Manual trigger

**Verification Reports:**
- Latest: `verification-reports/verification-report-2026-01-09.md`
- Contains detailed error messages for each scraper

---

**Last Updated:** January 10, 2026
**Status:** Ready for implementation
