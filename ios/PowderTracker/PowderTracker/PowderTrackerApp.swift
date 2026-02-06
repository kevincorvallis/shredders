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

    /// Show loading screen while initial data loads (skip during UI tests)
    @State private var isLoadingInitialData: Bool = !ProcessInfo.processInfo.arguments.contains("UI_TESTING")

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
                    deepLinkInviteToken: $deepLinkInviteToken
                )
                    .opacity(isLoadingInitialData ? 0 : 1)
                    .blur(radius: isLoadingInitialData ? 10 : 0)
                    .environment(authService)

                if isLoadingInitialData {
                    BrockSkiingLoadingView()
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
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    /// Handle Universal Links and deep links
    private func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }

        let path = components.path

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
        let isAuthenticated = authService.isAuthenticated

        // Fetch initial data with a 10-second timeout
        let dataTask = Task {
            await MountainService.shared.fetchMountains()
            if isAuthenticated {
                await FavoritesService.shared.fetchFromBackend()
            }
        }
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            dataTask.cancel()
        }
        await dataTask.value
        timeoutTask.cancel()

        // Ensure minimum display time for smooth UX (1.0 seconds)
        let elapsed = Date().timeIntervalSince(startTime)
        let minimumDisplayTime: TimeInterval = 1.0
        if elapsed < minimumDisplayTime {
            try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
        }

        // Dismiss loading screen
        withAnimation(.smooth(duration: 0.5)) {
            isLoadingInitialData = false
        }
    }
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

        // DEFERRED - Non-critical services after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.initializeNonCriticalServices()
        }

        return true
    }

    /// Initialize services that are not needed for first frame
    private func initializeNonCriticalServices() {
        Task { @MainActor in
            await PushNotificationService.shared.checkAuthorizationStatus()
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

        Task { @MainActor in
            PushNotificationService.shared.didReceiveNotification(notification)

            // Handle deep linking based on notification type
            let userInfo = notification.request.content.userInfo

            if let eventId = userInfo["eventId"] as? String {
                // Post notification to trigger event deep link
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkToEvent"),
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            } else if let mountainId = userInfo["mountainId"] as? String {
                // Post notification to trigger mountain deep link
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
	