# PowderTracker iOS App

## Project Overview
PowderTracker is an iOS app for tracking ski resort conditions, weather overlays, and powder alerts.

## Tech Stack
- SwiftUI for UI
- UIKit (MKMapView) for weather map overlays
- Supabase for backend
- RainViewer API for radar/precipitation (free)
- OpenWeatherMap API for temperature/wind overlays

## Key Directories
- `PowderTracker/` - Main app code
  - `Views/` - SwiftUI views
  - `Services/` - API services and managers
  - `Config/` - App configuration (API keys, URLs)
  - `ViewModels/` - View models
- `scripts/` - Automation scripts

## API Keys
- OpenWeatherMap key is in `Config/AppConfig.swift`
- Supabase credentials are in `Config/AppConfig.swift`

## Building
```bash
cd ios/PowderTracker
xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Running E2E Tests
```bash
./scripts/e2e_test.sh
```

---

## Custom Agents

### e2e-tester
Use this agent after making changes to the iOS app to verify the UI is working correctly.

**Trigger:** After modifying Views, Services, or any UI-related code

**What it does:**
1. Builds the app
2. Installs on simulator
3. Navigates through all tabs
4. Tests weather overlays
5. Takes screenshots for verification

**How to run:**
```bash
./scripts/e2e_test.sh
```

### weather-overlay-verifier
Use this agent to verify weather tile overlays are loading correctly.

**Checks:**
- RainViewer API connectivity (radar, clouds fallback)
- OpenWeatherMap API connectivity (temperature, wind)
- Iowa State Mesonet API (smoke/AQI)
- Tile loading and rendering

### production-verifier
Use this agent after making changes to authentication, events, or backend API code.

**Trigger:** After modifying:
- `src/app/api/auth/*` - Authentication endpoints
- `src/app/api/events/*` - Events endpoints
- `src/lib/auth/*` - Auth utilities
- `Services/AuthService.swift` - iOS auth service
- `Services/EventService.swift` - iOS events service

**What it does:**
1. Runs automated API health checks (12 tests)
2. Verifies auth protection (401 for protected endpoints)
3. Checks data quality (events have creators, mountains exist)
4. Measures response times

**How to run:**
```bash
# Quick API checks (from project root)
./scripts/verify-production-full.sh

# Full verification with iOS build
./scripts/verify-production-full.sh --ios-build

# Everything including UI tests
./scripts/verify-production-full.sh --all
```

**Production Checklist:** See `PRODUCTION_CHECKLIST.md` for manual testing steps.

---

## UI Features

### Design System
- **8pt Grid Spacing** - Consistent spacing tokens (`.spacingXS` through `.spacingXXL`)
- **Glassmorphic Cards** - `.ultraThinMaterial` backgrounds with layered shadows
- **SF Symbols** - Semantic icon system via `SkiIcon` enum with 40+ mappings
- **Adaptive Colors** - All colors use system variants for dark mode support

See `DESIGN_SYSTEM.md` for full component documentation.

### Animations & Interactions
- **Spring Animations** - `.bouncy`, `.snappy`, `.smooth` presets
- **Haptic Feedback** - Selection, impact, and notification haptics
- **Scroll Effects** - `.scrollTransition()` for depth effects
- **Hero Transitions** - iOS 18+ zoom transitions for mountain cards

### Loading States
- **Skeleton Views** - Shimmer loading placeholders
- **Progressive Loading** - Staggered card appearance
- **Empty States** - Illustrated states with actionable CTAs

### Platform Integration
- **Widgets** - Small, medium, large home screen widgets
- **Live Activities** - Dynamic Island and Lock Screen updates
- **Siri Shortcuts** - "Check conditions at [mountain]" intents
- **Deep Linking** - `powdertracker://mountains/{id}` URLs

### Accessibility
- **Dynamic Type** - All text scales with system settings
- **VoiceOver** - Full accessibility labels and hints
- **Reduce Motion** - Animations respect system preference
- **Reduce Haptics** - Haptics disabled when preference set

---

## Weather Overlay System

### Supported Overlays
| Overlay | Source | API Key Required |
|---------|--------|------------------|
| Radar | RainViewer | No |
| Clouds | OpenWeatherMap (fallback: RainViewer) | Optional |
| Temperature | OpenWeatherMap | Yes |
| Wind | OpenWeatherMap | Yes |
| Snowfall | OpenWeatherMap (fallback: Radar) | Optional |
| Smoke | Iowa State Mesonet | No |

### Files
- `Services/WeatherTileOverlay.swift` - Tile overlay implementation
- `Views/Map/WeatherMapView.swift` - UIKit MKMapView wrapper

## Simulator Commands

```bash
# List running simulators
xcrun simctl list devices | grep Booted

# Take screenshot
xcrun simctl io booted screenshot /tmp/screenshot.png

# Install app
xcrun simctl install booted path/to/App.app

# Launch app
xcrun simctl launch booted com.shredders.powdertracker

# Stream logs
xcrun simctl spawn booted log stream --predicate 'process CONTAINS "PowderTracker"'
```
