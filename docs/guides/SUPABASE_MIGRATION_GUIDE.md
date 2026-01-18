# Supabase Migration Guide

**Date**: January 5, 2026
**Status**: In Progress

---

## 🎯 Migration Strategy

**FROM**: AWS RDS + AWS Cognito + AWS S3
**TO**: Supabase (Auth + Database + Storage) + DynamoDB (Lambda writes only)

**Cost Savings**: ~$15-20/month → ~$0.15/month 💰

---

## ✅ Completed Steps

### 1. AWS RDS Deleted
- ✅ Verified no RDS instances exist (already deleted or never created)
- ✅ **Saving $15-20/month**

### 2. Supabase Project Created
- ✅ Project ID: `nmkavdrvgjkolreoexfe`
- ✅ URL: `https://nmkavdrvgjkolreoexfe.supabase.co`
- ✅ Database: `postgresql://postgres:***@db.nmkavdrvgjkolreoexfe.supabase.co:5432/postgres`

### 3. Schema Created
- ✅ SQL file: `/scripts/setup-supabase-schema.sql`
- ✅ Includes:
  - Mountain tables (mountain_status, scraper_runs)
  - Social tables (users, user_photos, comments, check_ins, likes)
  - Alert tables (alert_subscriptions, push_notification_tokens)
  - Triggers (auto-update counts)
  - Views (latest_mountain_status, mountain_recent_activity)
  - **Row Level Security (RLS)** policies for all tables

### 4. Environment Variables Updated
- ✅ `.env.local` now points to Supabase
- ✅ Legacy AWS RDS URLs commented out

---

## ⏳ Pending Steps - ACTION REQUIRED

### Step 1: Get Supabase Service Role Key

You need to add the **Service Role Key** from Supabase Dashboard:

1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/settings/api
2. Copy the **`service_role`** key (not anon key!)
3. Add to `.env.local`:
   ```bash
   SUPABASE_SERVICE_ROLE_KEY=eyJhb...your-key-here
   ```

**Why needed**: Server-side operations (bypasses RLS for admin tasks)

---

### Step 2: Run Supabase Schema Setup

Run the schema SQL file to create all tables:

**Option A: Via psql (when network is stable)**
```bash
/opt/homebrew/opt/postgresql@15/bin/psql \
  "postgresql://postgres:Dlwoals827!@db.nmkavdrvgjkolreoexfe.supabase.co:5432/postgres" \
  -f /Users/kevin/Downloads/shredders/scripts/setup-supabase-schema.sql
```

**Option B: Via Supabase Dashboard**
1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/editor
2. Click "SQL Editor" → "New query"
3. Copy/paste contents of `/scripts/setup-supabase-schema.sql`
4. Run query

**What this creates**:
- 9 tables (mountain_status, scraper_runs, users, user_photos, comments, check_ins, likes, push_notification_tokens, alert_subscriptions)
- Triggers for auto-updating like/comment counts
- Views for common queries
- RLS policies for security

---

### Step 3: Set Up Supabase Storage Bucket

Create a storage bucket for user photos:

1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/storage/buckets
2. Click "New bucket"
3. Name: `user-photos`
4. Public: ✅ **Yes** (for CDN access)
5. File size limit: 10MB
6. Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`, `image/heic`

**Folder structure**:
```
user-photos/
├── users/{user-id}/
│   ├── profile/
│   │   └── avatar.jpg
│   └── photos/
│       └── {photo-uuid}.jpg
└── mountains/{mountain-id}/
    └── {year}/{month}/
        └── {photo-uuid}.jpg
```

---

### Step 4: Enable Supabase Auth Providers

Enable authentication methods you want to support:

1. Go to: https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe/auth/providers
2. Enable **Email** (password-based)
3. Optional: Enable **Google**, **GitHub**, **Apple** (social login)
4. Configure redirect URLs:
   - https://shredders-bay.vercel.app/auth/callback
   - http://localhost:3000/auth/callback

---

## 📊 Current Data Architecture

### **Data Flow After Migration:**

```
┌──────────────────────────────────────────────────────────┐
│   LAMBDA SCRAPER (runs 2x daily)                         │
│   - Scrapes 15 mountains for lift/run status             │
└──────────────┬───────────────────────────────────────────┘
               │
               ▼ writes to
┌──────────────────────────────────────────────────────────┐
│   DYNAMODB: mountain-status                              │
│   - Fast writes from Lambda (~$0.15/month)               │
│   - 90-day TTL auto-cleanup                              │
│   - Current system (KEEP AS-IS)                          │
└──────────────┬───────────────────────────────────────────┘
               │
               │ API reads for lift status
               ▼
┌──────────────────────────────────────────────────────────┐
│   NEXT.JS API (Vercel)                                   │
│   - Reads from DynamoDB for lift status                  │
│   - Reads from Supabase for social features              │
│   - Writes social data to Supabase                       │
└──────────────┬───────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│   SUPABASE (FREE - Primary Database)                     │
│   ├── Auth: User authentication                          │
│   ├── Database (PostgreSQL):                             │
│   │   ├── mountain_status (historical display)           │
│   │   ├── scraper_runs (tracking)                        │
│   │   └── Social: users, photos, comments, likes, etc.   │
│   └── Storage: User-uploaded photos with CDN             │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│   CLIENTS (Web + iOS App)                                │
│   - Use Supabase JS/Swift SDK                            │
│   - Direct auth via Supabase                             │
│   - Upload photos directly to Supabase Storage           │
└──────────────────────────────────────────────────────────┘
```

---

## 🔧 Code Changes Needed

### 1. Install Dependencies

**Backend (Next.js)**:
```bash
npm install @supabase/supabase-js @supabase/ssr
```

**iOS (SwiftUI)**:
```swift
// Add via SPM in Xcode:
- supabase/supabase-swift
```

### 2. Create Supabase Client

**`/src/lib/supabase/client.ts`** (Browser):
```typescript
import { createBrowserClient } from '@supabase/ssr'

export const createClient = () =>
  createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
```

**`/src/lib/supabase/server.ts`** (Server):
```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export const createClient = () => {
  const cookieStore = cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
      },
    }
  )
}
```

### 3. Keep DynamoDB for Lift Status

**NO CHANGES NEEDED** to:
- `/src/lib/dynamodb.ts` ✅ Keep as-is
- `/src/app/api/mountains/[mountainId]/all/route.ts` (line 66) ✅ Keep DynamoDB read
- Lambda scraper ✅ Keep writing to DynamoDB

**Why**: DynamoDB is perfect for Lambda writes (cheap, fast, serverless-friendly)

### 4. Update iOS App Configuration

**`/ios/PowderTracker/PowderTracker/Config/AppConfig.swift`**:
```swift
enum AppConfig {
    static let apiBaseURL = "https://shredders-bay.vercel.app/api"

    // NEW: Supabase config
    static let supabaseURL = "https://nmkavdrvgjkolreoexfe.supabase.co"
    static let supabaseAnonKey = "sbp_89c07a03194eefe645a4ffef1f081ec0702048d7"
}
```

---

## 🧪 Testing Plan

### Step 1: Test Supabase Connection

```bash
# Test database connection
npm run test:supabase
```

Create `/scripts/test-supabase.ts`:
```typescript
import { createClient } from '@/lib/supabase/server'

const supabase = createClient()
const { data, error } = await supabase
  .from('mountain_status')
  .select('*')
  .limit(1)

console.log('Supabase test:', { data, error })
```

### Step 2: Test iOS App Data Fetching

1. Open iOS app in Xcode
2. Build and run
3. Verify:
   - Mountains list loads ✅
   - Mountain detail shows lift status ✅
   - Forecast displays ✅

**Expected**: Everything should work as before (DynamoDB still being used for lift status)

### Step 3: Test Social Features (New)

Once auth is implemented:
1. Sign up a test user
2. Upload a photo
3. Add a comment
4. Like a photo
5. Check-in at a mountain

---

## 📝 Migration Checklist

- [x] Delete AWS RDS (or verify it doesn't exist)
- [x] Create Supabase project
- [x] Generate SQL schema with RLS
- [x] Update environment variables
- [ ] **Get Supabase Service Role Key** ⏳ ACTION REQUIRED
- [ ] **Run schema SQL in Supabase** ⏳ ACTION REQUIRED
- [ ] Create Supabase Storage bucket
- [ ] Enable Supabase Auth providers
- [ ] Install `@supabase/supabase-js` in Next.js
- [ ] Install `supabase-swift` in iOS
- [ ] Create Supabase clients (browser + server)
- [ ] Update iOS AppConfig with Supabase URL/key
- [ ] Test existing app functionality (DynamoDB lift status)
- [ ] Implement Supabase Auth (Phase 1)
- [ ] Implement photo upload to Supabase Storage (Phase 2)
- [ ] Test social features end-to-end
- [ ] Delete AWS S3 bucket (after Supabase Storage confirmed working)
- [ ] Delete AWS Cognito User Pool (not being used)

---

## 💰 Final Cost Comparison

**Before (AWS)**:
- RDS: ~$15-20/month ❌
- S3 + CloudFront: ~$0.72/month ❌
- Cognito: Free (but unused) ❌
- **Total: ~$15-20/month**

**After (Supabase + DynamoDB)**:
- Supabase: **$0/month** (free tier) ✅
- DynamoDB: **~$0.15/month** ✅
- **Total: ~$0.15/month** 🎉

**Annual Savings: ~$180-240** 💰💰💰

---

## 🚨 Important Notes

1. **DynamoDB is NOT being replaced** - Lambda continues writing there
2. **Supabase Postgres** is for social features + read-only mountain display
3. **Row Level Security (RLS)** is enabled - very important for security!
4. **Service Role Key** should NEVER be exposed to client-side code
5. **Anon Key** is safe for client-side (limited by RLS policies)

---

**Last Updated**: January 5, 2026
