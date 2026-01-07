# Tabbed Mountain View - Organization Guide

**Date**: January 5, 2026
**Status**: ✅ In Progress

---

## Overview

Created a comprehensive tabbed interface (`TabbedLocationView.swift`) that organizes all mountain information into 8 logical categories.

---

## 📊 Tab Structure

### 1. **Overview** ✅ Complete
- Powder score with visual indicator (1-10 scale)
- At-a-glance metrics card
- Quick stats grid (snow depth, temp, wind, conditions)
- Recent snowfall (24h, 48h, 7d)

**File**: `/Views/Location/Tabs/OverviewTab.swift`

---

### 2. **Forecast** ✅ Complete
- **Powder Day Planner** - 3-day best days to ride
  - Powder score per day
  - Expected snowfall
  - Crowd risk percentage
  - Road risk percentage
- **7-Day Forecast** - Daily weather predictions
  - High/low temperatures
  - Conditions with icons
  - Snowfall amounts
- **Hourly Forecast** - Next 24 hours
  - Temperature per hour
  - Precipitation chance
  - Snow vs rain indicators

**File**: `/Views/Location/Tabs/ForecastTab.swift`
**API Endpoints**:
- `/api/mountains/[id]/powder-day`
- `/api/mountains/[id]/forecast`
- `/api/mountains/[id]/hourly`

---

### 3. **History** 🚧 Stub Created
- Historical snow depth charts
- Year-over-year comparison
- 30/60/90 day trends
- Season comparisons

**File**: `/Views/Location/Tabs/HistoryTab.swift`
**API Endpoints**:
- `/api/mountains/[id]/history`
- `/api/mountains/[id]/snow-comparison`

**TODO**:
- Add snow depth line chart
- Add year-over-year bar chart
- Add season comparison widget

---

### 4. **Travel** 🚧 Stub Created
- Real-time road conditions
- Pass closures and restrictions
- Chain requirements
- Traffic predictions
- Drive time estimates
- Trip planning advice

**File**: `/Views/Location/Tabs/TravelTab.swift`
**API Endpoints**:
- `/api/mountains/[id]/roads`
- `/api/mountains/[id]/trip-advice`

**Currently Shows**:
- Uses existing `RoadConditionsSection` component

---

### 5. **Safety** 🚧 Stub Created
- Weather alerts (NOAA warnings)
- Avalanche conditions
- Road closures
- Safety recommendations
- Emergency information

**File**: `/Views/Location/Tabs/SafetyTab.swift`
**API Endpoints**:
- `/api/mountains/[id]/alerts`
- `/api/mountains/[id]/safety`

**TODO**:
- Add weather alert cards with severity levels
- Add avalanche rating display
- Add emergency contact information

---

### 6. **Webcams** 🚧 Stub Created
- Live resort webcams
- Road webcams (WSDOT)
- Auto-refresh capabilities
- Fullscreen view

**File**: `/Views/Location/Tabs/WebcamsTab.swift`

**Currently Shows**:
- Uses existing `WebcamsSection` component

---

### 7. **Social** 🚧 Stub Created
- User-submitted photos
- Check-ins and trip reports
- Comments and likes
- Community ratings

**File**: `/Views/Location/Tabs/SocialTab.swift`
**API Endpoints**:
- `/api/mountains/[id]/photos`
- `/api/mountains/[id]/check-ins`

**TODO**:
- Add photo grid
- Add check-in cards
- Add social interaction buttons (like, comment)

---

### 8. **Lifts** 🚧 Stub Created
- Interactive trail map
- Lift status (open/closed)
- Terrain difficulty ratings
- Trail names and routes

**File**: `/Views/Location/Tabs/LiftsTab.swift`
**API Endpoint**:
- `/api/mountains/[id]/lifts`

**Currently Shows**:
- Uses existing `LocationMapSection` component

---

## 🎨 Design Features

### Tab Navigation
- **Scrollable horizontal tab bar** with icons
- **Color-coded tabs** for visual categorization
- **Selected tab highlighting** with background color
- **Smooth animations** between tabs

### Tab Colors
| Tab | Color | Icon |
|-----|-------|------|
| Overview | Blue | gauge |
| Forecast | Orange | cloud.sun.fill |
| History | Purple | chart.line.uptrend |
| Travel | Green | car.fill |
| Safety | Red | exclamationmark.triangle.fill |
| Webcams | Cyan | video.fill |
| Social | Pink | person.3.fill |
| Lifts | Indigo | cablecar.fill |

---

## 🔧 Implementation Details

### File Structure
```
/Views/Location/
├── TabbedLocationView.swift          (Main tabbed container)
├── LocationView.swift                 (Legacy view - keep for now)
└── Tabs/
    ├── OverviewTab.swift             ✅ Complete
    ├── ForecastTab.swift             ✅ Complete
    ├── HistoryTab.swift              🚧 Stub
    ├── TravelTab.swift               🚧 Stub
    ├── SafetyTab.swift               🚧 Stub
    ├── WebcamsTab.swift              🚧 Stub
    ├── SocialTab.swift               🚧 Stub
    └── LiftsTab.swift                🚧 Stub
```

### Shared Components
These existing components are reused in the tabs:
- `AtAGlanceCard` - Overview tab
- `RadialDashboard` - Available for future use
- `WebcamsSection` - Webcams tab
- `RoadConditionsSection` - Travel tab
- `LocationMapSection` - Lifts tab

---

## 📱 Usage

### Switch to Tabbed View
Replace `LocationView` with `TabbedLocationView` in navigation:

```swift
// Before
NavigationLink(destination: LocationView(mountain: mountain)) {
    MountainCard(mountain: mountain)
}

// After
NavigationLink(destination: TabbedLocationView(mountain: mountain)) {
    MountainCard(mountain: mountain)
}
```

### Add to Xcode Project
1. Add all `.swift` files in `/Views/Location/Tabs/` to Xcode
2. Ensure `TabbedLocationView.swift` is added
3. Build and run

---

## 🚀 Next Steps

### High Priority
1. **Complete History Tab** - Add charts and comparisons
2. **Complete Safety Tab** - Weather alerts and avalanche data
3. **Complete Social Tab** - Photo grid and check-ins

### Medium Priority
4. **Enhance Travel Tab** - Add trip planning widgets
5. **Add animations** - Tab transitions, loading states
6. **Add pull-to-refresh** - Update data on tab change

### Low Priority
7. **Add settings** - Customize which tabs to show
8. **Add search** - Quick find information across tabs
9. **Add favorites** - Bookmark specific tabs per mountain

---

## 🐛 Known Issues

### Data Issues
1. ⚠️ **Snoqualmie showing 0" snow depth** - Verify SNOTEL data source
   - API Response: `"snowDepth":0`
   - Last year same date: 8"
   - Likely data source issue, not code issue

### Build Status
- ✅ All tab files created
- ✅ Stub implementations prevent build errors
- 🚧 Xcode project integration pending

---

## 📝 API Endpoints Reference

All endpoints follow pattern: `https://shredders-bay.vercel.app/api/mountains/{mountainId}/{endpoint}`

**Available Endpoints**:
- ✅ `conditions` - Current snow/weather data
- ✅ `forecast` - 7-day forecast
- ✅ `hourly` - Hourly forecast
- ✅ `powder-day` - 3-day powder planning
- ✅ `powder-score` - Current powder rating
- ✅ `history` - Historical snow depth
- ✅ `snow-comparison` - Year-over-year comparison
- ✅ `roads` - Road conditions and passes
- ✅ `trip-advice` - Drive time and crowd predictions
- ✅ `alerts` - NOAA weather alerts
- ✅ `safety` - Safety conditions
- ✅ `photos` - User-submitted photos
- ✅ `check-ins` - User trip reports
- ✅ `lifts` - Lift status and trail map
- ✅ `webcams` - Included in mountain detail
- ✅ `all` - Batched endpoint with all data

---

## 🎯 Success Metrics

**User Experience Goals**:
- ✅ Reduce information overload with categorization
- ✅ Quick access to specific information types
- ✅ Visual hierarchy with icons and colors
- ✅ Consistent navigation pattern

**Technical Goals**:
- ✅ Modular tab components
- ✅ Reusable existing components
- ✅ Lazy loading of tab-specific data
- ✅ Smooth animations and transitions

---

**Generated**: January 5, 2026
**Status**: 25% Complete (2/8 tabs fully implemented)
**Next**: Complete History, Safety, and Social tabs
