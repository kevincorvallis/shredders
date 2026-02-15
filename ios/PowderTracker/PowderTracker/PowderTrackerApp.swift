import SwiftUI
@preconcurrency import UserNotifications
import NukeUI

@main
struct PowderTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authService = AuthService.shared
    @State private var deepLinkMountainId: String? = nil
    @State private var deepLinkEventId: String? = nil
    @State private var deepLinkInviteToken: String? = nil
    @State private var deepLinkCreateEventMountainId: String? = nil
    /// Initialize showOnboarding directly from launch argument for reliable UI testing
    @State private var showOnboarding = ProcessInfo.processInfo.arguments.contains("SHOW_ONBOARDING")

    /// Track previous auth state to detect logout
    @State private var wasAuthenticated = false

    /// Show welcome landing page after logout
    @State private var showWelcomeLanding = false

    /// Check if running in UI testing mode
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    /// Check if state should be reset (for UI testing)
    private var shouldResetState: Bool {
        ProcessInfo.processInfo.arguments.contains("RESET_STATE")
    }

    /// Home view model – created here so loadInitialData() can pre-fetch
    @State private var homeViewModel = HomeViewModel()

    /// Show loading screen while initial data loads (skip during UI tests)
    @State private var isLoadingInitialData: Bool = !ProcessInfo.processInfo.arguments.contains("UI_TESTING")

    /// Loading progress (0.0 – 1.0)
    @State private var loadingProgress: Double = 0

    init() {
        // Reset state during UI tests if requested
        if ProcessInfo.processInfo.arguments.contains("RESET_STATE") {
            // Clear Keychain tokens
            KeychainHelper.clearTokens()
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(
                    deepLinkMountainId: $deepLinkMountainId,
                    deepLinkEventId: $deepLinkEventId,
                    deepLinkInviteToken: $deepLinkInviteToken,
                    homeViewModel: homeViewModel
                )
                    .opacity(isLoadingInitialData ? 0 : 1)
                    .blur(radius: isLoadingInitialData ? 10 : 0)
                    .environment(authService)

                if isLoadingInitialData {
                    BrockSkiingLoadingView(progress: loadingProgress)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.smooth(duration: 0.4), value: isLoadingInitialData)
            .task {
                await loadInitialData()
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                // Detect logout: user was authenticated, now they're not
                if wasAuthenticated && !isAuthenticated {
                    withAnimation(.smooth(duration: 0.3)) {
                        showWelcomeLanding = true
                    }
                }

                // Check if user needs onboarding after authentication
                if isAuthenticated && authService.needsOnboarding {
                    withAnimation(.smooth(duration: 0.3)) {
                        showOnboarding = true
                    }
                }

                // Update tracking state
                wasAuthenticated = isAuthenticated
            }
            .onAppear {
                // Initialize wasAuthenticated on first appear
                wasAuthenticated = authService.isAuthenticated
            }
            .onChange(of: authService.userProfile) { _, profile in
                // Also check when profile loads
                if let profile = profile, profile.needsOnboarding && authService.isAuthenticated {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingContainerView(authService: authService)
            }
            .fullScreenCover(isPresented: $showWelcomeLanding) {
                WelcomeLandingView(
                    onContinueBrowsing: {
                        // Dismiss welcome and navigate to Today tab
                        showWelcomeLanding = false
                        // Post notification to switch to Today tab
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NavigateToTab"),
                            object: nil,
                            userInfo: ["tabIndex": 0]
                        )
                    },
                    onSignIn: {
                        // Sign in is handled within WelcomeLandingView via sheet
                        // When auth succeeds, this cover will auto-dismiss due to wasAuthenticated change
                    }
                )
                .environment(authService)
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                // Auto-dismiss welcome landing when user signs back in
                if isAuthenticated && showWelcomeLanding {
                    showWelcomeLanding = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeepLinkToMountain"))) { notification in
                if let mountainId = notification.userInfo?["mountainId"] as? String {
                    deepLinkMountainId = mountainId
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeepLinkToEvent"))) { notification in
                if let eventId = notification.userInfo?["eventId"] as? String {
                    deepLinkEventId = eventId
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeepLinkToInvite"))) { notification in
                if let token = notification.userInfo?["token"] as? String {
                    deepLinkInviteToken = token
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeepLinkToCreateEvent"))) { notification in
                if let mountainId = notification.userInfo?["mountainId"] as? String {
                    deepLinkCreateEventMountainId = mountainId
                }
            }
            .sheet(item: Binding(
                get: { deepLinkCreateEventMountainId.map { CreateEventDeepLink(mountainId: $0) } },
                set: { deepLinkCreateEventMountainId = $0?.mountainId }
            )) { link in
                EventCreateView(suggestedMountainId: link.mountainId)
                    .environment(authService)
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onAppear {
                // Support deep links via launch environment for UI testing
                if isUITesting, let deepLink = ProcessInfo.processInfo.environment["UI_TEST_DEEP_LINK"],
                   let url = URL(string: deepLink) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        handleDeepLink(url)
                    }
                }
            }
        }
    }

    /// Handle Universal Links and deep links
    private func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        let path = components.path

        // Handle /events/create?mountainId=X
        if path.hasPrefix("/events/create") {
            let mountainId = components.queryItems?.first(where: { $0.name == "mountainId" })?.value
            if let mountainId, !mountainId.isEmpty {
                deepLinkCreateEventMountainId = mountainId
            }
            return
        }

        // Handle /events/invite/[token]
        if path.hasPrefix("/events/invite/") {
            let token = String(path.dropFirst("/events/invite/".count))
            if !token.isEmpty {
                deepLinkInviteToken = token
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkToInvite"),
                    object: nil,
                    userInfo: ["token": token]
                )
            }
        }
        // Handle /events/[id]
        else if path.hasPrefix("/events/") {
            let eventId = String(path.dropFirst("/events/".count))
            if !eventId.isEmpty && eventId != "create" {
                deepLinkEventId = eventId
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkToEvent"),
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            }
        }
        // Handle /mountains/[id]
        else if path.hasPrefix("/mountains/") {
            let mountainId = String(path.dropFirst("/mountains/".count))
            if !mountainId.isEmpty {
                deepLinkMountainId = mountainId
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkToMountain"),
                    object: nil,
                    userInfo: ["mountainId": mountainId]
                )
            }
        }
    }

    /// Load initial app data and dismiss loading screen when ready
    private func loadInitialData() async {
        // Start timing
        let startTime = Date()
        let launchSpan = PerformanceLogger.beginAppLaunch()
        let isAuthenticated = authService.isAuthenticated

        // Step 1: Fetch mountains list
        loadingProgress = 0.1

        let dataTask = Task {
            let mtnsSpan = PerformanceLogger.beginMountainsLoad()
            await MountainService.shared.fetchMountains()
            mtnsSpan.end()
            await MainActor.run { loadingProgress = 0.25 }

            // Step 2: Fetch favorites list (if authenticated)
            if isAuthenticated {
                let favsSpan = PerformanceLogger.beginFavoritesLoad()
                await FavoritesService.shared.fetchFromBackend()
                favsSpan.end()
                await MainActor.run { loadingProgress = 0.4 }
            }

            // Step 3: Pre-fetch mountain data (forecasts, conditions, graphs)
            let homeSpan = PerformanceLogger.beginHomeRefresh()
            await homeViewModel.loadData()
            homeSpan.end()
            await MainActor.run { loadingProgress = 0.7 }

            // Step 4: Pre-fetch enhanced data (arrival times, parking)
            let enhancedSpan = PerformanceLogger.beginEnhancedDataLoad()
            await homeViewModel.loadEnhancedData()
            enhancedSpan.end()
            await MainActor.run { loadingProgress = 0.95 }
        }

        // 15-second timeout
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            dataTask.cancel()
        }
        await dataTask.value
        timeoutTask.cancel()

        // Complete
        loadingProgress = 1.0

        // Ensure minimum display time so the user can enjoy the loading animation
        // (Brock skis across in 3.5s, messages cycle every 2s)
        let elapsed = Date().timeIntervalSince(startTime)
        let minimumDisplayTime: TimeInterval = 3.0
        if elapsed < minimumDisplayTime {
            try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
        }

        // Dismiss loading screen
        launchSpan.end()
        PerformanceLogger.event("Loading Screen Dismissed")
        withAnimation(.smooth(duration: 0.5)) {
            isLoadingInitialData = false
        }
    }
}

/// Identifiable wrapper for create-event deep link sheet binding
struct CreateEventDeepLink: Identifiable {
    let id = UUID()
    let mountainId: String
}

// AppDelegate for handling push notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // CRITICAL - Configure image caching first for fast first frame
        ImageCacheConfig.configure()
        ImageCacheConfig.registerForLifecycleNotifications()

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register actionable notification categories
        registerNotificationCategories()

        // DEFERRED - Non-critical services after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.initializeNonCriticalServices()
        }

        return true
    }

    /// Register notification categories with action buttons
    private func registerNotificationCategories() {
        let rallyAction = UNNotificationAction(
            identifier: "RALLY_CREW",
            title: "Rally Your Crew",
            options: [.foreground]
        )
        let powderAlertCategory = UNNotificationCategory(
            identifier: "powder-alert-actionable",
            actions: [rallyAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([powderAlertCategory])
    }

    /// Initialize services that are not needed for first frame
    private func initializeNonCriticalServices() {
        Task { @MainActor in
            await PushNotificationService.shared.checkAuthorizationStatus()
        }

        // Prune expired event cache entries in the background
        Task { @MainActor in
            EventCacheService.shared.pruneExpiredCache()
        }

        // MountainService.shared.fetchMountains() in loadInitialData() handles pre-warming
    }

    // MARK: - Push Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationService.shared.didFailToRegisterForRemoteNotifications(withError: error)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])

        // Handle the notification on main actor
        Task { @MainActor in
            PushNotificationService.shared.didReceiveNotification(notification)
        }
    }

    // Handle notification tap (when user taps notification)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let notification = response.notification
        let actionIdentifier = response.actionIdentifier

        Task { @MainActor in
            PushNotificationService.shared.didReceiveNotification(notification)

            let userInfo = notification.request.content.userInfo

            // Handle RALLY_CREW action button tap
            if actionIdentifier == "RALLY_CREW",
               let mountainId = userInfo["mountainId"] as? String {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkToCreateEvent"),
                    object: nil,
                    userInfo: ["mountainId": mountainId]
                )
            } else if let eventId = userInfo["eventId"] as? String {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkToEvent"),
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            } else if let mountainId = userInfo["mountainId"] as? String {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkToMountain"),
                    object: nil,
                    userInfo: ["mountainId": mountainId]
                )
            }
        }

        completionHandler()
    }
}
	