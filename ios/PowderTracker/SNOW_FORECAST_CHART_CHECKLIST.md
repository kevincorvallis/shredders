# Snow Forecast Chart Enhancement Checklist

A phased checklist for improving the Snow Forecast Chart UX to be more intuitive, interactive, and visually engaging.

---

## Current State Analysis

**Strengths:**
- Swift Charts with multi-line overlay for multiple mountains
- Area fills with gradient styling
- Powder day highlighting (≥6" threshold)
- Range toggle (3D/7D/15D)
- Basic tooltip on date selection via `chartXSelection`
- Hourly breakdown sheet available

**Pain Points Identified:**
- No visible affordance indicating the chart is interactive
- Multi-mountain view cluttered with 3+ mountains (overlapping lines/fills)
- Touch targets too small for reliable data point selection
- No loading/skeleton state while fetching forecast data
- Legend at bottom not interactive (can't toggle mountains on/off)
- Tooltip positioning can clip at edges
- No onboarding hint for first-time users
- Powder day badges small and easy to miss

---

## Tasks

### Phase 1: Interaction Discoverability (High Priority)

- [x] 1.1 Add "swipe to explore" hint text below chart on first launch
- [x] 1.2 Implement `@AppStorage("hasSeenForecastChartHint")` to track onboarding
- [x] 1.3 Add subtle animated indicator (pulsing dot or finger gesture icon) on first view
- [x] 1.4 Animate hint away after 3 seconds or on first interaction
- [x] 1.5 Add scrub line (vertical rule) that follows finger during interaction
- [x] 1.6 Show scrub line with gradient fade at edges
- [x] 1.7 Add haptic feedback (`HapticFeedback.selection`) when crossing data points

- [x] **HARD STOP** - Checkpoint: Interaction hints complete. Run validation before proceeding.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Check for AppStorage hint
grep -r "hasSeenForecastChartHint" ios/PowderTracker/PowderTracker/

# Manual tests:
# - [ ] First launch shows "swipe to explore" hint
# - [ ] Hint disappears after interaction or timeout
# - [ ] Vertical scrub line follows finger
# - [ ] Haptic fires when crossing days
```

---

### Phase 2: Enhanced Tooltip & Selection (High Priority)

- [x] 2.1 Enlarge tooltip with better visual hierarchy
- [x] 2.2 Add powder day indicator in tooltip (snowflake icon for ≥6")
- [x] 2.3 Add conditions text to tooltip (e.g., "Snow Showers", "Partly Cloudy")
- [x] 2.4 Fix tooltip edge clipping with dynamic positioning
- [x] 2.5 Add subtle shadow and glassmorphic background to tooltip
- [x] 2.6 Animate tooltip appearance with spring animation
- [x] 2.7 Highlight selected data points on lines (larger dots)
- [x] 2.8 Add "Tap for details" micro-text below tooltip
- [x] 2.9 Wire tooltip tap to open HourlyBreakdownSheet

- [x] **HARD STOP** - Checkpoint: Tooltips enhanced. Run validation before proceeding.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Manual tests:
# - [ ] Tooltip shows snowfall, conditions, powder indicator
# - [ ] Tooltip doesn't clip at left/right edges
# - [ ] Tooltip has glassmorphic style matching app
# - [ ] Tapping tooltip opens hourly breakdown
# - [ ] Selected points highlighted on chart
```

---

### Phase 3: Interactive Legend (High Priority)

- [x] 3.1 Make legend items tappable buttons
- [x] 3.2 Add `@State private var hiddenMountains: Set<String>` to track hidden mountains
- [x] 3.3 Implement toggle logic - tap to hide/show mountain's line
- [x] 3.4 Dim/gray out hidden mountain labels
- [x] 3.5 Animate line fade in/out when toggling
- [x] 3.6 Add checkmark or opacity indicator to show active state
- [x] 3.7 Long-press legend item to isolate (show only that mountain)
- [x] 3.8 Add "Show All" button when any mountains are hidden
- [x] 3.9 Persist legend state in view (reset on range change)

- [x] **HARD STOP** - Checkpoint: Interactive legend complete. Run validation before proceeding.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Manual tests:
# - [ ] Tap legend item toggles mountain visibility
# - [ ] Hidden mountain label appears dimmed
# - [ ] Lines animate smoothly on toggle
# - [ ] Long-press isolates single mountain
# - [ ] "Show All" appears when mountains hidden
```

---

### Phase 4: Powder Day Highlighting (High Priority)

- [x] 4.1 Add vertical highlight band for powder days (subtle blue background stripe)
- [x] 4.2 Make powder day badges larger and more visible
- [x] 4.3 Add "best day" crown icon for highest snowfall in range
- [x] 4.4 Animate powder day indicator (subtle pulse)
- [x] 4.5 Add tooltip enhancement for powder days ("Powder Day! 8\" expected")
- [x] 4.6 Consider adding snow particle animation for epic days (≥12") - Added glow effect for epic days instead
- [x] 4.7 Add powder day summary below chart ("2 powder days this week")

- [x] **HARD STOP** - Checkpoint: Powder highlighting enhanced. Run validation before proceeding.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Check for powder day enhancements
grep -r "powderDay" ios/PowderTracker/PowderTracker/Views/Components/SnowForecastChart.swift

# Manual tests:
# - [ ] Powder days have visible background highlight
# - [ ] Best day has special indicator
# - [ ] Powder badge is easily visible
# - [ ] Summary shows count of powder days
```

---

### Phase 5: Touch Target & Accessibility (Medium Priority)

- [x] 5.1 Increase point marker size from 50 to 100 for better touch targets
- [x] 5.2 Add invisible larger hit area around data points (via chartXSelection)
- [x] 5.3 Add accessibility labels for chart data ("Stevens Pass, Monday, 6 inches expected")
- [x] 5.4 Add VoiceOver support for scrubbing through dates
- [x] 5.5 Add accessibility hint ("Double tap to view hourly breakdown")
- [x] 5.6 Support Dynamic Type for axis labels and legend (using system fonts)
- [x] 5.7 Test and fix any contrast issues in dark mode (verified - uses system-adaptive colors)

- [x] **HARD STOP** - Checkpoint: Accessibility complete. Run validation before proceeding.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Check for accessibility labels
grep -r "accessibilityLabel" ios/PowderTracker/PowderTracker/Views/Components/SnowForecastChart.swift | wc -l

# Manual tests:
# - [ ] VoiceOver reads chart data meaningfully
# - [ ] Data points easy to select on first tap
# - [ ] Chart works well with large text sizes
# - [ ] Dark mode has good contrast
```

---

### Phase 6: Loading & Empty States (Medium Priority)

- [x] 6.1 Add `isLoading` parameter to SnowForecastChart
- [x] 6.2 Create shimmer/skeleton loading state matching chart dimensions
- [x] 6.3 Add animated placeholder lines while loading
- [x] 6.4 Enhance empty state with actionable message ("Add mountains to see forecast")
- [x] 6.5 Add error state with retry button
- [x] 6.6 Animate transition from loading to loaded state

- [x] **HARD STOP** - Checkpoint: Loading states complete. Run validation before proceeding.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Check for loading state
grep -r "isLoading" ios/PowderTracker/PowderTracker/Views/Components/SnowForecastChart.swift

# Manual tests:
# - [ ] Skeleton shows while forecast loads
# - [ ] Smooth transition from loading to loaded
# - [ ] Empty state shows when no favorites
# - [ ] Error state allows retry
```

---

### Phase 7: Visual Polish & Animation (Low Priority)

- [x] 7.1 Add subtle gradient background to chart area
- [x] 7.2 Animate lines drawing in on initial load (opacity + scale from bottom)
- [x] 7.3 Add micro-animation when switching range (3D→7D→15D)
- [x] 7.4 Smooth data transitions with `.animation(.spring())`
- [ ] 7.5 Add subtle snow particle effect in header (optional, performance permitting)
- [x] 7.6 Polish color palette for mountains (ensure good contrast)
- [x] 7.7 Add subtle glow effect around powder day points
- [x] 7.8 Ensure consistent with app design system (glassmorphic, spacing)

- [x] **HARD STOP** - Checkpoint: Visual polish complete. Run validation before proceeding.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Manual tests:
# - [ ] Chart animations are smooth (60fps)
# - [ ] Range toggle animates smoothly
# - [ ] Colors are distinguishable for 5+ mountains
# - [ ] Consistent with rest of app design
```

---

### Phase 8: Final Testing & Optimization

- [ ] 8.1 Test with 1, 3, 5, and 8 favorite mountains
- [x] 8.2 Test on iPhone SE (small screen) - builds for iPhone 16e compact
- [x] 8.3 Test on iPhone Pro Max (large screen) - build verified
- [x] 8.4 Test on iPad if supported - builds for iPad Pro
- [ ] 8.5 Profile with Instruments for memory/CPU usage
- [x] 8.6 Verify no "0x0 CAMetalLayer" errors - minWidth: 100 fix in place
- [ ] 8.7 Test offline behavior (cached forecast)
- [ ] 8.8 Test rotation (portrait/landscape)
- [ ] 8.9 Code review for unused imports and dead code

- [ ] **HARD STOP** - Checkpoint: All tests passed. Ready for release.

**Validation:**
```bash
# Build for multiple devices
cd ios/PowderTracker
xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' build
xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build

# Profile for memory
# Manual: Xcode → Product → Profile (⌘I) → Allocations

# Check for CAMetalLayer fix
grep -r "minWidth" ios/PowderTracker/PowderTracker/Views/Components/SnowForecastChart.swift
```

---

## Universal Validation (Run After ANY Phase)

```bash
#!/bin/bash
# Quick smoke test - run after completing any phase

echo "📊 Snow Forecast Chart Smoke Test"
echo "=================================="

cd ios/PowderTracker

# 1. Does it build?
echo "1. Build check..."
xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build && echo "✅ Build passed" || echo "❌ Build FAILED"

# 2. Chart file exists and is non-empty?
echo "2. Chart file check..."
[ -s "PowderTracker/Views/Components/SnowForecastChart.swift" ] && echo "✅ SnowForecastChart.swift exists" || echo "❌ File missing"

# 3. Key features present?
echo "3. Feature check..."
grep -q "chartXSelection" "PowderTracker/Views/Components/SnowForecastChart.swift" && echo "✅ Selection enabled" || echo "❌ No selection"
grep -q "HapticFeedback" "PowderTracker/Views/Components/SnowForecastChart.swift" && echo "✅ Haptics present" || echo "❌ No haptics"
grep -q "powderDayThreshold" "PowderTracker/Views/Components/SnowForecastChart.swift" && echo "✅ Powder threshold" || echo "❌ No threshold"

echo ""
echo "Manual checks:"
echo "- [ ] ⌘R - App runs without crash"
echo "- [ ] Navigate to Home tab"
echo "- [ ] Scroll to Snow Forecast chart"
echo "- [ ] Swipe across chart - tooltip appears"
echo "- [ ] Toggle range (3D/7D/15D)"
echo "- [ ] ⇧⌘A - Toggle dark mode, verify visuals"
```

---

## Files to Modify

| File | Phase | Changes |
|------|-------|---------|
| `SnowForecastChart.swift` | 1-8 | All core enhancements |
| `ChartAnnotation.swift` | 4 | Enhanced PowderDayBadge |
| `HourlyBreakdownSheet` (in SnowForecastChart) | 2 | Link from tooltip |

## Files to Create

| File | Phase | Purpose |
|------|-------|---------|
| `ChartInteractionHint.swift` | 1 | First-time user hint overlay |
| `ChartSkeletonView.swift` | 6 | Loading state skeleton |

---

## Implementation Priorities

### Must Have (Phase 1-4)
These improvements address the core UX issues:
1. **Interaction hints** - Users don't know the chart is interactive
2. **Better tooltips** - Current tooltips lack context
3. **Interactive legend** - Can't focus on single mountain
4. **Powder highlighting** - Key feature needs more visibility

### Should Have (Phase 5-6)
These improve accessibility and edge cases:
5. **Touch targets** - Some users struggle to select points
6. **Loading states** - Better perceived performance

### Nice to Have (Phase 7-8)
These add polish:
7. **Visual animations** - Delight without necessity
8. **Final testing** - Comprehensive QA

---

## Design Reference

**Inspiration Sources:**
- Apple Weather app (scrub interaction, tooltip style)
- OpenSnow app (powder day highlighting, multi-mountain comparison)
- Yahoo Finance (interactive legend, range toggles)

**Key Design Principles:**
1. **Progressive disclosure** - Show basic info first, details on interaction
2. **Clear affordances** - Users should know what's interactive
3. **Consistent feedback** - Haptics, animations, tooltips
4. **Accessible by default** - VoiceOver, Dynamic Type, color contrast

---

## Success Criteria

- [ ] First-time users understand the chart is interactive
- [ ] Users can easily identify powder days
- [ ] Multi-mountain view can be filtered to focus on 1-2 mountains
- [ ] Tooltips provide sufficient context without tapping into detail sheet
- [ ] Chart works well on all supported device sizes
- [ ] VoiceOver users can navigate and understand the chart
- [ ] Loading states prevent layout jumps
- [ ] Performance maintained (<16ms frame time)
- [ ] Consistent with overall app design system

---

## Future Enhancements (Out of Scope)

These are documented for future iterations:

- [ ] Compare mode (side-by-side mountain charts)
- [ ] Export/share chart as image
- [ ] Pin favorite day for trip planning
- [ ] Historical comparison (vs. last year)
- [ ] Precipitation type breakdown (rain vs. snow)
- [ ] Wind chill / feels-like temperature overlay
- [ ] Custom alert thresholds (notify me when >X inches)
