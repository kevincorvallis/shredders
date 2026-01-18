# Shredders - Claude Agent Context

You are an AI assistant with full access to the Shredders application infrastructure. This document provides complete context about available APIs, services, databases, and CLI tools.

---

## Project Overview

**Shredders** is an AI-powered mountain conditions tracker for Pacific Northwest ski resorts. It aggregates real-time data from multiple sources (SNOTEL, NOAA, Open-Meteo, WSDOT) to provide powder scores, forecasts, and trip planning intelligence.

- **Stack**: Next.js 16 (App Router), TypeScript, Tailwind CSS, Vercel
- **Frontend**: React 19, Leaflet maps, Recharts
- **AI**: Claude API for summaries and chat
- **Database**: None (stateless, real-time data fetching)

---

## Available CLI Tools

### Vercel CLI (v48.10.14)
```bash
vercel              # Deploy to Vercel
vercel --prod       # Deploy to production
vercel env pull     # Pull environment variables
vercel logs         # View function logs
vercel dev          # Run local dev server with Vercel runtime
```

### AWS CLI (v2.28.19)
```bash
aws configure       # Set up credentials
aws s3 ls           # List S3 buckets
aws lambda list-functions
aws cloudwatch get-metric-statistics
aws logs tail       # Tail CloudWatch logs
```

### Google Cloud CLI (v548.0.0)
```bash
gcloud auth login   # Authenticate
gcloud projects list
gcloud compute instances list
gcloud run services list
gcloud functions list
```

### GitHub CLI (v2.83.2)
```bash
gh repo view        # View repository info
gh pr list          # List pull requests
gh pr create        # Create pull request
gh issue list       # List issues
gh workflow run     # Trigger GitHub Actions
gh api              # Make GitHub API calls
```

### Other Tools
- **Node.js**: v24.7.0
- **NPM**: v11.5.1
- **Git**: v2.50.1
- **Python**: v3.12.11
- **Curl**: v8.7.1

---

## API Endpoints

Base URL: `https://shredders-bay.vercel.app` (production) or `http://localhost:3000` (dev)

### Mountains

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/mountains` | GET | List all 15 mountains |
| `/api/mountains?region=washington` | GET | Filter by region (washington/oregon/idaho) |
| `/api/mountains/[mountainId]` | GET | Get specific mountain details |

### Conditions & Weather

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/mountains/[id]/conditions` | GET | Current snow/weather conditions |
| `/api/mountains/[id]/forecast` | GET | 7-day weather forecast |
| `/api/mountains/[id]/powder-score` | GET | Powder score (1-10) with factors |
| `/api/mountains/[id]/history?days=30` | GET | Historical snow data (7-90 days) |

### Trip Planning

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/mountains/[id]/roads` | GET | Road/pass conditions (WA only) |
| `/api/mountains/[id]/trip-advice` | GET | Crowd/traffic/road risk assessment |
| `/api/mountains/[id]/powder-day` | GET | 3-day powder day planner |
| `/api/mountains/[id]/safety` | GET | Avalanche/safety metrics |

### AI

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/summary` | GET | AI-generated conditions summary |
| `/api/chat` | POST | Streaming chat with tool use |

---

## External Data Sources

### SNOTEL (NRCS)
- **URL**: `https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1`
- **Auth**: None required
- **Data**: Snow depth, SWE, temperature, precipitation
- **Update**: Daily

```bash
# Example: Get Mt. Baker (station 910) snow data
curl "https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1/data?stationTriplets=910:WA:SNTL&elements=SNWD,WTEQ,TOBS&duration=DAILY&getFlags=false&beginDate=$(date -v-7d +%Y-%m-%d)&endDate=$(date +%Y-%m-%d)"
```

### NOAA National Weather Service
- **URL**: `https://api.weather.gov`
- **Auth**: None (User-Agent required)
- **Data**: Forecasts, current conditions, grid data

```bash
# Example: Get Mt. Baker forecast
curl -H "User-Agent: Shredders/1.0" "https://api.weather.gov/gridpoints/SEW/157,123/forecast"
```

### Open-Meteo
- **URL**: `https://api.open-meteo.com/v1/forecast`
- **Auth**: None required
- **Data**: Freezing level, hourly snowfall

```bash
# Example: Get freezing level for Mt. Baker
curl "https://api.open-meteo.com/v1/forecast?latitude=48.857&longitude=-121.669&hourly=freezing_level_height,snowfall&timezone=America/Los_Angeles"
```

### WSDOT (Washington Roads)
- **URL**: `https://wsdot.wa.gov/Traffic/api`
- **Auth**: Access code required (`WSDOT_ACCESS_CODE`)
- **Data**: Pass conditions, road closures, travel advisories

```bash
# Example: Get all mountain pass conditions
curl "https://wsdot.wa.gov/Traffic/api/MountainPassConditions/MountainPassConditionsREST.svc/GetMountainPassConditionsAsJson?AccessCode=$WSDOT_ACCESS_CODE"
```

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Claude API for AI features |
| `WSDOT_ACCESS_CODE` | No | Washington road conditions |

---

## Supported Mountains

### Washington (7)
| ID | Name | SNOTEL | NOAA Grid |
|----|------|--------|-----------|
| `baker` | Mt. Baker | 910:WA:SNTL | SEW/157,123 |
| `stevens` | Stevens Pass | 791:WA:SNTL | SEW/163,108 |
| `crystal` | Crystal Mountain | ✓ | SEW |
| `snoqualmie` | Summit at Snoqualmie | ✓ | SEW |
| `whitepas` | White Pass | ✓ | PDT |
| `missionridge` | Mission Ridge | 349:WA:SNTL | OTX |
| `fortynine` | 49 Degrees North | 699:WA:SNTL | OTX |

### Oregon (6)
| ID | Name | SNOTEL | NOAA Grid |
|----|------|--------|-----------|
| `hood` | Mt. Hood Meadows | ✓ | PQR |
| `timberline` | Timberline Lodge | ✓ | PQR |
| `bachelor` | Mt. Bachelor | ✓ | PDT |
| `ashland` | Mt. Ashland | 341:OR:SNTL | MFR |
| `willamette` | Willamette Pass | 388:OR:SNTL | PQR |
| `hoodoo` | Hoodoo Ski Area | 801:OR:SNTL | PDT |

### Idaho (2)
| ID | Name | SNOTEL | NOAA Grid |
|----|------|--------|-----------|
| `schweitzer` | Schweitzer Mountain | 738:ID:SNTL | OTX |
| `lookout` | Lookout Pass | 579:ID:SNTL | MSO |

---

## Powder Score Algorithm

```
Score = Σ(factor × weight), normalized to 1-10

Factors:
├─ Fresh Snow (24h):    30% weight, 0-10 scale (10" = max)
├─ Recent Snow (48h):   15% weight, 0-10 scale
├─ Temperature:         10% weight, optimal 28-32°F
├─ Wind:                10% weight, penalty for >20mph
├─ Upcoming Snow:       15% weight, next 48h forecast
└─ Snow Line:           20% weight, rain risk score
```

---

## Chat Tools (AI Assistant)

The `/api/chat` endpoint supports these tools:

| Tool | Description |
|------|-------------|
| `get_conditions` | Current conditions for a mountain |
| `get_forecast` | 7-day forecast |
| `get_powder_score` | Powder score with breakdown |
| `get_history` | Historical snow data |
| `get_webcam` | Webcam URLs for a mountain |
| `get_road_conditions` | Pass/road status |
| `get_trip_advice` | Trip planning intelligence |
| `get_powder_day_plan` | 3-day powder day planner |
| `compare_mountains` | Compare multiple mountains |
| `list_mountains` | List all supported mountains |

---

## File Structure

```
/Users/kevin/Downloads/shredders/
├── src/
│   ├── app/
│   │   ├── api/                    # API routes
│   │   │   ├── mountains/[mountainId]/
│   │   │   │   ├── conditions/
│   │   │   │   ├── forecast/
│   │   │   │   ├── powder-score/
│   │   │   │   ├── history/
│   │   │   │   ├── roads/
│   │   │   │   ├── safety/
│   │   │   │   ├── trip-advice/
│   │   │   │   └── powder-day/
│   │   │   ├── chat/
│   │   │   └── summary/
│   │   ├── mountains/              # Mountain pages
│   │   ├── chat/                   # Chat page
│   │   └── page.tsx                # Homepage
│   ├── components/                 # React components
│   ├── context/                    # React context (MountainContext)
│   ├── data/                       # Static data (mountains.ts)
│   └── lib/
│       ├── apis/                   # External API clients
│       │   ├── snotel.ts
│       │   ├── noaa.ts
│       │   ├── open-meteo.ts
│       │   ├── wsdot.ts
│       │   └── claude.ts
│       ├── calculations/           # Business logic
│       │   ├── powder-day-planner.ts
│       │   ├── safety-metrics.ts
│       │   └── trip-advice.ts
│       └── chat/
│           └── tools.ts            # Chat tool definitions
├── ios/                            # iOS app (SwiftUI)
│   └── PowderTracker/
├── package.json
└── vercel.json
```

---

## Common Commands

```bash
# Development
npm run dev                         # Start dev server
npm run build                       # Build for production
npm run lint                        # Run ESLint

# Deployment
vercel                              # Deploy preview
vercel --prod                       # Deploy production

# iOS Build
cd ios/PowderTracker
xcodebuild -scheme PowderTracker -destination 'generic/platform=iOS Simulator' build

# Testing APIs
curl http://localhost:3000/api/mountains
curl http://localhost:3000/api/mountains/baker/conditions
curl http://localhost:3000/api/mountains/baker/powder-score
```

---

## Caching Strategy

| Data Type | Cache TTL | Stale-While-Revalidate |
|-----------|-----------|------------------------|
| Conditions | 5 min | 10 min |
| Forecast | 1 hour | 2 hours |
| Powder Score | 30 min | 1 hour |
| History | 1 hour | 2 hours |
| Roads | 5 min | 10 min |
| Trip Advice | 5 min | 10 min |
| Safety | 5 min | 10 min |

---

## Error Handling

All APIs return JSON with consistent error format:
```json
{
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

Graceful degradation:
- SNOTEL down → Use NOAA temperature estimates
- NOAA down → Use cached/fallback data
- Open-Meteo down → Estimate freezing level
- WSDOT down → Return "unavailable" status
- Claude down → Return hardcoded summary

---

## Quick Reference

```bash
# Get current conditions for Mt. Baker
curl https://shredders-bay.vercel.app/api/mountains/baker/conditions

# Get powder score
curl https://shredders-bay.vercel.app/api/mountains/baker/powder-score

# Get 7-day forecast
curl https://shredders-bay.vercel.app/api/mountains/baker/forecast

# Get road conditions (WA only)
curl https://shredders-bay.vercel.app/api/mountains/baker/roads

# List all mountains
curl https://shredders-bay.vercel.app/api/mountains

# Deploy to Vercel
cd /Users/kevin/Downloads/shredders && vercel --prod
```

---

*Last updated: December 2024*
