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
    @State private var showOnboarding = false

    /// Check if running in UI testing mode
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    /// Check if state should be reset (for UI testing)
    private var shouldResetState: Bool {
        ProcessInfo.processInfo.arguments.contains("RESET_STATE")
    }

    /// Skip intro screen during UI tests for faster test execution
    @State private var showIntro: Bool = !ProcessInfo.processInfo.arguments.contains("UI_TESTING")

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
                    .opacity(showIntro ? 0.3 : 1)
                    .environment(authService)

                if showIntro {
                    PookieBSnowIntroView(showIntro: $showIntro)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showIntro)
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                // Check if user needs onboarding after authentication
                if isAuthenticated && authService.needsOnboarding {
                    // Small delay to let the UI settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOnboarding = true
                    }
                }
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

        // Pre-warm Supabase connection in background
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0) {
            Task { @MainActor in
                // Light API call to warm connection
                _ = try? await APIClient.shared.fetchMountains()
            }
        }
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
            if let mountainId = userInfo["mountainId"] as? String {
                // Post notification to trigger deep link
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
	