# Phase 1: Data Source Verification Agent

Comprehensive verification system for all data sources in the Shredders app.

## Overview

This verification agent tests **150+ data sources** across 5 categories:

1. **Resort Scrapers** (15 configs)
   - HTML scraping with CSS selectors
   - Bot protection detection
   - Selector validation

2. **NOAA Weather API** (68 endpoints)
   - 17 mountains × 4 endpoints each
   - Hourly forecasts
   - Daily forecasts
   - Current observations
   - Weather alerts

3. **SNOTEL Stations** (17 stations)
   - Snow depth measurements
   - Snow water equivalent (SWE)
   - Data recency validation

4. **Open-Meteo API** (26 mountains)
   - Global weather coverage (especially Canadian mountains)
   - Temperature and precipitation forecasts
   - Snowfall predictions

5. **Webcams** (40+ webcams)
   - Image accessibility
   - Staleness detection
   - Format validation

## Features

✅ **Comprehensive Testing**
- Tests all 150+ data sources systematically
- Rate limiting to avoid overwhelming servers
- Automatic retry with exponential backoff

✅ **Error Categorization**
- Bot protection (Cloudflare, Incapsula)
- Invalid CSS selectors
- Dynamic content requiring JavaScript
- HTTP errors (404, 403, 500)
- Stale data detection
- Network timeouts
- Validation errors

✅ **Detailed Reports**
- JSON report with all results
- Human-readable markdown summary
- Categorized recommendations
- Performance metrics

✅ **Flexible Configuration**
- Filter by source type
- Filter by mountain
- Adjustable timeouts and retries
- Configurable rate limiting

## Usage

### CLI (Recommended for testing)

```bash
# Verify all sources
npm run verify

# Verify only scrapers
npm run verify -- --type=scraper

# Verify only Mt. Baker
npm run verify -- --mountain=baker

# Quick test (Mt. Baker only)
npm run verify -- --quick

# Show help
npm run verify -- --help
```

### API Endpoint

```bash
# Verify all sources
GET /api/verify-sources

# Verify only scrapers
GET /api/verify-sources?type=scraper

# Verify only Mt. Baker
GET /api/verify-sources?mountain=baker

# Get markdown report
GET /api/verify-sources?format=markdown

# Filter by type and mountain
GET /api/verify-sources?type=noaa&mountain=stevens
```

### Programmatic Usage

```typescript
import {
  runVerification,
  verifyMountain,
  verifyOnlyScrapers,
  VerificationAgent,
} from '@/lib/verification';

// Verify all sources
const report = await runVerification();

// Verify single mountain
const bakerReport = await verifyMountain('baker');

// Verify only scrapers
const scraperReport = await verifyOnlyScrapers();

// Custom configuration
const agent = new VerificationAgent({
  delayBetweenRequests: 2000,
  timeout: 15000,
  includeTypes: ['scraper', 'noaa'],
  includeMountains: ['baker', 'stevens'],
});
const customReport = await agent.verifyAll();
```

## Configuration

Default configuration:

```typescript
{
  delayBetweenRequests: 1000,  // 1 second between requests
  maxRetries: 3,               // Retry failed requests 3 times
  retryDelay: 1000,            // Start with 1s, exponential backoff
  timeout: 10000,              // 10 second timeout per request
  maxConcurrent: 5,            // Max 5 concurrent requests
  staleDataThreshold: 48,      // Data older than 48 hours is stale
  saveToFile: true,            // Save reports to disk
  outputDir: './verification-reports',
  saveToDB: false,             // Database storage (not yet implemented)
}
```

## Output

### Console Summary

```
============================================================
VERIFICATION REPORT SUMMARY
============================================================

Total Sources: 150
✅ Working: 120 (80.0%)
⚠️  Warning: 10
❌ Broken: 20 (13.3%)

By Source Type:
  Scrapers: 8/15 working
  NOAA API: 64/68 working
  SNOTEL: 15/17 working
  Open-Meteo: 26/26 working
  Webcams: 7/40 working

Top Recommendations:
  🔴 Bot Protection: 4 sources
  🔴 Invalid Selectors: 3 sources
  🟡 Stale Data: 10 sources

============================================================
```

### JSON Report

Saved to `./verification-reports/verification-report-YYYY-MM-DD.json`

Contains:
- Full results for all sources
- Error categorization
- Recommendations by priority
- Performance metrics
- Sample data from successful fetches

### Markdown Report

Saved to `./verification-reports/verification-report-YYYY-MM-DD.md`

Human-readable summary with:
- Executive summary
- Breakdown by source type
- Error categories
- Prioritized recommendations
- Detailed results for each source

## Architecture

```
src/lib/verification/
├── types.ts                  # TypeScript interfaces
├── VerificationAgent.ts      # Main orchestrator
├── scraperVerifier.ts        # Resort scraper tests
├── noaaVerifier.ts           # NOAA Weather API tests
├── snotelVerifier.ts         # SNOTEL station tests
├── openMeteoVerifier.ts      # Open-Meteo API tests
├── webcamVerifier.ts         # Webcam image tests
├── reportGenerator.ts        # Report generation
├── index.ts                  # Public exports
└── README.md                 # This file

src/app/api/verify-sources/
└── route.ts                  # API endpoint

scripts/
└── verify-data-sources.ts    # CLI script
```

## Error Categories

| Category | Description | Recommendation |
|----------|-------------|----------------|
| `bot_protection` | Cloudflare, Incapsula, etc. | Use Puppeteer or find API alternative |
| `invalid_selector` | CSS selectors don't match | Update selectors, site may have changed |
| `dynamic_content` | JavaScript required | Switch to Puppeteer scraping |
| `http_error` | 404, 403, 500 errors | Verify URLs, check if moved |
| `stale_data` | Data >48 hours old | Check if station/source is operational |
| `network_timeout` | Request timed out | Increase timeout or check connectivity |
| `validation_error` | Data doesn't match schema | Update validation logic |
| `missing_data` | No configuration found | Add configuration to mountain data |
| `api_error` | API-specific errors | Check API status, verify credentials |
| `unknown` | Unclassified error | Manual investigation needed |

## Recommendations

After running verification, you'll get prioritized recommendations:

### 🔴 High Priority
- Bot protection blocking scrapers
- Invalid selectors (site redesigned)

### 🟡 Medium Priority
- Dynamic content requiring JS
- API errors or credential issues
- Stale data (station offline)

### 🟢 Low Priority
- HTTP errors (may be temporary)
- Network timeouts (may be transient)

## Next Steps (Phase 2)

1. **Database Integration**
   - Store verification results in PostgreSQL
   - Track verification history
   - Alert on newly broken sources

2. **Automated Healing**
   - Auto-update simple selector changes
   - Switch to fallback sources automatically
   - Notify maintainers of critical failures

3. **Monitoring Dashboard**
   - Real-time source health visualization
   - Historical uptime tracking
   - Performance metrics over time

4. **Smart Recommendations**
   - ML-based selector suggestions
   - Automatic API discovery
   - Predictive maintenance

## Contributing

To add a new data source type:

1. Create a new verifier module (e.g., `radarVerifier.ts`)
2. Follow the pattern from existing verifiers
3. Add types to `types.ts`
4. Integrate into `VerificationAgent.ts`
5. Update documentation

## License

Part of the Shredders PNW snow tracking application.
