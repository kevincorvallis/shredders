# 🚀 Quick Start: Automated Mountain Scraping

Get your automated mountain data scraping up and running in 15 minutes.

## ✅ Prerequisites Checklist

- [ ] AWS Account (with billing enabled)
- [ ] GitHub repository
- [ ] Vercel account and deployment
- [ ] AWS CLI installed: `brew install awscli`
- [ ] PostgreSQL client: `brew install postgresql`

## 🏃 5-Step Setup

### Step 1: Install Dependencies (1 min)

```bash
cd /Users/kevin/Downloads/shredders
npm install @vercel/postgres uuid
npm install --save-dev @types/uuid
```

✅ Already done! Packages installed.

### Step 2: Set Up AWS Database (5 min)

```bash
# Configure AWS credentials (first time only)
aws configure
# Enter: Access Key ID, Secret Key, Region (us-west-2)

# Create RDS database (takes 5-10 minutes)
npm run db:setup-aws
```

This creates:
- PostgreSQL 15.4 database (free tier eligible)
- Secure connection with SSL
- Auto-saved credentials in `.env.local`

### Step 3: Create Database Schema (1 min)

```bash
npm run db:setup
```

This creates:
- Tables for mountain status and scraper runs
- Views for latest data and statistics
- Functions for cleanup and history

### Step 4: Test Locally (2 min)

```bash
# Start dev server
npm run dev

# In another terminal, test scraper
npm run scraper:run

# Check status
npm run scraper:status
```

Expected output:
```json
{
  "success": true,
  "message": "Scraped 15/15 mountains",
  "storage": "postgresql",
  "results": {
    "successful": 15,
    "failed": 0
  }
}
```

### Step 5: Deploy and Automate (5 min)

```bash
# Add DATABASE_URL to Vercel
vercel env add DATABASE_URL production
# Paste connection string from .env.local

# Deploy to production
vercel --prod

# Set up GitHub Actions
git add .github/workflows/daily-scraper.yml
git commit -m "Add automated scraping"
git push

# Add GitHub secret
# Go to: Settings → Secrets → Actions → New secret
# Name: APP_URL
# Value: https://your-app.vercel.app
```

## ✨ You're Done!

Your scraper will now run automatically:
- **10 PM PST** (evening scrape)
- **10 AM PST** (morning scrape)

## 📊 Verify It's Working

### Check GitHub Actions
1. Go to your GitHub repo → **Actions** tab
2. Click **"Daily Mountain Scraper"**
3. Click **"Run workflow"** to test manually
4. Verify it completes successfully ✅

### Check Database
```bash
psql $DATABASE_URL

SELECT COUNT(*) FROM mountain_status;
SELECT * FROM latest_mountain_status;
SELECT * FROM scraper_runs ORDER BY started_at DESC LIMIT 5;
```

### Check API
```bash
curl https://your-app.vercel.app/api/scraper/status
```

## 📚 Full Documentation

- **Database Setup:** `DATABASE_SETUP.md`
- **GitHub Actions:** `GITHUB_ACTIONS_SETUP.md`
- **Scraper Details:** `src/lib/scraper/README.md`
- **Initial Setup:** `SCRAPER_SETUP.md`

## 💰 Monthly Cost

**Free Tier (12 months):**
- AWS RDS: $0/month
- GitHub Actions: $0/month
- Vercel: $0/month
- **Total: $0/month** 🎉

**After Free Tier:**
- AWS RDS (db.t3.micro): ~$20/month
- Everything else: $0/month
- **Total: ~$20/month**

## 🎯 Success Metrics

You'll know it's working when:
- ✅ GitHub Actions runs twice daily
- ✅ 90%+ success rate
- ✅ Fresh data (< 12 hours old)
- ✅ Database growing steadily
- ✅ Both web and iOS apps show live data

## 🐛 Troubleshooting

**Database connection failed:**
```bash
# Check DATABASE_URL is set
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT NOW();"
```

**Scraper returns errors:**
```bash
# Check logs
npm run dev
# Then in another terminal:
npm run scraper:run
```

**GitHub Actions not running:**
- Verify secret `APP_URL` is set
- Check workflow file syntax
- Manually trigger workflow to test

## 🔄 Architecture

```
┌─────────────────┐
│ GitHub Actions  │  Triggers twice daily (6 AM, 6 PM UTC)
└────────┬────────┘
         │ HTTP GET
         ▼
┌─────────────────┐
│ Vercel App      │  /api/scraper/run endpoint
│ (Next.js)       │
└────────┬────────┘
         │ Scrapes
         ▼
┌─────────────────┐
│ Resort Websites │  Mt Baker, Stevens, Crystal, etc.
└────────┬────────┘
         │ Data
         ▼
┌─────────────────┐
│ AWS PostgreSQL  │  Stores historical data
└────────┬────────┘
         │ Serves
         ▼
┌─────────────────┐
│ Web + iOS Apps  │  Display live mountain conditions
└─────────────────┘
```

## 📱 Bonus: iOS App Integration

Your iOS app automatically gets the scraped data! No changes needed.

The API endpoints at `/api/mountains/{id}` will use the latest scraped data from the database.

## 🎉 Next Steps

1. ✅ Monitor first few scraper runs
2. ⏱️ Add Slack/Discord notifications (optional)
3. ⏱️ Update CSS selectors for specific mountains (see `SCRAPER_SETUP.md`)
4. ⏱️ Add more mountains to configs.ts

---

**Questions?** Check the full documentation in:
- `DATABASE_SETUP.md`
- `GITHUB_ACTIONS_SETUP.md`
- `SCRAPER_SETUP.md`
