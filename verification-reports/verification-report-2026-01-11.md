# Data Source Verification Report

**Generated:** 1/11/2026, 6:32:54 AM

## Executive Summary

- **Total Sources Tested:** 199
- **✅ Working:** 134 (67.3%)
- **⚠️ Warning:** 6
- **❌ Broken:** 59 (29.6%)

## Breakdown by Source Type

### Resort Scrapers

- Total: 15
- ✅ Working: 1 (6.7%)
- ❌ Broken: 14

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
- **invalid_selector:** 14

## Recommendations

### 🔴 Invalid Selectors (high priority)

**Suggestion:** CSS selectors need updating. Inspect the pages manually to find correct selectors or check if sites have been redesigned.

**Affected sources (14):**
- stevens
- crystal
- snoqualmie
- whitepass
- meadows
- timberline
- bachelor
- missionridge
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
- **Response Time:** 709ms

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

#### ❌ snoqualmie
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ whitepass
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ meadows
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ timberline
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ bachelor
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ missionridge
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ fortynine
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ schweitzer
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ lookout
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ ashland
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ willamette
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

#### ❌ hoodoo
- **Error:** No selectors found matching elements on page
- **Category:** invalid_selector
- **Recommendations:**
  - Inspect the page HTML to update selectors
  - Check if the site has been redesigned
  - Consider switching to API-based scraping if available

### NOAA

#### ✅ baker-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1466ms

#### ✅ baker-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 444ms

#### ✅ baker-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 182ms

#### ✅ baker-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 387ms

#### ✅ stevens-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1074ms

#### ✅ stevens-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 418ms

#### ✅ stevens-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 167ms

#### ✅ stevens-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 345ms

#### ✅ crystal-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1154ms

#### ✅ crystal-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 459ms

#### ✅ crystal-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 165ms

#### ✅ crystal-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 396ms

#### ✅ snoqualmie-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1019ms

#### ✅ snoqualmie-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 428ms

#### ✅ snoqualmie-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 168ms

#### ✅ snoqualmie-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 352ms

#### ✅ whitepass-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1225ms

#### ✅ whitepass-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 515ms

#### ✅ whitepass-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 167ms

#### ✅ whitepass-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 338ms

#### ✅ meadows-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1875ms

#### ✅ meadows-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 422ms

#### ✅ meadows-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 184ms

#### ✅ meadows-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 353ms

#### ✅ timberline-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 733ms

#### ✅ timberline-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 442ms

#### ✅ timberline-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 165ms

#### ✅ timberline-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 339ms

#### ✅ bachelor-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 492ms

#### ✅ bachelor-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 420ms

#### ✅ bachelor-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 162ms

#### ✅ bachelor-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 362ms

#### ✅ missionridge-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 734ms

#### ✅ missionridge-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 413ms

#### ✅ missionridge-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 164ms

#### ✅ missionridge-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 330ms

#### ✅ fortynine-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 866ms

#### ✅ fortynine-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 410ms

#### ✅ fortynine-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 181ms

#### ✅ fortynine-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 590ms

#### ✅ schweitzer-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 921ms

#### ✅ schweitzer-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 418ms

#### ✅ schweitzer-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 167ms

#### ✅ schweitzer-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 449ms

#### ✅ lookout-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 722ms

#### ✅ lookout-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 422ms

#### ✅ lookout-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 165ms

#### ✅ lookout-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 339ms

#### ✅ ashland-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 478ms

#### ✅ ashland-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 407ms

#### ✅ ashland-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 162ms

#### ✅ ashland-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 605ms

#### ✅ willamette-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 3299ms

#### ✅ willamette-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 757ms

#### ✅ willamette-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 167ms

#### ✅ willamette-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 478ms

#### ✅ hoodoo-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1061ms

#### ✅ hoodoo-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 410ms

#### ✅ hoodoo-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 185ms

#### ✅ hoodoo-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 402ms

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
- **Response Time:** 1042ms

#### ✅ sunvalley-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 417ms

#### ✅ sunvalley-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 153ms

#### ✅ sunvalley-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 362ms

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
- **Response Time:** 1165ms

#### ✅ brundage-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1403ms

#### ✅ brundage-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 157ms

#### ✅ brundage-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 380ms

#### ✅ anthonylakes-noaa-hourly
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 700ms

#### ✅ anthonylakes-noaa-daily
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 441ms

#### ✅ anthonylakes-noaa-observations
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 155ms

#### ✅ anthonylakes-noaa-alerts
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 336ms

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
- **Response Time:** 1852ms

#### ✅ stevens-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 252ms

#### ✅ crystal-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 248ms

#### ✅ snoqualmie-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 238ms

#### ✅ whitepass-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 232ms

#### ✅ meadows-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 248ms

#### ✅ timberline-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 245ms

#### ✅ bachelor-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 235ms

#### ✅ missionridge-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 252ms

#### ✅ fortynine-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 257ms

#### ✅ schweitzer-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 252ms

#### ✅ lookout-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 241ms

#### ✅ ashland-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 243ms

#### ✅ willamette-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 253ms

#### ✅ hoodoo-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 254ms

#### ❌ whistler-snotel
- **Error:** No SNOTEL configuration for this mountain
- **Category:** missing_data
- **Recommendations:**
  - Add SNOTEL station ID to mountain config

#### ✅ sunvalley-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 230ms

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
- **Response Time:** 1184ms

#### ✅ anthonylakes-snotel
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 458ms

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
- **Response Time:** 1197ms

#### ✅ stevens-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ crystal-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 295ms

#### ✅ snoqualmie-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 294ms

#### ✅ whitepass-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ meadows-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 294ms

#### ✅ timberline-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 299ms

#### ✅ bachelor-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 298ms

#### ✅ missionridge-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ fortynine-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 300ms

#### ✅ schweitzer-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 296ms

#### ✅ lookout-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 298ms

#### ✅ ashland-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 293ms

#### ✅ willamette-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 300ms

#### ✅ hoodoo-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 296ms

#### ✅ whistler-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 298ms

#### ✅ sunvalley-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ revelstoke-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 294ms

#### ✅ cypress-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 299ms

#### ✅ sunpeaks-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 298ms

#### ✅ bigwhite-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ brundage-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ anthonylakes-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ red-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ panorama-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 296ms

#### ✅ silverstar-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

#### ✅ apex-open-meteo
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 297ms

### WEBCAM

#### ✅ baker-webcam-nwcaa
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 1190ms

#### ✅ snoqualmie-webcam-i90-northbend
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 819ms

#### ✅ snoqualmie-webcam-i90-tinkham
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 534ms

#### ✅ snoqualmie-webcam-i90-dennycreek
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 534ms

#### ✅ snoqualmie-webcam-i90-asahelcurtis
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 535ms

#### ✅ snoqualmie-webcam-i90-rockdale
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 553ms

#### ✅ snoqualmie-webcam-i90-franklinfalls
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 536ms

#### ✅ snoqualmie-webcam-i90-summit
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 537ms

#### ✅ snoqualmie-webcam-i90-eastsummit
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 618ms

#### ✅ snoqualmie-webcam-i90-hyak
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 602ms

#### ✅ snoqualmie-webcam-i90-keechelusshed
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 603ms

#### ✅ snoqualmie-webcam-i90-keechelusdam
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 558ms

#### ✅ snoqualmie-webcam-i90-pricecreek
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 531ms

#### ✅ snoqualmie-webcam-i90-stampede
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 531ms

#### ✅ snoqualmie-webcam-i90-lakeeaston
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 530ms

#### ✅ snoqualmie-webcam-i90-easton
- **Status:** success
- **Data Quality:** excellent
- **Response Time:** 554ms

#### ⚠️ whistler-webcam-roundhouse
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 666ms

#### ⚠️ whistler-webcam-whistler-peak
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 603ms

#### ⚠️ whistler-webcam-rendezvous
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 610ms

#### ⚠️ whistler-webcam-7th-heaven
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 634ms

#### ⚠️ whistler-webcam-creekside
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 637ms

#### ⚠️ whistler-webcam-blackcomb-base
- **Status:** warning
- **Data Quality:** poor
- **Response Time:** 617ms
