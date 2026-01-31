# Shredders (PowderTracker)

AI-powered mountain conditions tracker for powder chasers across the Pacific Northwest. Real-time snow data, weather forecasts, and intelligent powder day predictions for 15 ski resorts across Washington, Oregon, and Idaho.

**Live**: [shredders-bay.vercel.app](https://shredders-bay.vercel.app)

---

## Features

- **Real-time Conditions** - Live snow depth, temperature, and lift status for 15 PNW resorts
- **8-Factor Powder Score** - AI-calculated powder day predictions using SNOTEL, NOAA, and weather data
- **7-Day Forecasts** - Detailed snow and weather forecasts with hourly breakdowns
- **Weather Alerts** - Winter storm warnings, avalanche advisories, and road conditions
- **AI Chat** - Natural language queries about conditions, comparisons, and trip planning
- **Trip Events** - Create and share ski trips with friends, RSVP tracking
- **Native iOS App** - SwiftUI app with widgets and push notifications
- **Road Conditions** - WSDOT pass conditions and webcams

---

## Quick Start

### Prerequisites

- Node.js 18+
- pnpm 9+ (`npm install -g pnpm`)
- Supabase account (for database)

### Setup

```bash
# Clone and install
git clone <your-repo-url>
cd shredders
pnpm install

# Configure environment
cp .env.example .env.local
# Edit .env.local with your Supabase credentials

# Start development server
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000).

---

## Scripts

| Command | Description |
|---------|-------------|
| `pnpm dev` | Start development server |
| `pnpm build` | Build for production |
| `pnpm start` | Start production server |
| `pnpm test` | Run tests |
| `pnpm test:watch` | Run tests in watch mode |
| `pnpm lint` | Run ESLint |
| `pnpm type-check` | Run TypeScript checks |

---

## Project Structure

```
shredders/
├── src/
│   ├── app/              # Next.js App Router
│   │   ├── api/          # API routes (60+ endpoints)
│   │   ├── mountains/    # Mountain pages
│   │   ├── chat/         # AI chat interface
│   │   └── auth/         # Authentication pages
│   ├── components/       # React components
│   ├── hooks/            # React hooks (useAuth, useMountainData)
│   ├── lib/              # Core libraries
│   │   ├── apis/         # External API clients (NOAA, SNOTEL, etc.)
│   │   ├── auth/         # JWT + Supabase authentication
│   │   ├── scraper/      # Web scraping system
│   │   └── supabase/     # Database client
│   └── types/            # TypeScript types
├── packages/
│   └── shared/           # Shared mountain config
├── ios/                  # Native iOS app (SwiftUI)
├── docs/                 # Documentation
│   ├── guides/           # Setup guides
│   ├── features/         # Feature documentation
│   └── archive/          # Historical docs
├── scripts/              # Utility scripts
└── apps/
    └── lambda-scraper/   # AWS Lambda scraper
```

---

## Environment Variables

Copy `.env.example` to `.env.local` and configure:

**Required:**
- `NEXT_PUBLIC_SUPABASE_URL` - Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (for server-side operations)

**Optional:**
- `ANTHROPIC_API_KEY` - AI chat and summaries
- `OPENAI_API_KEY` - Arrival time predictions
- `APNS_*` - Push notifications (iOS)
- `AWS_*` - S3 storage, DynamoDB
- See `.env.example` for full list

---

## API Overview

### Mountain Data
- `GET /api/mountains` - List all 15 mountains
- `GET /api/mountains/[id]/conditions` - Current conditions
- `GET /api/mountains/[id]/forecast` - 7-day forecast
- `GET /api/mountains/[id]/powder-score` - 8-factor powder rating
- `GET /api/mountains/[id]/alerts` - Weather alerts
- `GET /api/mountains/[id]/all` - All data in one request

### Authentication
- `POST /api/auth/login` - Login
- `POST /api/auth/signup` - Register
- `POST /api/auth/logout` - Logout

### Events
- `GET /api/events` - List events
- `POST /api/events` - Create event (auth required)
- `GET /api/events/[id]` - Event details

---

## Tech Stack

- **Frontend**: Next.js 16, React 19, Tailwind CSS 4
- **Database**: Supabase (PostgreSQL)
- **AI**: Claude (Anthropic), OpenAI
- **Data Sources**: SNOTEL, NOAA, Open-Meteo, WSDOT
- **iOS**: SwiftUI, WidgetKit
- **Testing**: Vitest

---

## Documentation

- [Database Setup](docs/guides/DATABASE_SETUP.md)
- [iOS Development](docs/guides/IOS_SETUP.md)
- [Powder Score Algorithm](docs/features/ENHANCED_POWDER_SCORE.md)
- [Weather.gov Integration](docs/features/WEATHER_GOV_INTEGRATION.md)
- [Push Notifications](docs/guides/PUSH_NOTIFICATIONS_GUIDE.md)

---

## Deployment

### Pre-Deployment Checklist

Before deploying, run the verification checks appropriate for your change:

```bash
# Quick checks (~1 min) - For minor changes, config updates
./scripts/deploy-check.sh --quick

# Standard checks (~15 min) - For feature additions, bug fixes
./scripts/deploy-check.sh --standard

# Full verification (~45 min) - For major releases, auth changes
./scripts/deploy-check.sh --full
```

| Tier | Time | Use For | What It Runs |
|------|------|---------|--------------|
| Quick | ~1 min | Config changes, hotfixes | Git status, API health (12 checks) |
| Standard | ~15 min | Feature additions, bug fixes | + iOS build, unit tests |
| Full | ~45 min | Major releases, auth changes | + Snapshot, UI, performance tests, E2E |

See [PRE_DEPLOYMENT_CHECKLIST.md](PRE_DEPLOYMENT_CHECKLIST.md) for the complete manual checklist.

### Vercel (Web)

```bash
# Auto-deploys on push to main
git push origin main

# Or manual deploy
vercel --prod
```

Set environment variables in Vercel dashboard.

### Post-Deployment Verification

After deploying, verify production health:

```bash
# Automated API health checks
./scripts/verify-production-full.sh

# Monitor Vercel logs
vercel logs shredders-bay --follow
```

**Quick Smoke Test (5 minutes):**
1. API responds: `curl https://shredders-bay.vercel.app/api/events`
2. Auth protected: `POST /api/events` returns 401 without token
3. iOS app can sign in and create events

### iOS (App Store)

See [docs/guides/APP_STORE_SUBMISSION_CHECKLIST.md](docs/guides/APP_STORE_SUBMISSION_CHECKLIST.md).

---

## Testing

### Web Tests

```bash
pnpm test           # Run all tests
pnpm test:watch     # Watch mode
pnpm lint           # ESLint
pnpm type-check     # TypeScript checks
```

### iOS Tests

```bash
cd ios/PowderTracker

# Run all tests
./scripts/run_tests.sh

# Run specific test types
./scripts/run_tests.sh unit         # Unit tests only
./scripts/run_tests.sh snapshots    # Snapshot tests only
./scripts/run_tests.sh performance  # Performance tests only

# Record new snapshot references (after intentional UI changes)
./scripts/run_tests.sh snapshots record
```

### Test Coverage

| Category | Tests | Description |
|----------|-------|-------------|
| **iOS Unit Tests** | 11 classes | API, Auth, Events, Models, ViewModels, Map |
| **iOS Snapshot Tests** | 86+ tests | Visual regression across 4 devices, light/dark mode |
| **iOS UI Tests** | 8 classes | Authentication, Events, Mountains, Map, Profile flows |
| **iOS Performance Tests** | 5 classes | App launch, scroll, map, image loading, data ops |
| **Backend API Tests** | 12 checks | Connectivity, auth protection, data quality, response time |

### Performance Targets

| Metric | Target | Acceptable |
|--------|--------|------------|
| Cold app launch | < 2s | < 3s |
| List scroll (50 items) | < 50MB | < 75MB |
| Map initial render | < 500ms | < 1s |
| API response time | < 500ms | < 1s |

---

## Contributing

1. Create a feature branch
2. Make changes
3. Run `pnpm test` and `pnpm lint`
4. Run `./scripts/deploy-check.sh --standard` before PR
5. Submit pull request

---

## License

MIT
