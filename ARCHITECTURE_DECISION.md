# Architecture Decision: Supabase + AWS Hybrid

## ✅ **RECOMMENDATION: Stick with Supabase (Primary) + AWS (Minimal)**

---

## 📊 Current Infrastructure Analysis

### **What's ACTIVE and WORKING:**

#### Supabase (Primary Infrastructure) ✅
- **PostgreSQL Database**: All social features + mountain data
  - ✅ `users` table exists (but schema cache needs reload)
  - ✅ `user_photos`, `comments`, `check_ins`, `likes` tables
  - ✅ `mountain_status` (migrated from DynamoDB)
  - ✅ `alert_subscriptions`, `push_notification_tokens`
  - ✅ Row Level Security (RLS) policies configured

- **Authentication**: Replaces AWS Cognito
  - ✅ Email/password signup/login
  - ✅ OAuth ready (Google, Apple, etc.)
  - ✅ JWT tokens with automatic refresh
  - ✅ 1 user already in auth.users table

- **Storage**: User photo uploads
  - ✅ `user-photos` bucket configured
  - ✅ RLS policies for secure uploads
  - ✅ 5MB file size limits

#### AWS (Supplementary Services) ✅
- **Lambda**: Web scraper for mountain data
  - ✅ Puppeteer-based scraping
  - ✅ Runs on schedule
  - Currently writes to DynamoDB (can migrate to Supabase)

- **S3**: Static lift map data
  - ✅ GeoJSON files for ski lift polylines
  - ✅ Cost-effective for static files

- **DynamoDB**: Legacy mountain status data
  - ⚠️  Still being written to by Lambda
  - 🔄 Should be migrated to Supabase PostgreSQL

### **What's DEPRECATED:**
- ❌ AWS RDS (replaced by Supabase PostgreSQL)
- ❌ AWS Cognito (replaced by Supabase Auth)
- ❌ AWS S3 for user photos (replaced by Supabase Storage)

---

## 🤔 Why Supabase Over Full AWS Migration?

### **1. Cost Comparison**

#### Supabase Free Tier:
- 500MB database
- 1GB storage
- 50K monthly active users
- 2GB bandwidth
- Unlimited API requests
- **Cost: $0/month**

#### AWS Equivalent:
- RDS PostgreSQL: $15-30/month minimum (t3.micro)
- S3: $0.023/GB + data transfer
- Cognito: $0.0055 per MAU (after first 50K)
- API Gateway: $3.50 per million requests
- Lambda: $0.20 per 1M requests
- **Estimated Cost: $30-60/month** (plus complexity)

### **2. Developer Experience**

#### Supabase:
- ✅ Auto-generated REST API
- ✅ Auto-generated GraphQL (optional)
- ✅ Real-time subscriptions built-in
- ✅ Built-in auth with RLS
- ✅ Dashboard UI for data management
- ✅ Simple client library: `supabase.from('users').select('*')`

#### AWS:
- ❌ Must build APIs manually (API Gateway + Lambda)
- ❌ Must configure Cognito + RDS integration
- ❌ Must set up VPC, security groups, IAM roles
- ❌ Complex SDK: `DynamoDBClient`, `CognitoIdentityProvider`, etc.
- ❌ No built-in real-time without additional services (AppSync)

### **3. Time to Market**

#### Supabase:
- ⏱️  Your auth system is already working
- ⏱️  Database is already created
- ⏱️  Just need to reload schema cache (5 minutes)

#### AWS Migration:
- ⏱️  Would take 1-2 weeks to rebuild everything:
  - Set up RDS
  - Configure Cognito
  - Build API Gateway endpoints
  - Write Lambda functions for CRUD operations
  - Set up VPC and networking
  - Migrate data
  - Update all client code

### **4. Perfect for Your Use Case**

Your app has:
- ✅ Social features (comments, likes, check-ins) → Benefits from Supabase real-time
- ✅ User-generated content (photos, trip reports) → Benefits from Supabase Storage + RLS
- ✅ Mountain data updates → Can use Supabase database triggers
- ✅ Push notifications → Supabase has built-in webhook support

### **5. Scalability**

Both Supabase and AWS can scale to millions of users. Supabase runs on AWS infrastructure anyway (PostgreSQL on RDS).

---

## 🏗️ Recommended Hybrid Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE (Primary)                       │
│                 https://nmkavdrvgjkolreoexfe.supabase.co    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  PostgreSQL Database:                                       │
│    • users (auth profiles)                                  │
│    • user_photos (photo metadata)                           │
│    • comments, check_ins, likes                             │
│    • mountain_status (scraped data)                         │
│    • alert_subscriptions                                    │
│    • push_notification_tokens                               │
│                                                             │
│  Authentication:                                            │
│    • Email/password                                         │
│    • OAuth (Google, Apple)                                  │
│    • JWT tokens                                             │
│                                                             │
│  Storage:                                                   │
│    • user-photos bucket                                     │
│    • 5MB max file size                                      │
│    • Automatic CDN distribution                             │
│                                                             │
│  Row Level Security:                                        │
│    • Users can only modify their own data                   │
│    • Public data readable by all                            │
│    • Admin override via service_role key                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │
                           │  API Calls
                           │  (REST / GraphQL)
                           │
         ┌─────────────────┴─────────────────┐
         │                                   │
         │                                   │
┌────────┴────────┐                 ┌────────┴────────┐
│   AWS Lambda    │                 │   Next.js App   │
│   (Scraper)     │                 │    (Vercel)     │
├─────────────────┤                 ├─────────────────┤
│                 │                 │                 │
│ • Puppeteer +   │                 │ • iOS app       │
│   Chromium      │                 │ • Web app       │
│ • Scheduled     │                 │ • API routes    │
│   (cron)        │                 │                 │
│                 │                 │ Reads/writes:   │
│ Writes to →     │                 │ • User data     │
│ Supabase        │                 │ • Photos        │
│ mountain_status │                 │ • Comments      │
│                 │                 │ • Check-ins     │
└────────┬────────┘                 └─────────────────┘
         │
         │ Reads static data
         ▼
┌─────────────────┐
│    AWS S3       │
│  (Static Data)  │
├─────────────────┤
│                 │
│ Bucket:         │
│ shredders-      │
│ lambda-         │
│ deployments     │
│                 │
│ Contains:       │
│ • Lift GeoJSON  │
│   files         │
│ • Trail maps    │
│                 │
└─────────────────┘
```

---

## 🎯 Migration Plan

### **Immediate (This Week):**
1. ✅ Fix schema cache issue (pause/resume Supabase project)
2. ✅ Test account creation flow
3. ✅ Verify photo upload works
4. ✅ Test social features (comments, likes, check-ins)

### **Short-term (Next 2 Weeks):**
1. 🔄 Update Lambda scraper to write to Supabase instead of DynamoDB
2. 🔄 Deprecate DynamoDB table
3. ✅ Keep S3 for static lift data (it's working fine)

### **Medium-term (1-2 Months):**
1. ⚡ Implement real-time features using Supabase subscriptions
   - Live comment updates
   - Live powder alerts
   - Live lift status changes
2. 📊 Set up Supabase database backups
3. 🔔 Configure push notifications via Supabase Edge Functions

---

## 📝 Environment Variables Required

### **Production (.env.local):**
```bash
# Supabase (PRIMARY)
NEXT_PUBLIC_SUPABASE_URL=https://nmkavdrvgjkolreoexfe.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# AWS (for Lambda scraper + S3 static files)
AWS_REGION=us-west-2
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>

# Database connection (for direct queries if needed)
DATABASE_URL=postgresql://postgres:***@db.nmkavdrvgjkolreoexfe.supabase.co:5432/postgres
```

---

## ⚠️ Current Issue: Schema Cache

**Problem:** PostgREST schema cache is stale
- Tables exist in PostgreSQL ✅
- But REST API doesn't know about them ❌
- Error: "Could not find the table 'public.users' in the schema cache"

**Solution:**
1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/settings/general
2. Scroll to "Pause project"
3. Click "Pause project" → Wait 10 seconds
4. Click "Resume project" → Wait 30 seconds
5. Schema cache will be fully reloaded

**Alternative (if available):**
```bash
# Via Supabase CLI (if installed)
supabase db reset --linked
```

---

## 🎉 Conclusion

**Stick with Supabase** as your primary infrastructure. It's:
- ✅ Faster to develop with
- ✅ Cheaper at scale
- ✅ 80% implemented already
- ✅ Perfect for your use case
- ✅ Easier to maintain

Keep AWS for:
- ✅ Lambda scraper (web scraping)
- ✅ S3 static files (lift GeoJSON)

Phase out:
- ❌ DynamoDB (replace with Supabase)
- ❌ RDS references (already replaced)
- ❌ Cognito references (already replaced)

---

## 📚 Resources

- Supabase Dashboard: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe
- Supabase Docs: https://supabase.com/docs
- PostgREST Docs: https://postgrest.org
- Row Level Security Guide: https://supabase.com/docs/guides/auth/row-level-security

---

**Decision Made:** 2026-01-08
**Status:** ✅ Approved - Proceed with Supabase + minimal AWS hybrid
