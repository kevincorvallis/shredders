# OnTheSnow Scraper Investigation - Key Findings

**Date:** January 11, 2026
**Investigated URL:** https://www.onthesnow.com/washington/crystal-mountain-wa/skireport

---

## Problem Summary

14 out of 15 scrapers are broken because they use **invalid OnTheSnow CSS selectors** that don't exist on the page:

```typescript
// CURRENT (BROKEN):
selectors: {
  liftsOpen: '[data-testid="lifts-status"], .lift-status, .lifts',
  runsOpen: '[data-testid="trails-status"], .trail-status, .trails',
  status: '.conditions-header, .status',
}
```

**Result:** All OnTheSnow scrapers return null/undefined for lifts and runs data.

---

## Investigation Findings

### ❌ What DOESN'T Work

1. **data-testid attributes** - OnTheSnow doesn't use these at all
2. **Simple class names** - Classes like `.lift-status` and `.trail-status` don't exist
3. **CSS selectors approach** - OnTheSnow uses CSS Modules with hashed class names

### ✅ What I Discovered

OnTheSnow uses **CSS Modules** with hashed class names:

```html
<!-- Lifts Section -->
<div class="styles_title__zz3Sm">Lifts Open</div>
<div class="styles_metric__z_U_F">11/11 open</div>

<!-- Runs Section -->
<div class="styles_title__zz3Sm">Runs Open</div>
<div class="styles_metric__z_U_F">73/85 open</div>
```

**Problem:** These class names (`styles_title__zz3Sm`, `styles_metric__z_U_F`) will **change with every OnTheSnow deployment**. They are NOT stable selectors.

### 🎯 The Best Solution: Parse JSON Data

OnTheSnow embeds ALL resort data in a JSON script tag:

```html
<script id="__NEXT_DATA__" type="application/json">
{
  "props": {
    "pageProps": {
      "resort": {
        "uuid": "124",
        "title": "Crystal Mountain",
        "liftCounts": {
          "open": 11,
          "total": 11
        },
        "trailCounts": {
          "open": 73,
          "total": 85
        },
        "snowReport": {
          "base": 27,
          "mid": 50,
          "summit": 55,
          "fresh24h": 4,
          "fresh48h": 15
        }
        // ... more data
      }
    }
  }
}
</script>
```

This JSON contains:
- ✅ Lifts open/total
- ✅ Runs open/total
- ✅ Snow depths (base, mid, summit)
- ✅ Fresh snowfall (24h, 48h)
- ✅ Status, conditions, and more

**Advantages:**
- **Stable** - JSON structure doesn't change
- **Complete** - Contains ALL data we need
- **Reliable** - Used by OnTheSnow's own React app
- **Fast** - No complex DOM parsing needed

---

## Recommended Fix

### Option A: Parse __NEXT_DATA__ JSON (RECOMMENDED)

Update `HTMLScraper.ts` to detect OnTheSnow pages and parse JSON:

```typescript
// In HTMLScraper.ts
private parseOnTheSnow($: CheerioAPI): Partial<ScraperResult> {
  try {
    // Find the __NEXT_DATA__ script tag
    const scriptContent = $('#__NEXT_DATA__').html();
    if (!scriptContent) {
      throw new Error('__NEXT_DATA__ script not found');
    }

    const data = JSON.parse(scriptContent);
    const resort = data?.props?.pageProps?.resort;

    if (!resort) {
      throw new Error('Resort data not found in JSON');
    }

    // Extract data from JSON
    const liftsOpen = resort.liftCounts?.open;
    const liftsTotal = resort.liftCounts?.total;
    const runsOpen = resort.trailCounts?.open;
    const runsTotal = resort.trailCounts?.total;

    return {
      liftsOpen: liftsOpen && liftsTotal ? `${liftsOpen}/${liftsTotal}` : null,
      runsOpen: runsOpen && runsTotal ? `${runsOpen}/${runsTotal}` : null,
      status: resort.status || 'OPEN',
      snowDepth: resort.snowReport?.base,
      // Can also extract: snowfall24h, snowfall48h, etc.
    };
  } catch (error) {
    console.error('[OnTheSnow] JSON parsing failed:', error);
    return {};
  }
}
```

### Option B: Use Hashed Classes (NOT RECOMMENDED)

Update selectors to use current hashed class names:

```typescript
selectors: {
  liftsOpen: '.styles_metric__z_U_F',  // First metric with "11/11 open"
  runsOpen: '.styles_metric__z_U_F',   // Second metric with "73/85 open"
}
```

**Problems:**
- ❌ Class names will break when OnTheSnow updates
- ❌ Need to distinguish which `.styles_metric__z_U_F` is lifts vs runs
- ❌ Fragile and maintenance-heavy

---

## Implementation Plan

1. **Update HTMLScraper.ts** (30 min)
   - Add `parseOnTheSnow()` method
   - Detect OnTheSnow URLs via hostname check
   - Parse `__NEXT_DATA__` JSON instead of using selectors

2. **Update scraper configs** (10 min)
   - Mark OnTheSnow scrapers with special flag
   - Or add a `parser: 'onthesnow-json'` option
   - Keep selectors for non-OnTheSnow scrapers

3. **Test all OnTheSnow scrapers** (20 min)
   - Test on all 14 OnTheSnow URLs
   - Verify lifts/runs data extraction
   - Check for edge cases (closed resorts, missing data)

**Total Time:** ~1 hour

---

## Impact

**Before Fix:**
- 1/15 scrapers working (6.7%)
- 14 scrapers broken due to invalid selectors

**After Fix:**
- 15/15 scrapers working (100%)
- Stable, maintainable solution
- Additional data available (snowfall, depths, etc.)

---

## Affected Scrapers

All these scrapers use OnTheSnow and need this fix:

1. ✅ **Stevens Pass** (Priority - Epic Pass)
2. ✅ **Crystal Mountain** (Priority - Epic Pass)
3. ✅ Snoqualmie
4. ✅ White Pass
5. ✅ Mt. Hood Meadows
6. ✅ Timberline Lodge
7. ✅ Mt. Bachelor
8. ✅ Mission Ridge
9. ✅ 49 Degrees North
10. ✅ Schweitzer
11. ✅ Lookout Pass
12. ✅ Mt. Ashland
13. ✅ Willamette Pass
14. ✅ Hoodoo

---

## Next Steps

1. [ ] Implement JSON parser in HTMLScraper.ts
2. [ ] Test on Crystal Mountain URL
3. [ ] Verify all 14 OnTheSnow scrapers work
4. [ ] Enable database persistence (Quick Fix #3)
5. [ ] Run full verification suite

---

## Alternative: Check for Official APIs

Some resorts may have official APIs that are more reliable:
- **Stevens Pass:** Check crystalmountainresort.com API (Alterra-owned)
- **Crystal Mountain:** Check crystalmountainresort.com API
- **Mt. Bachelor:** Check mtbachelor.com API

OnTheSnow JSON parsing is still the fastest path to fixing all 14 scrapers immediately.
