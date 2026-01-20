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
