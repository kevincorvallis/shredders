# Mountain Status Scraper Service

A Liftie-inspired web scraping service for automatically collecting ski resort status data (lifts open, runs open, terrain percentage) from Pacific Northwest mountains.

## 🏗️ Architecture

```
src/lib/scraper/
├── types.ts                 # TypeScript interfaces and types
├── BaseScraper.ts          # Abstract base class for all scrapers
├── HTMLScraper.ts          # Cheerio-based scraper for static HTML
├── APIScraper.ts           # Scraper for JSON API endpoints
├── configs.ts              # Scraper configurations for all mountains
├── ScraperOrchestrator.ts  # Manages all scrapers, runs them in parallel
├── storage.ts              # In-memory data storage (replace with DB)
├── cron.ts                 # Automated scheduling logic
└── README.md               # This file

src/app/api/scraper/
├── run/route.ts            # POST /api/scraper/run - Manual trigger
└── status/route.ts         # GET /api/scraper/status - Retrieve data
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install cheerio node-cron
# Optional: npm install puppeteer  (for dynamic sites)
```

### 2. Manual Test Run

```bash
# Start your Next.js dev server
npm run dev

# Trigger a scrape via API
curl http://localhost:3000/api/scraper/run

# View results
curl http://localhost:3000/api/scraper/status
```

### 3. Inspect a Specific Mountain

```bash
curl http://localhost:3000/api/scraper/status?mountain=baker
```

## 📋 How It Works

### Scraper Types

1. **HTML Scraper** (Fast, for static pages)
   - Uses Cheerio to parse HTML
   - Extracts data via CSS selectors
   - Best for simple, server-rendered pages

2. **API Scraper** (Most reliable)
   - Fetches JSON from resort APIs
   - Uses transform function to map data
   - Best when resorts provide endpoints

3. **Dynamic Scraper** (Not yet implemented)
   - Would use Puppeteer for JavaScript-heavy sites
   - Renders page before scraping
   - Slower but works with SPAs

### Workflow

```
1. ScraperOrchestrator.scrapeAll()
   ↓
2. For each mountain:
   - Load config from configs.ts
   - Create appropriate scraper (HTML/API)
   - Execute scrape()
   ↓
3. Parse response:
   - Extract lifts, runs, terrain %
   - Normalize to ScrapedMountainStatus
   ↓
4. Store results:
   - Save to storage.ts (in-memory)
   - Keep history (last 30 entries)
   ↓
5. Return aggregated results
```

## ⚙️ Configuration

Each mountain has a `ScraperConfig` in `configs.ts`:

```typescript
{
  id: 'baker',
  name: 'Mt. Baker',
  url: 'https://www.mtbaker.us',           // User-facing URL
  dataUrl: 'https://www.mtbaker.us/...',   // Scraping URL
  type: 'html',                             // html | api | dynamic
  enabled: true,
  selectors: {
    liftsOpen: '.lift-status',             // CSS selector
    runsOpen: '.runs-open',
    percentOpen: '.terrain-percent',
    status: '.mountain-status',
  }
}
```

## 🔧 Customizing Selectors

To update selectors for a mountain:

1. **Inspect the resort website:**
   ```bash
   # Open browser DevTools (F12)
   # Navigate to the mountain report page
   # Find elements containing lift/run counts
   # Copy CSS selector (right-click → Copy → Copy selector)
   ```

2. **Update configs.ts:**
   ```typescript
   baker: {
     // ...
     selectors: {
       liftsOpen: '.actual-css-selector',  // Update this
     }
   }
   ```

3. **Test:**
   ```bash
   curl http://localhost:3000/api/scraper/run
   ```

## 🤖 Automated Scraping

### Option 1: Vercel Cron Jobs (Recommended)

Create `vercel.json`:

```json
{
  "crons": [{
    "path": "/api/scraper/run",
    "schedule": "0 6,18 * * *"
  }]
}
```

### Option 2: GitHub Actions (Free)

Create `.github/workflows/scraper.yml`:

```yaml
name: Daily Mountain Scraper

on:
  schedule:
    - cron: '0 6,18 * * *'  # 6 AM and 6 PM UTC
  workflow_dispatch:  # Allow manual trigger

jobs:
  scrape:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Scraper
        run: |
          curl -X GET https://your-app.vercel.app/api/scraper/run
```

### Option 3: cron-job.org (External service)

1. Sign up at cron-job.org
2. Create new cron job
3. URL: `https://your-app.vercel.app/api/scraper/run`
4. Schedule: `0 6,18 * * *`

### Option 4: Self-hosted with node-cron

```typescript
// In your app startup:
import { startCronJob } from '@/lib/scraper/cron';

startCronJob();  // Runs at 6 AM and 6 PM daily
```

## 💾 Database Integration

### Current: In-Memory Storage

- Fast, simple, no setup
- Data lost on restart
- Not suitable for production

### Recommended: PostgreSQL

1. **Create table:**
   ```sql
   CREATE TABLE mountain_status (
     id SERIAL PRIMARY KEY,
     mountain_id VARCHAR(50) NOT NULL,
     is_open BOOLEAN NOT NULL,
     percent_open INTEGER,
     lifts_open INTEGER,
     lifts_total INTEGER,
     runs_open INTEGER,
     runs_total INTEGER,
     scraped_at TIMESTAMP DEFAULT NOW()
   );
   ```

2. **Update storage.ts:**
   ```typescript
   import { sql } from '@vercel/postgres';

   async save(data: ScrapedMountainStatus) {
     await sql`
       INSERT INTO mountain_status (mountain_id, is_open, ...)
       VALUES (${data.mountainId}, ${data.isOpen}, ...)
     `;
   }
   ```

3. **Environment variables:**
   ```bash
   POSTGRES_URL=postgres://...
   ```

## 🧪 Testing Individual Scrapers

```typescript
import { HTMLScraper } from '@/lib/scraper/HTMLScraper';
import { getScraperConfig } from '@/lib/scraper/configs';

const config = getScraperConfig('baker')!;
const scraper = new HTMLScraper(config);
const result = await scraper.scrape();

console.log(result);
```

## 📊 API Endpoints

### Manual Trigger
```bash
GET /api/scraper/run
```
Runs all scrapers and returns results.

**Response:**
```json
{
  "success": true,
  "message": "Scraped 15/15 mountains",
  "duration": 3245,
  "results": {
    "total": 15,
    "successful": 15,
    "failed": 0
  },
  "data": [...]
}
```

### Get Status
```bash
GET /api/scraper/status
GET /api/scraper/status?mountain=baker
```

Retrieve scraped data.

**Response:**
```json
{
  "success": true,
  "data": {
    "mountainId": "baker",
    "isOpen": true,
    "percentOpen": 85,
    "liftsOpen": 8,
    "liftsTotal": 10,
    "runsOpen": 70,
    "runsTotal": 82,
    "lastUpdated": "2025-12-29T10:00:00Z"
  }
}
```

## 🔍 Debugging

### Enable verbose logging:
```typescript
// In ScraperOrchestrator.ts or individual scrapers
console.log('[DEBUG]', ...);
```

### Test single mountain:
```bash
curl "http://localhost:3000/api/scraper/run?mountain=baker"
```

### Check HTML structure:
```bash
curl https://www.mtbaker.us/snow-report/ | grep "lifts"
```

## 🚨 Error Handling

All scrapers include:
- ✅ Request timeout (10 seconds)
- ✅ Graceful degradation (returns default data on error)
- ✅ Promise.allSettled (one failure doesn't block others)
- ✅ Detailed error logging

## 📈 Next Steps

1. **Verify selectors** - Inspect each resort website and update CSS selectors
2. **Add Puppeteer** - For dynamic sites (Stevens Pass, Crystal, etc.)
3. **Database** - Replace in-memory storage with PostgreSQL
4. **Monitoring** - Add error alerts (Sentry, etc.)
5. **Rate limiting** - Add delays between scrapes if needed
6. **Authentication** - Protect /api/scraper/run endpoint

## 🛠️ Troubleshooting

**Scraper returns empty data:**
- CSS selectors are wrong (inspect page, update configs.ts)
- Page requires JavaScript (switch to dynamic scraper)
- Rate limited by resort (add delays)

**Scraper times out:**
- Increase timeout in BaseScraper.ts
- Check if page is down

**Data is stale:**
- Check cron job is running
- Verify endpoint is being hit
- Check logs for errors

## 📚 References

- [Liftie GitHub](https://github.com/pirxpilot/liftie) - Original inspiration
- [Cheerio Docs](https://cheerio.js.org/) - HTML parsing
- [Puppeteer Docs](https://pptr.dev/) - Dynamic scraping
- [Vercel Cron](https://vercel.com/docs/cron-jobs) - Scheduling

## Sources

- [How to Web Scrape with Puppeteer and Node.js in 2025](https://www.scraperapi.com/web-scraping/puppeteer/)
- [Web Scraping with Node.js: Puppeteer and Cheerio](https://www.leadwithskills.com/blogs/web-scraping-nodejs-puppeteer-cheerio)
- [Cheerio vs Puppeteer for Web Scraping in 2025](https://proxyway.com/guides/cheerio-vs-puppeteer-for-web-scraping)
