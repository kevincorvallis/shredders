# iOS Performance Optimization Checklist

## Overview
Comprehensive performance optimization checklist for PowderTracker iOS app based on codebase analysis, WWDC 2025 guidance, and industry best practices. Addresses critical bottlenecks, memory issues, and rendering inefficiencies.

**Analysis Summary:**
- 12 performance issues identified (3 critical, 5 moderate, 4 minor)
- Estimated impact: 50-70% reduction in list scroll lag after fixes
- Primary targets: DateFormatter abuse, image caching, view re-renders

---

## Phase 1: Critical DateFormatter Fixes (HIGHEST PRIORITY)

### Background
Creating `DateFormatter()` is extremely expensive (~1ms per instance). Current codebase creates 123 instances across 56 files, many in view bodies and loops.

### EventsView.swift - DateFormatter in Row Views
File: `Views/Events/EventsView.swift` (Lines 670-687)

- [ ] Create static cached DateFormatter for event dates:
  ```swift
  private static let eventDateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEE, MMM d"
      return formatter
  }()
  ```

- [ ] Create static cached DateFormatter for event times:
  ```swift
  private static let eventTimeFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "h:mm a"
      return formatter
  }()
  ```

- [ ] Replace inline DateFormatter() calls in EventRowView with static versions

- [ ] Create static RelativeDateTimeFormatter:
  ```swift
  private static let relativeDateFormatter: RelativeDateTimeFormatter = {
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .abbreviated
      return formatter
  }()
  ```

### EnhancedMountainCard.swift - DateFormatter in Computed Property
File: `Views/Components/EnhancedMountainCard.swift` (Line 255)

- [ ] Move DateFormatter from `shouldShowLeaveNowBadge` computed property to static constant

- [ ] Cache the badge calculation result in parent view/ViewModel

- [ ] Pre-compute "leave now" status in MountainSelectionViewModel when data loads

### HomeViewModel.swift - DateFormatter in ViewModel
File: `ViewModels/HomeViewModel.swift` (Lines 200-202)

- [ ] Replace DateFormatter() instantiation with static formatter

- [ ] Create shared DateFormatters.swift utility file:
  ```swift
  enum DateFormatters {
      static let shortDate: DateFormatter = { ... }()
      static let time: DateFormatter = { ... }()
      static let relative: RelativeDateTimeFormatter = { ... }()
      static let iso8601: ISO8601DateFormatter = { ... }()
  }
  ```

### Global DateFormatter Audit
- [ ] Run grep for `DateFormatter()` across codebase
- [ ] Replace all inline DateFormatter() with shared static instances
- [ ] Verify no DateFormatter created in:
  - View body
  - Computed properties
  - ForEach loops
  - Closures called repeatedly

---

## Phase 2: Image Loading & Caching

### MountainLogoView.swift - Missing Nuke Integration
File: `Views/Components/MountainLogoView.swift` (Lines 34-46)

**Problem:** Using built-in `AsyncImage` which has poor caching. Same logos re-download when scrolling.

- [ ] Replace AsyncImage with LazyImage from NukeUI:
  ```swift
  // BEFORE
  AsyncImage(url: url) { phase in ... }

  // AFTER
  LazyImage(url: url) { state in
      if let image = state.image {
          image.resizable().aspectRatio(contentMode: .fit)
      } else if state.error != nil {
          Image(systemName: "photo")
      } else {
          ProgressView()
      }
  }
  .processors([.resize(width: 80)])  // Match display size
  .priority(.normal)
  ```

- [ ] Import NukeUI in MountainLogoView.swift

- [ ] Add image size processors to prevent oversized images in memory

### EnhancedMountainCard.swift - Image Optimization
File: `Views/Components/EnhancedMountainCard.swift`

- [ ] Use LazyImage for any remote images

- [ ] Add processor to resize images to card dimensions:
  ```swift
  .processors([
      .resize(width: 120, unit: .points),
      .roundedCorners(radius: 12)
  ])
  ```

### EventPhotosView.swift - Gallery Memory Management
File: `Views/Events/EventPhotosView.swift`

- [ ] Limit initial photo render count:
  ```swift
  ForEach(photos.prefix(50)) { photo in
      // render
  }
  .onAppear { loadMoreIfNeeded() }
  ```

- [ ] Add thumbnail processor for gallery grid

- [ ] Implement progressive loading for full-size images

### ImageCacheConfig.swift - Enhanced Memory Management
File: `Config/ImageCacheConfig.swift`

- [ ] Add background cache trimming:
  ```swift
  static func handleAppBackground() {
      ImageCache.shared.trim(toCost: ImageCache.shared.costLimit / 2)
  }
  ```

- [ ] Add URL cache clearing on memory warning:
  ```swift
  URLCache.shared.removeAllCachedResponses()
  ```

- [ ] Register for UIApplication lifecycle notifications

---

## Phase 3: SwiftUI View Optimization

### MountainsTabView.swift - View Restructuring (1,967 lines)
File: `Views/Mountains/MountainsTabView.swift`

**Problem:** Monolithic file with 4 sub-views, excessive filtering, all tabs loaded immediately.

- [ ] Extract ConditionsView into separate file:
  - Create `Views/Mountains/ConditionsView.swift`
  - Move lines 353-600 to new file
  - Import in MountainsTabView

- [ ] Extract PlannerView into separate file:
  - Create `Views/Mountains/PlannerView.swift`

- [ ] Extract ExploreView into separate file:
  - Create `Views/Mountains/ExploreView.swift`

- [ ] Extract MyPassView into separate file:
  - Create `Views/Mountains/MyPassView.swift`

- [ ] Implement lazy tab loading:
  ```swift
  TabView(selection: $selectedTab) {
      Group {
          if selectedTab == .conditions || hasLoadedConditions {
              ConditionsView(...)
                  .onAppear { hasLoadedConditions = true }
          } else {
              ProgressView()
          }
      }
      .tag(MountainTab.conditions)
      // ... repeat for other tabs
  }
  ```

### ConditionsView Filtering - Memoization
File: `Views/Mountains/MountainsTabView.swift` (Lines 353-402)

**Problem:** `filteredAndSortedMountains` recalculates on every view update.

- [ ] Move filtering logic to ViewModel:
  ```swift
  class MountainsViewModel: ObservableObject {
      @Published var filteredMountains: [Mountain] = []

      private var filterDebouncer: Timer?

      func updateFilters(passFilter: PassFilter, sortBy: SortOption) {
          filterDebouncer?.invalidate()
          filterDebouncer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
              self.applyFilters(passFilter: passFilter, sortBy: sortBy)
          }
      }
  }
  ```

- [ ] Cache filter results and only recalculate when filter inputs change

- [ ] Add Equatable conformance to filter enum for proper comparison

### List Performance - EventsView.swift
File: `Views/Events/EventsView.swift` (Lines 323-331)

- [ ] Add explicit `.id()` modifier to ForEach items:
  ```swift
  ForEach(events) { event in
      EventRowView(event: event)
          .id(event.id)  // Helps SwiftUI diff
  }
  ```

- [ ] Simplify EventRowView (currently 160 lines):
  - Extract subviews for attendee avatars
  - Extract subviews for RSVP status badge
  - Pre-compute complex conditionals in ViewModel

- [ ] Consider replacing ScrollView + LazyVStack with List for better cell recycling:
  ```swift
  List {
      ForEach(events) { event in
          EventRowView(event: event)
      }
      .listRowInsets(EdgeInsets(...))
      .listRowSeparator(.hidden)
  }
  .listStyle(.plain)
  ```

---

## Phase 4: State Management Optimization

### Migrate to @Observable (iOS 17+)
**Impact:** 30-40% reduction in unnecessary view updates

- [ ] Update MountainSelectionViewModel:
  ```swift
  // BEFORE
  class MountainSelectionViewModel: ObservableObject {
      @Published var mountains: [Mountain] = []
      @Published var isLoading = false
  }

  // AFTER
  @Observable
  class MountainSelectionViewModel {
      var mountains: [Mountain] = []
      var isLoading = false
  }
  ```

- [ ] Update EventsViewModel to @Observable

- [ ] Update HomeViewModel to @Observable

- [ ] Update all ViewModels to @Observable pattern

- [ ] Update view bindings from `@ObservedObject` to direct access

### EquatableView for Complex Cards
- [ ] Add Equatable conformance to EnhancedMountainCard:
  ```swift
  extension EnhancedMountainCard: Equatable {
      static func == (lhs: Self, rhs: Self) -> Bool {
          lhs.mountain.id == rhs.mountain.id &&
          lhs.conditions?.snowfall24h == rhs.conditions?.snowfall24h &&
          lhs.powderScore == rhs.powderScore &&
          lhs.isFavorite == rhs.isFavorite
      }
  }
  ```

- [ ] Wrap cards in EquatableView in lists:
  ```swift
  EquatableView(content: EnhancedMountainCard(...))
  ```

- [ ] Add Equatable to EventRowView

- [ ] Add Equatable to other heavy list cells

---

## Phase 5: Network Performance

### MountainSelectionViewModel.swift - Concurrency Limits
File: `ViewModels/MountainSelectionViewModel.swift` (Lines 73-116)

**Problem:** Creates 52 concurrent tasks (26 scores + 26 conditions) with no limit.

- [ ] Implement concurrency limit:
  ```swift
  func fetchAllConditions() async {
      await withTaskGroup(of: (String, MountainConditions?).self) { group in
          var activeTasks = 0
          let maxConcurrent = 6

          for mountain in mountains {
              // Wait if at capacity
              while activeTasks >= maxConcurrent {
                  if let result = await group.next() {
                      activeTasks -= 1
                      // process result
                  }
              }

              activeTasks += 1
              group.addTask {
                  // fetch
              }
          }

          // Collect remaining
          for await result in group {
              // process
          }
      }
  }
  ```

- [ ] Batch API requests where possible (fetch multiple IDs in one call)

### Request Deduplication
- [ ] Implement in-flight request tracking:
  ```swift
  class EventService {
      private var inflightRequests: [String: Task<Event, Error>] = [:]

      func fetchEvent(id: String) async throws -> Event {
          if let existing = inflightRequests[id] {
              return try await existing.value
          }

          let task = Task { ... }
          inflightRequests[id] = task
          defer { inflightRequests.removeValue(forKey: id) }
          return try await task.value
      }
  }
  ```

- [ ] Apply to MountainService

- [ ] Apply to EventService

### Local Data Caching
- [ ] Implement DataCache actor:
  ```swift
  actor DataCache {
      private var cache: [String: (data: Any, timestamp: Date)] = [:]
      private let maxAge: TimeInterval = 300  // 5 minutes

      func get<T>(_ key: String) -> T? { ... }
      func set<T>(_ key: String, value: T) { ... }
  }
  ```

- [ ] Add cache layer to MountainSelectionViewModel

- [ ] Add cache layer to EventsViewModel

- [ ] Cache mountain conditions for 5 minutes

- [ ] Cache events list for 2 minutes

---

## Phase 6: Map Performance

### WeatherTileOverlay.swift - Tile Caching
File: `Services/WeatherTileOverlay.swift` (Lines 145-194)

- [ ] Add NSCache for tiles:
  ```swift
  class WeatherTileOverlay: MKTileOverlay {
      private static let tileCache = NSCache<NSString, UIImage>()

      override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
          let cacheKey = "\(overlayType.rawValue)-\(path.z)-\(path.x)-\(path.y)" as NSString

          if let cached = Self.tileCache.object(forKey: cacheKey),
             let data = cached.pngData() {
              result(data, nil)
              return
          }

          super.loadTile(at: path) { data, error in
              if let data = data, let image = UIImage(data: data) {
                  Self.tileCache.setObject(image, forKey: cacheKey)
              }
              result(data, error)
          }
      }
  }
  ```

- [ ] Set cache count limit (e.g., 200 tiles)

- [ ] Clear cache on memory warning

### WeatherMapView.swift - Debounce Updates
File: `Views/Map/WeatherMapView.swift` (Lines 58-82)

- [ ] Add debouncing for overlay changes:
  ```swift
  @MainActor
  class WeatherOverlayManager: ObservableObject {
      private var updateTimer: Timer?

      func scheduleOverlayUpdate(type: OverlayType) {
          updateTimer?.invalidate()
          updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
              self.applyOverlay(type)
          }
      }
  }
  ```

- [ ] Debounce region change callbacks

- [ ] Only refresh visible tiles on pan/zoom

### Mountain Pins Optimization
- [ ] Implement annotation clustering for 200+ pins:
  ```swift
  class MountainAnnotationView: MKMarkerAnnotationView {
      override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
          super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
          clusteringIdentifier = "mountain"
      }
  }
  ```

- [ ] Use lightweight annotation views (no custom images at low zoom)

---

## Phase 7: App Launch Optimization

### AppDelegate - Lazy Initialization
File: `AppDelegate.swift`

- [ ] Defer non-critical services:
  ```swift
  func application(...) -> Bool {
      // CRITICAL - must happen first
      ImageCacheConfig.configure()
      UNUserNotificationCenter.current().delegate = self

      // DEFERRED - not needed for first frame
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          self.initializeNonCriticalServices()
      }

      return true
  }

  private func initializeNonCriticalServices() {
      Task { @MainActor in
          await PushNotificationManager.shared.checkAuthorizationStatus()
      }
      // Analytics, crash reporting, etc.
  }
  ```

- [ ] Pre-warm Supabase connection in background:
  ```swift
  DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0) {
      Task { @MainActor in
          _ = try? await supabase.from("mountains").select("id").limit(1).execute()
      }
  }
  ```

### ContentView - Load Content Under Splash
- [ ] Load critical data while intro animation plays:
  ```swift
  var body: some Scene {
      WindowGroup {
          ZStack {
              ContentView(...)
                  .task {
                      await loadCriticalData()
                  }
                  .opacity(showIntro ? 0 : 1)

              if showIntro {
                  IntroView(showIntro: $showIntro)
              }
          }
      }
  }
  ```

---

## Phase 8: Specific Component Fixes

### EventDetailView.swift - QR Code Caching
File: `Views/Events/EventDetailView.swift` (Lines 856-872)

- [ ] Cache generated QR code:
  ```swift
  @State private var cachedQRCode: UIImage?

  var qrCodeImage: UIImage {
      if let cached = cachedQRCode { return cached }
      let generated = generateQRCode(from: event.id)
      cachedQRCode = generated
      return generated
  }
  ```

### HomeViewModel.swift - Dictionary Filtering
File: `ViewModels/HomeViewModel.swift` (Lines 223-229, 416-418)

- [ ] Pre-filter and cache favorite mountains:
  ```swift
  private var cachedFavoriteMountainData: [String: MountainData]?

  var favoriteMountainData: [String: MountainData] {
      if let cached = cachedFavoriteMountainData { return cached }
      let favorites = Set(favoritesManager.favoriteIds)
      let filtered = mountainData.filter { favorites.contains($0.key) }
      cachedFavoriteMountainData = filtered
      return filtered
  }

  // Invalidate on favorites change
  func invalidateFavoriteCache() {
      cachedFavoriteMountainData = nil
  }
  ```

### MountainSelectionViewModel.swift - Region Filters
File: `ViewModels/MountainSelectionViewModel.swift` (Lines 148-158)

- [ ] Consolidate region filtering:
  ```swift
  private var mountainsByRegion: [String: [Mountain]] = [:]

  func mountains(in region: String) -> [Mountain] {
      if mountainsByRegion.isEmpty {
          mountainsByRegion = Dictionary(grouping: mountains) { $0.region }
      }
      return mountainsByRegion[region] ?? []
  }
  ```

---

## Phase 9: Profiling & Verification

### Set Up Instruments Profiles
- [ ] Create Time Profiler template:
  - Profile release build only
  - Look for functions > 100ms on main thread
  - Check for recursive view body calls

- [ ] Use SwiftUI Instrument (Instruments 26/Xcode 16+):
  - View update timeline
  - State change triggers
  - Target: < 16ms per frame

### Add Performance Monitoring Code
- [ ] Create PerformanceMonitor utility:
  ```swift
  class PerformanceMonitor {
      static func trackRenderTime(for viewName: String, block: () -> Void) {
          let start = CFAbsoluteTimeGetCurrent()
          block()
          let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000

          if duration > 16 {
              print("⚠️ \(viewName) took \(duration)ms (target: <16ms)")
          }
      }
  }
  ```

- [ ] Add to critical views during development

### Debug Tools
- [ ] Add _printChanges() to suspect views:
  ```swift
  var body: some View {
      let _ = Self._printChanges()  // Debug only
      // view content
  }
  ```

- [ ] Use Memory Graph Debugger for retain cycles

- [ ] Profile with Thread Sanitizer enabled

---

## Phase 10: Performance Tests

### Add Baseline Tests
- [ ] Test mountain list scroll with 50 items (target: < 100MB memory)

- [ ] Test event list scroll with 100 items

- [ ] Test map pan/zoom with weather overlay (target: < 16ms frame time)

- [ ] Test app launch to first content (target: < 2 seconds cold)

- [ ] Test memory after heavy usage (target: < 150MB)

### Verify Fixes
- [ ] Measure scroll performance before/after DateFormatter fix

- [ ] Measure network requests before/after image caching

- [ ] Measure re-render count before/after @Observable migration

- [ ] Measure memory before/after image resizing

---

## Verification Checklist

### Critical Fixes Complete
- [ ] No DateFormatter() in view bodies
- [ ] No DateFormatter() in computed properties
- [ ] No DateFormatter() in loops
- [ ] All DateFormatter uses static cached instances

### Image Optimization Complete
- [ ] MountainLogoView uses LazyImage/Nuke
- [ ] All remote images have size processors
- [ ] Gallery implements progressive loading
- [ ] Memory warning handler clears caches

### View Optimization Complete
- [ ] MountainsTabView split into 4+ files
- [ ] Tab views load lazily
- [ ] Filter results are memoized
- [ ] Heavy cards have Equatable conformance

### Network Optimization Complete
- [ ] Concurrent requests limited to 6
- [ ] Request deduplication implemented
- [ ] Local cache layer active
- [ ] Pre-warming on app launch

### Map Optimization Complete
- [ ] Tile caching implemented
- [ ] Overlay updates debounced
- [ ] Annotation clustering active (if 200+ pins)

### Launch Optimization Complete
- [ ] Non-critical services deferred
- [ ] Content loads under splash
- [ ] Cold launch < 2 seconds

---

## Priority Summary

| Priority | Fix | Estimated Impact | Effort |
|----------|-----|------------------|--------|
| 🔴 Critical | DateFormatter static caching | 50-70% scroll improvement | 2 hours |
| 🔴 Critical | MountainLogoView Nuke integration | 80% fewer network requests | 30 min |
| 🔴 Critical | View body computation removal | 40% fewer re-renders | 2 hours |
| 🟠 High | MountainsTabView split | 25% fewer re-renders | 4 hours |
| 🟠 High | @Observable migration | 30-40% fewer updates | 1 day |
| 🟠 High | Network concurrency limits | 40% less memory | 2 hours |
| 🟡 Medium | Tile caching for map | Faster map interaction | 2 hours |
| 🟡 Medium | Filter memoization | Smoother list updates | 2 hours |
| 🟡 Medium | Local data cache | Faster repeat loads | 4 hours |
| 🟢 Low | QR code caching | Minor improvement | 15 min |
| 🟢 Low | Region filter optimization | Minor improvement | 30 min |

---

## Key Files Reference

**Critical Files to Modify:**
```
Views/Events/EventsView.swift           - DateFormatter + List
Views/Components/EnhancedMountainCard.swift - DateFormatter + Equatable
Views/Components/MountainLogoView.swift - AsyncImage → LazyImage
ViewModels/MountainSelectionViewModel.swift - Concurrency + Cache
Views/Mountains/MountainsTabView.swift  - Split + Lazy loading
Services/WeatherTileOverlay.swift       - Tile caching
```

**New Files to Create:**
```
Utils/DateFormatters.swift              - Shared formatters
Utils/DataCache.swift                   - Local caching layer
Utils/PerformanceMonitor.swift          - Debug utilities
Views/Mountains/ConditionsView.swift    - Extracted view
Views/Mountains/PlannerView.swift       - Extracted view
Views/Mountains/ExploreView.swift       - Extracted view
Views/Mountains/MyPassView.swift        - Extracted view
```

---

## Sources

- [Apple: Understanding SwiftUI Performance](https://developer.apple.com/documentation/Xcode/understanding-and-improving-swiftui-performance)
- [WWDC 2025: Optimize SwiftUI with Instruments](https://developer.apple.com/videos/play/wwdc2025/306/)
- [24 SwiftUI Performance Tips (2025)](https://medium.com/@ravisolankice12/24-swiftui-performance-tips-every-ios-developer-should-know-2025-edition-723340d9bd79)
- [Preventing Excessive View Re-renders](https://medium.com/mobile-innovation-network/swiftui-performance-optimization-a-guide-to-preventing-excessive-view-re-renders-28cbfe95173b)
- [@Observable Macro Performance](https://www.avanderlee.com/swiftui/observable-macro-performance-increase-observableobject/)
- [List vs LazyVStack Performance](https://fatbobman.com/en/posts/list-or-lazyvstack/)
- [MKMapView Tile Caching](https://github.com/stadiamaps/mapkit-caching-tile-overlay)
