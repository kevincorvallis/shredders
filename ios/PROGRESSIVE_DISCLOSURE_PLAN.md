# Progressive Disclosure Implementation Plan
## LocationView Interactive Sections

---

## Overview

Transform LocationView sections into an intuitive **two-level interaction pattern**:
- **Tap 1**: Expand inline to show more details
- **Tap 2** (on expanded section): Navigate to dedicated detail view in TabbedLocationView

---

## Current Structure

### LocationView.swift
```
LocationView (ScrollView)
├── View Mode Toggle (At a Glance / Radial)
├── AtAGlanceCard (already has tap-to-expand)
├── LiftLinePredictorCard
├── WebcamsSection
└── "Show More Details" Toggle
    ├── SnowDepthSection
    ├── WeatherConditionsSection
    ├── LocationMapSection
    └── RoadConditionsSection
```

### TabbedLocationView.swift (Detail Views)
```
TabbedLocationView
├── Overview Tab
├── Forecast Tab (Weather details)
├── History Tab (Snow history)
├── Travel Tab (Roads + Trip planning)
├── Safety Tab (Alerts)
├── Webcams Tab
├── Social Tab
└── Lifts Tab (Lift status + map)
```

---

## Implementation Strategy

### 1. **Snow Depth Section**

#### Current State
- Shows: Base depth, Y-o-Y comparison, 24/48/72h cards, inline chart

#### Level 1: Inline Expansion (First Tap)
**Trigger**: Tap section header "Snow Depth"
**State**: `@State private var snowExpanded = false`
**Shows**:
- ✅ Already visible: Base depth + Y-o-Y + 24/48/72h cards
- ✅ Already visible: Historical depth chart (30/14/7/Now)
- **NEW**: Show snow depth thresholds (from API guidelines)
- **NEW**: Show SNOTEL station info + last updated timestamp
- **NEW**: Show SWE (Snow Water Equivalent) data

**Design**:
```swift
VStack(alignment: .leading, spacing: 16) {
    // Header (tappable)
    HStack {
        Image(systemName: "snowflake")
        Text("Snow Depth")
            .font(.headline)
        Spacer()
        Image(systemName: snowExpanded ? "chevron.up" : "chevron.down")
            .foregroundColor(.secondary)
    }
    .contentShape(Rectangle())
    .onTapGesture {
        withAnimation(.spring()) {
            if snowExpanded {
                // Second tap: Navigate to History tab
                navigateToDetailView(.history)
            } else {
                // First tap: Expand inline
                snowExpanded = true
            }
        }
    }

    // Always visible: Current depth
    Text("\(currentDepth)\"").font(.largeTitle)

    if snowExpanded {
        // Expanded content
        VStack {
            // SNOTEL info
            // SWE data
            // Depth thresholds

            // Navigate button
            Button("View Full Snow History →") {
                navigateToDetailView(.history)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
```

#### Level 2: Full Detail View (Second Tap)
**Destination**: `TabbedLocationView(selectedTab: .history)`
**Shows**:
- 30/60/90 day snow depth trends
- SNOTEL station details
- Historical comparisons (this year vs average)
- Snow quality indicators over time

---

### 2. **Weather Conditions Section**

#### Current State
- Shows: Temperature, wind, conditions, powder score banner

#### Level 1: Inline Expansion (First Tap)
**Trigger**: Tap section header "Weather Conditions"
**State**: `@State private var weatherExpanded = false`
**Shows**:
- ✅ Already visible: Temperature + wind + conditions
- **NEW**: Temperature by elevation (base/mid/summit)
- **NEW**: Wind gust data + direction
- **NEW**: Humidity / Dew point
- **NEW**: Today's high/low forecast

**Design**:
```swift
VStack(alignment: .leading, spacing: 16) {
    // Tappable header
    HStack {
        Image(systemName: "cloud.sun")
        Text("Weather Conditions")
        Spacer()
        Image(systemName: weatherExpanded ? "chevron.up" : "chevron.down")
    }
    .onTapGesture {
        withAnimation(.spring()) {
            if weatherExpanded {
                navigateToDetailView(.forecast)
            } else {
                weatherExpanded = true
            }
        }
    }

    // Always visible: Current temp + conditions
    HStack {
        Text("\(temperature)°F")
        Text(conditions)
    }

    if weatherExpanded {
        VStack {
            // Temperature by elevation map (tappable)
            if let tempByElevation = locationData.conditions.temperatureByElevation {
                NavigationLink(destination: TemperatureElevationMapView(...)) {
                    TemperatureElevationPreview(data: tempByElevation)
                }
            }

            // Wind details
            // Humidity/dew point
            // Today's forecast range

            Button("View 7-Day Forecast →") {
                navigateToDetailView(.forecast)
            }
        }
    }
}
```

#### Level 2: Full Detail View (Second Tap)
**Destination**: `TabbedLocationView(selectedTab: .forecast)`
**Shows**:
- 7-day detailed forecast
- Hourly forecast
- Powder day planner
- Weather alerts

---

### 3. **Lift Status Section**

#### Current State
- Shows: % open, lifts count, runs count, status badge

#### Level 1: Inline Expansion (First Tap)
**Trigger**: Tap "Lifts" in AtAGlanceCard (already expandable)
**Enhancement**: Add more detail to expanded state
**Shows**:
- ✅ Already visible: % open, lifts/runs count
- **NEW**: Individual lift status breakdown (if available from API)
- **NEW**: Terrain status (Beginner/Intermediate/Advanced/Expert)
- **NEW**: Last updated timestamp

**Design** (enhance AtAGlanceCard):
```swift
case .lifts:
    VStack(alignment: .leading, spacing: 12) {
        // Current summary
        HStack {
            Text("\(percentOpen)%")
            Text("Open")
        }

        // NEW: Detailed breakdown
        if let liftStatus = locationData.conditions.liftStatus {
            // Lifts breakdown
            // Terrain breakdown
            // Last updated
        }

        // Navigate button
        Button("View Lift Map & Details →") {
            navigateToDetailView(.lifts)
        }
        .padding(.top, 8)
    }
```

#### Level 2: Full Detail View (Second Tap)
**Destination**: `TabbedLocationView(selectedTab: .lifts)`
**Shows**:
- Interactive lift map with GeoJSON overlay
- Individual lift status
- Terrain park status
- Historical lift status data

---

### 4. **Road Conditions Section**

#### Current State
- Shows: Pass names, road condition, travel advisories

#### Level 1: Inline Expansion (First Tap)
**Trigger**: Tap section header "Road Conditions"
**State**: `@State private var roadsExpanded = false`
**Shows**:
- ✅ Already visible: Pass names + status
- **NEW**: Restrictions per direction (eastbound/westbound)
- **NEW**: Temperature at pass elevation
- **NEW**: Traction advisory details
- **NEW**: Last updated timestamp

**Design**:
```swift
VStack(alignment: .leading, spacing: 16) {
    HStack {
        Image(systemName: "road.lanes")
        Text("Road Conditions")
        Spacer()
        Image(systemName: roadsExpanded ? "chevron.up" : "chevron.down")
    }
    .onTapGesture {
        withAnimation(.spring()) {
            if roadsExpanded {
                navigateToDetailView(.travel)
            } else {
                roadsExpanded = true
            }
        }
    }

    // Always visible: Pass status
    ForEach(passes) { pass in
        PassStatusBadge(pass: pass)
    }

    if roadsExpanded {
        VStack {
            ForEach(passes) { pass in
                // Directional restrictions
                // Temperature data
                // Advisory details
            }

            Button("View Trip Planning →") {
                navigateToDetailView(.travel)
            }
        }
    }
}
```

#### Level 2: Full Detail View (Second Tap)
**Destination**: `TabbedLocationView(selectedTab: .travel)`
**Shows**:
- Full trip advice
- Suggested departure times
- Crowd predictions
- Road webcams

---

### 5. **Webcams Section**

#### Current State (Already Good!)
- Horizontal scroll gallery
- Tap image → Full screen sheet

#### Enhancement: Add Third Level
**Level 1**: Horizontal scroll (current)
**Level 2**: Tap image → Full screen sheet (current)
**Level 3**: Add button in sheet → Navigate to Webcams tab

**Design** (enhance WebcamExpandedView):
```swift
VStack {
    // Current: Image + name + info

    // NEW: Navigation button
    Button("Browse All Webcams →") {
        dismiss()
        navigateToDetailView(.webcams)
    }
}
```

---

## Technical Implementation

### 1. Add Navigation Support to LocationView

```swift
// Add @State for navigation
@State private var navigateToTab: TabbedLocationView.Tab?

// Add NavigationLink (invisible)
.background(
    NavigationLink(
        tag: navigateToTab,
        selection: $navigateToTab
    ) {
        if let tab = navigateToTab {
            TabbedLocationView(
                mountain: mountain,
                initialTab: tab
            )
        }
    } label: {
        EmptyView()
    }
)

// Navigation helper
private func navigateToDetailView(_ tab: TabbedLocationView.Tab) {
    navigateToTab = tab
}
```

### 2. Modify TabbedLocationView to Accept Initial Tab

```swift
struct TabbedLocationView: View {
    let mountain: Mountain
    let initialTab: Tab?  // NEW
    @StateObject private var viewModel: LocationViewModel
    @State private var selectedTab: Tab

    init(mountain: Mountain, initialTab: Tab? = nil) {
        self.mountain = mountain
        self.initialTab = initialTab
        _viewModel = StateObject(wrappedValue: LocationViewModel(mountain: mountain))
        _selectedTab = State(initialValue: initialTab ?? .overview)
    }

    // ... rest of implementation
}
```

### 3. Add Expansion States to Sections

Each section component needs:
```swift
@State private var isExpanded = false

var body: some View {
    VStack {
        // Tappable header
        sectionHeader
            .onTapGesture {
                handleTap()
            }

        // Always-visible content
        summaryContent

        // Expanded content
        if isExpanded {
            expandedContent
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

private func handleTap() {
    withAnimation(.spring()) {
        if isExpanded {
            // Second tap: Navigate
            onNavigate?()
        } else {
            // First tap: Expand
            isExpanded = true
        }
    }
}
```

---

## Data Mapping

### Snow Section → History Tab
**Data Flow**:
```
locationData.conditions.snowDepth/snowfall24h/48h/7d
    ↓
snowComparison (Y-o-Y data)
    ↓
SnowDepthSection (inline expansion)
    ↓
HistoryTab (full detail)
```

**History Tab Should Show**:
- SNOTEL station data (30/60/90 day trends)
- Year-over-year comparisons
- Base depth quality indicators
- Snow depth vs average charts

### Weather Section → Forecast Tab
**Data Flow**:
```
locationData.conditions.temperature/wind/temperatureByElevation
    ↓
WeatherConditionsSection (inline expansion)
    ↓
locationData.forecast[] (7-day array)
    ↓
ForecastTab (full detail)
```

**Forecast Tab Already Shows**:
- 7-day forecast cards
- Powder day planner (3-day outlook)
- Weather alerts

### Lifts Section → Lifts Tab
**Data Flow**:
```
locationData.conditions.liftStatus
    ↓
AtAGlanceCard (lifts expansion)
    ↓
liftData: LiftGeoJSON (from API)
    ↓
LiftsTab (full detail)
```

**Lifts Tab Should Show**:
- Interactive map with lift overlay
- Individual lift status
- Terrain breakdown
- Lift wait time predictions

### Roads Section → Travel Tab
**Data Flow**:
```
locationData.roads.passes[]
    ↓
RoadConditionsSection (inline expansion)
    ↓
locationData.tripAdvice
    ↓
TravelTab (full detail)
```

**Travel Tab Already Shows**:
- Trip advice cards
- Suggested departure times
- Crowd predictions

---

## Implementation Order

### Phase 1: Navigation Infrastructure
1. ✅ Modify TabbedLocationView to accept `initialTab` parameter
2. ✅ Add navigation state to LocationView
3. ✅ Add invisible NavigationLink
4. ✅ Create `navigateToDetailView(_ tab:)` helper

### Phase 2: Snow Section
1. ✅ Add `@State private var snowExpanded` to SnowDepthSection
2. ✅ Make header tappable with tap gesture
3. ✅ Add expanded content (SNOTEL info, SWE, thresholds)
4. ✅ Add "View Full History" button
5. ✅ Wire up navigation to History tab

### Phase 3: Weather Section
1. ✅ Add `@State private var weatherExpanded` to WeatherConditionsSection
2. ✅ Make header tappable
3. ✅ Add expanded content (temp by elevation, humidity, wind details)
4. ✅ Add TemperatureElevationMapView link (already exists!)
5. ✅ Add "View 7-Day Forecast" button
6. ✅ Wire up navigation to Forecast tab

### Phase 4: Lifts Section
1. ✅ Enhance AtAGlanceCard lift expansion
2. ✅ Add lift status breakdown
3. ✅ Add terrain breakdown
4. ✅ Add "View Lift Map" button
5. ✅ Wire up navigation to Lifts tab

### Phase 5: Roads Section
1. ✅ Add `@State private var roadsExpanded` to RoadConditionsSection
2. ✅ Make header tappable
3. ✅ Add expanded content (directional restrictions, temps)
4. ✅ Add "View Trip Planning" button
5. ✅ Wire up navigation to Travel tab

### Phase 6: Polish & Testing
1. ✅ Add haptic feedback on taps
2. ✅ Ensure smooth animations
3. ✅ Test navigation flow
4. ✅ Add visual indicators (chevrons, highlight states)
5. ✅ Test with missing data scenarios

---

## Visual Design Patterns

### Header Style (Tappable)
```swift
HStack {
    Image(systemName: icon)
        .foregroundColor(.blue)
    Text(title)
        .font(.headline)
    Spacer()
    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
        .foregroundColor(.secondary)
}
.contentShape(Rectangle())
.onTapGesture {
    handleTap()
}
```

### Expanded Content Style
```swift
VStack(spacing: 12) {
    // Expanded metrics/details
    expandedMetrics

    Divider()
        .padding(.vertical, 4)

    // Navigation button
    Button {
        onNavigate()
    } label: {
        HStack {
            Text("View Full Details")
                .fontWeight(.semibold)
            Spacer()
            Image(systemName: "arrow.right")
        }
        .foregroundColor(.blue)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}
.transition(.opacity.combined(with: .move(edge: .top)))
```

### Haptic Feedback
```swift
private func handleTap() {
    let impact = UIImpactFeedbackGenerator(style: .light)
    impact.impactOccurred()

    withAnimation(.spring()) {
        // ... tap logic
    }
}
```

---

## Expected User Experience

### Example: Snow Depth Interaction

**State 1**: Collapsed
```
┌─────────────────────────────┐
│ ❄️ Snow Depth          ⌄   │
│ 156"                        │
└─────────────────────────────┘
```

**State 2**: First Tap → Expanded
```
┌─────────────────────────────┐
│ ❄️ Snow Depth          ⌃   │
│ 156"                        │
│                             │
│ 📊 SNOTEL: Wells Creek      │
│ 💧 SWE: 62"                 │
│ 📈 Above average for date   │
│                             │
│ ┌─────────────────────────┐ │
│ │ View Full Snow History → │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

**State 3**: Second Tap → Navigate to TabbedLocationView (History Tab)
```
┌─────────────────────────────┐
│ Crystal Mountain            │
├─────────────────────────────┤
│ Overview Forecast [History] │
│ Travel Safety Webcams ...   │
├─────────────────────────────┤
│                             │
│ 📊 30-Day Snow Depth Trend  │
│ ▁▂▃▄▅▆▇███████████▇▆▅      │
│                             │
│ 📊 Year-over-Year Compare   │
│ 2026: ████████░░░░          │
│ 2025: ██████████░░          │
│                             │
└─────────────────────────────┘
```

---

## Files to Modify

### Core Files
1. `/Views/Location/LocationView.swift` - Add navigation state + links
2. `/Views/Location/TabbedLocationView.swift` - Add initialTab parameter

### Section Components
3. `/Views/Location/SnowDepthSection.swift` - Add expansion + navigation
4. `/Views/Location/WeatherConditionsSection.swift` - Add expansion + navigation
5. `/Views/Components/AtAGlanceCard.swift` - Enhance lifts expansion + navigation
6. `/Views/Location/RoadConditionsSection.swift` - Add expansion + navigation

### Tab Views (Ensure Complete)
7. `/Views/Location/Tabs/HistoryTab.swift` - Implement full snow history
8. `/Views/Location/Tabs/ForecastTab.swift` - Already complete ✅
9. `/Views/Location/Tabs/LiftsTab.swift` - Enhance with lift map
10. `/Views/Location/Tabs/TravelTab.swift` - Already complete ✅

---

## Success Metrics

✅ **User can discover details progressively**:
- Tap once: See more inline
- Tap twice: Navigate to full view

✅ **No information overload**:
- Default state shows essential info
- Advanced details hidden behind interaction

✅ **Clear navigation path**:
- Visual indicators (chevrons)
- "View Full Details" buttons
- Smooth animations

✅ **Consistent pattern**:
- All sections follow same interaction model
- Users learn pattern once, apply everywhere
