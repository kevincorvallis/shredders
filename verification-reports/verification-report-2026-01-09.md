# Data Source Verification Report

**Generated:** 1/9/2026, 3:46:47 AM

## Executive Summary

- **Total Sources Tested:** 199
- **✅ Working:** 134 (67.3%)
- **⚠️ Warning:** 7
- **❌ Broken:** 58 (29.1%)

## Breakdown by Source Type

### Resort Scrapers

- Total: 15
- ✅ Working: 1 (6.7%)
- ❌ Broken: 13

### NOAA Weather API

- Total: 108
- ✅ Working: 72 (66.7%)
- ❌ Broken: 36

### SNOTEL Stations

- Total: 27
- ✅ Working: 18 (66.7%)
- ❌ Broken: 9

### Open-Meteo API

- Total: 27
- ✅ Working: 27 (100.0%)
- ❌ Broken: 0

### Webcams

- Total: 22
- ✅ Working: 16 (72.7%)
- ❌ Broken: 0

## Error Categories

- **missing_data:** 45
- **http_error:** 9
- **invalid_selector:** 4

## Recommendations

### 🔴 Invalid Selectors (high priority)

**Suggestion:** CSS selectors need updating. Inspect the pages manually to find correct selectors or check if sites have been redesigned.

**Affected sources (4):**
- stevens
- crystal
- timberline
- missionridge

### 🟢 HTTP Errors (low priority)

**Suggestion:** URLs may have changed or servers may be temporarily down. Verify URLs are correct.

**Affected sources (9):**
- whitepass
- meadows
- bachelor
- fortynine
- schweitzer
- lookout
- ashland
- willamette
- hoodoo

## Detailed Results

### SCRAPER

#### ✅ baker
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 524ms

#### ❌ stevens
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ crystal
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ⚠️ snoqualmie
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 1426ms

#### ❌ whitepass
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

#### ❌ meadows
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

#### ❌ timberline
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ bachelor
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

#### ❌ missionridge
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ fortynine
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

#### ❌ schweitzer
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

#### ❌ lookout
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

#### ❌ ashland
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

#### ❌ willamette
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

#### ❌ hoodoo
- **Error:** HTTP 404
- **Category:** http_error
- **Recommendations:**
  - Verify the URL is correct
  - Check if the page has moved
  - Inspect the site for URL changes

### NOAA

#### ✅ baker-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 164ms

#### ✅ baker-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 47ms

#### ✅ baker-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 43ms

#### ✅ baker-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 352ms

#### ✅ stevens-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 45ms

#### ✅ stevens-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 42ms

#### ✅ stevens-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 46ms

#### ✅ stevens-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 425ms

#### ✅ crystal-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 45ms

#### ✅ crystal-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 88ms

#### ✅ crystal-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 45ms

#### ✅ crystal-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 357ms

#### ✅ snoqualmie-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 66ms

#### ✅ snoqualmie-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 44ms

#### ✅ snoqualmie-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 109ms

#### ✅ snoqualmie-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 309ms

#### ✅ whitepass-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 58ms

#### ✅ whitepass-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 44ms

#### ✅ whitepass-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 70ms

#### ✅ whitepass-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 529ms

#### ✅ meadows-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 45ms

#### ✅ meadows-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 43ms

#### ✅ meadows-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 46ms

#### ✅ meadows-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 295ms

#### ✅ timberline-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 46ms

#### ✅ timberline-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 148ms

#### ✅ timberline-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 47ms

#### ✅ timberline-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 331ms

#### ✅ bachelor-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 44ms

#### ✅ bachelor-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 52ms

#### ✅ bachelor-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 45ms

#### ✅ bachelor-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 292ms

#### ✅ missionridge-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 46ms

#### ✅ missionridge-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 47ms

#### ✅ missionridge-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 166ms

#### ✅ missionridge-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 299ms

#### ✅ fortynine-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 45ms

#### ✅ fortynine-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 44ms

#### ✅ fortynine-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 48ms

#### ✅ fortynine-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 301ms

#### ✅ schweitzer-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 48ms

#### ✅ schweitzer-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 100ms

#### ✅ schweitzer-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 48ms

#### ✅ schweitzer-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 273ms

#### ✅ lookout-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 51ms

#### ✅ lookout-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 43ms

#### ✅ lookout-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 52ms

#### ✅ lookout-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 500ms

#### ✅ ashland-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 54ms

#### ✅ ashland-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 42ms

#### ✅ ashland-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 45ms

#### ✅ ashland-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 296ms

#### ✅ willamette-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 46ms

#### ✅ willamette-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 52ms

#### ✅ willamette-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 46ms

#### ✅ willamette-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 303ms

#### ✅ hoodoo-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 46ms

#### ✅ hoodoo-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 41ms

#### ✅ hoodoo-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 45ms

#### ✅ hoodoo-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 326ms

#### ❌ whistler-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ whistler-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ whistler-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ whistler-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ✅ sunvalley-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 139ms

#### ✅ sunvalley-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 55ms

#### ✅ sunvalley-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 41ms

#### ✅ sunvalley-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 306ms

#### ❌ revelstoke-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ revelstoke-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ revelstoke-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ revelstoke-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ cypress-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ cypress-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ cypress-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ cypress-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ sunpeaks-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ sunpeaks-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ sunpeaks-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ sunpeaks-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ bigwhite-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ bigwhite-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ bigwhite-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ bigwhite-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ✅ brundage-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 148ms

#### ✅ brundage-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 50ms

#### ✅ brundage-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 44ms

#### ✅ brundage-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 305ms

#### ✅ anthonylakes-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 46ms

#### ✅ anthonylakes-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 44ms

#### ✅ anthonylakes-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 47ms

#### ✅ anthonylakes-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 311ms

#### ❌ red-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ red-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ red-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ red-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ panorama-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ panorama-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ panorama-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ panorama-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ silverstar-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ silverstar-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ silverstar-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ silverstar-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ apex-noaa-hourly
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ apex-noaa-daily
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ apex-noaa-observations
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

#### ❌ apex-noaa-alerts
- **Error:** No NOAA configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add NOAA grid coordinates to mountain config

### SNOTEL

#### ✅ baker-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1620ms

#### ✅ stevens-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 237ms

#### ✅ crystal-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 242ms

#### ✅ snoqualmie-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 234ms

#### ✅ whitepass-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 308ms

#### ✅ meadows-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 247ms

#### ✅ timberline-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 239ms

#### ✅ bachelor-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 237ms

#### ✅ missionridge-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 244ms

#### ✅ fortynine-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 241ms

#### ✅ schweitzer-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 241ms

#### ✅ lookout-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 241ms

#### ✅ ashland-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 249ms

#### ✅ willamette-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 237ms

#### ✅ hoodoo-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 241ms

#### ❌ whistler-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ✅ sunvalley-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 254ms

#### ❌ revelstoke-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ❌ cypress-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ❌ sunpeaks-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ❌ bigwhite-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ✅ brundage-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 816ms

#### ✅ anthonylakes-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 245ms

#### ❌ red-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ❌ panorama-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ❌ silverstar-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ❌ apex-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

### OPEN-METEO

#### ✅ baker-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1172ms

#### ✅ stevens-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 291ms

#### ✅ crystal-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 292ms

#### ✅ snoqualmie-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 291ms

#### ✅ whitepass-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 292ms

#### ✅ meadows-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 293ms

#### ✅ timberline-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 289ms

#### ✅ bachelor-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 291ms

#### ✅ missionridge-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 294ms

#### ✅ fortynine-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 292ms

#### ✅ schweitzer-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 291ms

#### ✅ lookout-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 291ms

#### ✅ ashland-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 290ms

#### ✅ willamette-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 290ms

#### ✅ hoodoo-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 290ms

#### ✅ whistler-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 291ms

#### ✅ sunvalley-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 290ms

#### ✅ revelstoke-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 318ms

#### ✅ cypress-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 291ms

#### ✅ sunpeaks-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 290ms

#### ✅ bigwhite-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 290ms

#### ✅ brundage-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 290ms

#### ✅ anthonylakes-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 292ms

#### ✅ red-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 290ms

#### ✅ panorama-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 292ms

#### ✅ silverstar-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 289ms

#### ✅ apex-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 293ms

### WEBCAM

#### ✅ baker-webcam-nwcaa
- **Status:** success
- **Data Quality:** good
- **Response Time:** 1049ms

#### ✅ snoqualmie-webcam-i90-northbend
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 642ms

#### ✅ snoqualmie-webcam-i90-tinkham
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 694ms

#### ✅ snoqualmie-webcam-i90-dennycreek
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 604ms

#### ✅ snoqualmie-webcam-i90-asahelcurtis
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 592ms

#### ✅ snoqualmie-webcam-i90-rockdale
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 643ms

#### ✅ snoqualmie-webcam-i90-franklinfalls
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 596ms

#### ✅ snoqualmie-webcam-i90-summit
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 596ms

#### ✅ snoqualmie-webcam-i90-eastsummit
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 625ms

#### ✅ snoqualmie-webcam-i90-hyak
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 624ms

#### ✅ snoqualmie-webcam-i90-keechelusshed
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 623ms

#### ✅ snoqualmie-webcam-i90-keechelusdam
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 651ms

#### ✅ snoqualmie-webcam-i90-pricecreek
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 706ms

#### ✅ snoqualmie-webcam-i90-stampede
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 609ms

#### ✅ snoqualmie-webcam-i90-lakeeaston
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 628ms

#### ✅ snoqualmie-webcam-i90-easton
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 602ms

#### ⚠️ whistler-webcam-roundhouse
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 680ms

#### ⚠️ whistler-webcam-whistler-peak
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 602ms

#### ⚠️ whistler-webcam-rendezvous
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 614ms

#### ⚠️ whistler-webcam-7th-heaven
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 617ms

#### ⚠️ whistler-webcam-creekside
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 658ms

#### ⚠️ whistler-webcam-blackcomb-base
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 624ms
