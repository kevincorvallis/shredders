# Snow Forecast Chart UX Analysis & Improvement Recommendations

## Executive Summary

The current `SnowForecastChart` implementation in PowderTracker has a solid foundation with interactive tooltips, powder day highlighting, and multi-mountain comparison. However, several UX pain points reduce its intuitiveness and engagement. This analysis identifies 12 critical areas for improvement across interaction clarity, visual affordances, information hierarchy, and best-practice patterns.

**Key Findings:**
- Interaction patterns are hidden (no visual cues for chart interactivity)
- Multi-mountain overlays become cluttered and difficult to distinguish
- Powder day highlighting lacks sufficient visual hierarchy
- Time range toggle is undersized for touch targets
- Missing contextual information and onboarding cues

---

## Current Implementation Overview

**File:** `/ios/PowderTracker/PowderTracker/Views/Components/SnowForecastChart.swift`

**Key Features:**
- 7-line multi-mountain forecast overlay chart
- 3D/7D/15D time range picker
- Interactive tooltip on tap/drag (using `chartXSelection`)
- Powder day markers (6"+ threshold) with badges
- Area fill gradients with enhanced powder day styling
- Hourly breakdown sheet (currently not implemented/connected)
- Chart height: 180pt (`.chartHeightStandard`)

**Current Interaction Model:**
- Tap/drag on chart → tooltip appears showing snowfall for all mountains on that date
- Tap on powder day badge → *intended* to show hourly breakdown sheet (not connected)
- Segmented control → switches between 3/7/15 day ranges

---

## Pain Point Analysis

### 1. INVISIBLE INTERACTION AFFORDANCES

**Problem:**
The chart has no visual indication that it's interactive. Users must discover tap-to-select behavior by accident.

**Evidence from code:**
```swift
.chartXSelection(value: $selectedDate)
.chartOverlay { proxy in
    // Tooltip appears on interaction, but nothing suggests this is possible
}
```

**User Impact:**
- Users miss out on detailed per-day comparisons
- Reduced engagement with the chart
- No discoverable entry point to hourly breakdown feature

**Best-in-class examples:**
- **Weather Channel app:** Shows "Tap for details" hint on first load
- **Windy.com:** Animated pulsing dot on chart line hints at interactivity
- **CARROT Weather:** Subtle gradient bar below chart suggests "drag to scrub"

**Recommendation Priority:** HIGH

---

### 2. POWDER DAY HIGHLIGHTING IS BURIED

**Problem:**
Powder days (6"+ snowfall) are the most important data points for skiers, but their visual treatment is insufficient:
- `PointMark` at `symbolSize(50)` is small on retina displays
- Badges positioned via `.annotation(position: .top)` often overlap with other mountains' lines
- Area fill gradient enhancement (cyan overlay) is subtle and gets lost in multi-mountain views

**Evidence from code:**
```swift
// Powder day markers
if isPowderDay {
    PointMark(...)
        .symbolSize(50)  // Too small for emphasis
        .annotation(position: .top, spacing: 4) {
            PowderDayBadge(snowfall: day.snowfall, compact: true)
        }
}
```

**Visual hierarchy issues:**
- All mountains use the same powder day badge style
- No differentiation between 6" (powder) vs 12"+ (epic powder)
- Badge size is uniform regardless of snowfall magnitude

**User Impact:**
- Users scan the chart and miss powder days
- Can't quickly identify which mountain has the best powder forecast
- Epic days (12"+) don't get the excitement they deserve

**Best-in-class examples:**
- **OpenSnow:** Uses star ratings above bars for powder quality
- **Mountain Forecast:** Highlights powder days with vertical accent stripes
- **Snocountry:** Shows "POWDER ALERT!" banner above charts on big days

**Recommendation Priority:** HIGH

---

### 3. MULTI-MOUNTAIN COMPARISON IS CLUTTERED

**Problem:**
When 3+ favorite mountains are displayed, the chart becomes difficult to read:
- Lines overlap and area fills blend together
- Legend shows only mountain shortName (3-letter codes like "Baker", "Stevens")
- No visual hierarchy - all mountains treated equally
- Color selection is based on mountain.color (could be too similar)

**Evidence from code:**
```swift
ForEach(favorites, id: \.mountain.id) { favorite in
    // All mountains rendered with same visual weight
    LineMark(...)
        .foregroundStyle(by: .value("Mountain", favorite.mountain.shortName))
        .lineStyle(StrokeStyle(lineWidth: .chartLineWidthMedium))  // Same width for all

    AreaMark(...)  // Area fills overlap and obscure each other
}
```

**User Impact:**
- Hard to distinguish which line belongs to which mountain
- Can't focus on a specific mountain in the comparison
- Cognitive overload when scanning multiple forecasts

**Best-in-class examples:**
- **Yahoo Weather:** Allows tapping legend items to highlight/dim specific lines
- **Weather Underground:** Uses dashed vs solid lines to distinguish series
- **Trading View charts:** On hover, brings selected series to foreground with bold stroke

**Recommendation Priority:** HIGH

---

### 4. TIME RANGE TOGGLE TOO SMALL

**Problem:**
The 3D/7D/15D segmented picker is only 140pt wide, making touch targets smaller than Apple's 44pt minimum recommendation.

**Evidence from code:**
```swift
Picker("Range", selection: $selectedRange) {
    ForEach(ForecastRange.allCases, id: \.self) { range in
        Text(range.rawValue).tag(range)
    }
}
.pickerStyle(.segmented)
.frame(width: 140)  // Divided by 3 options = ~47pt per segment
```

**User Impact:**
- Difficult to tap correct option, especially for users with larger fingers
- Frustration when accidentally tapping adjacent option
- Accessibility issue for motor impairment users

**Apple HIG guideline:**
> "Make tap targets at least 44 x 44 points so they're easy to tap."

**Recommendation Priority:** MEDIUM

---

### 5. NO LOADING/EMPTY STATES ON RANGE CHANGE

**Problem:**
When switching between 3D/7D/15D, if forecast data is incomplete:
- Chart immediately renders with partial data (no indication of loading)
- No message if a mountain lacks 15D forecast data
- User doesn't know if data is still loading or unavailable

**Evidence from code:**
```swift
let forecastDays = Array(favorite.forecast.prefix(selectedRange.days))
// No check if forecast.count < selectedRange.days
```

**User Impact:**
- Confusing when chart shows 7 days on "15D" toggle
- No feedback on why data is missing
- Looks like a bug rather than a data limitation

**Recommendation Priority:** MEDIUM

---

### 6. TOOLTIP POSITIONING ISSUES

**Problem:**
The tooltip uses fixed positioning logic that can overlap with chart content:
```swift
.position(x: min(max(xPosition, 70), proxy.plotSize.width - 70), y: 40)
```
- Fixed Y position of 40pt from top always
- On dates with high snowfall, tooltip overlaps with powder day badges
- On narrow screens, 70pt padding may not prevent edge clipping

**User Impact:**
- Tooltip can obscure the data point being inspected
- On small iPhone screens, tooltip gets cut off
- Poor experience when inspecting powder days

**Recommendation Priority:** MEDIUM

---

### 7. MISSING CONTEXTUAL INFORMATION

**Problem:**
The chart lacks contextual cues that help users interpret the forecast:
- No indication of forecast confidence (all days treated equally, but day 1 is more accurate than day 15)
- No comparison to historical averages (is 8" a lot for this mountain?)
- No indication of forecast update time
- Missing snow level/freezing level information

**User Impact:**
- Users can't assess forecast reliability
- No context for "is this a good forecast?"
- Can't plan around snow level (rain vs snow)

**Best-in-class examples:**
- **OpenSnow:** Shows confidence bands (lighter shading for less certain days)
- **Weather Underground:** Displays "Forecast confidence: High" badge
- **Mountain Forecast:** Shows snow level as separate track on chart

**Recommendation Priority:** MEDIUM

---

### 8. NO ONBOARDING OR FIRST-USE HINTS

**Problem:**
New users don't know:
- The chart is interactive (can tap for details)
- What the powder day badges mean (6" threshold)
- That they can tap badges for hourly breakdown
- How to add/remove mountains from comparison

**Evidence:**
- No coach marks or first-run tutorial
- No inline hints or info buttons
- No empty state explanation when favorites list is empty

**User Impact:**
- Low feature discovery
- Users don't maximize value from the chart
- Missed opportunity for engagement

**Best-in-class examples:**
- **Duolingo:** Uses subtle animated arrows on first interaction
- **Instagram:** Shows swipe hints on Stories
- **Apple Weather:** Displays "Tap for more details" hint that fades after first interaction

**Recommendation Priority:** LOW (but high value-add)

---

### 9. INCONSISTENT GESTURE EXPECTATIONS

**Problem:**
Users expect different gestures based on platform patterns:
- **Expected:** Pinch-to-zoom for closer inspection
- **Expected:** Swipe left/right to pan between dates
- **Actual:** Only tap/drag to select date

**Evidence from code:**
```swift
.chartXSelection(value: $selectedDate)  // Only supports tap/drag
```

**User Impact:**
- Feels less responsive than native iOS charts
- Can't zoom into specific date ranges
- Standard gesture vocabulary isn't supported

**Note:** SwiftUI Charts (as of iOS 17) has limited built-in gesture support, so this may require custom gesture handling.

**Recommendation Priority:** LOW (complex to implement)

---

### 10. POWDER DAY BADGE TAP NOT IMPLEMENTED

**Problem:**
The code references `onDayTap` callback and `HourlyBreakdownSheet`, but:
- `onDayTap` is never called in the chart implementation
- Powder day badges show no visual feedback on press
- No indication that badges are tappable

**Evidence from code:**
```swift
var onDayTap: ((Mountain, ForecastDay) -> Void)? = nil  // Defined but unused
```

**User Impact:**
- Designed feature is non-functional
- Missed opportunity for deep dive into hourly conditions

**Recommendation Priority:** MEDIUM (fix incomplete implementation)

---

### 11. LEGEND IS NOT INTERACTIVE

**Problem:**
The chart legend at the bottom is purely informational:
- Can't tap a mountain name to highlight/isolate its line
- Can't hide a mountain from view temporarily
- No indication of which mountains are currently visible

**Evidence from code:**
```swift
.chartLegend(position: .bottom, spacing: 8) {
    HStack(spacing: 12) {
        ForEach(favorites, id: \.mountain.id) { favorite in
            HStack(spacing: 4) {
                Circle().fill(mountainColor(for: favorite.mountain)).frame(width: 8, height: 8)
                Text(favorite.mountain.shortName).font(.caption)
            }
        }
    }
}
```

**User Impact:**
- Can't focus on specific mountains in cluttered comparisons
- No control over chart density

**Best-in-class examples:**
- **Trading View:** Tap legend item to toggle series visibility
- **Google Analytics:** Click legend to show/hide data series
- **Strava:** Long-press legend to isolate single series

**Recommendation Priority:** MEDIUM

---

### 12. NO VISUAL FEEDBACK FOR CHART INTERACTION

**Problem:**
When user drags on chart to scrub through dates:
- No visible selection indicator moves along X axis (only RuleMark in overlay)
- RuleMark is subtle (1pt line, 30% opacity)
- No animation/easing when tooltip appears

**Evidence from code:**
```swift
RuleMark(x: .value("Selected", selectedDate))
    .foregroundStyle(Color.primary.opacity(0.3))
    .lineStyle(StrokeStyle(lineWidth: 1))
```

**User Impact:**
- Interaction feels unresponsive
- Hard to see which date is currently selected
- Lacks the polish of best-in-class weather apps

**Recommendation Priority:** LOW (polish improvement)

---

## Information Hierarchy Issues

### Current Visual Hierarchy (in order of prominence):

1. Mountain lines (LineMark with 2.5pt stroke)
2. Area fills (gradient with 40% → 2% opacity)
3. Powder day points (PointMark symbolSize 50)
4. Powder day badges (small text annotations)
5. Axis labels (caption2, secondary color)
6. Legend (caption text)
7. Tooltip (appears on interaction only)

### Desired Visual Hierarchy (for ski app):

1. **Powder day indicators** ← Should be MOST prominent
2. **Selected date tooltip** ← Currently primary interaction
3. **Mountain with highest snowfall** ← Should stand out
4. **Other mountain lines** ← Supporting context
5. **Area fills** ← Background context
6. **Axis labels and legend** ← Reference info

### Gap Analysis:

**What's wrong:**
- Powder days don't dominate the visual hierarchy despite being the primary user goal
- All mountains have equal visual weight (no "hero mountain" concept)
- Tooltip is hidden until interaction (but contains most valuable info)

**Why it matters:**
- Users scan charts top-to-bottom, left-to-right
- First glance should answer: "Where's the powder?"
- Current design requires users to actively explore to find key insights

---

## Comparison to Best-in-Class Weather & Ski Apps

### 1. OpenSnow (Industry Leader for Ski Forecasts)

**What they do well:**
- **Powder score badges** prominently displayed above chart
- **Confidence bands** using gradient opacity for days 8-10
- **Snow level indicator** as dotted line overlaid on forecast
- **Tap anywhere on chart** to see detailed hourly breakdown modal
- **Animated transitions** when switching between 3D/10D forecast
- **"Add to favorites" star** button directly in chart header

**What PowderTracker lacks:**
- Snow level indicator (critical for rain vs snow)
- Confidence visualization
- Prominent powder score display
- Direct favoriting action from chart

### 2. Weather Underground

**What they do well:**
- **Interactive legend** - tap to highlight/hide series
- **Forecast confidence badge** ("High", "Medium", "Low")
- **Hourly scrubber** below chart with mini condition icons
- **Comparison mode toggle** (this year vs last year vs historical)
- **Share chart button** to export as image

**What PowderTracker lacks:**
- Historical comparison mode
- Confidence indicators
- Share/export functionality
- Hourly scrubber UI pattern

### 3. Apple Weather (Best-in-Class Native Experience)

**What they do well:**
- **Subtle gradient bar below chart** suggests "drag to scrub"
- **Haptic feedback** on date selection (selectionChanged)
- **Smooth animations** on range toggle
- **Graceful loading states** with skeleton loaders
- **Dynamic Type support** for accessibility
- **VoiceOver labels** for chart elements

**What PowderTracker lacks:**
- Drag affordance hint
- Skeleton loading states
- Full accessibility support for chart

### 4. Windy.com (Web-Based Weather Visualization)

**What they do well:**
- **Animated playback** through forecast timeline
- **Multiple data layers** (wind, precipitation, clouds) toggled via buttons
- **Time scrubber** with play/pause controls
- **Split-screen comparison** of different forecast models
- **Forecast legend** explains data sources and confidence

**What PowderTracker could adapt:**
- Data layer toggles (snowfall, temperature, wind)
- Animated playback through forecast days
- Forecast model attribution

---

## Specific, Actionable Recommendations

### HIGH PRIORITY (Must-Fix for Intuitive UX)

#### 1. Add Interaction Affordances

**Implementation:**
```swift
VStack(alignment: .leading, spacing: 12) {
    headerWithToggle

    // Add hint overlay on first chart interaction
    if viewModel.isFirstChartInteraction {
        HStack {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(.blue)
            Text("Tap chart for details")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .transition(.opacity.combined(with: .scale))
    }

    chart
}
```

**Visual hint below chart:**
- Gradient bar with 40% opacity below X-axis
- Fades in/out on scroll interaction
- Dismissed after first use (stored in UserDefaults)

**Estimated effort:** 2 hours

---

#### 2. Redesign Powder Day Highlighting

**Visual hierarchy overhaul:**

```swift
// 1. Larger, more prominent markers
if isPowderDay {
    PointMark(...)
        .foregroundStyle(mountainColor(for: favorite.mountain))
        .symbolSize(isPowderDay ? 100 : 0)  // Doubled from 50

    // 2. Vertical accent line behind data point
    RuleMark(x: .value("Date", chartDate))
        .foregroundStyle(
            LinearGradient(
                colors: [Color.cyan.opacity(0.8), Color.cyan.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .lineStyle(StrokeStyle(lineWidth: 3, dash: []))

    // 3. Enhanced badge with magnitude scaling
    .annotation(position: .top, spacing: 8) {
        PowderDayBadge(snowfall: day.snowfall, style: .prominent)
            .scaleEffect(day.snowfall >= 12 ? 1.2 : 1.0)  // Epic days are larger
    }
}
```

**Badge redesign:**
- 6-8": Blue badge with "❄️ 8""
- 9-11": Cyan badge with "💙 10""
- 12"+ : Orange/yellow gradient badge with "⭐️ EPIC 14""

**Estimated effort:** 4 hours

---

#### 3. Improve Multi-Mountain Comparison

**Interactive legend:**
```swift
.chartLegend(position: .bottom, spacing: 8) {
    HStack(spacing: 12) {
        ForEach(favorites, id: \.mountain.id) { favorite in
            Button {
                toggleMountainHighlight(favorite.mountain)
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(mountainColor(for: favorite.mountain))
                        .frame(width: 8, height: 8)
                        .opacity(highlightedMountain == favorite.mountain.id ? 1.0 : 0.4)

                    Text(favorite.mountain.shortName)
                        .font(.caption)
                        .foregroundColor(highlightedMountain == favorite.mountain.id ? .primary : .secondary)
                }
            }
        }
    }
}
```

**Line styling based on selection:**
```swift
LineMark(...)
    .foregroundStyle(by: .value("Mountain", favorite.mountain.shortName))
    .lineStyle(StrokeStyle(
        lineWidth: highlightedMountain == favorite.mountain.id
            ? .chartLineWidthBold  // 3.5pt
            : .chartLineWidthThin,  // 1.5pt
        lineCap: .round
    ))
    .opacity(highlightedMountain == nil || highlightedMountain == favorite.mountain.id ? 1.0 : 0.3)
```

**Add "show only" mode:**
- Long-press legend item → isolates that mountain
- Other mountains fade to 10% opacity
- Tap again to restore all mountains

**Estimated effort:** 6 hours

---

### MEDIUM PRIORITY (Significant UX Improvements)

#### 4. Enlarge Time Range Picker

**Recommended implementation:**
```swift
Picker("Range", selection: $selectedRange) {
    ForEach(ForecastRange.allCases, id: \.self) { range in
        Text(range.rawValue).tag(range)
    }
}
.pickerStyle(.segmented)
.frame(width: 180)  // Increased from 140 → ~60pt per segment ✓
```

**Alternative: Icon-based picker**
```swift
HStack(spacing: 8) {
    ForEach(ForecastRange.allCases, id: \.self) { range in
        Button {
            selectedRange = range
        } label: {
            Text(range.rawValue)
                .font(.subheadline.weight(selectedRange == range ? .semibold : .regular))
                .foregroundColor(selectedRange == range ? .white : .secondary)
                .frame(width: 60, height: 34)  // Apple HIG compliant
                .background(selectedRange == range ? Color.blue : Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
    }
}
```

**Estimated effort:** 1 hour

---

#### 5. Smart Tooltip Positioning

**Improved positioning logic:**
```swift
.chartOverlay { proxy in
    if let selectedDate = selectedDate,
       let xPosition = proxy.position(forX: selectedDate) {
        let snowfallData = getSnowfallForDate(selectedDate)

        // Calculate tooltip height based on content
        let tooltipHeight: CGFloat = CGFloat(40 + (snowfallData.count * 24))

        // Smart Y positioning: avoid overlapping with high data points
        let maxSnowfallAtDate = snowfallData.map(\.snowfall).max() ?? 0
        let dataYPosition = proxy.position(forY: maxSnowfallAtDate) ?? 0

        let tooltipY: CGFloat = {
            if dataYPosition > tooltipHeight + 20 {
                // Position above data point if room available
                return dataYPosition - tooltipHeight - 10
            } else {
                // Position below data point
                return min(dataYPosition + 60, proxy.plotSize.height - tooltipHeight - 10)
            }
        }()

        // Smart X positioning with dynamic padding
        let tooltipWidth: CGFloat = 160
        let safeXPosition = min(
            max(xPosition, tooltipWidth / 2 + 10),
            proxy.plotSize.width - tooltipWidth / 2 - 10
        )

        ChartTooltip {
            tooltipContent(for: snowfallData, date: selectedDate)
        }
        .position(x: safeXPosition, y: tooltipY)
        .animation(.chartTooltip, value: selectedDate)
    }
}
```

**Estimated effort:** 3 hours

---

#### 6. Add Loading & Empty States

**Range change loading state:**
```swift
@State private var isLoadingRange = false

var chart: some View {
    ZStack {
        if isLoadingRange {
            ChartSkeleton(height: chartHeight)
                .transition(.opacity)
        } else {
            Chart {
                // ... existing chart marks
            }
        }
    }
    .onChange(of: selectedRange) { oldValue, newValue in
        withAnimation {
            isLoadingRange = true
        }

        Task {
            await viewModel.fetchForecastForRange(newValue.days)
            await MainActor.run {
                withAnimation {
                    isLoadingRange = false
                }
            }
        }
    }
}
```

**Partial data indicator:**
```swift
if favorites.contains(where: { $0.forecast.count < selectedRange.days }) {
    HStack(spacing: 4) {
        Image(systemName: "info.circle")
            .font(.caption2)
        Text("Limited forecast data for some mountains")
            .font(.caption2)
    }
    .foregroundColor(.orange)
    .padding(.top, 4)
}
```

**Estimated effort:** 3 hours

---

#### 7. Implement Powder Day Badge Taps

**Connect onDayTap callback:**
```swift
// In chart marks
if isPowderDay {
    PointMark(...)
        .annotation(position: .top, spacing: 4) {
            Button {
                selectedDataPoint = (favorite.mountain, day)
                showingHourlySheet = true
            } label: {
                PowderDayBadge(snowfall: day.snowfall, compact: true)
            }
            .buttonStyle(ScaleButtonStyle())  // Visual feedback
        }
}
```

**ScaleButtonStyle for tactile feedback:**
```swift
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticFeedback.light.trigger()
                }
            }
    }
}
```

**Estimated effort:** 2 hours

---

### LOW PRIORITY (Polish & Delight)

#### 8. Add First-Use Onboarding

**Coach mark overlay:**
```swift
@AppStorage("hasSeenForecastChartTutorial") private var hasSeenTutorial = false

var body: some View {
    VStack {
        // ... chart content
    }
    .overlay {
        if !hasSeenTutorial {
            CoachMarkView(
                message: "Tap the chart to see detailed forecasts for each day",
                arrowPosition: .bottom,
                onDismiss: {
                    hasSeenTutorial = true
                }
            )
            .position(x: UIScreen.main.bounds.width / 2, y: 120)
        }
    }
}
```

**Animated hint for drag interaction:**
```swift
struct DragHintView: View {
    @State private var offset: CGFloat = -20

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "hand.draw")
                .offset(x: offset)
            Text("Drag to explore")
                .font(.caption)
        }
        .foregroundColor(.blue.opacity(0.8))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                offset = 20
            }
        }
    }
}
```

**Estimated effort:** 4 hours

---

#### 9. Improve Visual Feedback

**Enhanced selection indicator:**
```swift
// Replace subtle RuleMark with prominent indicator
if let selectedDate = selectedDate {
    // Vertical line
    RuleMark(x: .value("Selected", selectedDate))
        .foregroundStyle(
            LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .lineStyle(StrokeStyle(lineWidth: 2, dash: []))

    // Data point highlights
    ForEach(favorites, id: \.mountain.id) { favorite in
        if let day = favorite.forecast.first(where: {
            parseDate($0.date).map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } ?? false
        }) {
            PointMark(
                x: .value("Day", selectedDate),
                y: .value("Snow", day.snowfall)
            )
            .foregroundStyle(mountainColor(for: favorite.mountain))
            .symbolSize(80)
            .symbol {
                Circle()
                    .fill(mountainColor(for: favorite.mountain))
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
    }
}
```

**Haptic feedback improvements:**
```swift
.onChange(of: selectedDate) { _, newValue in
    if newValue != nil {
        HapticFeedback.selection.trigger()  // Current
    }
}

// Enhanced: trigger on powder day discovery
.onChange(of: selectedDate) { _, newValue in
    if let date = newValue {
        let snowfallData = getSnowfallForDate(date)
        let maxSnowfall = snowfallData.map(\.snowfall).max() ?? 0

        if maxSnowfall >= 12 {
            HapticFeedback.success.trigger()  // Epic powder day!
        } else if maxSnowfall >= 6 {
            HapticFeedback.medium.trigger()  // Powder day
        } else {
            HapticFeedback.selection.trigger()  // Normal selection
        }
    }
}
```

**Estimated effort:** 3 hours

---

#### 10. Add Contextual Information

**Forecast confidence indicator:**
```swift
struct ForecastConfidenceBand: ViewModifier {
    let dayIndex: Int

    var confidence: Double {
        switch dayIndex {
        case 0...2: return 0.9   // High confidence
        case 3...5: return 0.7   // Medium confidence
        case 6...10: return 0.5  // Low confidence
        default: return 0.3      // Very low confidence
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(confidence)
    }
}

// Apply to chart marks
ForEach(Array(forecastDays.enumerated()), id: \.offset) { index, day in
    LineMark(...)
        .modifier(ForecastConfidenceBand(dayIndex: index))
}
```

**Historical comparison line:**
```swift
// Add historical average as dashed reference line
if let historicalAvg = viewModel.historicalAverageForRange(selectedRange) {
    LineMark(
        x: .value("Day", date),
        y: .value("Historical", historicalAvg)
    )
    .foregroundStyle(.secondary)
    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
    .annotation(position: .trailing) {
        Text("Avg")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}
```

**Estimated effort:** 5 hours

---

## Summary of Recommendations by Priority

| Priority | Recommendation | Impact | Effort | ROI |
|----------|---------------|---------|--------|-----|
| HIGH | Add interaction affordances | High | 2h | 10/10 |
| HIGH | Redesign powder day highlighting | High | 4h | 9/10 |
| HIGH | Improve multi-mountain comparison | High | 6h | 8/10 |
| MEDIUM | Enlarge time range picker | Medium | 1h | 10/10 |
| MEDIUM | Smart tooltip positioning | Medium | 3h | 7/10 |
| MEDIUM | Add loading & empty states | Medium | 3h | 6/10 |
| MEDIUM | Implement powder badge taps | Medium | 2h | 8/10 |
| LOW | Add first-use onboarding | Low | 4h | 5/10 |
| LOW | Improve visual feedback | Low | 3h | 6/10 |
| LOW | Add contextual information | Low | 5h | 7/10 |

**Total estimated effort:** 33 hours (1 week for one developer)

**Recommended phased approach:**
1. **Phase 1 (Week 1):** HIGH priority items → immediate UX gains
2. **Phase 2 (Week 2):** MEDIUM priority items → polish and completeness
3. **Phase 3 (Week 3):** LOW priority items → delight and differentiation

---

## Accessibility Considerations

### Current gaps:
1. No VoiceOver labels on chart marks
2. Tooltip text may be too small for Dynamic Type users
3. Color-blind users can't distinguish mountain lines (relies only on color)
4. No keyboard/switch control navigation support

### Recommendations:
```swift
// 1. Add VoiceOver support
Chart {
    // ... marks
}
.accessibilityLabel("Snow forecast chart showing \(favorites.count) mountains")
.accessibilityHint("Double-tap to select a date for detailed forecast")
.accessibilityChartDescriptor(chartDescriptor)

// 2. Generate text summary for screen readers
private var chartDescriptor: AXChartDescriptor {
    let xAxis = AXCategoricalDataAxisDescriptor(
        title: "Date",
        categoryOrder: forecastDates.map { $0.formatted(date: .abbreviated, time: .omitted) }
    )

    let yAxis = AXNumericDataAxisDescriptor(
        title: "Snowfall (inches)",
        range: 0...maxSnowfall,
        gridlinePositions: []
    )

    let series = favorites.map { favorite in
        AXDataSeriesDescriptor(
            name: favorite.mountain.name,
            isContinuous: true,
            dataPoints: favorite.forecast.map { day in
                AXDataPoint(
                    x: day.date,
                    y: Double(day.snowfall),
                    label: "\(day.snowfall) inches on \(day.date)"
                )
            }
        )
    }

    return AXChartDescriptor(
        title: "7-Day Snow Forecast",
        summary: forecastSummary,
        xAxis: xAxis,
        yAxis: yAxis,
        series: series
    )
}

// 3. Add non-color differentiators
.foregroundStyle(by: .value("Mountain", favorite.mountain.shortName))
.lineStyle(StrokeStyle(
    lineWidth: .chartLineWidthMedium,
    dash: dashPattern(for: favorite.mountain.id)  // Different dash patterns
))

private func dashPattern(for mountainId: String) -> [CGFloat] {
    let patterns: [[CGFloat]] = [
        [],           // Solid
        [5, 3],       // Medium dash
        [2, 2],       // Dotted
        [8, 3, 2, 3], // Dash-dot
        [8, 3]        // Long dash
    ]
    let hash = abs(mountainId.hashValue)
    return patterns[hash % patterns.count]
}
```

---

## Testing Checklist

Before shipping improvements, test:

- [ ] Interaction hints appear on first chart view
- [ ] Hints dismiss after first interaction or manual close
- [ ] Powder days are immediately recognizable on first glance
- [ ] 12"+ days stand out more than 6-8" days
- [ ] Tapping legend isolates mountain line (others fade)
- [ ] Long-press legend shows only that mountain
- [ ] Time range picker is easy to tap (no mis-taps)
- [ ] Tooltip doesn't overlap with data points
- [ ] Tooltip repositions on narrow screens (iPhone SE)
- [ ] Loading state shows when changing ranges
- [ ] Partial data indicator appears when forecast < range days
- [ ] Tapping powder badge opens hourly breakdown sheet
- [ ] VoiceOver announces chart context and navigation hints
- [ ] Haptic feedback triggers on date selection
- [ ] Enhanced haptics on powder day discovery
- [ ] Chart works in landscape orientation
- [ ] Dark mode rendering is correct
- [ ] Dynamic Type scaling works up to Accessibility sizes
- [ ] Color-blind users can distinguish lines (dash patterns)

---

## Conclusion

The PowderTracker snow forecast chart has solid technical implementation but suffers from hidden interaction patterns, insufficient powder day emphasis, and multi-mountain comparison clutter. By implementing the HIGH priority recommendations (interaction affordances, powder highlighting redesign, and legend interactivity), the chart will transform from a data visualization into an intuitive, engaging experience that helps users quickly answer: **"Where should I ski this week?"**

The recommended improvements draw from best-in-class patterns in weather apps (Apple Weather, Weather Underground), financial charts (Trading View), and ski-specific tools (OpenSnow). These changes will dramatically improve first-time user comprehension while adding depth for power users who want to explore detailed forecasts.

**Next steps:**
1. Review this analysis with design team
2. Prioritize recommendations based on product roadmap
3. Create detailed design mocks for HIGH priority items
4. Implement Phase 1 (HIGH priority) in next sprint
5. Conduct usability testing with target users (skiers/snowboarders)
6. Iterate based on feedback before moving to Phase 2

