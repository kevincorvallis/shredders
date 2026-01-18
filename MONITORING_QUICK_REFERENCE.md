# Scraper Monitoring Quick Reference

Fast reference guide for monitoring scraper health and debugging issues.

## Quick Health Check

```bash
# Instant health check (no database query)
curl https://your-app.vercel.app/api/scraper/ping | jq

# Comprehensive dashboard
curl https://your-app.vercel.app/api/scraper/monitor | jq

# Check if healthy
curl -s https://your-app.vercel.app/api/scraper/monitor | jq '.status'
# Output: "healthy" | "degraded" | "unhealthy"
```

## Monitoring Endpoints

### 1. `/api/scraper/ping` - Instant Health
**Response Time:** < 100ms (no database query)

```bash
curl https://your-app.vercel.app/api/scraper/ping | jq
```

**Response:**
```json
{
  "status": "ok",
  "message": "Scraper API is operational",
  "timestamp": "2026-01-12T10:30:00.000Z",
  "environment": {
    "hasDatabase": true,
    "hasSlackWebhook": false
  }
}
```

**Use for:** Uptime monitoring, quick availability check

---

### 2. `/api/scraper/monitor` - Main Dashboard
**Response Time:** < 1 second

```bash
curl https://your-app.vercel.app/api/scraper/monitor | jq
```

**Response:**
```json
{
  "status": "healthy",
  "health": {
    "isHealthy": true,
    "successRate": 93.33,
    "threshold": 80,
    "message": "All systems operational"
  },
  "recentRuns": [...],
  "recentFailures": [...],
  "failuresByMountain": [...],
  "stats": {...},
  "alerts": {...}
}
```

**Use for:** Overall health, recent activity, failure patterns

---

### 3. `/api/scraper/runs` - Run History
**Response Time:** < 1 second

```bash
# Last 20 runs (default)
curl https://your-app.vercel.app/api/scraper/runs | jq

# Last 50 runs
curl https://your-app.vercel.app/api/scraper/runs?limit=50 | jq

# Get specific fields
curl -s https://your-app.vercel.app/api/scraper/runs | \
  jq '.runs[] | {runId, successful, failed, successRate}'
```

**Response:**
```json
{
  "runs": [
    {
      "runId": "run-1736677200-abc123",
      "totalMountains": 15,
      "successful": 14,
      "failed": 1,
      "duration": 1823,
      "status": "completed",
      "triggeredBy": "cron",
      "startedAt": "2026-01-12T06:00:00.000Z",
      "completedAt": "2026-01-12T06:00:02.000Z",
      "successRate": 93.33
    }
  ],
  "stats": {
    "last30Days": {
      "totalRuns": 15,
      "completedRuns": 14,
      "failedRuns": 1,
      "avgSuccessful": 14.5,
      "avgFailed": 0.5,
      "avgDurationMs": 1800,
      "overallSuccessRate": 96.67
    }
  }
}
```

**Use for:** Historical performance, trend analysis

---

### 4. `/api/scraper/failures` - Detailed Failures
**Response Time:** < 1 second

```bash
# All failures (last 7 days)
curl https://your-app.vercel.app/api/scraper/failures | jq

# Last 14 days
curl https://your-app.vercel.app/api/scraper/failures?days=14 | jq

# Specific mountain
curl https://your-app.vercel.app/api/scraper/failures?mountainId=baker | jq

# Get error messages only
curl -s https://your-app.vercel.app/api/scraper/failures | \
  jq '.failures[].error'
```

**Response:**
```json
{
  "failures": [
    {
      "id": "uuid-here",
      "runId": "run-1736677200-abc123",
      "mountainId": "crystal",
      "error": "Timeout after 30000ms",
      "sourceUrl": "https://crystalmountainresort.com/conditions",
      "failedAt": "2026-01-12T06:00:01.000Z",
      "runStartedAt": "2026-01-12T06:00:00.000Z",
      "runStats": {
        "successful": 14,
        "failed": 1
      }
    }
  ],
  "summary": [
    {
      "mountainId": "crystal",
      "count": 3,
      "lastFailure": "2026-01-12T06:00:01.000Z",
      "errors": ["Timeout after 30000ms", "Invalid JSON response"]
    }
  ]
}
```

**Use for:** Debugging specific failures, identifying problematic scrapers

---

### 5. `/api/scraper/run` - Manual Trigger
**Response Time:** ~2 seconds (runs all scrapers)

```bash
# Trigger manual scraper run
curl https://your-app.vercel.app/api/scraper/run | jq

# Get just the summary
curl -s https://your-app.vercel.app/api/scraper/run | \
  jq '{success, storage, results, duration}'
```

**Response:**
```json
{
  "success": true,
  "message": "Scraped 15/15 mountains",
  "duration": 1823,
  "results": {
    "total": 15,
    "successful": 15,
    "failed": 0
  },
  "storage": "postgres",
  "runId": "run-1736677200-abc123",
  "data": [...],
  "timestamp": "2026-01-12T10:30:02.000Z"
}
```

**Use for:** Testing after configuration changes, immediate data refresh

---

## Common Commands

### Check Success Rate
```bash
curl -s https://your-app.vercel.app/api/scraper/monitor | \
  jq '.health.successRate'
```

### List Failed Mountains
```bash
curl -s https://your-app.vercel.app/api/scraper/monitor | \
  jq '.failuresByMountain[] | {mountainId, failureCount}'
```

### Get Last Run Status
```bash
curl -s https://your-app.vercel.app/api/scraper/runs | \
  jq '.runs[0] | {runId, successful, failed, duration, startedAt}'
```

### Count Recent Failures (24h)
```bash
curl -s https://your-app.vercel.app/api/scraper/monitor | \
  jq '.recentFailures | length'
```

### Show Failure Errors
```bash
curl -s https://your-app.vercel.app/api/scraper/failures | \
  jq '.failures[] | "\(.mountainId): \(.error)"'
```

### Verify Database Connection
```bash
curl -s https://your-app.vercel.app/api/scraper/ping | \
  jq '.environment.hasDatabase'
```

---

## Local Testing Commands

### Test All Scrapers
```bash
cd /Users/kevin/Downloads/shredders
pnpm tsx scripts/test-scraper.ts
```

**Output:**
```
🏔️  Testing all 15 scrapers...

📊 Results Summary:

✅ SUCCESS | Mt. Baker               | 234ms
✅ SUCCESS | Stevens Pass            | 156ms
✅ SUCCESS | Crystal Mountain        | 189ms
...

📈 Success Rate: 15/15 (100.0%)
✅ Success rate above 80% threshold - healthy!
```

### Test Single Mountain
```bash
pnpm tsx scripts/test-scraper.ts baker
```

**Output:**
```
🏔️  Testing Mt. Baker (baker)...
   URL: https://www.mtbaker.us/mountain-report/
   Type: html
   Enabled: ✅

   ✅ SUCCESS (234ms)
      Open: YES
      Lifts: 7/10
      Runs: 42/58
      % Open: 72%
      Message: Excellent conditions with fresh powder...
```

### Test with Detailed Output
```bash
pnpm tsx scripts/test-scraper.ts baker --verbose
```

Shows full JSON response data.

---

## Troubleshooting

### Problem: Success Rate < 80%

**Check which mountains are failing:**
```bash
curl -s https://your-app.vercel.app/api/scraper/failures | \
  jq '.summary | sort_by(.count) | reverse | .[] | "\(.mountainId): \(.count) failures"'
```

**Test locally:**
```bash
pnpm tsx scripts/test-scraper.ts [mountain-id]
```

**Common causes:**
- Website HTML structure changed
- API endpoint moved or changed format
- Network timeout (increase timeout in config)
- OnTheSnow fallback URL outdated

---

### Problem: No Recent Runs

**Check last run time:**
```bash
curl -s https://your-app.vercel.app/api/scraper/runs | \
  jq '.runs[0].startedAt'
```

**Verify cron schedule:**
```bash
# Check vercel.json
cat vercel.json | jq '.crons'

# Should show:
# [{ "path": "/api/scraper/run", "schedule": "0 6 * * *" }]
```

**Check Vercel cron logs:**
- Go to Vercel dashboard
- Select project → Cron Jobs
- View execution history

---

### Problem: Endpoint Timeouts

**Symptoms:**
- Requests take > 10 seconds
- Function invocation timeout errors

**Solutions:**

1. **Verify connection pooling:**
```typescript
// ✅ CORRECT (fast)
import { sql } from '@vercel/postgres';
const result = await sql`SELECT ...`;

// ❌ WRONG (slow)
import { createClient } from '@vercel/postgres';
const db = createClient({ connectionString: ... });
const result = await db.sql`SELECT ...`;
```

2. **Check function timeout** in `vercel.json`:
```json
{
  "functions": {
    "src/app/api/scraper/**/*.ts": {
      "maxDuration": 60
    }
  }
}
```

---

### Problem: Storage Shows "none"

**Check response:**
```bash
curl -s https://your-app.vercel.app/api/scraper/run | jq '.storage'
```

**If returns "none":**
- Database connection not configured
- Missing `scraperStorage` import
- Environment variable missing

**Verify environment:**
```bash
curl -s https://your-app.vercel.app/api/scraper/ping | jq '.environment'
```

**Should show:**
```json
{
  "hasDatabase": true,
  "hasSlackWebhook": false
}
```

---

### Problem: Scraper Failures

**Get error details:**
```bash
curl -s https://your-app.vercel.app/api/scraper/failures?mountainId=baker | \
  jq '.failures[] | {error, failedAt, sourceUrl}'
```

**Common errors:**

1. **"Timeout after 30000ms"**
   - Website is slow or down
   - Increase timeout in config
   - Check if website is accessible

2. **"Invalid JSON response"**
   - API format changed
   - Update `jsonPath` in config
   - Check API endpoint directly: `curl [url] | jq`

3. **"Selector returned no elements"**
   - HTML structure changed
   - Update selectors in config
   - Inspect website HTML: DevTools → Elements

4. **"Network error"**
   - DNS resolution failed
   - Website temporarily down
   - Check website availability: `curl -I [url]`

---

## Database Queries

### Check Scraper Run History
```sql
SELECT
  run_id,
  total_mountains,
  successful_count,
  failed_count,
  duration_ms,
  status,
  started_at,
  completed_at
FROM scraper_runs
ORDER BY started_at DESC
LIMIT 10;
```

### Check Mountain Status Freshness
```sql
SELECT
  mountain_id,
  lifts_open,
  lifts_total,
  runs_open,
  runs_total,
  scraped_at,
  AGE(NOW(), scraped_at) as age
FROM mountain_status
ORDER BY scraped_at DESC;
```

### Find Problem Mountains
```sql
SELECT
  mountain_id,
  COUNT(*) as failure_count,
  MAX(failed_at) as last_failure,
  ARRAY_AGG(DISTINCT error_message) as errors
FROM scraper_failures
WHERE failed_at >= NOW() - INTERVAL '7 days'
GROUP BY mountain_id
ORDER BY failure_count DESC;
```

### Calculate Success Rate Trend
```sql
SELECT
  DATE(started_at) as date,
  COUNT(*) as runs,
  AVG(successful_count) as avg_successful,
  AVG(failed_count) as avg_failed,
  AVG(successful_count * 100.0 / total_mountains) as success_rate
FROM scraper_runs
WHERE started_at >= NOW() - INTERVAL '30 days'
  AND status = 'completed'
GROUP BY DATE(started_at)
ORDER BY date DESC;
```

---

## Alert Configuration

### Set Up Slack Alerts

1. **Create Slack Webhook:**
   - Go to Slack API → Incoming Webhooks
   - Create webhook for your channel
   - Copy webhook URL

2. **Add to Vercel:**
```bash
printf "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" | \
  vercel env add SLACK_WEBHOOK_URL production
```

3. **Verify:**
```bash
curl -s https://your-app.vercel.app/api/scraper/monitor | \
  jq '.alerts'
```

Should show:
```json
{
  "enabled": true,
  "channels": ["slack"]
}
```

### Alert Triggers

Alerts are sent automatically when:
- Success rate < 80% (degraded warning)
- Success rate < 50% (critical failure)
- Individual scraper fails 3+ times in 24 hours

---

## Performance Benchmarks

**Target Metrics:**
- Total scrape time: < 3 seconds
- Individual scraper: < 500ms
- Success rate: > 80%
- Database query time: < 1 second
- API response time: < 2 seconds

**Current Performance (15 scrapers):**
- Total time: ~1.8 seconds ✅
- Success rate: 100% ✅
- API response: < 1 second ✅

---

## Cron Schedule

**Current Schedule:**
```
0 6 * * *  →  Daily at 6:00 AM UTC
           →  10:00 PM PST (winter)
           →  11:00 PM PDT (summer)
```

**Next run:**
```bash
# Convert UTC to your local time
date -d "06:00 UTC" "+%I:%M %p %Z"
```

**Check last cron execution:**
- Vercel Dashboard → Project → Cron Jobs → View Logs

---

## Quick Diagnostic Script

Save as `check-scrapers.sh`:

```bash
#!/bin/bash
API_URL="https://your-app.vercel.app"

echo "=== SCRAPER HEALTH CHECK ==="
echo ""

# 1. API Availability
echo "1. API Status:"
curl -s "$API_URL/api/scraper/ping" | jq -r '.status'
echo ""

# 2. Overall Health
echo "2. System Health:"
curl -s "$API_URL/api/scraper/monitor" | \
  jq -r '"\(.status) - Success Rate: \(.health.successRate)%"'
echo ""

# 3. Last Run
echo "3. Last Scraper Run:"
curl -s "$API_URL/api/scraper/runs" | \
  jq -r '.runs[0] | "\(.startedAt) - \(.successful)/\(.totalMountains) successful"'
echo ""

# 4. Recent Failures
echo "4. Recent Failures (24h):"
curl -s "$API_URL/api/scraper/monitor" | \
  jq -r '.recentFailures | length'
echo ""

# 5. Failed Mountains
echo "5. Mountains with Most Failures (7d):"
curl -s "$API_URL/api/scraper/failures" | \
  jq -r '.summary[:5][] | "\(.mountainId): \(.count) failures"'
echo ""
```

**Usage:**
```bash
chmod +x check-scrapers.sh
./check-scrapers.sh
```

---

## Related Documentation

- **Configuration:** `SCRAPER_CONFIGURATION.md`
- **Phase 2 Complete:** `PHASE_2_COMPLETE.md`
- **Full Monitoring Guide:** `MONITORING.md`
- **Data Verification:** `QUICK_REFERENCE.md`

---

## Support Contacts

**GitHub Issues:** https://github.com/anthropics/claude-code/issues
**Vercel Status:** https://www.vercel-status.com
**OnTheSnow:** https://www.onthesnow.com

---

**Last Updated:** 2026-01-12
**System Version:** Phase 2 Complete
**Scrapers:** 15 active, 100% success rate
