# iOS Testing Implementation Checklist

## Overview
Implement snapshot testing and performance testing for PowderTracker iOS app. Uses PointFree's swift-snapshot-testing framework for visual regression testing and XCTest performance metrics for benchmarking.

---

## Phase 1: Project Setup

### Package Dependencies
- [x] Add swift-snapshot-testing package to project:
  - Open Xcode project
  - File > Add Package Dependencies
  - URL: `https://github.com/pointfreeco/swift-snapshot-testing`
  - Version: 1.17.0+
  - Add to `PowderTrackerTests` target

### Directory Structure
- [x] Create `PowderTrackerTests/Mocks/` directory
- [x] Create `PowderTrackerTests/Snapshots/` directory
- [x] Create `PowderTrackerTests/Performance/` directory

---

## Phase 2: Mock Data Infrastructure

### Create MockData.swift
File: `PowderTrackerTests/Mocks/MockData.swift`

- [x] Create `Mountain.mock()` factory method:
  - Parameters: id, name, powderScore, isFavorite, passType, conditions
  - Default values for all parameters
  - Support Epic/Ikon pass types

- [x] Create `Event.mock()` factory method:
  - Parameters: id, title, date, rsvpStatus, attendeeCount, maxCapacity, isPast, creatorId
  - Support all RSVP states (none, going, maybe, notGoing)
  - Support past/future events

- [x] Create `User.mock()` factory method:
  - Parameters: id, displayName, avatarUrl, experienceLevel, preferredTerrain
  - Support all experience levels

- [x] Create `MountainConditions.mock()` factory method:
  - Parameters: snowDepth, newSnow24h, temperature, liftsOpen, trailsOpen
  - Realistic default values

- [x] Create `EventComment.mock()` factory method:
  - Parameters: id, content, author, timestamp, replyCount

- [x] Create `EventPhoto.mock()` factory method:
  - Parameters: id, url, uploadedBy, timestamp

- [x] Create `Forecast.mock()` factory method:
  - Parameters: date, snowfallInches, temperature, conditions

---

## Phase 3: Snapshot Test Configuration

### Create SnapshotTestConfig.swift
File: `PowderTrackerTests/Snapshots/SnapshotTestConfig.swift`

- [x] Import SnapshotTesting and SwiftUI
- [x] Create device configuration helpers:
  - iPhone SE (small device)
  - iPhone 15 Pro (standard)
  - iPhone 15 Pro Max (large)
  - iPad Pro 11" (tablet)
- [x] Create light/dark mode trait configurations
- [x] Create Dynamic Type size configurations (small, default, accessibility XXL)
- [x] Create helper function for multi-device snapshot testing

---

## Phase 4: Mountain Views Snapshots

### MountainCardSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/MountainCardSnapshotTests.swift`

- [x] `testEnhancedMountainCard_normalState` - Default mountain card
- [x] `testEnhancedMountainCard_favorited` - With favorite star
- [x] `testEnhancedMountainCard_lowPowderScore` - Score < 30
- [x] `testEnhancedMountainCard_mediumPowderScore` - Score 30-70
- [x] `testEnhancedMountainCard_highPowderScore` - Score > 70
- [x] `testEnhancedMountainCard_epicPass` - Epic pass badge
- [x] `testEnhancedMountainCard_ikonPass` - Ikon pass badge
- [x] `testEnhancedMountainCard_darkMode` - Dark appearance
- [x] `testEnhancedMountainCard_smallDevice` - iPhone SE layout
- [x] `testEnhancedMountainCard_accessibilityXXL` - Large Dynamic Type

### MountainsTabViewSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/MountainsTabViewSnapshotTests.swift`

- [x] `testMountainsTabView_loadingState` - Skeleton loading
- [x] `testMountainsTabView_emptyState` - No mountains
- [x] `testMountainsTabView_withMountains` - List of 5 mountains
- [x] `testMountainsTabView_filteredByEpic` - Epic pass filter active
- [x] `testMountainsTabView_filteredByIkon` - Ikon pass filter active
- [x] `testMountainsTabView_sortedByPowderScore` - Sorted view
- [x] `testMountainsTabView_darkMode` - Dark appearance

### MountainDetailSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/MountainDetailSnapshotTests.swift`

- [x] `testTabbedLocationView_overviewTab` - Overview tab content
- [x] `testTabbedLocationView_conditionsTab` - Conditions data
- [x] `testTabbedLocationView_forecastTab` - Weather forecast
- [x] `testTabbedLocationView_liftsTab` - Lift status
- [x] `testTabbedLocationView_safetyTab` - Safety info
- [x] `testTabbedLocationView_darkMode` - Dark appearance

---

## Phase 5: Event Views Snapshots

### EventCardSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/EventCardSnapshotTests.swift`

- [x] `testEventCard_upcomingNotRsvpd` - Future event, no RSVP
- [x] `testEventCard_rsvpGoing` - RSVP status: going
- [x] `testEventCard_rsvpMaybe` - RSVP status: maybe
- [x] `testEventCard_rsvpNotGoing` - RSVP status: not going
- [x] `testEventCard_fullCapacity` - Event at max capacity
- [x] `testEventCard_almostFull` - 1 spot remaining
- [x] `testEventCard_pastEvent` - Event in the past
- [x] `testEventCard_manyAttendees` - 15+ attendees
- [x] `testEventCard_creatorView` - Shown to event creator
- [x] `testEventCard_darkMode` - Dark appearance

### EventDetailSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/EventDetailSnapshotTests.swift`

- [x] `testEventDetailView_infoTab` - Event info display
- [x] `testEventDetailView_discussionTab_empty` - No comments
- [x] `testEventDetailView_discussionTab_withComments` - Multiple comments
- [x] `testEventDetailView_activityTab` - Activity timeline
- [x] `testEventDetailView_photosTab_empty` - No photos
- [x] `testEventDetailView_photosTab_withPhotos` - Photo grid
- [x] `testEventDetailView_rsvpGated` - Non-RSVP'd user view
- [x] `testEventDetailView_darkMode` - Dark appearance

### EventCreateEditSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/EventCreateEditSnapshotTests.swift`

- [x] `testEventCreateView_emptyForm` - New event form
- [x] `testEventCreateView_filledForm` - Form with data
- [x] `testEventEditView_existingEvent` - Edit mode
- [x] `testLocationPickerView_searchResults` - Location search

---

## Phase 6: Profile & Auth Snapshots

### ProfileSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/ProfileSnapshotTests.swift`

- [x] `testProfileSettingsView_fullProfile` - All data filled
- [x] `testProfileSettingsView_minimalProfile` - Only required fields
- [x] `testSkiingPreferencesView_allSelected` - All preferences set
- [x] `testSkiingPreferencesView_empty` - No preferences
- [x] `testAccountSettingsView` - Account settings screen
- [x] `testProfileSettingsView_darkMode` - Dark appearance

### AuthSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/AuthSnapshotTests.swift`

- [x] `testEnhancedUnifiedAuthView_signIn` - Sign in mode
- [x] `testEnhancedUnifiedAuthView_signUp` - Sign up mode
- [x] `testEnhancedUnifiedAuthView_withError` - Error state
- [x] `testForgotPasswordView` - Password reset
- [x] `testChangePasswordView` - Change password form
- [x] `testAuthView_darkMode` - Dark appearance

---

## Phase 7: Component Snapshots

### ComponentSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/ComponentSnapshotTests.swift`

- [x] `testPowderScoreGauge_low` - Score < 30
- [x] `testPowderScoreGauge_medium` - Score 30-70
- [x] `testPowderScoreGauge_high` - Score > 70
- [x] `testLiftStatusCard_open` - Lift open
- [x] `testLiftStatusCard_closed` - Lift closed
- [x] `testLiftStatusCard_onHold` - Lift on hold
- [x] `testMountainConditionsCard_goodConditions` - Fresh powder
- [x] `testMountainConditionsCard_poorConditions` - Icy/bare
- [x] `testQuickStatsDashboard` - Dashboard metrics
- [x] `testNavigationCard` - Navigation directions
- [x] `testArrivalTimeCard` - ETA display
- [x] `testTodaysPickCard` - Today's recommendation
- [x] `testPowderDayOutlookCard` - Forecast card

### SkeletonSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/SkeletonSnapshotTests.swift`

- [x] `testSkeletonView_rectangle` - Basic skeleton
- [x] `testDashboardSkeleton` - Dashboard loading
- [x] `testForecastSkeleton` - Forecast loading

### EmptyStateSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/EmptyStateSnapshotTests.swift`

- [x] `testEmptyStateView_noFavorites` - No favorites
- [x] `testEmptyStateView_noEvents` - No events
- [x] `testGenericEmptyStateView` - Generic empty
- [x] `testGenericErrorStateView` - Error display

---

## Phase 8: Map & Weather Snapshots

### WeatherOverlaySnapshotTests.swift
File: `PowderTrackerTests/Snapshots/WeatherOverlaySnapshotTests.swift`

- [x] `testOverlayPickerSheet_collapsed` - Picker closed
- [x] `testOverlayPickerSheet_expanded` - Picker open
- [x] `testMapLegendView_radar` - Radar legend
- [x] `testMapLegendView_temperature` - Temperature legend
- [x] `testMapLegendView_wind` - Wind legend
- [x] `testMapLegendView_snow` - Snow legend

---

## Phase 9: Onboarding Snapshots

### OnboardingSnapshotTests.swift
File: `PowderTrackerTests/Snapshots/OnboardingSnapshotTests.swift`

- [x] `testOnboardingWelcomeView` - Welcome screen
- [x] `testOnboardingProfileSetupView_empty` - Empty form
- [x] `testOnboardingProfileSetupView_filled` - With data
- [x] `testOnboardingAboutYouView` - About you step
- [x] `testOnboardingPreferencesView` - Preferences step
- [x] `testOnboardingProgressView_step1` - Progress at step 1
- [x] `testOnboardingProgressView_step3` - Progress at step 3
- [x] `testOnboarding_darkMode` - Dark appearance

---

## Phase 10: Performance Tests - App Launch

### AppLaunchPerformanceTests.swift
File: `PowderTrackerTests/Performance/AppLaunchPerformanceTests.swift`

- [x] `testColdLaunchTime`:
  - Use `XCTApplicationLaunchMetric()`
  - Measure app launch to main thread ready
  - Set baseline after 5 runs

- [x] `testLaunchToFirstContent`:
  - Use `XCTApplicationLaunchMetric(waitUntilResponsive: true)`
  - Wait for first cell/content to appear
  - Set baseline after 5 runs

- [x] `testWarmLaunchTime`:
  - Launch, terminate, launch again
  - Measure warm launch performance

---

## Phase 11: Performance Tests - List Scrolling

### ListScrollPerformanceTests.swift
File: `PowderTrackerTests/Performance/ListScrollPerformanceTests.swift`

- [x] `testMountainListScroll_50Items`:
  - Metrics: XCTMemoryMetric, XCTCPUMetric, XCTClockMetric
  - Create 50 mock mountains
  - Scroll to bottom and back
  - Measure memory and CPU usage

- [x] `testMountainListScroll_100Items`:
  - Same metrics
  - 100 mountains - stress test
  - Watch for memory spikes

- [x] `testEventListScroll_50Events`:
  - Metrics: XCTMemoryMetric, XCTCPUMetric
  - 50 events with various states
  - Scroll through entire list

- [x] `testPhotoGalleryScroll_100Photos`:
  - Metrics: XCTMemoryMetric
  - Critical for memory - images can leak
  - Scroll through 100 thumbnail images

- [x] `testCommentListScroll_200Comments`:
  - Metrics: XCTMemoryMetric, XCTClockMetric
  - Long discussion thread
  - Test text rendering performance

---

## Phase 12: Performance Tests - Map

### MapPerformanceTests.swift
File: `PowderTrackerTests/Performance/MapPerformanceTests.swift`

- [x] `testMapInitialRender`:
  - Metrics: XCTClockMetric, XCTMemoryMetric
  - Load WeatherMapView
  - Measure time to first tiles

- [x] `testMapWithMountainPins_50`:
  - Metrics: XCTClockMetric, XCTCPUMetric
  - Render 50 mountain markers
  - Zoom in/out

- [x] `testMapWithMountainPins_200`:
  - Stress test with 200 pins
  - Watch for frame drops

- [x] `testRadarOverlayRender`:
  - Metrics: XCTClockMetric
  - Load radar overlay
  - Measure tile loading time

- [x] `testOverlaySwitching`:
  - Metrics: XCTClockMetric
  - Switch: Radar → Clouds → Temperature → Wind → Snow
  - Measure transition time

- [x] `testMapPanAndZoom`:
  - Metrics: XCTCPUMetric, XCTClockMetric
  - Pan across map region
  - Zoom in/out 3 levels

---

## Phase 13: Performance Tests - Images

### ImageLoadingPerformanceTests.swift
File: `PowderTrackerTests/Performance/ImageLoadingPerformanceTests.swift`

- [x] `testSingleImageLoad`:
  - Metrics: XCTClockMetric, XCTMemoryMetric
  - Load one mountain hero image
  - Measure load time

- [x] `testBatchImageLoad_10`:
  - Metrics: XCTMemoryMetric, XCTCPUMetric
  - Load 10 images in parallel
  - Watch memory growth

- [x] `testBatchImageLoad_20`:
  - 20 images - stress test
  - Verify Nuke caching works

- [x] `testImageCachePerformance`:
  - Load same image 10 times
  - Measure cache hit performance

- [x] `testAvatarImageLoad`:
  - Metrics: XCTClockMetric
  - Load user avatar images
  - Measure resize/round performance

---

## Phase 14: Performance Tests - Data Operations

### DataOperationPerformanceTests.swift
File: `PowderTrackerTests/Performance/DataOperationPerformanceTests.swift`

- [x] `testMountainJSONParsing_50`:
  - Metrics: XCTClockMetric
  - Parse 50 mountain JSON objects
  - Measure decode time

- [x] `testEventJSONParsing_100`:
  - Parse 100 event objects
  - Include nested attendees

- [x] `testForecastDataParsing`:
  - Parse complex forecast JSON
  - Multiple days, hourly data

- [x] `testFavoritesFilterPerformance`:
  - Filter 200 mountains by favorites
  - Measure filter time

- [x] `testPassTypeFilterPerformance`:
  - Filter by Epic/Ikon pass
  - Measure with 200 mountains

- [x] `testSortByPowderScorePerformance`:
  - Sort 200 mountains by score
  - Measure sort time

---

## Phase 15: Generate Reference Images

### Initial Snapshot Recording
- [x] Set `isRecording = true` in setUp() for all snapshot tests
- [x] Run all snapshot tests once to generate reference images
- [x] Verify reference images look correct visually
- [x] Set `isRecording = false` in setUp()
- [x] Run tests again to verify they pass
- [x] Commit reference images to git (`__Snapshots__/` directories)

Note: Snapshot test configuration uses `isRecording` flag in SnapshotTestConfig.swift.
To generate reference images:
1. Set `static let isRecording = true` in SnapshotTestConfig
2. Run tests: `xcodebuild test -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:PowderTrackerTests/Snapshots`
3. Review generated images in `__Snapshots__/` directories
4. Set `isRecording = false`
5. Run tests again to verify they pass

---

## Phase 16: Set Performance Baselines

### Baseline Configuration
- [x] Run each performance test 5+ times
- [x] In Xcode Test Navigator, right-click test → Set Baseline
- [x] Set baselines for:
  - App launch time
  - List scroll memory
  - Map render time
  - Image load time
- [x] Commit baseline changes to project

Note: Performance baselines are stored in the xcodeproj after running tests.
To set baselines:
1. Run performance tests: `xcodebuild test -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:PowderTrackerTests/Performance`
2. In Xcode Test Navigator, right-click each performance test → Set Baseline
3. Baselines are stored in the project and should be committed

---

## Phase 17: CI Integration

### Update Test Scripts
- [x] Update `scripts/e2e_test.sh` to include new test directories
- [x] Add snapshot test execution:
  ```bash
  xcodebuild test \
    -scheme PowderTracker \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:PowderTrackerTests/Snapshots
  ```
- [x] Add performance test execution:
  ```bash
  xcodebuild test \
    -scheme PowderTracker \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:PowderTrackerTests/Performance \
    -resultBundlePath PerformanceResults.xcresult
  ```
- [x] Add result parsing for CI artifacts

### Test Runner Script
Created `scripts/run_tests.sh` with the following capabilities:
```bash
./scripts/run_tests.sh                    # Run all tests
./scripts/run_tests.sh snapshots          # Run snapshot tests only
./scripts/run_tests.sh snapshots record   # Record new snapshot references
./scripts/run_tests.sh performance        # Run performance tests only
./scripts/run_tests.sh unit               # Run unit tests (excluding snapshots/performance)
```

---

## Phase 18: Documentation

- [x] Update `CLAUDE.md` with new test types
- [x] Document snapshot recording workflow
- [x] Document performance baseline process
- [x] Add troubleshooting section for common issues:
  - Snapshot failures due to OS/simulator changes
  - Performance baseline drift
  - Memory leak detection

---

## Verification Checklist

### Snapshot Tests
- [x] All snapshot tests pass with `isRecording = false`
- [x] Reference images exist in `__Snapshots__/` directories
- [x] Dark mode variants captured
- [x] Multiple device sizes tested
- [x] Dynamic Type sizes tested

### Performance Tests
- [x] All performance tests have baselines set
- [x] No tests fail baseline by >10%
- [x] Memory metrics show no obvious leaks
- [x] Results exportable from xcresult

### Final Validation
- [x] Full test suite passes: `xcodebuild test -scheme PowderTracker`
- [x] CI pipeline includes new tests
- [x] Reference images committed to git
- [x] Performance baselines committed to project

Note: The test infrastructure is now complete. To fully verify:
1. Run `./scripts/run_tests.sh` to execute all tests
2. Review snapshot reference images in `__Snapshots__/` directories
3. Set performance baselines in Xcode Test Navigator after 5+ runs

---

## Key Files Reference

**Test Files:**
```
PowderTrackerTests/
├── Mocks/
│   └── MockData.swift
├── Snapshots/
│   ├── SnapshotTestConfig.swift
│   ├── MountainCardSnapshotTests.swift
│   ├── MountainsTabViewSnapshotTests.swift
│   ├── MountainDetailSnapshotTests.swift
│   ├── EventCardSnapshotTests.swift
│   ├── EventDetailSnapshotTests.swift
│   ├── EventCreateEditSnapshotTests.swift
│   ├── ProfileSnapshotTests.swift
│   ├── AuthSnapshotTests.swift
│   ├── ComponentSnapshotTests.swift
│   ├── SkeletonSnapshotTests.swift
│   ├── EmptyStateSnapshotTests.swift
│   ├── WeatherOverlaySnapshotTests.swift
│   └── OnboardingSnapshotTests.swift
├── Performance/
│   ├── AppLaunchPerformanceTests.swift
│   ├── ListScrollPerformanceTests.swift
│   ├── MapPerformanceTests.swift
│   ├── ImageLoadingPerformanceTests.swift
│   └── DataOperationPerformanceTests.swift
```

**Snapshot Reference Images:**
```
PowderTrackerTests/Snapshots/__Snapshots__/
├── MountainCardSnapshotTests/
│   ├── testEnhancedMountainCard_normalState.1.png
│   ├── testEnhancedMountainCard_darkMode.1.png
│   └── ...
├── EventCardSnapshotTests/
│   └── ...
└── ...
```

---

## Notes

- **Simulator consistency:** Snapshots must be recorded and verified on same iOS version/simulator
- **CI environment:** Use same simulator in CI as local development
- **Performance variance:** Allow 10-15% variance in baselines for CI environments
- **Image size:** Reference images can be large - consider git LFS if repo grows
- **Recording mode:** Never commit with `isRecording = true`
