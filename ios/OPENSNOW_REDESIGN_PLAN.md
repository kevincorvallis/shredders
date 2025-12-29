# OpenSnow-Inspired Navigation Redesign

## Current Issues
- Map takes up too much vertical space (35%)
- Forecast is buried at bottom (low priority)
- Too many sections compete for attention
- Unclear information hierarchy

## OpenSnow Pattern Analysis

### OpenSnow's Approach
1. **Mountain Selector** - Simple dropdown/picker at top
2. **Forecast Cards** - HERO SECTION (next 7-10 days)
   - Large cards showing snowfall amounts
   - Visual snow icons/graphics
   - Temperature, wind
3. **Current Conditions** - Below forecast
4. **Charts/History** - Further down
5. **Bottom Tabs**: Home | Maps | Alerts | More

### Key UX Principles
- **Forecast = Priority #1** - Users want to know "when to go"
- **Current conditions = Secondary** - Less important than upcoming snow
- **Map = Separate feature** - Not on main screen
- **Clean, scrollable** - One clear vertical flow

## Proposed Redesign

### Option 1: Forecast-First Tab (Recommended)

**Tab Structure (4 tabs):**
1. **Home** (forecast-first) - Replaces Discover
2. **Mountains** (map + list) - Separate tab
3. **Chat** - Keep as-is
4. **Patrol** - Keep as-is

**Home Tab Layout:**
```
┌─────────────────────────┐
│ Mt. Baker ▼             │ ← Mountain picker (compact)
├─────────────────────────┤
│                         │
│  FORECAST (Hero)        │ ← Next 7 days, large cards
│  ┌─────┬─────┬─────┐   │   with snow amounts
│  │ Mon │ Tue │ Wed │   │
│  │ 8"  │ 3"  │ 0"  │   │
│  └─────┴─────┴─────┘   │
│                         │
├─────────────────────────┤
│  Powder Score: 7/10     │ ← Gauge
├─────────────────────────┤
│  Current Conditions     │ ← Snow depth, temp, etc.
├─────────────────────────┤
│  Road Conditions        │ ← I-90 status
├─────────────────────────┤
│  Trip Advice            │ ← AI recommendations
└─────────────────────────┘
```

**Mountains Tab:**
- Interactive map (larger, 50% screen)
- Mountain list below
- Tap to switch selected mountain

### Option 2: Unified with Forecast Priority

Keep Discover tab but reorder:
1. Mountain picker (compact, no giant map)
2. **7-Day Forecast** (large, prominent)
3. Powder Score
4. Current Conditions
5. Road Conditions
6. Small map thumbnail (tap to expand)

## Recommended Implementation: Option 1

### New Home Tab Features

**Mountain Selector:**
- Compact button at top
- Shows current mountain name + chevron
- Taps opens sheet with list (no map needed here)

**Forecast Section (Hero):**
- Horizontal scrollable cards (7 days)
- Each card shows:
  - Day name
  - Snow icon + amount (8", 3", etc.)
  - High/Low temp
  - Wind speed
- Visually prominent with icons/colors

**Powder Score:**
- Gauge visualization
- Current score + verdict
- Tap for details

**Current Conditions Card:**
- Snow depth, temperature, wind
- Last updated timestamp
- Compact presentation

**Road Conditions:**
- I-90 status with cameras
- Tap to see all webcams

**Bottom Section:**
- Quick actions: View All Forecast, Webcams, Patrol
- Weather.gov links

### Benefits
✅ Forecast immediately visible (no scrolling)
✅ Matches user mental model (OpenSnow users)
✅ Clearer information hierarchy
✅ Map separated (not competing for attention)
✅ Faster to scan and use

## Implementation Steps

1. Create `HomeView.swift` (forecast-first layout)
2. Keep `MountainMapView.swift` as separate Mountains tab
3. Update `ContentView.swift` tabs:
   - Home (homeView) - forecast priority
   - Mountains (map + list)
   - Chat
   - Patrol
4. Add horizontal forecast card component
5. Compact mountain picker component

## Questions for User

1. Do you want forecast cards horizontal (swipe) or vertical (scroll)?
2. Keep 4 tabs (Home, Mountains, Chat, Patrol) or go back to 5?
3. Where should Forecast detail screen go? (separate tab or modal from Home?)
