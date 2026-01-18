# 🎿 Mountain Scraper Setup Guide

Complete guide to set up the automated mountain status scraping service for your Shredders app.

## 🎯 What This Does

Automatically scrapes ski resort websites daily to collect:
- ✅ Lifts open/total
- ✅ Runs open/total
- ✅ Terrain percentage open
- ✅ Operating status (open/closed)
- ✅ Conditions message

## 📦 Step 1: Install Dependencies

```bash
cd /Users/kevin/Downloads/shredders
npm install cheerio node-cron
```

**Optional (for JavaScript-heavy sites):**
```bash
npm install puppeteer
```

## 🧪 Step 2: Test the Scraper

```bash
# Start dev server
npm run dev

# In another terminal, trigger a test scrape
curl http://localhost:3000/api/scraper/run
```

**Expected output:**
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
  "data": [
    {
      "mountainId": "baker",
      "isOpen": true,
      "liftsOpen": 8,
      "liftsTotal": 10,
      ...
    }
  ]
}
```

## 🔍 Step 3: Update CSS Selectors

The default selectors are **placeholders**. You need to inspect each resort's website and update them:

### For Mt. Baker example:

1. **Visit the snow report page:**
   ```
   https://www.mtbaker.us/snow-report/
   ```

2. **Open DevTools** (F12 or right-click → Inspect)

3. **Find the lifts count element:**
   - Look for text like "8/10 Lifts Open"
   - Right-click the element → Copy → Copy selector
   - Example: `.lift-status-count`

4. **Update configs.ts:**
   ```typescript
   // src/lib/scraper/configs.ts
   baker: {
     selectors: {
       liftsOpen: '.lift-status-count',  // ← Update this
       runsOpen: '.runs-count',           // ← And this
       percentOpen: '.percent-terrain',   // ← And this
       status: '.operating-status',
     }
   }
   ```

5. **Test:**
   ```bash
   curl http://localhost:3000/api/scraper/run
   ```

6. **Repeat for all 15 mountains**

### Quick selector finding tips:

```bash
# Download HTML to inspect offline
curl https://www.mtbaker.us/snow-report/ > baker.html

# Search for keywords
grep -i "lifts" baker.html
grep -i "terrain" baker.html
grep -i "open" baker.html
```

## ⚙️ Step 4: Set Up Automation

### Option A: Vercel Cron Jobs (Easiest for Vercel)

Create `vercel.json` in project root:

```json
{
  "crons": [{
    "path": "/api/scraper/run",
    "schedule": "0 6,18 * * *"
  }]
}
```

Deploy:
```bash
git add vercel.json
git commit -m "Add scraper cron job"
git push
```

Cron will run at **6 AM and 6 PM** daily.

### Option B: GitHub Actions (Free)

Create `.github/workflows/scraper.yml`:

```yaml
name: Daily Mountain Scraper

on:
  schedule:
    - cron: '0 6,18 * * *'  # 6 AM and 6 PM UTC
  workflow_dispatch:

jobs:
  scrape:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Scraper
        run: |
          curl -X GET ${{ secrets.APP_URL }}/api/scraper/run
```

Add secret:
1. GitHub → Settings → Secrets → New secret
2. Name: `APP_URL`
3. Value: `https://your-app.vercel.app`

### Option C: External Cron Service

Use [cron-job.org](https://cron-job.org):
1. Create free account
2. Add job: `https://your-app.vercel.app/api/scraper/run`
3. Schedule: Every 12 hours

## 💾 Step 5: Add Database Storage (Recommended)

Current setup uses in-memory storage (data lost on restart). For production:

### Using Vercel Postgres:

```bash
# Install
npm install @vercel/postgres

# In Vercel dashboard:
# Storage → Create Database → Postgres
```

**Create table:**
```sql
CREATE TABLE mountain_status (
  id SERIAL PRIMARY KEY,
  mountain_id VARCHAR(50) NOT NULL,
  is_open BOOLEAN NOT NULL,
  percent_open INTEGER,
  lifts_open INTEGER DEFAULT 0,
  lifts_total INTEGER DEFAULT 0,
  runs_open INTEGER DEFAULT 0,
  runs_total INTEGER DEFAULT 0,
  scraped_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_mountain_id (mountain_id),
  INDEX idx_scraped_at (scraped_at)
);
```

**Update storage.ts:**
```typescript
import { sql } from '@vercel/postgres';

async save(data: ScrapedMountainStatus) {
  await sql`
    INSERT INTO mountain_status (
      mountain_id, is_open, percent_open,
      lifts_open, lifts_total, runs_open, runs_total
    ) VALUES (
      ${data.mountainId}, ${data.isOpen}, ${data.percentOpen},
      ${data.liftsOpen}, ${data.liftsTotal},
      ${data.runsOpen}, ${data.runsTotal}
    )
  `;
}

async get(mountainId: string) {
  const { rows } = await sql`
    SELECT * FROM mountain_status
    WHERE mountain_id = ${mountainId}
    ORDER BY scraped_at DESC
    LIMIT 1
  `;
  return rows[0] || null;
}
```

## 🔗 Step 6: Integrate with Your App

Update your existing mountain status endpoint to use scraped data:

```typescript
// src/app/api/mountains/[mountainId]/route.ts
import { scraperStorage } from '@/lib/scraper/storage';

export async function GET(req, { params }) {
  const { mountainId } = await params;

  // Get scraped data
  const scrapedStatus = scraperStorage.get(mountainId);

  // Use scraped data if available, otherwise use static config
  const status = scrapedStatus ? {
    isOpen: scrapedStatus.isOpen,
    percentOpen: scrapedStatus.percentOpen,
    liftsOpen: `${scrapedStatus.liftsOpen}/${scrapedStatus.liftsTotal}`,
    runsOpen: `${scrapedStatus.runsOpen}/${scrapedStatus.runsTotal}`,
    message: scrapedStatus.message,
    lastUpdated: scrapedStatus.lastUpdated,
  } : mountain.status;  // Fallback to static data

  return NextResponse.json({ ...mountain, status });
}
```

## 🧪 Testing Checklist

- [ ] Dependencies installed (`npm install cheerio node-cron`)
- [ ] Test scrape runs: `curl localhost:3000/api/scraper/run`
- [ ] At least 3 mountains return successful data
- [ ] Updated CSS selectors for tested mountains
- [ ] Cron job configured (Vercel/GitHub/External)
- [ ] Database set up (optional but recommended)
- [ ] Integrated scraped data into app endpoints

## 🐛 Troubleshooting

### "No data returned"
- CSS selectors are wrong
- Inspect page HTML manually
- Try different selectors

### "Request timeout"
- Increase timeout in BaseScraper.ts (line 31)
- Check if resort website is down

### "Data is incorrect"
- Selectors might be matching wrong elements
- Use more specific selectors (add parent classes)

### "Scraper doesn't run automatically"
- Check cron job configuration
- Verify endpoint URL is correct
- Check Vercel logs: `vercel logs`

## 📚 Next Steps

1. **Test all mountains** - Verify selectors work for each resort
2. **Add monitoring** - Set up alerts for scraper failures
3. **Optimize** - Add caching, rate limiting if needed
4. **Puppeteer** - Add for dynamic sites that need JavaScript

## 🎉 Success Metrics

After setup, you should see:
- ✅ Scraper runs twice daily (6 AM, 6 PM)
- ✅ 80%+ success rate (12+ of 15 mountains)
- ✅ Fresh data (< 12 hours old)
- ✅ Accurate status reflected in app

## 📞 Need Help?

Check the full documentation:
- Main README: `src/lib/scraper/README.md`
- Architecture docs in each scraper file
- Liftie project: https://github.com/pirxpilot/liftie

---

**Estimated Setup Time:** 2-3 hours (mostly testing selectors)
**Maintenance:** ~1 hour/month (fixing broken selectors)
