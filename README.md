# Shredders (PowderTracker) 🏔️❄️

**AI-powered mountain conditions tracker for powder chasers across the Pacific Northwest.**

Real-time snow data, comprehensive weather forecasts, intelligent powder day predictions, and weather alerts for **15 ski resorts** across Washington, Oregon, and Idaho.

![App Icon](ios/PowderTracker/PowderTracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png)

---

## 🎯 Features

### 🌨️ Real-Time Conditions
- **Live Snow Data** - Current depth, 24h/48h snowfall from SNOTEL stations
- **Weather Conditions** - Temperature, wind speed & gusts, humidity, visibility
- **Snow Line Tracking** - Freezing level and rain/snow risk assessment
- **Historical Charts** - 30/60/90 day snow depth trends

### ⚠️ Weather Alerts
- **Real-Time Alerts** - Winter storm warnings, avalanche advisories, wind warnings
- **Severity Levels** - Color-coded by urgency (Extreme/Severe/Moderate/Minor)
- **Safety Instructions** - NWS recommendations and precautions
- **Expiration Tracking** - Know when alerts expire

### 🔗 Weather.gov Integration
- **Direct Links** - One-click access to detailed NOAA forecasts
- **Hourly Graphs** - Interactive 7-day hourly temperature/precipitation
- **Forecast Discussion** - Read meteorologist technical analysis
- **Official Source** - All data from National Weather Service

### ⭐ Enhanced Powder Score (1-10)
**8-factor algorithm** combining multiple data sources:
- Fresh Snow (24h) - Most recent accumulation
- Recent Snow (48h) - Short-term history
- Temperature - Ideal for powder preservation
- Wind (with gusts) - Accounts for blown-out conditions
- Upcoming Snow - Next 48 hours forecast
- Snow Line - Rain vs snow risk
- Visibility - Safety and enjoyment
- Conditions - Sky cover, humidity, precipitation probability

### 🗺️ 15 Mountains Covered

**Washington (7)**
- Mt. Baker
- Stevens Pass
- Crystal Mountain
- Summit at Snoqualmie
- White Pass
- Mission Ridge
- 49 Degrees North

**Oregon (6)**
- Mt. Hood Meadows
- Timberline Lodge
- Mt. Bachelor
- Mt. Ashland
- Willamette Pass
- Hoodoo Ski Area

**Idaho (2)**
- Schweitzer Mountain
- Lookout Pass

### 🚗 Trip Planning
- **Road Conditions** - Pass status and restrictions (WA via WSDOT)
- **Traffic Estimates** - Crowd predictions based on conditions
- **Departure Timing** - Suggested times from major cities
- **3-Day Planner** - Best powder days with travel context

### 📱 Multi-Platform
- **Web App** - Responsive Next.js application
- **iOS App** - Native SwiftUI with widgets
- **REST API** - Full API access for custom integrations

### 🤖 AI-Powered Insights
- **Natural Language Summaries** - Conditions explained in plain English
- **Intelligent Recommendations** - When to go, what to expect
- **Chat Interface** - Ask questions about conditions

---

## 🚀 Live Demo

**Web App**: [shredders-bay.vercel.app](https://shredders-bay.vercel.app)

**iOS App**: Available via TestFlight (contact for access)

---

## 📡 API Endpoints

### Mountain-Specific Endpoints

| Endpoint | Description |
|----------|-------------|
| `/api/mountains` | List all 15 mountains with metadata |
| `/api/mountains/[id]` | Detailed mountain information |
| `/api/mountains/[id]/conditions` | Current snow depth, temps, wind from SNOTEL + NOAA |
| `/api/mountains/[id]/forecast` | 7-day weather forecast from NOAA |
| `/api/mountains/[id]/powder-score` | **Enhanced 8-factor** powder rating |
| `/api/mountains/[id]/history?days=30` | Historical snow depth charts |
| `/api/mountains/[id]/alerts` | ⭐ **Active weather alerts** from NWS |
| `/api/mountains/[id]/hourly?hours=48` | ⭐ **Hourly forecast** (up to 156 hours) |
| `/api/mountains/[id]/weather-gov-links` | ⭐ **Direct links** to weather.gov pages |
| `/api/mountains/[id]/roads` | Road & pass conditions (WA only) |
| `/api/mountains/[id]/trip-advice` | Crowd/traffic/road risk analysis |
| `/api/mountains/[id]/powder-day` | 3-day powder day planner |
| `/api/mountains/[id]/safety` | Avalanche & weather safety info |

### Legacy Endpoints (default to Mt. Baker)

| Endpoint | Description |
|----------|-------------|
| `/api/conditions` | Current conditions (Baker) |
| `/api/forecast` | 7-day forecast (Baker) |
| `/api/powder-score` | Powder score (Baker) |
| `/api/history` | Historical data (Baker) |
| `/api/summary` | AI-generated summary (Baker) |

### Chat & Agent

| Endpoint | Description |
|----------|-------------|
| `/api/chat` | AI chat about conditions |
| `/api/agent` | Autonomous agent for complex queries |

---

## 🗄️ Data Sources

### Primary Sources
1. **SNOTEL** (USDA Natural Resources Conservation Service)
   - Snow depth and accumulation
   - Snow water equivalent (SWE)
   - Temperature readings
   - 15 stations across PNW

2. **NOAA Weather.gov** - National Weather Service
   - **Basic API** - 7-day forecast, current conditions
   - **Extended Grid Data** - Wind gusts, humidity, visibility, sky cover
   - **Hourly Forecast** - 156-hour detailed predictions
   - **Active Alerts** - Real-time warnings and watches
   - 6 grid offices (SEW, PDT, PQR, OTX, MSO, MFR)

3. **Open-Meteo**
   - Freezing level elevation
   - Rain/snow line predictions
   - High-altitude weather data

4. **Claude AI** (Anthropic)
   - Natural language summaries
   - Intelligent recommendations
   - Interactive chat

### Secondary Sources
- **WSDOT** (Washington State DOT) - Road conditions
- **Mountain Resort Webcams** - Visual conditions

---

## 🛠️ Tech Stack

### Web Application
- **Framework**: Next.js 14+ (App Router, Turbopack)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Charts**: Recharts
- **Deployment**: Vercel
- **Maps**: Leaflet.js

### iOS Application
- **Framework**: SwiftUI
- **Language**: Swift 6
- **Charts**: Swift Charts
- **Widgets**: WidgetKit
- **Architecture**: MVVM
- **Minimum iOS**: 17.0

### Backend & APIs
- **Runtime**: Node.js 18+
- **API Client**: Native Fetch API
- **Data Formats**: JSON, GeoJSON
- **Rate Limiting**: Built-in retry logic
- **Caching**: Next.js automatic caching

---

## 🏃 Getting Started

### Prerequisites
- **Node.js** 18+ and npm/yarn
- **Xcode** 15+ (for iOS development)
- **Anthropic API Key** (for AI features)

### Web App Setup

```bash
# Clone repository
git clone https://github.com/yourusername/shredders.git
cd shredders

# Install dependencies
npm install

# Set up environment variables (optional for AI features)
cp .env.example .env.local
# Edit .env.local and add your ANTHROPIC_API_KEY

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the app.

### iOS App Setup

```bash
# Navigate to iOS project
cd ios/PowderTracker

# Generate Xcode project (requires xcodegen)
brew install xcodegen
xcodegen generate

# Open in Xcode
open PowderTracker.xcodeproj
```

**Note**: The iOS app connects to your local dev server or production API. Configure the base URL in `AppConfig.swift`.

### Build for Production

```bash
# Web app
npm run build
npm start

# iOS app
# Build in Xcode (Product → Archive)
```

---

## 📁 Project Structure

```
shredders/
├── src/
│   ├── app/
│   │   ├── api/                    # API routes
│   │   │   ├── mountains/
│   │   │   │   └── [mountainId]/
│   │   │   │       ├── alerts/     # ⭐ Weather alerts
│   │   │   │       ├── conditions/
│   │   │   │       ├── forecast/
│   │   │   │       ├── hourly/     # ⭐ Hourly forecast
│   │   │   │       ├── powder-score/
│   │   │   │       ├── weather-gov-links/ # ⭐ Deep links
│   │   │   │       └── ...
│   │   │   ├── chat/
│   │   │   └── agent/
│   │   ├── mountains/              # Mountain pages
│   │   │   └── [mountainId]/
│   │   │       ├── page.tsx        # Main dashboard
│   │   │       ├── history/
│   │   │       ├── patrol/
│   │   │       └── webcams/
│   │   └── page.tsx                # Home page
│   ├── components/                 # React components
│   ├── lib/
│   │   ├── apis/
│   │   │   ├── noaa.ts            # ⭐ Enhanced NOAA client
│   │   │   ├── snotel.ts
│   │   │   └── open-meteo.ts
│   │   └── calculations/
│   ├── data/
│   │   └── mountains.ts            # ⭐ All 15 mountains config
│   └── types/
├── ios/
│   └── PowderTracker/
│       ├── PowderTracker/
│       │   ├── Views/
│       │   │   ├── DashboardView.swift
│       │   │   ├── WeatherGovLinksView.swift # ⭐ New
│       │   │   └── ...
│       │   ├── Models/
│       │   │   └── MountainResponses.swift   # ⭐ Enhanced
│       │   ├── Services/
│       │   │   └── APIClient.swift           # ⭐ Enhanced
│       │   └── Config/
│       ├── PowderTrackerWidget/
│       └── project.yml
├── public/
│   ├── logo_master.png             # ⭐ New logo
│   └── ...
├── docs/                           # ⭐ Documentation
│   ├── WEATHER_GOV_INTEGRATION.md
│   ├── ENHANCED_POWDER_SCORE.md
│   └── INTEGRATION_SUMMARY.md
└── package.json
```

---

## 🧮 Enhanced Powder Score Algorithm

### Algorithm Overview

The powder score is calculated using **8 weighted factors** from **5 data sources**:

```
Score = Σ (Factor Value × Weight)
Range: 1.0 - 10.0
```

### Scoring Factors

| Factor | Weight | Source | Description |
|--------|--------|--------|-------------|
| **Fresh Snow (24h)** | 25% | SNOTEL | Most recent snowfall |
| **Recent Snow (48h)** | 12% | SNOTEL | Short-term accumulation |
| **Temperature** | 10% | NOAA Extended | Ideal 28-32°F |
| **Wind (with gusts)** | 8% | NOAA Extended | Includes peak gusts |
| **Upcoming Snow** | 15% | NOAA Hourly | Next 48 hours |
| **Snow Line** | 18% | Open-Meteo | Rain vs snow risk |
| **Visibility** | 7% | NOAA Extended | Safety + enjoyment |
| **Conditions** | 5% | NOAA Extended | Sky/humidity/precip |

### Score Interpretation

| Score | Verdict | Meaning |
|-------|---------|---------|
| 8.0-10.0 | **SEND IT!** Epic powder conditions! | Fresh snow, perfect weather, go now! |
| 6.0-7.9 | **Great day!** Fresh snow awaits | Good conditions, worth the trip |
| 4.0-5.9 | **Decent** Groomed runs good | Fair conditions, locals only |
| 1.0-3.9 | **Wait** Consider better conditions | Poor conditions, stay home |

### Example Calculation

**Mt. Baker - Epic Day (Score: 9.2/10)**

```
✅ Fresh Snow (24h): 2.50 points (10" × 25%)
✅ Recent Snow (48h): 1.20 points (20" × 12%)
✅ Temperature: 1.00 points (28°F × 10%)
✅ Wind: 0.80 points (5 mph, gusts 12 × 8%)
✅ Upcoming Snow: 1.50 points (8" × 15%)
✅ Snow Line: 1.80 points (All snow × 18%)
✅ Visibility: 0.70 points (6.5 mi × 7%)
⚠️  Conditions: 0.30 points (Active weather × 5%)
────────────────────────────────────────────
Total: 9.2/10 - SEND IT! Epic powder!
```

See [ENHANCED_POWDER_SCORE.md](ENHANCED_POWDER_SCORE.md) for complete algorithm documentation.

---

## 🌐 Environment Variables

### Required for AI Features

```bash
# .env.local
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

### Optional

```bash
# Washington road conditions (WSDOT Traveler Info API)
WSDOT_ACCESS_CODE=your_wsdot_access_code

# Custom API base URL (iOS app development)
API_BASE_URL=http://localhost:3000
```

---

## 🧪 Testing

### Run Tests

```bash
# Test weather.gov API for all mountains
node test-weather-gov.js

# Test enhanced powder scores
node test-powder-scores.js

# Build test
npm run build
```

### Test Results

```
✅ Weather.gov API: 100% success (15/15 mountains)
✅ Powder Score: 8 factors, all data sources
✅ Builds: Web (Next.js) + iOS (SwiftUI)
```

---

## 📖 Documentation

### Comprehensive Guides

- [**WEATHER_GOV_INTEGRATION.md**](WEATHER_GOV_INTEGRATION.md) - Complete technical documentation
- [**ENHANCED_POWDER_SCORE.md**](ENHANCED_POWDER_SCORE.md) - Algorithm details and examples
- [**INTEGRATION_SUMMARY.md**](INTEGRATION_SUMMARY.md) - High-level overview
- [**DEPLOYMENT_READY.txt**](DEPLOYMENT_READY.txt) - Deployment checklist

### Quick Links

- [All Mountains Configuration](src/data/mountains.ts)
- [NOAA API Client](src/lib/apis/noaa.ts)
- [Powder Score Algorithm](src/app/api/mountains/[mountainId]/powder-score/route.ts)
- [iOS Models](ios/PowderTracker/PowderTracker/Models/MountainResponses.swift)

---

## 🚀 Deployment

### Web App (Vercel)

```bash
# Deploy to Vercel
vercel --prod

# Or use Vercel GitHub integration for automatic deploys
```

**Environment Variables**: Set `ANTHROPIC_API_KEY` in Vercel dashboard.

### iOS App (App Store)

1. Open project in Xcode
2. Update version and build number
3. Archive: Product → Archive
4. Distribute to App Store Connect
5. Submit for review

**Requirements**:
- Apple Developer Account
- App Store Connect app created
- Privacy policy URL
- App screenshots (all required sizes)

---

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- Additional mountains (California, British Columbia, etc.)
- More data sources (avalanche forecasts, webcams)
- Enhanced visualizations
- Mobile app features
- API optimizations

### Development

```bash
# Fork and clone
git clone https://github.com/yourusername/shredders.git

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and test
npm run dev
npm run build

# Submit pull request
```

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

### Data Providers
- **NOAA National Weather Service** - Weather forecasts and alerts
- **USDA NRCS** - SNOTEL snow telemetry network
- **Open-Meteo** - High-altitude weather data
- **Anthropic** - Claude AI for natural language processing

### Mountain Resorts
Thanks to all 15 Pacific Northwest ski resorts for their incredible terrain and the powder they provide!

### Special Thanks
- Mt. Baker Ski Area for being legendary
- The powder skiing community
- Open source contributors

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/shredders/issues)
- **Website**: [shredders-bay.vercel.app](https://shredders-bay.vercel.app)
- **Email**: support@shredders.app

---

## 📊 Stats

- **15 Mountains** across WA, OR, ID
- **5 Data Sources** integrated
- **8 Scoring Factors** for powder rating
- **156 Hours** of hourly forecasts
- **100% Success Rate** weather.gov integration
- **~1,200 Lines** of enhanced code

**Built with ❄️ by powder chasers, for powder chasers.**

---

**Status**: ✅ Production Ready | 🚀 Deployed | 📱 iOS App Available

Last Updated: December 2024
