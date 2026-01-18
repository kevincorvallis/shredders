# Scraper Configuration Guide

Complete guide for configuring and adding new mountain scrapers to the Shredders system.

## Overview

The Shredders scraper system uses a configuration-driven approach with three main scraper types:
1. **JSON Scrapers** - Parse structured JSON data from APIs
2. **HTML Scrapers** - Extract data from HTML using CSS selectors
3. **OnTheSnow Scrapers** - Parse OnTheSnow's Next.js data (fallback for most mountains)

## Configuration File

**Location:** `/src/lib/scraper/configs/index.ts`

Each mountain scraper is defined in the `scraperConfigs` map with a unique ID.

## Configuration Schema

```typescript
interface ScraperConfig {
  id: string;              // Unique identifier (e.g., "baker", "alpental")
  name: string;            // Display name (e.g., "Mt. Baker")
  url: string;             // Primary source URL
  dataUrl?: string;        // Optional separate data endpoint
  type: 'json' | 'html' | 'onthesnow';
  enabled: boolean;        // Whether to include in scraper runs
  selectors?: {            // CSS selectors (HTML type only)
    [key: string]: string | RegExp;
  };
  jsonPath?: {             // JSON extraction paths (JSON type only)
    [key: string]: string;
  };
  parser?: (data: any) => MountainStatus;  // Custom parsing function
}
```

## Scraper Types

### 1. JSON Scraper

Used when the mountain provides a structured JSON API.

**Example: Crystal Mountain**
```typescript
crystal: {
  id: 'crystal',
  name: 'Crystal Mountain',
  url: 'https://www.crystalmountainresort.com/the-mountain/mountain-report/',
  dataUrl: 'https://www.crystalmountainresort.com/api/mountain-conditions',
  type: 'json',
  enabled: true,
  jsonPath: {
    liftsOpen: 'lifts.open',
    liftsTotal: 'lifts.total',
    runsOpen: 'trails.open',
    runsTotal: 'trails.total',
  },
}
```

**When to use:**
- Mountain has a public JSON API endpoint
- Data is consistently structured
- No HTML parsing needed

**Advantages:**
- Fast and reliable
- Less prone to breaking from UI changes
- Easy to debug

### 2. HTML Scraper

Used when scraping data directly from HTML pages using CSS selectors.

**Example: Mt. Baker (Direct Scraping)**
```typescript
baker: {
  id: 'baker',
  name: 'Mt. Baker',
  url: 'https://www.mtbaker.us/mountain-report/',
  type: 'html',
  enabled: true,
  selectors: {
    isOpen: '.status-open',  // CSS selector for open status
    liftsOpen: '.lifts .open',
    liftsTotal: '.lifts .total',
    runsOpen: '.runs .open',
    runsTotal: '.runs .total',
    message: '.conditions-message',
    // RegExp for text extraction:
    percentOpen: /(\d+)% Open/i,
  },
  parser: (data: CheerioAPI) => {
    // Custom parsing logic
    const liftsOpen = parseInt(data('.lifts-open').text().trim()) || 0;
    const liftsTotal = parseInt(data('.lifts-total').text().trim()) || 0;

    return {
      mountainId: 'baker',
      isOpen: liftsOpen > 0,
      liftsOpen,
      liftsTotal,
      // ... more fields
    };
  },
}
```

**When to use:**
- No JSON API available
- Data is embedded in HTML
- You need full control over parsing

**Advantages:**
- Works with any website
- Can extract complex data structures
- Custom parser for special cases

**Disadvantages:**
- Breaks when HTML structure changes
- Slower than JSON
- More complex to maintain

### 3. OnTheSnow Scraper (Fallback)

Used as a fallback when direct scraping fails or is unavailable. Parses OnTheSnow's Next.js `__NEXT_DATA__` script tag.

**Example: Alpental (OnTheSnow Fallback)**
```typescript
alpental: {
  id: 'alpental',
  name: 'Alpental',
  url: 'https://www.onthesnow.com/washington/alpental/skireport',
  type: 'onthesnow',
  enabled: true,
}
```

**When to use:**
- Mountain's direct API/HTML is unreliable
- Quick setup for new mountains
- Temporary solution until direct scraper is built

**Advantages:**
- Works for most major ski resorts
- Consistent data format
- Quick to configure

**Disadvantages:**
- Depends on third-party data accuracy
- May not be as fresh as direct scraping
- Limited control over data quality

## Adding a New Mountain

### Step 1: Find Data Source

1. **Check for JSON API:**
   - Open browser DevTools → Network tab
   - Load the mountain's website
   - Filter by XHR/Fetch requests
   - Look for JSON responses with lift/run data

2. **Inspect HTML Structure:**
   - Right-click → Inspect Element on lift/run counts
   - Note CSS classes and structure
   - Test selectors in browser console: `document.querySelector('.your-selector')`

3. **Fallback to OnTheSnow:**
   - Search: `site:onthesnow.com [mountain name]`
   - Verify data exists in page source

### Step 2: Add Configuration

Add to `/src/lib/scraper/configs/index.ts`:

```typescript
export const scraperConfigs: Map<string, ScraperConfig> = new Map([
  // ... existing configs

  ['your-mountain-id', {
    id: 'your-mountain-id',
    name: 'Your Mountain Name',
    url: 'https://mountain-website.com/conditions',
    type: 'json', // or 'html' or 'onthesnow'
    enabled: true,

    // For JSON type:
    dataUrl: 'https://mountain-website.com/api/conditions',
    jsonPath: {
      liftsOpen: 'data.lifts.open',
      liftsTotal: 'data.lifts.total',
      runsOpen: 'data.trails.open',
      runsTotal: 'data.trails.total',
    },

    // For HTML type:
    selectors: {
      liftsOpen: '.lift-status .open',
      liftsTotal: '.lift-status .total',
      // ... more selectors
    },
  }],
]);
```

### Step 3: Test Locally

```bash
# Test single mountain
pnpm tsx scripts/test-scraper.ts your-mountain-id

# Test all scrapers
pnpm tsx scripts/test-scraper.ts

# Verbose output
pnpm tsx scripts/test-scraper.ts your-mountain-id --verbose
```

### Step 4: Verify Data

Check that the scraper returns:
- `isOpen`: boolean
- `liftsOpen`: number (>= 0)
- `liftsTotal`: number (>= liftsOpen)
- `runsOpen`: number (>= 0)
- `runsTotal`: number (>= runsOpen)
- `percentOpen`: number (0-100, optional)
- `message`: string (optional)

### Step 5: Deploy

```bash
git add .
git commit -m "Add scraper for [Mountain Name]"
git push origin main
```

Vercel will automatically deploy and run the scraper daily at 6 AM UTC.

## Common Patterns

### Pattern 1: Nested JSON Path

```typescript
jsonPath: {
  liftsOpen: 'mountain.lifts.operational.count',
  liftsTotal: 'mountain.lifts.total.count',
}
```

This extracts from:
```json
{
  "mountain": {
    "lifts": {
      "operational": { "count": 5 },
      "total": { "count": 10 }
    }
  }
}
```

### Pattern 2: RegExp Text Extraction

```typescript
selectors: {
  percentOpen: /(\d+)% of terrain/i,
  snowfall24h: /(\d+)" new snow/i,
}
```

Extracts numbers from text like "75% of terrain open" → `75`

### Pattern 3: Custom Parser for Complex Logic

```typescript
parser: (data: CheerioAPI) => {
  const statusText = data('.status').text().toLowerCase();
  const isOpen = statusText.includes('open') && !statusText.includes('closed');

  // Extract numbers from combined string "5/10 Lifts"
  const liftsMatch = data('.lifts').text().match(/(\d+)\/(\d+)/);
  const liftsOpen = liftsMatch ? parseInt(liftsMatch[1]) : 0;
  const liftsTotal = liftsMatch ? parseInt(liftsMatch[2]) : 0;

  return {
    mountainId: 'your-mountain-id',
    isOpen,
    liftsOpen,
    liftsTotal,
    runsOpen: 0,
    runsTotal: 0,
    scrapedAt: new Date(),
  };
}
```

## Debugging Tips

### 1. Check Selector Matches

```typescript
// Add to parser:
console.log('Lifts element:', data('.lifts').html());
console.log('Lifts text:', data('.lifts').text());
```

### 2. Validate JSON Path

```bash
# Test JSON endpoint directly
curl "https://mountain-api.com/conditions" | jq '.mountain.lifts.open'
```

### 3. Test with Verbose Output

```bash
pnpm tsx scripts/test-scraper.ts your-mountain-id --verbose
```

Shows full parsed data structure.

### 4. Check for Dynamic Content

If selectors don't match:
- Content may be loaded via JavaScript
- Check browser DevTools → Network for AJAX calls
- Look for JSON API instead of HTML scraping

## Error Handling

All scrapers automatically handle:
- Network timeouts (30s)
- Invalid HTML/JSON
- Missing selectors
- Parse errors

Failed scrapers return:
```typescript
{
  success: false,
  error: 'Timeout after 30000ms',
  duration: 30000,
}
```

## Performance

**Current Performance (15 scrapers):**
- Total time: ~1.8 seconds
- Parallel execution via `Promise.allSettled`
- Individual timeout: 30 seconds
- Success rate: 100%

**Tips:**
- Use JSON scrapers when possible (fastest)
- Keep HTML selectors simple
- Add timeout for slow endpoints
- Test locally before deploying

## Configuration Reference

**Current Mountains (15):**
1. Mt. Baker - HTML (direct scraping)
2. Stevens Pass - OnTheSnow fallback
3. Crystal Mountain - OnTheSnow fallback
4. Snoqualmie Pass - OnTheSnow fallback
5. White Pass - OnTheSnow fallback
6. Mission Ridge - OnTheSnow fallback
7. 49 Degrees North - OnTheSnow fallback
8. Schweitzer - OnTheSnow fallback
9. Mt. Spokane - OnTheSnow fallback
10. Hurricane Ridge - OnTheSnow fallback
11. Alpental - OnTheSnow fallback
12. Summit West - OnTheSnow fallback
13. Summit Central - OnTheSnow fallback
14. Summit East - OnTheSnow fallback
15. Mt. Rainier Paradise - OnTheSnow fallback

**Status:** 100% success rate, all operational

## Related Files

- **Config:** `/src/lib/scraper/configs/index.ts`
- **Orchestrator:** `/src/lib/scraper/ScraperOrchestrator.ts`
- **Scrapers:** `/src/lib/scraper/scrapers/`
  - `JsonScraper.ts`
  - `HtmlScraper.ts`
  - `OnTheSnowScraper.ts`
- **Storage:** `/src/lib/scraper/storage-postgres.ts`
- **Test Script:** `/scripts/test-scraper.ts`
- **API Endpoint:** `/src/app/api/scraper/run/route.ts`

## Next Steps

1. Monitor scraper health via `/api/scraper/monitor`
2. Check for failures in `/api/scraper/failures`
3. Review run history at `/api/scraper/runs`
4. Set up Slack alerts (see MONITORING.md)
