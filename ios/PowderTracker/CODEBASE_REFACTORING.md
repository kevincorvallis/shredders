# iOS Codebase Refactoring Checklist

## Overview
Comprehensive cleanup, organization, and optimization checklist for PowderTracker iOS app. Organized by component area to allow focused refactoring sessions.

**Codebase Stats:**
- 269 Swift files
- ~68,667 lines of code
- 25+ services
- 188+ views

**Goals:**
- Consistent naming conventions
- Single responsibility principle
- Testable architecture
- Reduced coupling
- Improved maintainability

---

## Progress Summary

### Completed ✅
- **Phase 1.1**: Consolidated Utils/ into Utilities/ directory
- **Phase 2.1**: Standardized service naming (Manager → Service for 4 services)
- **Phase 2.2**: Added "View" suffix to 15 components (FilterChip, ConditionCard, WeatherMetric, etc.)
- **Phase 2.3**: Renamed `AvalancheDangerLevel` → `DangerLevel`
- **Phase 2.4**: Fixed ProfileImagePicker.swift → AvatarEditorView.swift mismatch
- **Phase 8.1**: Removed dead code (duplicate DateFormatters, unused DataCache, PerformanceMonitor, AlertTypes.swift, RoadCondition struct)
- **Phase 8.2**: Added MARK comments to large files (CommentListView, LiftStatusCard)
- **Phase 10.1**: Verified clean build succeeds

### Remaining (Complex/Risky)
- Phase 1.2-1.4: Directory reorganization (Models, Services, Views)
- Phase 3: Model consolidation (Comment, Photo, User DTOs)
- Phase 4-5: Service/View splitting (AuthService, EventService, large views)
- Phase 6-7: Protocols and dependency injection
- Phase 8.3: Documentation
- Phase 9: ViewModel cleanup
- Phase 10.2-10.3: Test and runtime verification

---

# PHASE 1: Directory Structure & Organization
**Effort: Low | Impact: High | Focus: File organization**

## 1.1 Consolidate Utilities Directories

### Problem
Two separate utility directories with unclear separation:
- `Utilities/` - 4 files (ChartAnnotation, ChartStyles, DesignSystem, HapticFeedback)
- `Utils/` - 3 files (DataCache, DateFormatters, PerformanceMonitor)

### Tasks
- [x] Create unified `Utilities/` directory structure:
  ```
  Utilities/
  ├── Cache/
  │   └── DataCache.swift
  ├── Charts/
  │   ├── ChartAnnotation.swift
  │   └── ChartStyles.swift
  ├── Design/
  │   └── DesignSystem.swift
  ├── Formatting/
  │   └── DateFormatters.swift
  ├── Haptics/
  │   └── HapticFeedback.swift
  └── Performance/
      └── PerformanceMonitor.swift
  ```

- [x] Move files from `Utils/` to `Utilities/` (DataCache.swift, DateFormatters.swift, PerformanceMonitor.swift)

- [x] Delete empty `Utils/` directory

- [x] Update all import statements across codebase (none needed - Swift doesn't use directory imports)

- [x] Verify build succeeds

---

## 1.2 Organize Models Directory

### Problem
Models directory is flat with 40+ files, some duplicated (Comment.swift + EventComment.swift)

### Current Structure (Flat)
```
Models/
├── ArrivalTime.swift
├── CheckIn.swift
├── Comment.swift           # Duplicate
├── Event.swift
├── EventComment.swift      # Duplicate
├── EventPhoto.swift        # Duplicate
├── Mountain.swift
├── Photo.swift             # Duplicate
├── User.swift
└── ... 30+ more files
```

### Tasks
- [ ] Create organized Models structure:
  ```
  Models/
  ├── Core/
  │   ├── User.swift
  │   ├── Mountain.swift
  │   └── Event.swift
  ├── Events/
  │   ├── EventActivity.swift
  │   ├── EventRSVP.swift
  │   └── Invite.swift
  ├── Social/
  │   ├── Comment.swift          # Consolidated
  │   ├── Photo.swift            # Consolidated
  │   ├── CheckIn.swift
  │   └── Like.swift
  ├── Weather/
  │   ├── Forecast.swift
  │   ├── WeatherConditions.swift
  │   └── PowderScore.swift
  ├── DTOs/
  │   ├── MountainResponses.swift
  │   ├── EventResponses.swift
  │   └── APIResponses.swift
  └── Enums/
      ├── RSVPStatus.swift
      ├── SkillLevel.swift
      └── EventStatus.swift
  ```

- [ ] Move files to appropriate subdirectories

- [ ] Update all import statements

- [ ] Verify build succeeds

---

## 1.3 Organize Services Directory

### Problem
Services directory is flat with 25+ files, mixed naming (Service vs Manager)

### Tasks
- [ ] Create organized Services structure:
  ```
  Services/
  ├── Auth/
  │   ├── AuthService.swift
  │   ├── SessionManager.swift       # Extracted from AuthService
  │   ├── TokenManager.swift         # Extracted from AuthService
  │   └── BiometricAuthService.swift
  ├── Data/
  │   ├── SupabaseClientManager.swift
  │   ├── APIClient.swift
  │   └── KeychainHelper.swift
  ├── Events/
  │   ├── EventService.swift
  │   ├── EventActivityService.swift  # Extracted
  │   └── EventSocialService.swift    # Extracted
  ├── Mountains/
  │   ├── MountainService.swift
  │   └── AvalancheService.swift
  ├── Social/
  │   ├── CommentService.swift
  │   ├── PhotoService.swift
  │   ├── CheckInService.swift
  │   └── LikeService.swift
  ├── Location/
  │   ├── LocationService.swift
  │   └── LocationSearchService.swift
  ├── Notifications/
  │   ├── PushNotificationService.swift  # Renamed from Manager
  │   └── AlertSubscriptionService.swift
  └── Storage/
      ├── AvatarService.swift
      └── FavoritesService.swift      # Renamed from Manager
  ```

- [ ] Create subdirectories

- [ ] Move files to appropriate locations

- [ ] Rename Manager → Service for consistency (see Phase 2)

- [ ] Update all import statements

---

## 1.4 Organize Views Directory

### Problem
Views directory has 188+ files with inconsistent organization

### Tasks
- [ ] Create organized Views structure:
  ```
  Views/
  ├── App/
  │   ├── ContentView.swift
  │   └── MainTabView.swift
  ├── Auth/
  │   ├── EnhancedUnifiedAuthView.swift
  │   ├── SignInWithAppleButton.swift
  │   └── ...
  ├── Events/
  │   ├── List/
  │   │   ├── EventsView.swift
  │   │   └── EventRowView.swift
  │   ├── Detail/
  │   │   ├── EventDetailView.swift
  │   │   └── EventTabViews/
  │   └── Create/
  │       ├── EventCreateView.swift
  │       └── EventEditView.swift
  ├── Mountains/
  │   ├── List/
  │   │   ├── MountainsTabView.swift
  │   │   └── MountainCards/
  │   ├── Detail/
  │   │   ├── TabbedLocationView.swift
  │   │   └── Tabs/
  │   └── Map/
  │       ├── WeatherMapView.swift
  │       └── Overlays/
  ├── Home/
  │   └── Dashboard/
  ├── Profile/
  │   ├── ProfileSettingsView.swift
  │   └── Settings/
  ├── Onboarding/
  │   └── Steps/
  └── Components/
      ├── Cards/
      ├── Charts/
      ├── Buttons/
      ├── Skeletons/
      ├── EmptyStates/
      └── Primitives/
  ```

- [ ] Create subdirectory structure

- [ ] Move views to appropriate locations

- [ ] Update all navigation and import statements

---

# PHASE 2: Naming Conventions
**Effort: Low | Impact: Medium | Focus: Consistency**

## 2.1 Standardize Service Naming

### Problem
Mixed naming: some use "Service", some use "Manager"

### Current State
| Current Name | Type |
|--------------|------|
| `FavoritesManager` | Manager |
| `AchievementManager` | Manager |
| `SkiDayActivityManager` | Manager |
| `PushNotificationManager` | Manager |
| `EventService` | Service |
| `AuthService` | Service |
| `PhotoService` | Service |

### Tasks
- [x] Rename `FavoritesManager` → `FavoritesService`
  - Update file: `Services/FavoritesManager.swift`
  - Update all references (~15 files)

- [x] Rename `AchievementManager` → `AchievementService`
  - Update file and references

- [x] Rename `SkiDayActivityManager` → `SkiDayActivityService`
  - Update file and references

- [x] Rename `PushNotificationManager` → `PushNotificationService`
  - Update file and references

- [x] Global find/replace to update all `.shared` references

- [x] Verify build succeeds

---

## 2.2 Standardize View Component Naming

### Problem
Inconsistent "View" suffix on components

### Components Missing "View" Suffix
```swift
// Current → Should Be
FilterChip → FilterChipView
QuickFilterChip → QuickFilterChipView
ConditionCard → ConditionCardView
NearbyCard → NearbyCardView
FavoriteCard → FavoriteCardView
RegionCard → RegionCardView
CompactMountainRow → CompactMountainRowView
SearchResultRow → SearchResultRowView
WeatherAlertRow → WeatherAlertRowView
ConditionStat → ConditionStatView
RegionDetailSheet → RegionDetailSheetView
SafetyAssessmentCard → SafetyAssessmentCardView
ExtendedWeatherCard → ExtendedWeatherCardView
WeatherMetric → WeatherMetricView
VisibilityCard → VisibilityCardView
```

### Tasks
- [x] Add "View" suffix to all SwiftUI component structs

- [x] Update file names to match struct names (N/A - components are inline in larger files)

- [x] Update all references across codebase

- [x] Verify build succeeds

---

## 2.3 Standardize Enum Naming

### Problem
Inconsistent enum naming patterns

### Current State
```swift
EventStatus      // Status suffix
RSVPStatus       // Status suffix (abbreviation)
SkillLevel       // Level suffix
UrgencyLevel     // Level suffix
AvalancheDangerLevel  // Level suffix (long name)
EventFilter      // Filter suffix
MountainViewMode // Mode suffix
```

### Tasks
- [ ] Standardize to consistent pattern:
  ```swift
  // State enums: use "Status" suffix
  EventStatus
  RSVPStatus
  CheckInStatus

  // Level enums: use "Level" suffix
  SkillLevel
  DangerLevel  // Shortened from AvalancheDangerLevel

  // Type enums: use "Type" suffix
  PassType
  TerrainType

  // Mode enums: use "Mode" suffix
  ViewMode
  FilterMode
  ```

- [x] Rename `AvalancheDangerLevel` → `DangerLevel` (context clear from usage)

- [ ] Move enum definitions to dedicated files in `Models/Enums/`

---

## 2.4 Fix File/Class Name Mismatches

### Problem
Some files contain classes/structs with different names

| File | Contains | Issue |
|------|----------|-------|
| `ProfileImagePicker.swift` | `AvatarEditorView` | Mismatch |

### Tasks
- [x] Rename `ProfileImagePicker.swift` → `AvatarEditorView.swift`

- [ ] Audit all files for name mismatches

- [ ] Rename files to match primary type name

---

# PHASE 3: Consolidate Duplicate Models
**Effort: Medium | Impact: High | Focus: DRY principle**

## 3.1 Consolidate Comment Models

### Problem
Two separate comment models with duplicated code:
- `Comment.swift` (59 lines) - Generic comments
- `EventComment.swift` (137 lines) - Event-specific with threading

### Tasks
- [ ] Create unified `Comment.swift`:
  ```swift
  struct Comment: Codable, Identifiable {
      let id: String
      let content: String
      let createdAt: Date
      let updatedAt: Date?
      let author: CommentAuthor

      // Optional - for threaded comments
      let parentId: String?
      var replies: [Comment]?

      // Optional - for different contexts
      let eventId: String?
      let checkInId: String?
      let photoId: String?
  }

  struct CommentAuthor: Codable {
      let id: String
      let displayName: String?
      let avatarUrl: String?
  }
  ```

- [ ] Delete `EventComment.swift` after migration

- [ ] Update `CommentService` to use unified model

- [ ] Update all views using comments

- [ ] Update all tests

---

## 3.2 Consolidate Photo Models

### Problem
Two separate photo models:
- `Photo.swift` - Generic
- `EventPhoto.swift` (158 lines) - Event-specific

### Tasks
- [ ] Create unified `Photo.swift`:
  ```swift
  struct Photo: Codable, Identifiable {
      let id: String
      let url: String
      let thumbnailUrl: String?
      let caption: String?
      let createdAt: Date
      let uploadedBy: PhotoUploader

      // Optional context
      let eventId: String?
      let checkInId: String?
  }

  struct PhotoUploader: Codable {
      let id: String
      let displayName: String?
      let avatarUrl: String?
  }
  ```

- [ ] Delete `EventPhoto.swift` after migration

- [ ] Update `PhotoService` to use unified model

- [ ] Update all views using photos

---

## 3.3 Consolidate User DTOs

### Problem
Multiple identical `User` struct definitions across files

### Locations with Duplicate User Structs
- `Event.swift` - `EventCreator`, `EventAttendee`
- `Comment.swift` - `CommentUser`
- `Photo.swift` - `PhotoUser`
- `CheckIn.swift` - `CheckInUser`

### Tasks
- [ ] Create single `UserSummary.swift`:
  ```swift
  /// Lightweight user representation for embedded contexts
  struct UserSummary: Codable, Identifiable {
      let id: String
      let username: String?
      let displayName: String?
      let avatarUrl: String?

      enum CodingKeys: String, CodingKey {
          case id
          case username
          case displayName = "display_name"
          case avatarUrl = "avatar_url"
      }
  }
  ```

- [ ] Replace all duplicate User structs with `UserSummary`

- [ ] Update CodingKeys in parent models if needed

---

# PHASE 4: Split Oversized Services
**Effort: High | Impact: High | Focus: Single Responsibility**

## 4.1 Split AuthService (825 lines)

### Current Responsibilities
1. Session management & caching
2. Debug auto-login
3. Auth state listeners
4. Sign in/up methods (3 variants)
5. Token refresh
6. Profile management
7. Onboarding management

### Tasks
- [ ] Extract `SessionManager.swift`:
  ```swift
  @MainActor
  @Observable
  class SessionManager {
      private(set) var isAuthenticated = false
      private(set) var cachedUserId: String?
      private(set) var cachedUser: AuthUser?

      func cacheCurrentUser() async { }
      func getCurrentUserId() -> String? { }
      func clearSession() { }
  }
  ```

- [ ] Extract `TokenManager.swift`:
  ```swift
  class TokenManager {
      func refreshTokens() async throws { }
      func saveTokens(access: String, refresh: String, expiry: Date) { }
      func clearTokens() { }
      func isTokenExpired() -> Bool { }
  }
  ```

- [ ] Extract `ProfileManager.swift`:
  ```swift
  @MainActor
  @Observable
  class ProfileManager {
      private(set) var userProfile: UserProfile?

      func fetchProfile() async throws { }
      func updateProfile(_ profile: UserProfile) async throws { }
      func completeOnboarding() async throws { }
      func skipOnboarding() async throws { }
  }
  ```

- [ ] Slim down `AuthService.swift` to coordinate:
  ```swift
  @MainActor
  @Observable
  class AuthService {
      let session: SessionManager
      let tokens: TokenManager
      let profile: ProfileManager

      func signIn(email: String, password: String) async throws { }
      func signUp(email: String, password: String) async throws { }
      func signInWithApple(credential: ASAuthorizationCredential) async throws { }
      func signOut() { }
  }
  ```

- [ ] Update all references to use appropriate sub-manager

- [ ] Add protocol definitions for each manager

---

## 4.2 Split EventService (767 lines)

### Current Responsibilities
1. Event CRUD
2. Event listing with filters
3. Activity timeline
4. Comments/Discussion
5. Photos
6. Likes
7. RSVPs
8. Invites

### Tasks
- [ ] Keep `EventService.swift` for core CRUD:
  ```swift
  class EventService {
      func fetchEvents(filters: EventFilters) async throws -> [Event]
      func fetchEvent(id: String) async throws -> Event
      func createEvent(_ event: CreateEventRequest) async throws -> Event
      func updateEvent(id: String, _ updates: UpdateEventRequest) async throws -> Event
      func cancelEvent(id: String) async throws
  }
  ```

- [ ] Extract `EventRSVPService.swift`:
  ```swift
  class EventRSVPService {
      func rsvp(eventId: String, status: RSVPStatus, options: RSVPOptions) async throws
      func removeRSVP(eventId: String) async throws
      func fetchAttendees(eventId: String) async throws -> [Attendee]
  }
  ```

- [ ] Extract `EventDiscussionService.swift`:
  ```swift
  class EventDiscussionService {
      func fetchComments(eventId: String, pagination: Pagination) async throws -> [Comment]
      func postComment(eventId: String, content: String, parentId: String?) async throws -> Comment
      func deleteComment(eventId: String, commentId: String) async throws
  }
  ```

- [ ] Extract `EventPhotoService.swift`:
  ```swift
  class EventPhotoService {
      func fetchPhotos(eventId: String, pagination: Pagination) async throws -> [Photo]
      func uploadPhoto(eventId: String, data: Data, caption: String?) async throws -> Photo
      func deletePhoto(eventId: String, photoId: String) async throws
  }
  ```

- [ ] Extract `EventActivityService.swift`:
  ```swift
  class EventActivityService {
      func fetchActivity(eventId: String, pagination: Pagination) async throws -> [ActivityItem]
  }
  ```

- [ ] Extract `EventInviteService.swift`:
  ```swift
  class EventInviteService {
      func fetchInvite(token: String) async throws -> InviteInfo
      func useInvite(token: String) async throws -> String
      func createInvite(eventId: String) async throws -> InviteLink
  }
  ```

- [ ] Update all ViewModels to use appropriate sub-service

---

## 4.3 Split WeatherTileOverlay (449 lines)

### Current State
Single file contains:
- `WeatherTileOverlay` (MKTileOverlay subclass)
- `WeatherTileOverlayRenderer` (MKTileOverlayRenderer subclass)
- `WeatherOverlayManager` (@Observable class)
- `OverlayType` enum
- Helper extensions

### Tasks
- [ ] Extract `WeatherTileOverlay.swift` (UIKit component):
  ```swift
  class WeatherTileOverlay: MKTileOverlay {
      let overlayType: OverlayType
      // Tile loading logic only
  }
  ```

- [ ] Extract `WeatherTileOverlayRenderer.swift` (UIKit component):
  ```swift
  class WeatherTileOverlayRenderer: MKTileOverlayRenderer {
      // Rendering logic only
  }
  ```

- [ ] Extract `WeatherOverlayManager.swift` (SwiftUI observable):
  ```swift
  @MainActor
  @Observable
  class WeatherOverlayManager {
      var currentOverlay: OverlayType?
      var isLoading = false

      func switchOverlay(to type: OverlayType) { }
      func clearOverlay() { }
  }
  ```

- [ ] Extract `OverlayType.swift` to Models/Enums:
  ```swift
  enum OverlayType: String, CaseIterable {
      case radar
      case clouds
      case temperature
      case wind
      case snow
      case smoke
  }
  ```

---

# PHASE 5: Split Oversized Views
**Effort: High | Impact: High | Focus: Component extraction**

## 5.1 Split MountainsTabView (1,966 lines)

### Current Structure
Single file with 4 tab views + shared state

### Tasks
- [ ] Create `MountainsTabView.swift` as coordinator (200 lines max):
  ```swift
  struct MountainsTabView: View {
      @State private var selectedTab: MountainTab = .conditions
      @State private var hasLoadedTabs: Set<MountainTab> = []

      var body: some View {
          TabView(selection: $selectedTab) {
              ConditionsTabView()
                  .tag(MountainTab.conditions)
              PlannerTabView()
                  .tag(MountainTab.planner)
              ExploreTabView()
                  .tag(MountainTab.explore)
              MyPassTabView()
                  .tag(MountainTab.myPass)
          }
      }
  }
  ```

- [ ] Extract `ConditionsTabView.swift`:
  - Mountain list with conditions
  - Filtering controls
  - Sort options

- [ ] Extract `PlannerTabView.swift`:
  - Trip planning UI
  - Date selection
  - Mountain comparison

- [ ] Extract `ExploreTabView.swift`:
  - Map-based exploration
  - Region browsing
  - Discovery features

- [ ] Extract `MyPassTabView.swift`:
  - Pass-specific mountains
  - Season pass management

- [ ] Extract shared components:
  - `MountainFilterBar.swift`
  - `MountainSortPicker.swift`
  - `MountainSearchBar.swift`

---

## 5.2 Split SnowForecastChart (1,492 lines)

### Tasks
- [ ] Create `SnowForecastChart.swift` as container (300 lines max):
  ```swift
  struct SnowForecastChart: View {
      let forecast: [ForecastDay]

      var body: some View {
          VStack {
              ChartHeader(...)
              ForecastChartView(forecast: forecast)
              ChartLegend(...)
          }
      }
  }
  ```

- [ ] Extract `ForecastChartView.swift`:
  - Core Chart rendering
  - Data point plotting
  - Axis configuration

- [ ] Extract `ChartLegend.swift`:
  - Legend items
  - Color coding
  - Labels

- [ ] Extract `ChartDataFormatter.swift`:
  - Date formatting
  - Value formatting
  - Axis labels

- [ ] Extract `ChartInteraction.swift`:
  - Touch handling
  - Selection state
  - Tooltips

---

## 5.3 Split EventsView (1,092 lines)

### Tasks
- [ ] Create `EventsView.swift` as container (200 lines max)

- [ ] Extract `EventListView.swift`:
  - Event list rendering
  - Pull to refresh
  - Pagination

- [ ] Extract `EventFilterBar.swift`:
  - Filter chips
  - Date range picker
  - Mountain filter

- [ ] Extract `EventRowView.swift` (if not already separate):
  - Single event card
  - RSVP status display
  - Attendee avatars

- [ ] Extract `CreateEventSheet.swift`:
  - Event creation form
  - Validation
  - Submit handling

---

## 5.4 Split EventDetailView (897 lines)

### Tasks
- [ ] Create `EventDetailView.swift` as container (200 lines max)

- [ ] Extract tab views to separate files:
  - `EventInfoTab.swift`
  - `EventDiscussionTab.swift`
  - `EventActivityTab.swift`
  - `EventPhotosTab.swift`

- [ ] Extract shared components:
  - `EventHeader.swift`
  - `EventCreatorInfo.swift`
  - `RSVPButton.swift`
  - `AttendeeList.swift`

---

# PHASE 6: Protocol Definitions
**Effort: Medium | Impact: High | Focus: Testability**

## 6.1 Create Service Protocols

### Tasks
- [ ] Create `Protocols/` directory in Services

- [ ] Create `AuthServiceProtocol.swift`:
  ```swift
  protocol AuthServiceProtocol {
      var isAuthenticated: Bool { get }
      var currentUserId: String? { get }

      func signIn(email: String, password: String) async throws
      func signUp(email: String, password: String) async throws
      func signOut()
  }
  ```

- [ ] Create `EventServiceProtocol.swift`:
  ```swift
  protocol EventServiceProtocol {
      func fetchEvents(filters: EventFilters) async throws -> EventsListResponse
      func fetchEvent(id: String) async throws -> EventWithDetails
      func createEvent(_ request: CreateEventRequest) async throws -> CreateEventResponse
      func updateEvent(id: String, _ request: UpdateEventRequest) async throws -> Event
      func cancelEvent(id: String) async throws
  }
  ```

- [ ] Create `MountainServiceProtocol.swift`

- [ ] Create `CommentServiceProtocol.swift`

- [ ] Create `PhotoServiceProtocol.swift`

- [ ] Make all services conform to their protocols

---

## 6.2 Create Error Protocol

### Tasks
- [ ] Create `AppError.swift`:
  ```swift
  protocol AppError: LocalizedError {
      var category: ErrorCategory { get }
      var isRetryable: Bool { get }
      var userMessage: String { get }
  }

  enum ErrorCategory {
      case network
      case authentication
      case authorization
      case validation
      case notFound
      case server
      case unknown
  }
  ```

- [ ] Update all service error enums to conform:
  ```swift
  enum AuthError: AppError {
      case invalidCredentials
      case sessionExpired
      // ...

      var category: ErrorCategory {
          switch self {
          case .invalidCredentials: return .authentication
          case .sessionExpired: return .authentication
          }
      }
  }
  ```

- [ ] Create unified error handling in views

---

## 6.3 Create Repository Protocol

### Tasks
- [ ] Create `RepositoryProtocol.swift`:
  ```swift
  protocol Repository {
      associatedtype Entity: Identifiable

      func fetch(id: Entity.ID) async throws -> Entity
      func fetchAll() async throws -> [Entity]
      func create(_ entity: Entity) async throws -> Entity
      func update(_ entity: Entity) async throws -> Entity
      func delete(id: Entity.ID) async throws
  }
  ```

- [ ] Create `EventRepository`:
  ```swift
  protocol EventRepository: Repository where Entity == Event {
      func fetchUpcoming() async throws -> [Event]
      func fetchByMountain(id: String) async throws -> [Event]
  }
  ```

---

# PHASE 7: Dependency Injection
**Effort: High | Impact: High | Focus: Decoupling**

## 7.1 Create DI Container

### Tasks
- [ ] Create `DependencyContainer.swift`:
  ```swift
  @MainActor
  final class DependencyContainer {
      static let shared = DependencyContainer()

      // Core
      lazy var supabaseClient = SupabaseClientManager.shared.client
      lazy var httpClient: HTTPClientProtocol = URLSessionHTTPClient()

      // Auth
      lazy var sessionManager = SessionManager()
      lazy var tokenManager = TokenManager()
      lazy var authService: AuthServiceProtocol = AuthService(
          session: sessionManager,
          tokens: tokenManager,
          client: supabaseClient
      )

      // Events
      lazy var eventService: EventServiceProtocol = EventService(
          client: supabaseClient,
          auth: authService
      )

      // Mountains
      lazy var mountainService: MountainServiceProtocol = MountainService(
          client: httpClient
      )

      // ... more services
  }
  ```

- [ ] Update `PowderTrackerApp.swift` to use container:
  ```swift
  @main
  struct PowderTrackerApp: App {
      let container = DependencyContainer.shared

      var body: some Scene {
          WindowGroup {
              ContentView()
                  .environment(container.authService)
                  .environment(container.eventService)
          }
      }
  }
  ```

---

## 7.2 Remove Singleton References

### Tasks
- [ ] Audit all `.shared` usages:
  ```bash
  grep -r "\.shared" --include="*.swift" PowderTracker/
  ```

- [ ] Replace direct singleton access with injected dependencies

- [ ] Update all ViewModels to accept dependencies via init:
  ```swift
  @Observable
  class EventsViewModel {
      private let eventService: EventServiceProtocol
      private let authService: AuthServiceProtocol

      init(
          eventService: EventServiceProtocol,
          authService: AuthServiceProtocol
      ) {
          self.eventService = eventService
          self.authService = authService
      }
  }
  ```

---

# PHASE 8: Code Quality Cleanup
**Effort: Low | Impact: Medium | Focus: Maintainability**

## 8.1 Remove Dead Code

### Tasks
- [x] Find unused files:
  - Removed duplicate DateFormatters.swift from Utilities/
  - Removed unused DataCache.swift from Utilities/
  - Removed unused PerformanceMonitor.swift from Utilities/
  - Fixed EventService to use dateParser instead of eventDate

- [ ] Find unused functions:
  - Use Xcode's "Find Call Hierarchy" on suspect functions

- [ ] Remove commented-out code blocks

- [x] Remove TODO/FIXME items by addressing or removing
  - Reviewed TODOs - all are legitimate future feature requests, not dead code

---

## 8.2 Standardize Code Style

### Tasks
- [ ] Ensure consistent access control:
  - `private` for internal implementation
  - `internal` (default) for same-module access
  - `public` for module API

- [ ] Ensure consistent property ordering:
  1. Static properties
  2. @Published/@State properties
  3. Instance properties
  4. Computed properties
  5. Initializers
  6. Body (for Views)
  7. Methods
  8. Private methods

- [x] Add MARK comments to large files:
  - Added to CommentListView.swift (498 lines)
  - Added to LiftStatusCard.swift (520 lines)
  - Most major files already had MARK comments

---

## 8.3 Documentation

### Tasks
- [ ] Add documentation comments to all public APIs:
  ```swift
  /// Fetches events with optional filters
  /// - Parameters:
  ///   - mountainId: Optional mountain to filter by
  ///   - upcoming: If true, only return future events
  /// - Returns: List of matching events
  /// - Throws: EventServiceError if fetch fails
  func fetchEvents(mountainId: String?, upcoming: Bool) async throws -> [Event]
  ```

- [ ] Document complex algorithms

- [ ] Add README.md to each major directory explaining its purpose

---

# PHASE 9: ViewModel Cleanup
**Effort: Medium | Impact: Medium | Focus: State management**

## 9.1 Split HomeViewModel (558 lines)

### Tasks
- [ ] Extract `MountainDataViewModel.swift`:
  ```swift
  @Observable
  class MountainDataViewModel {
      private(set) var mountainData: [String: MountainBatchedResponse] = [:]
      private(set) var isLoading = false

      func loadMountainData(for ids: [String]) async { }
  }
  ```

- [ ] Extract `ArrivalTimeViewModel.swift`:
  ```swift
  @Observable
  class ArrivalTimeViewModel {
      private(set) var arrivalTimes: [String: ArrivalTimeRecommendation] = [:]
      private(set) var failedLoads: Set<String> = []

      func loadArrivalTime(for mountainId: String) async { }
  }
  ```

- [ ] Extract `ParkingViewModel.swift`:
  ```swift
  @Observable
  class ParkingViewModel {
      private(set) var parkingPredictions: [String: ParkingPredictionResponse] = [:]

      func loadParkingPrediction(for mountainId: String) async { }
  }
  ```

- [ ] Slim `HomeViewModel` to coordinate child ViewModels

---

## 9.2 Standardize ViewModel Patterns

### Tasks
- [ ] Ensure all ViewModels use `@Observable` (iOS 17+)

- [ ] Remove any remaining `@ObservableObject` / `@Published`

- [ ] Create base ViewModel protocol:
  ```swift
  protocol ViewModel: Observable {
      var isLoading: Bool { get }
      var error: AppError? { get }

      func load() async
      func retry() async
  }
  ```

---

# PHASE 10: Final Verification
**Effort: Low | Impact: High | Focus: Stability**

## 10.1 Build Verification

### Tasks
- [x] Clean build folder (Cmd+Shift+K)

- [ ] Build for all targets:
  - [x] PowderTracker (iOS)
  - [ ] PowderTrackerTests
  - [ ] PowderTrackerUITests

- [x] Fix any build errors

- [ ] Fix any build warnings

---

## 10.2 Test Verification

### Tasks
- [ ] Run all unit tests

- [ ] Run all UI tests

- [ ] Run all snapshot tests

- [ ] Fix any failing tests

---

## 10.3 Runtime Verification

### Tasks
- [ ] Test all major user flows:
  - [ ] Authentication (sign in, sign up, sign out)
  - [ ] Event creation and RSVP
  - [ ] Mountain browsing and favorites
  - [ ] Map and weather overlays
  - [ ] Profile and settings

- [ ] Check for console errors/warnings

- [ ] Profile memory usage

---

# Summary

## Phase Priority Order

| Phase | Effort | Impact | Recommended Order |
|-------|--------|--------|-------------------|
| Phase 1: Directory Structure | Low | High | 1st |
| Phase 2: Naming Conventions | Low | Medium | 2nd |
| Phase 3: Consolidate Models | Medium | High | 3rd |
| Phase 8: Code Quality | Low | Medium | 4th |
| Phase 5: Split Views | High | High | 5th |
| Phase 4: Split Services | High | High | 6th |
| Phase 6: Protocols | Medium | High | 7th |
| Phase 9: ViewModel Cleanup | Medium | Medium | 8th |
| Phase 7: Dependency Injection | High | High | 9th |
| Phase 10: Verification | Low | High | 10th |

## Quick Wins (< 1 day each)
1. Consolidate Utilities/Utils directories
2. Rename Manager → Service consistently
3. Add View suffix to components
4. Remove dead code
5. Add MARK comments to large files

## Medium Effort (1-3 days each)
1. Consolidate duplicate models (Comment, Photo, User)
2. Create service protocols
3. Split oversized services
4. Split ViewModel responsibilities

## High Effort (1+ week each)
1. Split all oversized views
2. Implement dependency injection
3. Full architectural refactor
