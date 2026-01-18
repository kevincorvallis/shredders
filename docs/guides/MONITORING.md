# Scraper Monitoring & Alerts

This document describes the monitoring and alerting system for the mountain status scraper.

## Overview

The scraper system includes comprehensive monitoring with:
- Health tracking (80% success rate threshold)
- Automatic alerts via Slack webhooks
- Failure tracking and debugging endpoints
- Run history and performance metrics
- Per-mountain success rate tracking

## Monitoring Endpoints

### 1. Health Check: `/api/scraper/health`

Returns overall health status based on 7-day performance.

**Response:**
```json
{
  "healthy": true,
  "stats": {
    "totalMountains": 15,
    "totalHistoryEntries": 450,
    "last7Days": {
      "totalRuns": 7,
      "avgSuccessful": 14.5,
      "avgFailed": 0.5,
      "avgDurationMs": 12500,
      "successRate": 96.67
    }
  },
  "timestamp": "2026-01-12T04:00:00Z"
}
```

**Health Threshold:**
- `healthy: true` if success rate >= 80%
- `healthy: false` if success rate < 80%

### 2. Comprehensive Monitoring: `/api/scraper/monitor`

Main dashboard endpoint with all monitoring data in one place.

**Response:**
```json
{
  "status": "healthy",
  "health": {
    "isHealthy": true,
    "successRate": 96.67,
    "threshold": 80,
    "message": "All systems operational"
  },
  "recentRuns": [
    {
      "runId": "run-1234567890-abc123",
      "successful": 15,
      "failed": 0,
      "total": 15,
      "duration": 12500,
      "startedAt": "2026-01-12T06:00:00Z",
      "completedAt": "2026-01-12T06:00:12Z",
      "status": "completed",
      "successRate": 100
    }
  ],
  "recentFailures": [
    {
      "mountainId": "stevens",
      "error": "Timeout after 30000ms",
      "sourceUrl": "https://www.stevenspass.com",
      "failedAt": "2026-01-11T06:00:05Z"
    }
  ],
  "failuresByMountain": [
    {
      "mountainId": "stevens",
      "failureCount": 3,
      "lastFailure": "2026-01-11T06:00:05Z"
    }
  ],
  "stats": {
    "last7Days": {
      "totalRuns": 7,
      "avgSuccessful": 14.5,
      "avgFailed": 0.5,
      "avgDurationMs": 12500
    }
  },
  "alerts": {
    "enabled": true,
    "channels": ["slack"]
  },
  "timestamp": "2026-01-12T04:00:00Z"
}
```

### 3. Failure History: `/api/scraper/failures`

Get detailed failure logs for debugging.

**Query Parameters:**
- `days` (default: 7) - Number of days to look back
- `mountainId` (optional) - Filter by specific mountain

**Examples:**
```bash
# Last 7 days of all failures
GET /api/scraper/failures

# Last 30 days for stevens
GET /api/scraper/failures?days=30&mountainId=stevens
```

**Response:**
```json
{
  "failures": [
    {
      "id": 123,
      "runId": "run-1234567890-abc123",
      "mountainId": "stevens",
      "error": "Timeout after 30000ms",
      "sourceUrl": "https://www.stevenspass.com",
      "failedAt": "2026-01-11T06:00:05Z",
      "runStartedAt": "2026-01-11T06:00:00Z",
      "runStats": {
        "successful": 14,
        "failed": 1
      }
    }
  ],
  "summary": [
    {
      "mountainId": "stevens",
      "count": 3,
      "lastFailure": "2026-01-11T06:00:05Z",
      "errors": ["Timeout after 30000ms", "Network error", "..."]
    }
  ],
  "filters": {
    "days": 7,
    "mountainId": "all"
  },
  "timestamp": "2026-01-12T04:00:00Z"
}
```

### 4. Run History: `/api/scraper/runs`

Get scraper run history with stats.

**Query Parameters:**
- `limit` (default: 20, max: 100) - Number of runs to return

**Response:**
```json
{
  "runs": [
    {
      "runId": "run-1234567890-abc123",
      "totalMountains": 15,
      "successful": 15,
      "failed": 0,
      "duration": 12500,
      "status": "completed",
      "triggeredBy": "cron",
      "startedAt": "2026-01-12T06:00:00Z",
      "completedAt": "2026-01-12T06:00:12Z",
      "error": null,
      "successRate": 100
    }
  ],
  "stats": {
    "last30Days": {
      "totalRuns": 30,
      "completedRuns": 29,
      "failedRuns": 1,
      "avgSuccessful": 14.5,
      "avgFailed": 0.5,
      "avgDurationMs": 12500,
      "overallSuccessRate": 96.67
    }
  },
  "timestamp": "2026-01-12T04:00:00Z"
}
```

## Alert System

### Alert Types

The system sends three types of alerts:

1. **Failure** (`< 50% success rate`)
   - 🚨 Scraper Run Failed
   - Critical alert requiring immediate attention

2. **Degraded** (`50-79% success rate`)
   - ⚠️ Scraper Performance Degraded
   - Warning that performance is below threshold

3. **Recovered** (`>= 80% success rate`)
   - ✅ Scraper Recovered
   - Confirmation that system is healthy again

### Alert Triggers

Alerts are automatically sent:
- After each scraper run completes
- Only if success rate < 80%
- To all configured channels (Slack, email)

### Setting Up Slack Alerts

#### 1. Create a Slack Webhook

1. Go to https://api.slack.com/apps
2. Create a new app or select existing app
3. Navigate to "Incoming Webhooks"
4. Activate Incoming Webhooks
5. Click "Add New Webhook to Workspace"
6. Select the channel for alerts (e.g., `#monitoring` or `#scraper-alerts`)
7. Copy the webhook URL (starts with `https://hooks.slack.com/services/...`)

#### 2. Add to Vercel Environment Variables

```bash
# Using Vercel CLI
vercel env add SLACK_WEBHOOK_URL production

# Or via Vercel Dashboard:
# Project Settings → Environment Variables → Add
# Name: SLACK_WEBHOOK_URL
# Value: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
# Environment: Production
```

#### 3. Redeploy

After adding the environment variable, redeploy your application:

```bash
vercel --prod
```

#### 4. Verify

Check the monitoring endpoint to confirm alerts are enabled:

```bash
curl https://your-app.vercel.app/api/scraper/monitor | jq '.alerts'
```

Expected output:
```json
{
  "enabled": true,
  "channels": ["slack"]
}
```

### Slack Alert Format

Alerts appear in Slack with this format:

```
🚨 Scraper Run Failed (45% success)

Run ID: `run-1234567890-abc123`
Success Rate: 45%
Failed Mountains: stevens, crystal, baker
```

### Testing Alerts

To test your Slack integration:

1. **Manually trigger a scraper run** (may timeout but will still run):
   ```bash
   curl https://your-app.vercel.app/api/scraper/run
   ```

2. **Wait for the daily cron job** (6 AM UTC):
   - Configured in `vercel.json`
   - Automatically runs daily
   - Sends alerts if success rate < 80%

3. **Check recent runs**:
   ```bash
   curl https://your-app.vercel.app/api/scraper/runs | jq '.runs[0]'
   ```

## Email Alerts (Optional)

Email alerts are supported but require additional setup:

1. Choose an email service (SendGrid, Resend, AWS SES, etc.)
2. Install the appropriate package
3. Uncomment and configure the email code in `src/lib/alerts/scraper-alerts.ts`
4. Add environment variables:
   - `SENDGRID_API_KEY` or similar
   - `ALERT_EMAIL_FROM`
   - `ALERT_EMAIL_TO`

## Monitoring Best Practices

### 1. Regular Health Checks

Set up external monitoring (e.g., Uptime Robot, StatusCake) to ping:
```
https://your-app.vercel.app/api/scraper/health
```

Alert if:
- Response time > 10 seconds
- Status code != 200
- `healthy: false` in response

### 2. Review Failure Logs

Regularly check failure patterns:
```bash
# Get failure summary
curl https://your-app.vercel.app/api/scraper/failures | jq '.summary'
```

Look for:
- Repeated failures for same mountain
- Common error patterns
- Time-based patterns (e.g., failures only at night)

### 3. Monitor Success Rates

Track trends over time:
```bash
# Get last 30 days stats
curl https://your-app.vercel.app/api/scraper/runs | jq '.stats.last30Days'
```

Watch for:
- Declining success rates
- Increasing average duration
- More failed runs

### 4. Dashboard Integration

Build a simple dashboard using the monitoring endpoints:

```tsx
// Example React component
function ScraperDashboard() {
  const { data } = useSWR('/api/scraper/monitor', fetcher, {
    refreshInterval: 60000, // Refresh every minute
  });

  return (
    <div>
      <StatusIndicator status={data?.status} />
      <SuccessRateChart rate={data?.health.successRate} />
      <RecentRunsTable runs={data?.recentRuns} />
      <FailuresAlert failures={data?.recentFailures} />
    </div>
  );
}
```

## Troubleshooting

### No Alerts Received

1. **Check webhook URL is set**:
   ```bash
   vercel env ls | grep SLACK
   ```

2. **Verify webhook URL is valid**:
   ```bash
   curl -X POST YOUR_WEBHOOK_URL \
     -H 'Content-Type: application/json' \
     -d '{"text":"Test alert"}'
   ```

3. **Check recent runs**:
   ```bash
   curl https://your-app.vercel.app/api/scraper/runs | jq '.runs[0]'
   ```

4. **Review function logs** in Vercel Dashboard:
   - Go to your project
   - Click "Functions"
   - Select `/api/scraper/run`
   - Check logs for alert messages

### High Failure Rate

1. **Check specific failures**:
   ```bash
   curl https://your-app.vercel.app/api/scraper/failures?days=1
   ```

2. **Common issues**:
   - Website structure changed (update selectors)
   - Website blocking scrapers (add User-Agent)
   - Timeout too short (increase in config)
   - Network issues (temporary, will resolve)

3. **Update scraper config** if needed:
   - Edit `src/lib/scraper/configs/mountains/*.ts`
   - Test locally: `pnpm run dev` and visit `/api/scraper/run`
   - Deploy: `git push origin main`

## Database Tables

### `scraper_runs`

Tracks each scraper execution:
- `run_id` - Unique identifier
- `total_mountains` - How many mountains attempted
- `successful_count` - How many succeeded
- `failed_count` - How many failed
- `duration_ms` - Total execution time
- `status` - 'running', 'completed', or 'failed'
- `triggered_by` - 'manual', 'cron', or 'api'
- `started_at` - When run started
- `completed_at` - When run completed
- `error_message` - Error if run failed

### `scraper_failures`

Tracks individual mountain failures:
- `id` - Auto-increment ID
- `run_id` - Links to scraper_runs
- `mountain_id` - Which mountain failed
- `error_message` - What went wrong
- `source_url` - URL that was scraped
- `failed_at` - When failure occurred

### `mountain_status`

Stores scraped data:
- `mountain_id` - Mountain identifier
- `is_open` - Whether resort is open
- `percent_open` - Percentage of terrain open
- `lifts_open`, `lifts_total` - Lift counts
- `runs_open`, `runs_total` - Run counts
- `message` - Status message from resort
- `source_url` - Where data came from
- `scraped_at` - When data was scraped

## Cron Schedule

Configured in `vercel.json`:

```json
{
  "crons": [
    {
      "path": "/api/scraper/run",
      "schedule": "0 6 * * *"
    }
  ]
}
```

- Runs daily at **6:00 AM UTC** (10 PM PST / 11 PM PDT)
- Automatically triggered by Vercel
- Has 5-minute timeout (vs 10-second for manual requests)
- Results stored in database
- Alerts sent automatically if needed

## Summary

The monitoring system provides:
- ✅ Automatic health tracking
- ✅ Real-time alerts via Slack
- ✅ Detailed failure logs for debugging
- ✅ Performance metrics and trends
- ✅ Easy-to-use API endpoints
- ✅ Comprehensive dashboard data

To get started:
1. Add `SLACK_WEBHOOK_URL` to Vercel
2. Redeploy
3. Monitor via `/api/scraper/monitor`
4. Receive automatic alerts when issues occur
