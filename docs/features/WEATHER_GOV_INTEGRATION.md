# Weather.gov Integration - Complete Documentation

## Overview
Comprehensive integration of NOAA Weather.gov data and links throughout PowderTracker/Shredders web and iOS applications.

## Features Implemented

### 1. Weather Alerts System
**API Endpoint:** `/api/mountains/[mountainId]/alerts`

**Features:**
- Real-time weather alerts from NOAA for each mountain location
- Displays severity levels (Extreme, Severe, Moderate, Minor)
- Shows alert headline, description, and safety instructions
- Expiration timestamps

**Data Included:**
- Winter Storm Warnings
- Avalanche Warnings
- Wind Advisories
- Heavy Snow Warnings
- All NOAA active alerts for the mountain's coordinates

### 2. Hourly Forecast
**API Endpoint:** `/api/mountains/[mountainId]/hourly`

**Features:**
- Up to 156 hours (6.5 days) of hourly forecast data
- Temperature, wind speed/direction
- Precipitation probability
- Detailed conditions for each hour

**Parameters:**
- `hours` - Number of hours to fetch (default: 48)

### 3. Weather.gov Deep Links
**API Endpoint:** `/api/mountains/[mountainId]/weather-gov-links`

**Links Generated for Each Mountain:**
1. **Main Forecast** - Detailed 7-day forecast page
2. **Hourly Graph** - Interactive hourly weather graph
3. **Detailed Text Forecast** - Full meteorologist-written forecast
4. **Active Alerts** - All alerts for the location
5. **Forecast Discussion** - Technical discussion from NWS meteorologists

**URL Format:**
```
https://forecast.weather.gov/MapClick.php?lat={lat}&lon={lon}
```

### 4. Enhanced NOAA API Client
**File:** `src/lib/apis/noaa.ts`

**New Functions:**
- `getWeatherAlerts(lat, lng)` - Fetch active alerts
- `getHourlyForecast(config, hours)` - Get hourly forecast
- `getForecastDiscussion(config)` - Get meteorologist discussion
- `getWeatherGovUrls(lat, lng, config)` - Generate all weather.gov URLs

### 5. Web Application Updates

#### Mountain Page (`src/app/mountains/[mountainId]/page.tsx`)

**Alerts Section:**
- Displays at top of page when active
- Color-coded by severity (Red/Orange/Yellow/Blue)
- Expandable descriptions
- Safety instructions highlighted
- Expiration times shown

**Forecast Section Enhancements:**
- "Hourly" button - Links to hourly graph
- "Weather.gov" button - Links to main forecast
- "Forecast Discussion" link - Technical forecast details
- NOAA attribution footer

**Visual Design:**
```
⚠️ WINTER STORM WARNING
Heavy Snow Expected - Up to 12 inches
[Full description with truncation]
[Safety instructions in highlighted box]
Expires: Dec 22, 2025 6:00 PM
```

### 6. iOS Application Updates

#### New Files:
**`WeatherGovLinksView.swift`** - Complete weather.gov integration view

#### Updated Files:
- `MountainResponses.swift` - Added alert and link models
- `APIClient.swift` - Added new API endpoints
- `DashboardView.swift` - Integrated WeatherGovLinksView

#### iOS Features:
**Weather Alerts:**
- Native iOS alert cards
- Severity-based color coding
- Tap to expand full details
- Auto-refresh with mountain data

**Quick Links Section:**
- Safari links to weather.gov pages
- Native iOS design patterns
- Icons for each link type
- External link indicators

**Links Provided:**
1. Detailed Forecast
2. Hourly Graph
3. Active Alerts
4. Forecast Discussion

## API Endpoints Summary

### All Mountains Support:
```
GET /api/mountains/[mountainId]/alerts
GET /api/mountains/[mountainId]/hourly?hours=48
GET /api/mountains/[mountainId]/weather-gov-links
GET /api/mountains/[mountainId]/forecast (existing, enhanced)
GET /api/mountains/[mountainId]/conditions (existing)
```

## Mountain-Specific Weather.gov Configuration

Each mountain in `src/data/mountains.ts` has:
```typescript
noaa: {
  gridOffice: string;  // e.g., "SEW", "PDT", "PQR", "OTX", "MSO", "MFR"
  gridX: number;
  gridY: number;
}
```

**Supported Grid Offices:**
- **SEW** (Seattle) - Mt. Baker, Stevens Pass, Crystal, Snoqualmie
- **PDT** (Pendleton) - White Pass, Mt. Bachelor, Hoodoo
- **PQR** (Portland) - Mt. Hood Meadows, Timberline, Willamette
- **OTX** (Spokane) - Mission Ridge, 49° North, Schweitzer
- **MSO** (Missoula) - Lookout Pass
- **MFR** (Medford) - Mt. Ashland

## Weather.gov URLs by Mountain

### Example: Mt. Baker
```
Forecast: https://forecast.weather.gov/MapClick.php?lat=48.857&lon=-121.669
Hourly: https://forecast.weather.gov/MapClick.php?lat=48.857&lon=-121.669&FcstType=graphical
Alerts: https://alerts.weather.gov/search?lat=48.857&lon=-121.669
Discussion: https://forecast.weather.gov/product.php?site=SEW&product=AFD
```

## User Experience Flow

### Web Application:
1. User navigates to mountain page
2. **Alerts appear at top** if any are active
3. Forecast section shows **NOAA attribution**
4. **Quick action buttons** link to weather.gov
5. **Forecast Discussion** link in footer

### iOS Application:
1. Open DashboardView for selected mountain
2. **Scroll to Weather.gov section**
3. **View alerts** (if active) with full details
4. **Tap any link** to open in Safari
5. Get official NOAA forecast data

## Attribution & Compliance

**NOAA Weather.gov Attribution:**
- Displayed on all forecast sections
- "Powered by NOAA Weather.gov" with checkmark icon
- Direct links to source data
- API usage follows weather.gov terms

## Technical Implementation

### Data Flow:
```
Mountain Config → NOAA API → Next.js Route → React/SwiftUI UI
     ↓              ↓              ↓                ↓
  lat/lng      API calls      JSON cache     User display
  gridX/Y      Alerts/Fcst    Error handling   Deep links
```

### Caching Strategy:
- Web: Next.js route caching (default)
- iOS: Async/await with task cancellation
- Alerts: Real-time fetch (no cache)
- Forecasts: Suitable for short caching (~15 min)

### Error Handling:
- Network failures: Graceful degradation
- Missing alerts: Empty array (no error)
- Invalid coordinates: Fallback to grid points
- API rate limits: Retry with exponential backoff

## Testing Checklist

### Web Application:
- [x] Alerts display for active warnings
- [x] Weather.gov links are functional
- [x] Hourly forecast endpoint works
- [x] NOAA attribution visible
- [x] Mobile responsive design
- [x] All 15 mountains configured

### iOS Application:
- [x] WeatherGovLinksView renders
- [x] Alerts display with correct severity colors
- [x] Safari links open correctly
- [x] Loading states work
- [x] Error handling graceful
- [x] Refresh functionality works

### API Endpoints:
- [x] `/alerts` - Returns alert data
- [x] `/hourly` - Returns hourly forecast
- [x] `/weather-gov-links` - Returns all URLs
- [x] Error responses (404, 500)
- [x] CORS configuration

## Future Enhancements

### Potential Additions:
1. **Hourly Forecast Chart** - Graph in web app
2. **Push Notifications** - iOS alerts for severe weather
3. **Forecast Comparison** - Compare multiple mountains
4. **Historical Alerts** - Archive past warnings
5. **Radar Integration** - Embed weather.gov radar
6. **Snow Level Tracking** - From gridded forecast data

### Advanced Features:
- Avalanche forecast integration (if available)
- Marine weather for coastal mountains
- Road weather cameras from DOT
- Real-time SNOTEL + NOAA fusion

## Benefits for Users

1. **One-Stop Shop** - All weather data in one app
2. **Official Source** - Direct from NOAA
3. **Local Expertise** - NWS meteorologist discussions
4. **Timely Alerts** - Critical safety information
5. **Deep Integration** - Seamless access to detailed data

## Maintenance Notes

### Update Frequency:
- **Alerts**: Check every page load (critical)
- **Hourly**: Refresh every 30-60 minutes
- **Discussion**: Update 2-3 times daily
- **Grid configs**: Only when mountains added

### Dependencies:
- NOAA Weather API (free, no key required)
- Must use proper User-Agent header
- Respect rate limits (not published)
- Monitor for API changes

### Known Limitations:
- Some discussions may be large (truncate if needed)
- API can be slow during high load
- Not all data available for all locations
- Text forecasts are human-written (variable format)

## Integration Complete ✓

All 15 mountains now have:
- ✅ Real-time weather alerts
- ✅ Hourly forecast data
- ✅ Direct links to weather.gov
- ✅ NOAA attribution
- ✅ iOS + Web support
- ✅ Error handling
- ✅ Responsive design

**Implementation Date:** December 21, 2024
**Version:** 1.0
**Status:** Production Ready
