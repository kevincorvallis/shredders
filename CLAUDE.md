# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Shredders - Ski Trip Planning App

## Project Overview
Shredders is a full-stack ski trip planning application with:
- **Web app**: Next.js frontend deployed on Vercel
- **iOS app**: SwiftUI native app
- **Backend**: Supabase (PostgreSQL, Auth, Storage)

## Tech Stack
- **Frontend**: Next.js 16, React 19, TypeScript, Tailwind CSS 4
- **iOS**: SwiftUI, UIKit (maps), Supabase Swift SDK
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Deployment**: Vercel (auto-deploy from main branch)

## Key Directories
```
src/
  app/api/          # API routes (Next.js)
  app/auth/         # Auth pages
  app/events/       # Events pages
  lib/auth/         # Auth utilities (dual-auth system)
  lib/supabase/     # Supabase clients
ios/PowderTracker/  # iOS app (see ios/PowderTracker/CLAUDE.md)
scripts/            # Automation scripts
packages/shared/    # Shared types and utilities
```

## Development

### Run locally
```bash
pnpm dev           # Start Next.js dev server (localhost:3000)
pnpm build         # Production build
pnpm test          # Run all tests (vitest)
pnpm test:watch    # Watch mode
pnpm lint          # ESLint on src/
pnpm type-check    # TypeScript --noEmit

# Run a single test file
pnpm vitest run path/to/file.test.ts
```

### Deploy to production
```bash
git push origin main   # Auto-deploys to Vercel
```

---

## Custom Agents

### production-verifier
**IMPORTANT:** Run this agent after making changes to authentication, events, or any backend API code.

**Trigger:** After modifying:
- `src/app/api/auth/*` - Authentication endpoints
- `src/app/api/events/*` - Events endpoints
- `src/lib/auth/*` - Auth utilities
- `ios/*/Services/AuthService.swift` - iOS auth
- `ios/*/Services/EventService.swift` - iOS events

**How to run:**
```bash
# Quick API health check (recommended after every backend change)
./scripts/verify-production-full.sh

# Full verification with iOS build
./scripts/verify-production-full.sh --ios-build

# Everything including UI tests
./scripts/verify-production-full.sh --all
```

**What it checks:**
- API availability and response times
- Public endpoints (events, mountains)
- Auth protection (401 for protected endpoints)
- Data quality (events have creators)

### ios-tester
Run after iOS app changes. See `ios/PowderTracker/CLAUDE.md` for details.

---

## Authentication System

### Dual Auth
The app supports two auth methods:
1. **Apple Sign In** - Uses Supabase Auth with Apple provider
2. **Email/Password** - Custom JWT tokens

Both are handled by `src/lib/auth/dual-auth.ts` which:
- Checks for custom JWT tokens first
- Falls back to Supabase Bearer tokens (for Apple Sign In)

### Important: User ID Mapping
The database has two user IDs:
- `users.id` - Internal primary key (UUID)
- `users.auth_user_id` - Supabase Auth ID

**Foreign keys reference `users.id`, NOT `auth_user_id`**

When creating records (events, RSVPs, etc.), always:
1. Get `auth_user_id` from authentication
2. Look up `users.id` from the users table
3. Use `users.id` for foreign key relationships

---

## Production Verification

After deploying changes, verify production is healthy:

```bash
# Automated checks
./scripts/verify-production-full.sh

# Manual checklist
cat ios/PowderTracker/PRODUCTION_CHECKLIST.md
```

### Quick Smoke Test
1. API responds: `curl https://shredders-bay.vercel.app/api/events`
2. Auth protected: `POST /api/events` returns 401 without token
3. iOS app can sign in and create events

---

## Common Issues

### "User not found" on signup
Email already exists with different auth method. User should sign in with original method.

### "Must be signed in" after Apple Sign In
Token not stored in Keychain. Sign out and sign in again.

### "Failed to create event"
User ID mismatch. Check that `users.id` (not `auth_user_id`) is used for foreign keys.

---

## Environment Variables

### Required for Vercel
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `JWT_SECRET`

### iOS App
Configured in `ios/PowderTracker/PowderTracker/Config/AppConfig.swift`
