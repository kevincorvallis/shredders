# 🔄 GitHub Actions Setup Guide

Complete guide to set up automated daily scraping using GitHub Actions.

## 🎯 Why GitHub Actions?

✅ **Better than Vercel Cron** because:
- Platform-agnostic (works even if you move away from Vercel)
- Can trigger multiple actions (web deployment, iOS updates, notifications)
- Better for shared data between web and iOS apps
- More powerful workflow capabilities
- Free tier: 2,000 minutes/month (plenty for daily scraping)
- Can run tests, validations, and cleanup tasks

## 📋 Prerequisites

- GitHub repository set up
- Vercel deployment URL
- Database configured (optional but recommended)

## 🚀 Quick Start

### 1. Add GitHub Secret

Go to your GitHub repository:

1. **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Name: `APP_URL`
4. Value: Your Vercel deployment URL (e.g., `https://shredders.vercel.app`)
5. Click **"Add secret"**

### 2. Workflow File Already Created

The workflow file is already created at:
```
.github/workflows/daily-scraper.yml
```

It runs:
- **6 AM UTC** (10 PM PST) - Evening scrape
- **6 PM UTC** (10 AM PST) - Morning scrape

### 3. Push to GitHub

```bash
cd /Users/kevin/Downloads/shredders
git add .github/workflows/daily-scraper.yml
git commit -m "Add GitHub Actions workflow for daily mountain scraping"
git push
```

### 4. Manual Test Run

1. Go to GitHub repository
2. Click **"Actions"** tab
3. Click **"Daily Mountain Scraper"** workflow
4. Click **"Run workflow"** → **"Run workflow"**
5. Wait 30-60 seconds
6. Check the results

Expected output:
```
🏔️ Starting mountain data scrape...
Response Code: 200
✅ Scraper completed successfully
📊 Results: 15 successful, 0 failed
```

## 📅 Schedule Configuration

### Current Schedule

```yaml
schedule:
  - cron: '0 6,18 * * *'  # 6 AM and 6 PM UTC
```

**Times in PST:**
- 6 AM UTC = 10 PM PST (evening)
- 6 PM UTC = 10 AM PST (morning)

### Change Schedule

Edit `.github/workflows/daily-scraper.yml`:

```yaml
# Run every 6 hours
- cron: '0 */6 * * *'

# Run only once per day at 6 AM UTC (10 PM PST)
- cron: '0 6 * * *'

# Run three times per day (6 AM, 2 PM, 10 PM UTC)
- cron: '0 6,14,22 * * *'

# Run only on weekdays at 6 AM UTC
- cron: '0 6 * * 1-5'
```

**Cron Syntax:**
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
* * * * *
```

## 🔔 Adding Notifications

### Slack Notifications

Add to `.github/workflows/daily-scraper.yml`:

```yaml
- name: Send Slack Notification
  if: failure()
  uses: slackapi/slack-github-action@v1.24.0
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "❌ Mountain scraper failed",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "Mountain data scrape failed. Check logs: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            }
          }
        ]
      }
```

Add `SLACK_WEBHOOK_URL` secret in GitHub.

### Discord Notifications

```yaml
- name: Send Discord Notification
  if: failure()
  run: |
    curl -X POST "${{ secrets.DISCORD_WEBHOOK_URL }}" \
      -H "Content-Type: application/json" \
      -d '{
        "content": "❌ Mountain scraper failed",
        "embeds": [{
          "title": "Scraper Error",
          "description": "Check logs for details",
          "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}",
          "color": 15158332
        }]
      }'
```

Add `DISCORD_WEBHOOK_URL` secret in GitHub.

### Email Notifications

```yaml
- name: Send Email Notification
  if: failure()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.MAIL_USERNAME }}
    password: ${{ secrets.MAIL_PASSWORD }}
    subject: Mountain Scraper Failed
    body: |
      The mountain data scraper failed.

      Check logs: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
    to: your-email@example.com
    from: Mountain Scraper
```

## 🧪 Testing

### Manual Trigger

GitHub UI:
1. Go to **Actions** tab
2. Select **"Daily Mountain Scraper"**
3. Click **"Run workflow"**
4. Click green **"Run workflow"** button

### Via GitHub CLI

```bash
# Install GitHub CLI
brew install gh

# Trigger workflow
gh workflow run daily-scraper.yml
```

### Check Status

```bash
# List recent runs
gh run list --workflow=daily-scraper.yml

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

## 📊 Monitoring

### View Run History

1. Go to **Actions** tab in GitHub
2. Click **"Daily Mountain Scraper"**
3. View all runs with status indicators:
   - ✅ Green = Success
   - ❌ Red = Failed
   - 🟡 Yellow = In Progress

### Download Logs

1. Click on a specific run
2. Click **"scrape-mountains"** job
3. Expand steps to view details
4. Click **"⋮"** → **"Download log archive"**

### API Access

```bash
# Get workflow runs via GitHub API
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/actions/workflows/daily-scraper.yml/runs
```

## 🔧 Advanced Configuration

### Run on Multiple Environments

```yaml
jobs:
  scrape-mountains:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [production, staging]
    steps:
      - name: Trigger Scraper
        run: |
          curl -X GET ${{ secrets[format('{0}_APP_URL', matrix.environment)] }}/api/scraper/run
```

Add secrets: `PRODUCTION_APP_URL` and `STAGING_APP_URL`

### Cleanup After Scrape

```yaml
- name: Cleanup Old Data
  run: |
    curl -X POST "${{ secrets.APP_URL }}/api/scraper/cleanup"
```

### Cache Dependencies

```yaml
- name: Cache Node Modules
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

## 💰 Cost

### GitHub Actions Free Tier
- 2,000 minutes/month for private repos
- Unlimited for public repos

### Usage Estimate
- Each scrape run: ~1 minute
- Daily runs (2x): ~60 minutes/month
- **Total: ~3% of free tier** 🎉

## 🐛 Troubleshooting

### Workflow Not Running

**Check cron schedule:**
```bash
# Verify it's in UTC
date -u
```

**Check workflow file syntax:**
```bash
# Install actionlint
brew install actionlint

# Lint workflow
actionlint .github/workflows/daily-scraper.yml
```

### Connection Timeout

Increase timeout in workflow:

```yaml
- name: Trigger Scraper Endpoint
  timeout-minutes: 5  # Default is 360
  run: |
    curl --max-time 300 ...
```

### Authentication Errors

Add authentication to scraper endpoint:

```yaml
- name: Trigger Scraper Endpoint
  run: |
    curl -H "Authorization: Bearer ${{ secrets.SCRAPER_API_KEY }}" \
      ${{ secrets.APP_URL }}/api/scraper/run
```

### View Detailed Logs

```yaml
- name: Trigger Scraper Endpoint
  run: |
    set -x  # Enable debug mode
    curl -v ...  # Verbose output
```

## 📈 Success Metrics

After setup, you should see:
- ✅ Workflow runs twice daily (6 AM, 6 PM UTC)
- ✅ 90%+ success rate
- ✅ Consistent execution time (~30-60 seconds)
- ✅ Fresh mountain data (< 12 hours old)

## 🔄 Comparison: GitHub Actions vs Vercel Cron

| Feature | GitHub Actions | Vercel Cron |
|---------|---------------|-------------|
| **Cost** | Free (2,000 min/mo) | Free (limited) |
| **Reliability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Flexibility** | Very flexible | Limited |
| **Multi-platform** | ✅ Yes | ❌ Vercel only |
| **Manual trigger** | ✅ Easy (UI + API) | ⚠️ Harder |
| **Monitoring** | ✅ Built-in | ⚠️ Limited |
| **Notifications** | ✅ Easy to add | ⚠️ Complex |
| **Portability** | ✅ Platform-agnostic | ❌ Vendor lock-in |

**Recommendation:** Use GitHub Actions ✨

## 📚 Next Steps

1. ✅ Monitor first few runs
2. ⏱️ Add Slack/Discord notifications (optional)
3. ⏱️ Set up email alerts for failures (optional)
4. ⏱️ Create a status dashboard (optional)

## 📞 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Cron Schedule Examples](https://crontab.guru/)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)

---

**Setup completed successfully! 🎉**

Your mountain data will now be automatically updated twice daily.
