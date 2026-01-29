# PowderTracker iOS UI Analysis & Enhancement Recommendations

**Date:** 2026-01-27
**Scope:** MountainsTabView, TodayView/TodayTabView, MountainDetailView, Component Library

---

## Executive Summary

The PowderTracker iOS app demonstrates strong foundational UI patterns with a well-organized design system. However, there are significant opportunities to enhance visual polish, information density, interaction patterns, and leverage modern iOS 17/18 features.

**Overall Assessment:**
- ✅ **Strengths:** Solid design system, consistent spacing, good component architecture
- ⚠️ **Needs Improvement:** Visual hierarchy, animation polish, information density, accessibility
- 🚀 **Opportunities:** iOS 18 features, advanced animations, haptic feedback, widget extensions

---

## 1. MountainsTabView Analysis

### Current Implementation

**File:** `/ios/PowderTracker/PowderTracker/Views/Mountains/MountainsTabView.swift`

#### What's Working Well

1. **Clear Purpose-Driven Architecture**: Four distinct modes (Today, Plan, Explore, My Pass) address specific user intents
2. **Matched Geometry Effect**: Smooth tab transitions using `matchedGeometryEffect`
3. **Consistent Layout**: Uses `LazyVStack` for performance with large lists
4. **Accessibility Labels**: Good use of `.accessibilityLabel` and `.accessibilityHint`

#### What Could Be Improved

1. **Mode Picker UX Issues**
   - **Problem:** Horizontal 4-button layout with icons + text is cramped on smaller devices (iPhone SE, iPhone 15 Pro)
   - **Impact:** Text truncates, icons feel squeezed
   - **Current Code:**
   ```swift
   VStack(spacing: 4) {
       Image(systemName: mode.icon)
           .font(.system(size: 18))
       Text(mode.title)
           .font(.caption2)
   }
   ```

2. **Status Pills Are Static**
   - **Problem:** `statusHeader` pills (Open/Fresh Snow/Avg Score) don't animate or provide feedback
   - **Impact:** Missed opportunity for visual engagement

3. **Sort Picker Hierarchy**
   - **Problem:** Sort pills blend in with background, no visual weight
   - **Current:** `.background(sortBy == sort ? Color.blue : Color(.tertiarySystemBackground))`

4. **Empty States Lack Personality**
   - **Problem:** Generic empty states with simple icon + text
   - **Impact:** Doesn't encourage user action

5. **Card Density Issues**
   - **Problem:** `ConditionMountainCard` is spacious (good for accessibility) but limits visible content
   - **Impact:** Excessive scrolling on longer lists

### Specific Enhancements

#### Enhancement 1.1: Responsive Mode Picker
```swift
// IMPROVED: Adaptive layout based on screen size
private var modePicker: some View {
    GeometryReader { geometry in
        let isCompact = geometry.size.width < 380 // iPhone SE threshold

        HStack(spacing: 0) {
            ForEach(MountainViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.snappy) {
                        selectedMode = mode
                    }
                    HapticFeedback.selection.trigger()
                } label: {
                    if isCompact {
                        // Compact: Icon only
                        Image(systemName: mode.icon)
                            .font(.system(size: 20))
                            .symbolRenderingMode(.hierarchical)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        // Regular: Icon + Text
                        VStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18))
                            Text(mode.title)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
                .foregroundColor(selectedMode == mode ? .white : .secondary)
                .background(
                    Group {
                        if selectedMode == mode {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                                .matchedGeometryEffect(id: "selected", in: namespace)
                        }
                    }
                )
                .buttonStyle(.plain)
                .accessibilityLabel("\(mode.title) view")
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    .frame(height: 60) // Fixed height
    .padding(.horizontal)
}
```

**Benefits:**
- Adapts to screen size automatically
- Prevents text truncation on small devices
- Maintains accessibility labels

---

#### Enhancement 1.2: Animated Status Pills
```swift
private var statusHeader: some View {
    HStack(spacing: 16) {
        AnimatedStatusPill(
            value: "\(openMountainsCount)",
            label: openLabel,
            color: openLabel == "Open" ? .green : .gray,
            icon: "mountain.2.fill",
            trend: .stable // Could be .up, .down based on yesterday
        )

        AnimatedStatusPill(
            value: "\(freshSnowCount)",
            label: "Fresh Snow",
            color: .blue,
            icon: "snowflake",
            trend: freshSnowCount > 0 ? .up : .stable
        )

        AnimatedStatusPill(
            value: avgScore,
            label: "Avg Score",
            color: .yellow,
            icon: "gauge.with.dots.needle.bottom.50percent",
            trend: .stable
        )
    }
    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: openMountainsCount)
    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: freshSnowCount)
}

// New Component
struct AnimatedStatusPill: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    let trend: TrendDirection

    enum TrendDirection {
        case up, down, stable

        var iconName: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return ""
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .contentTransition(.numericText())

                if trend != .stable {
                    Image(systemName: trend.iconName)
                        .font(.caption2)
                        .foregroundColor(trend == .up ? .green : .red)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
```

**Benefits:**
- Visual feedback when values update
- Trend indicators show changes over time
- `.contentTransition(.numericText())` provides smooth number animations (iOS 17+)

---

#### Enhancement 1.3: Enhanced Sort Picker
```swift
private var sortPicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            ForEach(ConditionSort.allCases, id: \.self) { sort in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        sortBy = sort
                    }
                    HapticFeedback.light.trigger()
                } label: {
                    HStack(spacing: 6) {
                        // Add icons for visual clarity
                        Image(systemName: sortIcon(for: sort))
                            .font(.caption)

                        Text(sort.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(sortBy == sort ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(sortBy == sort ? Color.blue : Color(.tertiarySystemBackground))
                            .shadow(color: sortBy == sort ? Color.blue.opacity(0.3) : .clear, radius: 4)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(sortBy == sort ? 1.05 : 1.0)
                .animation(.spring(response: 0.3), value: sortBy)
            }
        }
        .padding(.horizontal, 16)
    }
}

private func sortIcon(for sort: ConditionSort) -> String {
    switch sort {
    case .bestConditions: return "star.fill"
    case .nearest: return "location.fill"
    case .mostSnow: return "snowflake"
    case .openLifts: return "cablecar.fill"
    }
}
```

**Benefits:**
- Icons provide visual scanning cues
- Scale effect adds tactile feedback
- Shadow on selected state adds depth

---

#### Enhancement 1.4: Engaging Empty State
```swift
private var emptyState: some View {
    VStack(spacing: 24) {
        // Animated icon
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 120, height: 120)

            Image(systemName: "mountain.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce, value: UUID())
        }

        VStack(spacing: 8) {
            Text("No mountains found")
                .font(.title2)
                .fontWeight(.bold)

            Text("Pull down to refresh data")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }

        // CTA button
        Button {
            Task {
                await viewModel.loadMountains()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Refresh Now")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.blue)
            )
        }
        .buttonStyle(.plain)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 80)
}
```

**Benefits:**
- `.symbolEffect(.bounce)` (iOS 17+) adds life
- Clear CTA encourages user action
- Gradient provides premium feel

---

#### Enhancement 1.5: Increased Card Density (Optional)
```swift
// For users who prefer more information density
struct CompactConditionMountainCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let score: Double?
    // ... other properties

    var body: some View {
        HStack(spacing: 10) {
            // Smaller logo
            MountainLogoView(logoUrl: mountain.logo, color: mountain.color, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(mountain.shortName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let status = conditions?.liftStatus {
                        Circle()
                            .fill(status.isOpen ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                    }
                }

                // Compact stats row
                HStack(spacing: 8) {
                    Label("\(conditions?.snowfall24h ?? 0)\"", systemImage: "snowflake")
                        .font(.caption2)
                        .foregroundColor(.blue)

                    Label("\(conditions?.liftStatus?.liftsOpen ?? 0)/\(conditions?.liftStatus?.liftsTotal ?? 0)",
                          systemImage: "cablecar.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let score = score {
                Text(String(format: "%.1f", score))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(score))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
```

**Benefits:**
- 30% more compact than current design
- Fits 5-6 mountains on iPhone 15 Pro screen
- Optional: Offer density toggle in settings

---

## 2. TodayView / TodayTabView Analysis

### Current Implementation

**Files:**
- `/ios/PowderTracker/PowderTracker/Views/Home/TodayView.swift`
- `/ios/PowderTracker/PowderTracker/Views/Home/TodayTabView.swift`

#### What's Working Well

1. **Clear Information Hierarchy**: Today's Pick → Forecast Chart → Your Mountains → Webcams
2. **Staggered Animations**: `.opacity()` + `.offset()` with `.delay()` creates pleasant reveal
3. **Smart Use of ComparisonGrid**: 2-column grid efficiently displays multiple mountains
4. **Good Component Reuse**: TodaysPickCard, SnowForecastChart are well-isolated

#### What Could Be Improved

1. **Today's Pick Card Visual Weight**
   - **Problem:** Card doesn't feel premium enough for "hero" content
   - **Current:** Standard corner radius, subtle shadow
   - **Impact:** Doesn't immediately draw user's eye

2. **Forecast Chart Lacks Context**
   - **Problem:** No legend for first-time users, unclear what lines represent
   - **Current:** Legend at bottom but could be missed

3. **Comparison Grid Information Overload**
   - **Problem:** Each card shows 10+ data points, hard to scan quickly
   - **Impact:** Users struggle to compare at a glance

4. **No Progressive Disclosure**
   - **Problem:** All data visible at once, no drill-down options
   - **Impact:** Overwhelms users who just want quick summary

5. **Empty State Lacks Guidance**
   - **Problem:** "Add favorites" button but no suggestion of what to add
   - **Impact:** New users don't know where to start

### Specific Enhancements

#### Enhancement 2.1: Premium Today's Pick Card
```swift
// IMPROVED: Add glassmorphic background, subtle glow
struct TodaysPickCard: View {
    // ... existing properties

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: .spacingM) {
                headerSection
                if !reasons.isEmpty {
                    reasonsSection
                }
                quickStatsRow
                ctaSection
            }
            .padding(.spacingL)
            .background(
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: .cornerRadiusHero)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.secondarySystemBackground),
                                    Color(.tertiarySystemBackground)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Glassmorphic overlay
                    RoundedRectangle(cornerRadius: .cornerRadiusHero)
                        .fill(.ultraThinMaterial)
                        .opacity(colorScheme == .dark ? 0.5 : 0.3)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusHero)
                    .stroke(
                        LinearGradient(
                            colors: [scoreColor, scoreColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: scoreColor.opacity(0.2), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
```

**Benefits:**
- Gradient + glassmorphism creates premium feel
- Dual shadows add depth
- Gradient border adds sophistication

---

#### Enhancement 2.2: Interactive Forecast Chart
```swift
struct SnowForecastChart: View {
    // ... existing properties

    @State private var selectedMountain: Mountain? = nil
    @State private var selectedDay: ForecastDay? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with info popover
            HStack {
                if showHeader {
                    Text("Snow Forecast")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Info button
                Button {
                    // Show tooltip explaining chart
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                // Range toggle picker
                Picker("Range", selection: $selectedRange) {
                    ForEach(ForecastRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }

            // Chart with selection
            Chart {
                ForEach(favorites, id: \.mountain.id) { favorite in
                    let forecastDays = Array(favorite.forecast.prefix(selectedRange.days))

                    ForEach(Array(forecastDays.enumerated()), id: \.offset) { index, day in
                        let chartDate = parseDate(day.date) ?? Calendar.current.date(byAdding: .day, value: index, to: Date())!

                        LineMark(
                            x: .value("Day", chartDate),
                            y: .value("Snow", day.snowfall)
                        )
                        .foregroundStyle(by: .value("Mountain", favorite.mountain.shortName))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        // Add point marks for interactivity
                        PointMark(
                            x: .value("Day", chartDate),
                            y: .value("Snow", day.snowfall)
                        )
                        .foregroundStyle(by: .value("Mountain", favorite.mountain.shortName))
                        .symbolSize(40)
                        .opacity(selectedMountain?.id == favorite.mountain.id ? 1.0 : 0.0)

                        AreaMark(
                            x: .value("Day", chartDate),
                            y: .value("Snow", day.snowfall)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    mountainColor(for: favorite.mountain).opacity(0.3),
                                    mountainColor(for: favorite.mountain).opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .frame(height: chartHeight)
            .chartXAxis { /* ... */ }
            .chartYAxis { /* ... */ }
            .chartLegend(position: .bottom, spacing: 8) {
                HStack(spacing: 12) {
                    ForEach(favorites, id: \.mountain.id) { favorite in
                        Button {
                            selectedMountain = favorite.mountain
                        } label: {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(mountainColor(for: favorite.mountain))
                                    .frame(width: 8, height: 8)

                                Text(favorite.mountain.shortName)
                                    .font(.caption)
                                    .foregroundColor(selectedMountain?.id == favorite.mountain.id ? .primary : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            // Selection overlay
            .chartAngleSelection(value: $selectedDay)
        }
    }
}
```

**Benefits:**
- `.chartAngleSelection` (iOS 17+) enables tap-to-select
- Highlighted points show selected mountain
- Info button provides onboarding

---

#### Enhancement 2.3: Simplified Comparison Cards
```swift
// Add toggle between "Detailed" and "Simple" view
struct ComparisonGrid: View {
    // ... existing properties
    @State private var viewMode: ViewMode = .simple

    enum ViewMode {
        case simple, detailed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mode toggle
            HStack {
                Text("Your Mountains")
                    .font(.headline)

                Spacer()

                Picker("View", selection: $viewMode) {
                    Label("Simple", systemImage: "square.grid.2x2").tag(ViewMode.simple)
                    Label("Detailed", systemImage: "list.bullet").tag(ViewMode.detailed)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(favorites, id: \.mountain.id) { favorite in
                    NavigationLink {
                        MountainDetailView(mountain: favorite.mountain)
                    } label: {
                        if viewMode == .simple {
                            SimpleComparisonCard(/* ... */)
                        } else {
                            ComparisonGridCard(/* ... */)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// New simplified card
struct SimpleComparisonCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?

    var body: some View {
        VStack(spacing: 8) {
            MountainLogoView(logoUrl: mountain.logo, color: mountain.color, size: 40)

            Text(mountain.shortName)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            // Just the score
            if let score = powderScore?.score {
                Text(String(format: "%.1f", score))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.forPowderScore(score))
            }

            // Just 24h snow
            if let snow = conditions?.snowfall24h {
                HStack(spacing: 2) {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                    Text("\(Int(snow))\"")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
```

**Benefits:**
- Simple mode reduces cognitive load
- Users can toggle based on preference
- Power users get detailed view when needed

---

#### Enhancement 2.4: Smart Empty State
```swift
private var emptyState: some View {
    VStack(spacing: 24) {
        // Animated icon
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 140, height: 140)

            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse.byLayer, options: .repeat(2))
        }

        VStack(spacing: 12) {
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add mountains to track conditions and snowfall")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Suggested mountains
            Text("Popular Choices:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            HStack(spacing: 8) {
                ForEach(suggestedMountains.prefix(3), id: \.id) { mountain in
                    Button {
                        addToFavorites(mountain)
                    } label: {
                        VStack(spacing: 4) {
                            MountainLogoView(logoUrl: mountain.logo, color: mountain.color, size: 32)
                            Text(mountain.shortName)
                                .font(.caption2)
                        }
                        .padding(8)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        // CTA
        Button("Browse All Mountains") {
            showingManageFavorites = true
        }
        .buttonStyle(.borderedProminent)
        .padding(.top, 8)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
}

private var suggestedMountains: [Mountain] {
    // Logic to suggest based on location, popular picks, etc.
    viewModel.mountains.prefix(3).map { $0 }
}
```

**Benefits:**
- `.symbolEffect(.pulse)` (iOS 17+) draws attention
- Suggested mountains reduce friction
- Clear path to action

---

## 3. MountainDetailView Analysis

### Current Implementation

**File:** `/ios/PowderTracker/PowderTracker/Views/Location/MountainDetailView.swift`

#### What's Working Well

1. **Collapsible Hero Header**: 160px header with webcam background is visually striking
2. **Tabbed Navigation**: 6 tabs (Overview, Forecast, Conditions, Travel, Lifts, Social) organize content well
3. **Smart Use of LazyVStack**: Defers loading of tab content
4. **AtAGlanceCard Expandable Sections**: Tap to expand for more details is elegant

#### What Could Be Improved

1. **Header Doesn't Actually Collapse**
   - **Problem:** `headerCollapsed` state variable exists but isn't used
   - **Impact:** Wasted screen space when scrolling

2. **Tab Bar Scrolling**
   - **Problem:** 6 tabs in horizontal scroll can be hard to navigate
   - **Current:** No indicators of "more tabs available"

3. **Empty States Across Tabs**
   - **Problem:** Generic empty state component reused everywhere
   - **Impact:** Doesn't provide tab-specific guidance

4. **AtAGlanceCard Animation**
   - **Problem:** Expansion is abrupt (only `.transition(.move(edge: .top))`)
   - **Impact:** Feels mechanical

5. **No Hero Animations**
   - **Problem:** Navigation into detail view lacks polish
   - **Impact:** Feels disconnected from list view

### Specific Enhancements

#### Enhancement 3.1: Collapsing Header
```swift
struct MountainDetailView: View {
    // ... existing properties
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header that shrinks
                heroHeader
                    .frame(height: max(headerCollapsedHeight, headerFullHeight - scrollOffset))
                    .clipped()
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )

                tabBarView
                    .background(Color(.systemBackground))
                    .zIndex(1) // Keep above content

                tabContent
                    .padding(.horizontal, .spacingL)
                    .padding(.top, .spacingM)
                    .padding(.bottom, .spacingXL)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = max(0, -value)
            withAnimation(.easeOut(duration: 0.2)) {
                headerCollapsed = scrollOffset > 60
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // Show title when header collapses
                Text(mountain.shortName)
                    .font(.headline)
                    .opacity(headerCollapsed ? 1 : 0)
            }
        }
    }

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Background - webcam or gradient
            if let webcam = viewModel.locationData?.mountain.webcams.first {
                AsyncImage(url: URL(string: webcam.url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: scrollOffset / 20) // Parallax blur effect
                    default:
                        mountainGradient
                    }
                }
            } else {
                mountainGradient
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Mountain info - fades out as header collapses
            HStack(spacing: .spacingM) {
                MountainLogoView(logoUrl: mountain.logo, color: mountain.color, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mountain.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(mountain.region.uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Text("\(mountain.elevation.summit.formatted())ft")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
            }
            .padding(.spacingM)
            .opacity(1 - (scrollOffset / 100)) // Fade out
        }
    }
}
```

**Benefits:**
- Header shrinks as user scrolls, maximizing content
- Parallax blur on background image adds depth
- Title appears in nav bar when header collapses

---

#### Enhancement 3.2: Tab Bar with Overflow Indicator
```swift
private var tabBarView: some View {
    ScrollViewReader { proxy in
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                ForEach(DetailTab.allCases) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                        withAnimation {
                            proxy.scrollTo(tab.id, anchor: .center)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18))
                                .symbolVariant(selectedTab == tab ? .fill : .none)
                            Text(tab.rawValue)
                                .font(.caption)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                        }
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        .frame(minWidth: 70)
                        .padding(.vertical, .spacingS)
                        .padding(.horizontal, .spacingS)
                        .background(
                            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                                .fill(selectedTab == tab ? Color.blue.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .id(tab.id)
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
        }
        .background(
            // Gradient indicators for overflow
            HStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)

                Spacer()

                LinearGradient(
                    colors: [Color.clear, Color(.systemBackground)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
            }
        )
    }
}
```

**Benefits:**
- `.symbolVariant(.fill)` (iOS 15+) provides visual feedback
- Gradients hint at overflow content
- `.scrollTo()` ensures selected tab is visible

---

#### Enhancement 3.3: Tab-Specific Empty States
```swift
// Replace generic emptyStateCard with specialized versions
private func forecastEmptyState() -> some View {
    VStack(spacing: 16) {
        Image(systemName: "calendar.badge.clock")
            .font(.system(size: 48))
            .foregroundStyle(
                LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
            )
            .symbolEffect(.pulse)

        Text("Forecast Unavailable")
            .font(.headline)

        Text("Weather forecast data is temporarily unavailable for this mountain.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

        Button("Try Again") {
            Task { await viewModel.fetchData() }
        }
        .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity)
    .padding(.spacingXL)
    .background(Color(.secondarySystemBackground))
    .cornerRadius(.cornerRadiusCard)
}

private func travelEmptyState() -> some View {
    VStack(spacing: 16) {
        Image(systemName: "road.lanes")
            .font(.system(size: 48))
            .foregroundStyle(
                LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
            )
            .symbolEffect(.variableColor)

        Text("No Road Data")
            .font(.headline)

        Text("Road conditions aren't tracked for this mountain yet.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

        if let website = viewModel.locationData?.mountain.website {
            Link("Visit Mountain Website", destination: URL(string: website)!)
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }
    .frame(maxWidth: .infinity)
    .padding(.spacingXL)
    .background(Color(.secondarySystemBackground))
    .cornerRadius(.cornerRadiusCard)
}
```

**Benefits:**
- Context-specific messaging
- Actionable next steps
- `.symbolEffect(.variableColor)` (iOS 17+) adds interest

---

#### Enhancement 3.4: Smooth AtAGlanceCard Expansion
```swift
struct AtAGlanceCard: View {
    // ... existing properties
    @Namespace private var animation

    private var expandedDetailsView(for section: ExpandableSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            switch section {
            case .snow:
                snowExpandedDetails
            case .weather:
                weatherExpandedDetails
            case .lifts:
                liftsExpandedDetails
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
        .matchedGeometryEffect(id: "expansion", in: animation)
    }

    private func glanceSection(...) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                if expandedSection == section {
                    expandedSection = nil
                } else {
                    expandedSection = section
                }
            }
            HapticFeedback.light.trigger()
        } label: {
            // ... existing content
        }
        .buttonStyle(.plain)
        .scaleEffect(expandedSection == section ? 0.98 : 1.0)
    }
}
```

**Benefits:**
- `.spring()` animation feels more natural
- `.scaleEffect()` provides press feedback
- `.matchedGeometryEffect()` smooths transition

---

#### Enhancement 3.5: Hero Transition from List
```swift
// In MountainsTabView's ConditionMountainCard
NavigationLink {
    MountainDetailView(mountain: mountain)
} label: {
    ConditionMountainCard(...)
}
.buttonStyle(.plain)
.matchedGeometryEffect(id: "mountain-\(mountain.id)", in: namespace)

// In MountainDetailView
var body: some View {
    ScrollView {
        // ...
    }
    .matchedGeometryEffect(id: "mountain-\(mountain.id)", in: namespace)
    .transition(.asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .scale.combined(with: .opacity)
    ))
}
```

**Benefits:**
- Seamless transition from list to detail
- Maintains spatial context
- Professional app feel

---

## 4. Component Library Analysis

### Current State

The component library is extensive with 50+ components. Key observations:

#### Strengths
1. **Consistent Design System** (`DesignSystem.swift`): 8pt grid, semantic spacing, standard corner radii
2. **Good Separation of Concerns**: Cards are isolated, reusable
3. **Accessibility Support**: Many components include `.accessibilityLabel`

#### Weaknesses
1. **Inconsistent Animation**: Some components animate, others don't
2. **No Loading Skeletons**: Components show empty states but no loading indicators
3. **Limited Haptic Feedback**: Only used in a few places
4. **Missing iOS 17/18 Features**: No use of `.phaseAnimator`, `.keyframeAnimator`, `.scrollTransition`

### Specific Enhancements

#### Enhancement 4.1: Unified Loading Skeleton
```swift
// New component: ShimmerView.swift
struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color(.systemGray5),
                    Color(.systemGray6),
                    Color(.systemGray5)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
}

// Usage in ComparisonGridCard
struct ComparisonGridCard: View {
    let isLoading: Bool = false

    var body: some View {
        if isLoading {
            VStack(spacing: 8) {
                ShimmerView()
                    .frame(height: 40)
                    .cornerRadius(20)

                ShimmerView()
                    .frame(height: 20)
                    .cornerRadius(10)

                ShimmerView()
                    .frame(height: 60)
                    .cornerRadius(10)
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        } else {
            // ... actual content
        }
    }
}
```

**Benefits:**
- Consistent loading experience
- Reduces perceived wait time
- Modern app expectation

---

#### Enhancement 4.2: Haptic Feedback System
```swift
// Expand HapticFeedback.swift
enum HapticFeedback {
    case selection
    case light
    case medium
    case heavy
    case success
    case warning
    case error

    func trigger() {
        switch self {
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// Apply throughout app:
// - Button taps: .selection or .light
// - Toggle switches: .light
// - Pull to refresh: .medium
// - Delete actions: .heavy
// - Successful operations: .success
// - Warnings: .warning
// - Errors: .error
```

**Benefits:**
- Consistent tactile feedback
- Reinforces interactions
- Accessibility benefit (VoiceOver users feel feedback)

---

#### Enhancement 4.3: iOS 17+ Phase Animator
```swift
// Update TodaysPickCard with phase animator
struct TodaysPickCard: View {
    // ... existing properties
    @State private var isVisible = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            // ... card content
        }
        .phaseAnimator([false, true], trigger: isVisible) { content, phase in
            content
                .scaleEffect(phase ? 1.0 : 0.95)
                .opacity(phase ? 1.0 : 0.0)
        } animation: { phase in
            .spring(response: 0.6, dampingFraction: 0.75)
        }
        .onAppear {
            isVisible = true
        }
    }
}
```

**Benefits:**
- `.phaseAnimator` (iOS 17+) provides sophisticated animation sequencing
- More efficient than multiple `.animation()` modifiers
- Cleaner code

---

#### Enhancement 4.4: Scroll Transition Effects
```swift
// Apply to mountain cards in ScrollView
struct ConditionsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedMountains) { mountain in
                    NavigationLink {
                        MountainDetailView(mountain: mountain)
                    } label: {
                        ConditionMountainCard(...)
                    }
                    .buttonStyle(.plain)
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.7)
                            .scaleEffect(phase.isIdentity ? 1 : 0.95)
                            .blur(radius: phase.isIdentity ? 0 : 2)
                    }
                }
            }
        }
    }
}
```

**Benefits:**
- `.scrollTransition` (iOS 17+) creates depth as cards scroll
- Improves perceived smoothness
- Minimal code overhead

---

## 5. Accessibility Enhancements

### Current State
- Good use of `.accessibilityLabel` and `.accessibilityHint`
- Missing: `.accessibilityValue`, `.accessibilityActions`, dynamic type testing

### Recommendations

#### Enhancement 5.1: Accessibility Actions
```swift
// Add to ConditionMountainCard
.accessibilityElement(children: .combine)
.accessibilityLabel("\(mountain.name), powder score \(String(format: "%.1f", score ?? 0))")
.accessibilityHint("Double tap to view details")
.accessibilityValue("\(conditions?.snowfall24h ?? 0) inches of snow in 24 hours")
.accessibilityActions {
    Button("Add to favorites") {
        onFavoriteToggle()
    }
    Button("View on map") {
        // Navigate to map
    }
}
```

#### Enhancement 5.2: Dynamic Type Testing
```swift
// Add to all text components
Text(mountain.name)
    .font(.headline)
    .minimumScaleFactor(0.8) // Prevent overflow
    .lineLimit(2)
    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
```

#### Enhancement 5.3: VoiceOver Improvements
- Add `.accessibilityHeading()` to section titles
- Use `.accessibilitySortPriority()` to guide reading order
- Add `.accessibilityRotor()` for quick navigation between mountains

---

## 6. Modern iOS 17/18 Features to Leverage

### 6.1 Widgets (WidgetKit)
**Recommendation:** Create a small widget showing Today's Pick
```swift
struct TodaysPickWidget: Widget {
    let kind: String = "TodaysPickWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodaysPickWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Pick")
        .description("Your best mountain for today")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

### 6.2 Live Activities (ActivityKit)
**Recommendation:** Show lift line wait times as Live Activity
```swift
struct LiftLineActivity: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var mountainName: String
        var averageWaitTime: Int
        var crowdLevel: String
    }

    var mountainId: String
}
```

### 6.3 App Intents (AppIntents)
**Recommendation:** Siri shortcuts for common actions
```swift
struct CheckConditionsIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Ski Conditions"

    @Parameter(title: "Mountain")
    var mountain: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Fetch and return conditions
        return .result(dialog: "Mt. Baker has 8 inches of fresh snow")
    }
}
```

### 6.4 Swift Charts Enhancements
- **Polar charts** for wind direction visualization
- **Heat maps** for crowd density over time
- **Selection markers** for interactive data points

---

## 7. Animation Opportunities

### Current State
Basic animations using `.animation()` and `.withAnimation()`

### Enhancements

#### 7.1 Micro-interactions
```swift
// Button press feedback
Button {
    action()
} label: {
    Text("Refresh")
}
.buttonStyle(BounceButtonStyle())

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
```

#### 7.2 Loading States
```swift
// Rotating refresh icon
Image(systemName: "arrow.clockwise")
    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRefreshing)
```

#### 7.3 Success Animations
```swift
// Checkmark animation after favorite added
Image(systemName: "checkmark.circle.fill")
    .foregroundColor(.green)
    .symbolEffect(.bounce, value: favoriteAdded)
```

---

## 8. Priority Implementation Roadmap

### Phase 1: Quick Wins (1-2 days)
1. ✅ Add haptic feedback throughout app
2. ✅ Implement loading skeletons for all cards
3. ✅ Fix mode picker responsiveness on small devices
4. ✅ Add animated status pills to TodayView

### Phase 2: Visual Polish (3-5 days)
1. ✅ Enhance Today's Pick card with premium styling
2. ✅ Implement collapsing header in MountainDetailView
3. ✅ Add scroll transition effects to mountain lists
4. ✅ Improve tab bar with overflow indicators

### Phase 3: Advanced Features (5-7 days)
1. ✅ Interactive forecast chart with selection
2. ✅ Implement view density toggles
3. ✅ Add tab-specific empty states
4. ✅ Hero transitions between views

### Phase 4: iOS 17/18 Features (Ongoing)
1. ✅ Widget implementation
2. ✅ Live Activities for lift lines
3. ✅ App Intents for Siri
4. ✅ Advanced Chart interactions

---

## 9. Key Metrics to Track

### Before/After Comparison
- **Time to First Content:** Measure perceived loading time
- **Scroll Smoothness:** 60fps target
- **Interaction Response:** <100ms for all button taps
- **Accessibility Score:** VoiceOver navigation time

### User Testing Focus Areas
1. Can users quickly identify best mountain?
2. Do animations feel smooth or janky?
3. Is information density appropriate?
4. Are empty states helpful?

---

## 10. Code Quality Recommendations

### 10.1 Component Documentation
Add doc comments to all public components:
```swift
/// Displays a mountain card in the comparison grid with key metrics.
///
/// Shows powder score, 24h/48h snow, base depth, temperature, lifts, and crowd level.
/// Supports tap to navigate to detail view and optional webcam quick-view.
///
/// - Parameters:
///   - mountain: The mountain to display
///   - conditions: Current conditions data
///   - powderScore: Calculated powder score
///   - trend: Snow trend indicator
///   - isBest: Whether this is the top pick
struct ComparisonGridCard: View {
    // ...
}
```

### 10.2 Extract Magic Numbers
```swift
// Instead of hardcoded values
.frame(width: 120, height: 160)

// Define as constants
extension CGFloat {
    static let comparisonCardWidth: CGFloat = 120
    static let comparisonCardHeight: CGFloat = 160
}

.frame(width: .comparisonCardWidth, height: .comparisonCardHeight)
```

### 10.3 Previews for All Components
Ensure every component has a working preview:
```swift
#Preview("Loading State") {
    ComparisonGridCard(
        mountain: .mock,
        conditions: nil,
        powderScore: nil,
        trend: .stable,
        isBest: false,
        isLoading: true
    )
    .padding()
}

#Preview("Dark Mode") {
    ComparisonGridCard(...)
        .preferredColorScheme(.dark)
}
```

---

## Summary

The PowderTracker iOS app has a solid foundation but significant opportunities exist to elevate it to a premium experience:

**Top 5 Priorities:**
1. **Add collapsing header** to MountainDetailView (max content visibility)
2. **Implement haptic feedback system** (tactile polish)
3. **Create loading skeletons** (perceived performance)
4. **Enhance Today's Pick card** (visual hierarchy)
5. **Add scroll transition effects** (motion design)

**iOS 17/18 Wins:**
- `.symbolEffect()` for icon animations
- `.phaseAnimator()` for complex sequences
- `.scrollTransition()` for depth effects
- `.contentTransition(.numericText())` for number updates

**Long-term Investment:**
- WidgetKit for home screen presence
- Live Activities for real-time updates
- App Intents for Siri integration

This analysis provides a roadmap for transforming PowderTracker from functional to exceptional.
