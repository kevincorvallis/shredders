# Shredders (PowderTracker)

AI-powered mountain conditions tracker for powder chasers across the Pacific Northwest. Real-time snow data, weather forecasts, and intelligent powder day predictions for 15 ski resorts across Washington, Oregon, and Idaho.

**Live**: [shredders-bay.vercel.app](https://shredders-bay.vercel.app)

---

## Quick Start

### Prerequisites

- Node.js 18+
- pnpm 9+ (`npm install -g pnpm`)
- Supabase account (for database)

### Setup

```bash
# Clone and install
git clone https://github.com/yourusername/shredders.git
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

**Optional:**
- `ANTHROPIC_API_KEY` - For AI chat features
- `OPENAI_API_KEY` - For arrival time predictions
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

Full API documentation in `docs/api/`.

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

### Vercel (Web)

```bash
vercel --prod
```

Set environment variables in Vercel dashboard.

### iOS (App Store)

See [docs/guides/APP_STORE_SUBMISSION_CHECKLIST.md](docs/guides/APP_STORE_SUBMISSION_CHECKLIST.md).

---

## Contributing

1. Create a feature branch
2. Make changes
3. Run `pnpm test` and `pnpm lint`
4. Submit pull request

---

## License

MIT
