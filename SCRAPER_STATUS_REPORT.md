# Shredders Mountain Scraper - Comprehensive Status Report
**Generated:** January 10, 2026, 10:30 PM
**Author:** Verification Analysis

---

## Executive Summary

The Shredders application uses a multi-source data collection architecture to aggregate mountain conditions from **15 scrapers, 17 NOAA endpoints, 17 SNOTEL stations, 26 Open-Meteo endpoints, and 40+ webcams**. Based on the latest verification run (January 9, 2026), **only 1 out of 15 resort scrapers is working** (6.7%), while API sources have better reliability.

### Critical Findings
- **Mt. Baker is the ONLY working resort scraper** (using native HTML selectors)
- **13 out of 15 scrapers are completely broken** (86.7% failure rate)
- All scrapers have switched to OnTheSnow.com fallback URLs, but the selectors don't match
- Bot protection is NOT the issue - the selectors are simply invalid
- NOAA, Open-Meteo, and most webcams are working well

---

## 1. Scraper Configuration Analysis

### Current Configuration (`/src/lib/scraper/configs.ts`)

**Total Scrapers:** 15
- **Enabled:** 15 (all enabled in config)
- **Actually Working:** 1 (Mt. Baker only)
- **Scraper Type Distribution:**
  - HTML: 15 (all use HTML scraping via Cheerio)
  - Puppeteer: 0 (none configured, though code exists)

**Key Architecture Decision:**
All scrapers except Mt. Baker use **OnTheSnow.com as the data source** instead of the resort's official website. This was likely done to avoid:
- Bot protection (Cloudflare, Incapsula)
- Dynamic JavaScript rendering (Next.js, React apps)
- Varying HTML structures across resorts

**The Problem:**
The OnTheSnow selectors in the config (`[data-testid="lifts-status"]`, `.lift-status`, etc.) do **NOT match the actual HTML structure** of OnTheSnow pages, causing 93% of scrapers to fail.

---

## 2. Scraper Implementation

### HTMLScraper (`/src/lib/scraper/HTMLScraper.ts`)
- Uses Cheerio for fast, server-side HTML parsing
- 30-second timeout (recently increased from 10s)
- Supports both CSS selectors and regex patterns
- Fallback logic: tries selectors first, then counts elements if no ratio found
- **Status:** Implementation is solid, selectors are the problem

### PuppeteerScraper (`/src/lib/scraper/PuppeteerScraper.ts`)
- Uses headless Chrome via `@sparticuz/chromium` (Vercel-compatible)
- 30-second navigation timeout with `networkidle2` wait
- 3-second additional wait for dynamic content
- User-agent spoofing to avoid bot detection
- **Status:** Code exists but NO scrapers use it (all marked as type: 'html')

### ScraperOrchestrator (`/src/lib/scraper/ScraperOrchestrator.ts`)
- Manages parallel scraping of all mountains
- Rate limiting built-in
- No database persistence in the current implementation
- **Status:** Working correctly, just needs working scrapers

---

## 3. Detailed Scraper Status (15 Mountains)

### ✅ WORKING (1)

#### Mt. Baker
- **Config:** `baker`
- **Data URL:** `https://www.mtbaker.us/snow-report/`
- **Type:** HTML (native site scraping)
- **Status:** ✅ SUCCESS
- **Selectors:**
  - `✅ .table-lifts .status-icon.status-open` - counts open lifts
  - `✅ .title.h3` - "OPEN FOR THE SEASON"
  - `✅ .conditions-conditions_summary p` - daily message
- **Response Time:** 493ms
- **Data Quality:** Excellent
- **Why It Works:** Uses the resort's actual website with correct selectors

---

### ❌ BROKEN - INVALID SELECTORS (4)

#### Stevens Pass
- **Config:** `stevens`
- **Data URL:** `https://www.onthesnow.com/washington/stevens-pass-resort/skireport`
- **Type:** HTML (OnTheSnow fallback)
- **Status:** ❌ BROKEN
- **Error:** No selectors found matching elements on page
- **Category:** `invalid_selector`
- **Selectors Tested:**
  - `❌ [data-testid="lifts-status"]` - NOT FOUND
  - `❌ .lift-status` - NOT FOUND
  - `❌ .lifts` - NOT FOUND
- **Recommendation:** Inspect OnTheSnow HTML and update selectors

#### Crystal Mountain
- **Config:** `crystal`
- **Data URL:** `https://www.onthesnow.com/washington/crystal-mountain-wa/skireport`
- **Type:** HTML (changed from 'dynamic')
- **Status:** ❌ BROKEN
- **Error:** No selectors found matching elements on page
- **Category:** `invalid_selector`
- **Previous Issue:** Was using Incapsula bot protection (hence the switch to OnTheSnow)
- **Current Issue:** OnTheSnow selectors don't match

#### Timberline Lodge
- **Config:** `timberline`
- **Data URL:** `https://www.onthesnow.com/oregon/timberline-lodge/skireport`
- **Status:** ❌ BROKEN
- **Error:** `invalid_selector`

#### Mission Ridge
- **Config:** `missionridge`
- **Data URL:** `https://www.onthesnow.com/washington/mission-ridge/skireport`
- **Status:** ❌ BROKEN
- **Error:** `invalid_selector`

---

### ❌ BROKEN - HTTP 404 (9)

The following scrapers point to OnTheSnow URLs that return **HTTP 404 Not Found**. This suggests either:
1. OnTheSnow changed their URL structure
2. The resort names in the URLs are incorrect
3. OnTheSnow removed these resorts

#### Failed OnTheSnow URLs (all 404):
1. **White Pass:** `https://www.onthesnow.com/washington/white-pass/skireport`
2. **Mt. Hood Meadows:** `https://www.onthesnow.com/oregon/mt-hood-meadows/skireport`
3. **Mt. Bachelor:** `https://www.onthesnow.com/oregon/mt-bachelor/skireport`
4. **49 Degrees North:** `https://www.onthesnow.com/washington/49-degrees-north/skireport`
5. **Schweitzer Mountain:** `https://www.onthesnow.com/idaho/schweitzer/skireport`
6. **Lookout Pass:** `https://www.onthesnow.com/idaho/lookout-pass-ski-area/skireport`
7. **Mt. Ashland:** `https://www.onthesnow.com/oregon/mount-ashland/skireport`
8. **Willamette Pass:** `https://www.onthesnow.com/oregon/willamette-pass/skireport`
9. **Hoodoo Ski Area:** `https://www.onthesnow.com/oregon/hoodoo-ski-area/skireport`

**Recommendation:** Verify correct OnTheSnow URLs or switch to resort websites directly

---

### ⚠️ WARNING - POOR DATA QUALITY (1)

#### Summit at Snoqualmie
- **Config:** `snoqualmie`
- **Data URL:** `https://www.onthesnow.com/washington/the-summit-at-snoqualmie/skireport`
- **Type:** HTML (changed from 'dynamic')
- **Status:** ⚠️ WARNING
- **Data Quality:** Poor
- **Response Time:** 1426ms
- **Issue:** Some selectors found, but data quality is low (< 40% success rate)

---

## 4. API Endpoint Status

### NOAA Weather.gov API
- **Total Endpoints:** 108 (27 mountains × 4 endpoints each)
- **Working:** 72 (66.7%)
- **Broken:** 36 (33.3%)
- **Endpoints per mountain:**
  - Hourly forecast
  - Daily forecast
  - Observations
  - Weather alerts

**US Mountains with NOAA (17 total):**
✅ Working: Mt. Baker, Stevens Pass, Crystal Mountain, Snoqualmie, White Pass, Mt. Hood Meadows, Timberline, Mt. Bachelor, Mission Ridge, 49 Degrees North, Schweitzer, Lookout Pass, Mt. Ashland, Willamette Pass, Hoodoo, Sun Valley, Anthony Lakes

❌ Missing Config (Canadian mountains + BC): Whistler, Revelstoke, Cypress, Sun Peaks, Big White, Red Mountain, Panorama, Silver Star, Apex

**Performance:** Excellent
- Average response time: 50-150ms
- Data quality: Excellent
- Reliability: Very high

### SNOTEL API (USGS AWDB)
- **Total Stations:** 27
- **Working:** 18 (66.7%)
- **Broken:** 9 (33.3%)
- **Status:** Generally reliable for US mountains

**Sample Stations:**
- ✅ Mt. Baker: `910:WA:SNTL` (Wells Creek)
- ✅ Stevens Pass: `791:WA:SNTL`
- ✅ Crystal Mountain: `1072:WA:SNTL` (Morse Lake)
- ⚠️ Some stations show warnings (fair data quality, slower response ~2s)

### Open-Meteo API
- **Total Endpoints:** 27 (one per mountain)
- **Working:** 27 (100%)
- **Broken:** 0
- **Status:** Perfect reliability

**Coverage:** All 26 mountains + Sun Valley
- Provides: Freezing level, hourly snowfall, temperature forecasts
- Especially important for Canadian mountains without NOAA

### Webcams
- **Total:** 22
- **Working:** 16 (72.7%)
- **Stale/Broken:** 6
- **Status:** Mostly working

---

## 5. Database & Storage

### PostgreSQL Schema (`scripts/setup-db-schema.sql`)
**Tables:**
- `mountain_status` - Stores scraped data with timestamps
- `scraper_runs` - Tracks execution metadata (success/failure counts, duration)

**Views:**
- `latest_mountain_status` - Most recent status per mountain
- `scraper_stats` - Daily aggregated statistics

**Functions:**
- `cleanup_old_mountain_status()` - Keeps last 90 days
- `get_mountain_history()` - Retrieves historical trends

**Status:** Schema is well-designed and ready to use

### Current Storage Implementation
**PostgreSQL Storage (`/src/lib/scraper/storage-postgres.ts`):**
- ✅ Full implementation exists
- Uses Vercel Postgres (`@vercel/postgres`)
- Connection string: Supabase PostgreSQL
- NOT currently being used by the API endpoints

**API Endpoints:**
- `/api/scraper/run` - Runs scrapers but **does NOT save to database**
- `/api/scraper/status` - Can read from PostgreSQL if `DATABASE_URL` is set
- Current behavior: Scrapers run in-memory, results returned but not persisted

**Issue:** The `/api/scraper/run` route explicitly says `no database persistence`:
```typescript
console.log('[API] Starting manual scrape (no database persistence)...');
```

---

## 6. Deployment & Automation

### Vercel Configuration (`vercel.json`)
**Cron Jobs Configured:**
```json
{
  "path": "/api/scraper/run",
  "schedule": "0 6 * * *"  // Daily at 6 AM
}
```

**Status:** Cron is set up to run daily at 6 AM, but:
- ❌ Scraper runs but only 1/15 works
- ❌ Results are NOT saved to database
- ❌ No error alerting or monitoring

**Function Timeout:**
- Scraper API functions: 60 seconds max
- Region: `sfo1`

### Production Environment
- **Platform:** Vercel
- **Database:** Supabase PostgreSQL
- **Storage:** Supabase (replaced AWS S3)
- **Authentication:** Supabase Auth (replaced AWS Cognito)

---

## 7. Verification System

### Built-in Verification (`/src/lib/verification/`)
**Status:** ✅ Comprehensive verification system already built!

**Modules:**
- `scraperVerifier.ts` - Tests all resort scrapers
- `noaaVerifier.ts` - Tests NOAA endpoints
- `snotelVerifier.ts` - Tests SNOTEL stations
- `openMeteoVerifier.ts` - Tests Open-Meteo
- `webcamVerifier.ts` - Tests webcam accessibility
- `reportGenerator.ts` - Generates JSON and Markdown reports
- `VerificationAgent.ts` - Orchestrates all verifications

**CLI Usage:**
```bash
npm run verify                    # Verify all sources
npm run verify -- --type=scraper  # Verify only scrapers
npm run verify -- --mountain=baker # Verify only Mt. Baker
npm run verify -- --quick         # Quick test (Mt. Baker only)
```

**Output:**
- JSON reports saved to `./verification-reports/`
- Markdown summaries with detailed findings
- Console output with color-coded status

**Latest Verification:** January 9, 2026
- Tested 199 total data sources
- Generated comprehensive report identifying all issues

---

## 8. Specific Mountain Analysis

### Mt. Baker (WORKING ✅)
**Why it works:**
- Scrapes the resort's actual website (mtbaker.us)
- Simple, static HTML structure
- No bot protection
- Correct CSS selectors

**Data Extracted:**
- Lifts open/total (via counting `.status-icon.status-open`)
- Status message ("OPEN FOR THE SEASON")
- Daily conditions summary

**Recommendation:** Use this as the model for fixing other scrapers

---

### Stevens Pass (BROKEN ❌)
**Priority:** HIGH (popular resort)
**Current Approach:** OnTheSnow fallback
**Issue:** Invalid selectors

**Options to Fix:**
1. **Fix OnTheSnow selectors** - Inspect current HTML and update
2. **Use official site** - `https://www.stevenspass.com/the-mountain/mountain-conditions.aspx`
   - Problem: Dynamic content (JavaScript rendering)
   - Solution: Switch to Puppeteer scraper type
3. **Find API endpoint** - Check network tab for API calls the frontend uses

**Recommended Fix:** Option 3 (API endpoint) if available, otherwise Option 2 (Puppeteer)

---

### Crystal Mountain (BROKEN ❌)
**Priority:** HIGH (popular resort)
**Previous Issue:** Incapsula bot protection on official site
**Current Approach:** OnTheSnow fallback
**Issue:** Invalid selectors

**Options to Fix:**
1. **Fix OnTheSnow selectors** - Update to match current structure
2. **Puppeteer with anti-detection** - Try headless browser with stealth plugin
3. **API reverse engineering** - Find the API their site uses

**Recommended Fix:** Option 1 (OnTheSnow) is fastest if selectors can be found

---

### Summit at Snoqualmie (WARNING ⚠️)
**Status:** Partial data extraction (poor quality)
**Issue:** Some selectors work, some don't
**Recommendation:** Review which selectors are failing and update them

---

## 9. Root Cause Analysis

### Why Are 93% of Scrapers Failing?

**Primary Cause: Invalid OnTheSnow Selectors**

The config uses selectors like:
```typescript
selectors: {
  liftsOpen: '[data-testid="lifts-status"], .lift-status, .lifts',
  runsOpen: '[data-testid="trails-status"], .trail-status, .trails',
  status: '.conditions-header, .status',
}
```

These selectors suggest someone expected OnTheSnow to have a standardized structure with `data-testid` attributes and semantic class names. **They don't.**

**Secondary Cause: Incorrect OnTheSnow URLs**

9 scrapers point to OnTheSnow URLs that return 404, suggesting:
- URL structure changed
- Resort names don't match OnTheSnow's naming
- Resorts were removed from OnTheSnow

### Why Did This Happen?

Timeline speculation:
1. **Original Implementation:** Direct resort website scraping
2. **Problem Encountered:** Bot protection (Cloudflare, Incapsula) on popular resorts
3. **Solution Attempted:** Switch to OnTheSnow as a universal aggregator
4. **Implementation:** Selectors were created without actually testing OnTheSnow HTML
5. **Result:** Only Mt. Baker works because it still uses the native site

---

## 10. Recommendations & Next Steps

### Immediate Actions (High Priority)

#### 1. Fix OnTheSnow Selectors (Quick Win)
**Affected:** Stevens, Crystal, Snoqualmie (+ 4 more if URLs fixed)
**Effort:** 2-4 hours
**Steps:**
1. Visit one OnTheSnow page manually
2. Inspect HTML structure with DevTools
3. Identify actual selectors for lifts/runs data
4. Update `configs.ts` with working selectors
5. Test with verification tool
6. Apply to all OnTheSnow-based scrapers

**Expected Outcome:** Could fix 4-7 scrapers immediately

---

#### 2. Fix OnTheSnow URLs (Quick Fix)
**Affected:** 9 scrapers returning 404
**Effort:** 1-2 hours
**Steps:**
1. Search OnTheSnow.com for each resort
2. Identify correct URL structure
3. Update `dataUrl` in config
4. Test with verification tool

**Expected Outcome:** Could enable 9 more scrapers

---

#### 3. Enable Database Persistence (Critical)
**Effort:** 30 minutes
**Steps:**
1. Update `/api/scraper/run/route.ts` to save results:
```typescript
const storage = await import('@/lib/scraper/storage-postgres').then(m => m.scraperStorage);
await storage.startRun(totalCount, 'cron');
// ... run scrapers ...
await storage.saveMany(successfulData);
await storage.completeRun(successCount, failedCount, duration);
```

**Expected Outcome:** Historical data tracking, monitoring, alerting capability

---

### Medium-Term Actions (1-2 weeks)

#### 4. Create OnTheSnow Universal Scraper
**Effort:** 4-8 hours
**Benefit:** Single codebase for all OnTheSnow-based scrapers

Instead of configuring selectors per mountain, create a specialized `OnTheSnowScraper` class that:
- Knows the exact HTML structure of OnTheSnow
- Parses the standardized layout
- Returns normalized data

Then update configs to use this scraper type.

---

#### 5. Implement Puppeteer for Dynamic Sites
**Affected:** Crystal (Incapsula), Stevens (Next.js), Snoqualmie (React)
**Effort:** 6-12 hours
**Steps:**
1. Update scrapers to type: 'dynamic' in config
2. Test PuppeteerScraper with anti-detection measures
3. Add stealth plugin if needed
4. Verify it bypasses bot protection

**Note:** Puppeteer is expensive on Vercel (serverless compute)
- Consider running separately on a VPS
- Or use Browserless.io API

---

#### 6. API Reverse Engineering
**Priority:** High value, medium effort
**Effort:** 2-4 hours per resort
**Steps:**
1. Open resort website in Chrome DevTools
2. Navigate to conditions page
3. Check Network tab for JSON API calls
4. Identify endpoint, headers, parameters
5. Create APIScraper config

**Benefits:**
- No bot protection issues
- No HTML parsing fragility
- Faster, more reliable

**Target resorts:** Stevens, Crystal, Snoqualmie (likely have APIs)

---

### Long-Term Actions (1+ months)

#### 7. Implement Monitoring & Alerts
**Components:**
- Daily verification runs
- Slack/email alerts when scrapers fail
- Dashboard showing scraper health
- Automatic fallback to cached data

---

#### 8. Build Scraper Health Dashboard
**Features:**
- Real-time scraper status (working/broken/warning)
- Historical success rates
- Response time charts
- Last successful scrape timestamp
- Quick actions: "Retry", "Disable", "Edit Config"

---

#### 9. Consider Third-Party APIs
**Options:**
- **Snocountry** - Official snow report aggregator
- **Resort APIs** - Some resorts offer official APIs
- **OnTheSnow API** - May have a paid API tier

**Tradeoff:** Cost vs reliability

---

## 11. Success Metrics

### Current State
- **Working Scrapers:** 1/15 (6.7%)
- **Data Persistence:** None
- **Monitoring:** Manual verification runs
- **Cron Success Rate:** Unknown (no logging)

### Target State (Phase 1 - Quick Fixes)
- **Working Scrapers:** 10/15 (66%)
- **Data Persistence:** All successful scrapes saved
- **Monitoring:** Daily verification reports
- **Cron Success Rate:** Tracked in database

### Target State (Phase 2 - Full Implementation)
- **Working Scrapers:** 14/15 (93%)
- **Data Persistence:** Historical tracking with trends
- **Monitoring:** Real-time alerts on failures
- **Cron Success Rate:** >95%
- **API Fallbacks:** Automated fallback to APIs when scrapers fail

---

## 12. Technical Debt & Architecture Notes

### What's Working Well
✅ Clean separation of concerns (Scraper, Orchestrator, Storage)
✅ Comprehensive type definitions
✅ Built-in verification system
✅ Database schema is well-designed
✅ NOAA, SNOTEL, Open-Meteo integrations are solid
✅ Vercel deployment with cron configured

### Areas for Improvement
❌ No database persistence in production
❌ No error monitoring or alerting
❌ OnTheSnow strategy was implemented without verification
❌ No A/B testing of scrapers before switching all to OnTheSnow
❌ No graceful degradation when scrapers fail
❌ No caching layer for resilience

---

## 13. Decision Points

### Should We Keep OnTheSnow?

**Pros:**
- Single source for many resorts
- No bot protection
- Potentially consistent HTML structure

**Cons:**
- Current selectors are completely wrong
- 9 resorts return 404
- We don't control the source (OnTheSnow could change at any time)

**Recommendation:** Use OnTheSnow as a **fallback**, not primary source
- Primary: Resort APIs or official sites
- Fallback: OnTheSnow when primary fails

---

### Should We Use Puppeteer?

**Pros:**
- Bypasses bot protection
- Handles dynamic JavaScript rendering
- More reliable for modern sites

**Cons:**
- Expensive on Vercel (serverless compute charges)
- Slower (3-5 seconds per scrape)
- Harder to debug

**Recommendation:** Use Puppeteer selectively
- Only for resorts with bot protection (Crystal, Stevens)
- Run on dedicated server or use Browserless.io API
- Keep HTML scraping for simple sites (Mt. Baker)

---

## 14. Files & Locations Reference

### Key Files
```
/src/lib/scraper/
  ├── configs.ts              # Scraper configurations (NEEDS UPDATE)
  ├── HTMLScraper.ts          # Working implementation
  ├── PuppeteerScraper.ts     # Not currently used
  ├── ScraperOrchestrator.ts  # Working orchestration
  ├── BaseScraper.ts          # Base class with helpers
  ├── storage-postgres.ts     # PostgreSQL persistence
  └── types.ts                # TypeScript interfaces

/src/lib/verification/
  ├── index.ts                # Main exports
  ├── VerificationAgent.ts    # Orchestrates all verifications
  ├── scraperVerifier.ts      # Tests resort scrapers
  ├── noaaVerifier.ts         # Tests NOAA API
  ├── snotelVerifier.ts       # Tests SNOTEL
  ├── openMeteoVerifier.ts    # Tests Open-Meteo
  ├── webcamVerifier.ts       # Tests webcams
  ├── reportGenerator.ts      # Generates reports
  └── types.ts                # Type definitions

/src/app/api/
  ├── scraper/run/route.ts    # Manual trigger (no DB save)
  └── scraper/status/route.ts # Get status from DB

/scripts/
  ├── setup-db-schema.sql     # PostgreSQL schema
  └── verify-data-sources.ts  # CLI verification tool

/verification-reports/
  ├── verification-report-2026-01-09.json # Latest JSON
  └── verification-report-2026-01-09.md   # Latest Markdown
```

---

## 15. Conclusion

The Shredders scraping infrastructure has solid foundations but is currently in a **critical state** with only 1 out of 15 resort scrapers working. The root cause is a failed migration to OnTheSnow.com with incorrect selectors and URLs.

**The Good News:**
- A comprehensive verification system exists and works perfectly
- NOAA, SNOTEL, and Open-Meteo APIs are highly reliable
- The database schema and storage layer are ready to use
- The codebase is well-structured and maintainable

**The Bad News:**
- 93% scraper failure rate is blocking core functionality
- No data persistence means no historical tracking
- No monitoring means failures go undetected
- Cron jobs run daily but save nothing

**The Path Forward:**
1. **Quick Win (2-4 hours):** Fix OnTheSnow selectors → 50% working
2. **Essential (30 min):** Enable database persistence → Data tracking
3. **Important (4-8 hours):** Fix OnTheSnow URLs → 70% working
4. **Strategic (1-2 weeks):** API reverse engineering → 90%+ working

With focused effort on the quick wins, Shredders can go from 6.7% to 70% working scrapers in under a week, dramatically improving the user experience.

---

**Report Compiled From:**
- Latest Verification Run: January 9, 2026
- Quick Verification Run: January 10, 2026 (Mt. Baker only)
- Source Code Analysis: configs.ts, scrapers, orchestrator, storage
- Database Schema: setup-db-schema.sql
- Deployment Config: vercel.json
- Environment: .env.local (Supabase PostgreSQL)

**Status:** Ready for immediate action. All tools and infrastructure are in place to fix the scraper issues.
