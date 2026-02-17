# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Shredders - Ski Trip Planning App

Full-stack ski trip planning app: Next.js web app (Vercel), SwiftUI iOS app, Supabase backend. Tracks real-time conditions for 15 PNW ski resorts using SNOTEL, NOAA, Open-Meteo, and WSDOT data.

## Tech Stack
- **Frontend**: Next.js 16, React 19, TypeScript, Tailwind CSS 4
- **iOS**: SwiftUI, UIKit (maps), Supabase Swift SDK
- **Backend**: Supabase (PostgreSQL + Auth + Storage), DynamoDB (lift status)
- **AI**: Anthropic Claude, OpenAI (arrival predictions)
- **Deployment**: Vercel (auto-deploy from main), iOS via App Store

## Development

```bash
pnpm dev           # Next.js dev server (localhost:3000)
pnpm build         # Production build
pnpm test          # Run all tests (vitest)
pnpm test:watch    # Watch mode
pnpm lint          # ESLint on src/
pnpm type-check    # TypeScript --noEmit
pnpm vitest run path/to/file.test.ts  # Single test file
```

### iOS
```bash
cd ios/PowderTracker
./scripts/run_tests.sh           # All tests
./scripts/run_tests.sh unit      # Unit only
./scripts/run_tests.sh snapshots # Snapshot only
```

See `ios/PowderTracker/CLAUDE.md` for full iOS details.

---

## Architecture

### Key Directories
```
src/app/api/          # API routes (Next.js App Router)
src/lib/auth/         # Dual auth system (JWT + Supabase)
src/lib/apis/         # External API integrations (NOAA, SNOTEL, Open-Meteo)
src/lib/scraper/      # Mountain lift/run status scraping
src/lib/supabase/     # Supabase client factories
src/lib/errors.ts     # Standardized error system (AppError + Sentry)
src/lib/cache.ts      # In-memory cache with stale-while-revalidate
src/lib/api-utils.ts  # Rate limiting, response helpers
packages/shared/      # Mountain config (IDs, coordinates, SNOTEL stations)
ios/PowderTracker/    # iOS app
```

### Data Flow: Real-time vs Scraped
Mountain data comes from two decoupled sources:
- **Real-time** (cached 10min): SNOTEL snow depth, NOAA weather/forecast/alerts, Open-Meteo freezing level — fetched on demand via `getMountainAllData()` in `src/lib/apis/mountain-data.ts`
- **Scraped** (DynamoDB): Lift/run open counts — populated by scraper system (`/api/scraper/run`), stored in AWS DynamoDB `mountain-status` table (us-west-2)

`getMountainAllData(mountainId)` uses `Promise.allSettled` across 7 sources — partial failures are silently swallowed so partial data is returned rather than a full error.

### Mountain Config
`packages/shared/` exports `mountains` record keyed by ID (`baker`, `stevens`, `crystal`, etc.) with metadata: coordinates, elevation, SNOTEL stations, NOAA grid points, webcam URLs. Used by `getMountain(id)` throughout the API layer.

---

## Authentication System

### Dual Auth (`src/lib/auth/dual-auth.ts`)
`getDualAuthUser(req)` tries three methods in order:
1. **Custom JWT** (email/password) — `Authorization: Bearer <jwt>`, verified against `JWT_SECRET`
2. **Supabase Bearer token** (Apple Sign In) — same header, verified via `adminClient.auth.getUser()`
3. **Supabase session cookies** (web clients) — reads from Next.js cookie store

### Critical: User ID Mapping
The database has two user IDs:
- `users.auth_user_id` — from Supabase Auth or JWT (what authentication returns)
- `users.id` — internal primary key (**all foreign keys reference this**)

**Always call `getUserProfileId(authUser)` before inserting records.** The `profileId` field on `AuthenticatedUser` caches this mapping (5-min TTL) to avoid repeated DB lookups.

### Auth Wrappers
- `withDualAuth(handler)` — route wrapper, auto-returns 401 on failure (use for mutations)
- `getDualAuthUser(req)` — returns null on failure, you handle the error (use when you need custom error handling)

### Supabase Clients (`src/lib/supabase/`)
- `createAdminClient()` — service role key, bypasses RLS. **Use for all mutations in API routes.**
- `createClient()` — cookie-based, respects RLS. Use for user-scoped reads only.

---

## API Route Patterns

Standard pattern for a **GET** endpoint:
```typescript
import { withCache } from '@/lib/cache';
// No auth required, cached 10 minutes
const data = await withCache(`key:${id}`, () => fetchData(id));
return NextResponse.json(data);
```

Standard pattern for a **POST/mutation** endpoint:
```typescript
import { withDualAuth } from '@/lib/auth';
import { getUserProfileId } from '@/lib/auth/get-user-id';
import { createAdminClient } from '@/lib/supabase/admin';
import { handleError, Errors } from '@/lib/errors';

// Auth required, uses users.id for FK
const authUser = await getDualAuthUser(req);
const profileId = await getUserProfileId(authUser);
const adminClient = createAdminClient();
// Insert with profileId (users.id), NOT authUser.userId
```

### Error Handling
- Use `Errors.*` factory functions (e.g., `Errors.notFound('Event')`, `Errors.unauthorized()`)
- Wrap with `handleError(error)` — reports non-operational errors to Sentry, returns formatted JSON response
- Rate limiting: `rateLimitEnhanced()` uses Upstash Redis when configured, falls back to in-memory

---

## Scraper System (`src/lib/scraper/`)

Three scraper types: `HTMLScraper` (Cheerio), `APIScraper` (JSON APIs), `PuppeteerScraper` (JS-heavy sites). Configs in `configs.ts` define per-mountain scraping strategy with batching to avoid Vercel timeouts (60s max).

---

## Verification

Run after backend/auth changes:
```bash
./scripts/verify-production-full.sh          # Quick API health check
./scripts/verify-production-full.sh --ios-build  # + iOS build
./scripts/verify-production-full.sh --all        # + UI tests
```

Pre-deployment:
```bash
./scripts/deploy-check.sh --quick     # ~1 min: config changes
./scripts/deploy-check.sh --standard  # ~15 min: feature additions
./scripts/deploy-check.sh --full      # ~45 min: major releases
```

---

## Environment Variables

### Required for Vercel
`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `JWT_SECRET`

### Optional
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `REDIS_URL`/`REDIS_TOKEN` (Upstash rate limiting), `AWS_*` (DynamoDB/S3), `APNS_*` (push notifications)

### iOS
Configured in `ios/PowderTracker/PowderTracker/Config/AppConfig.swift`
