import SwiftUI
@preconcurrency import UserNotifications

@main
struct PowderTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showIntro = true
    @State private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showIntro ? 0.3 : 1)
                    .environment(authService)

                if showIntro {
                    IntroView(showIntro: $showIntro)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showIntro)
        }
    }
}

// AppDelegate for handling push notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Check push notification authorization status
        Task {
            await PushNotificationManager.shared.checkAuthorizationStatus()
        }

        return true
    }

    // MARK: - Push Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationManager.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(withError: error)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])

        // Handle the notification
        PushNotificationManager.shared.didReceiveNotification(notification)
    }

    // Handle notification tap (when user taps notification)
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let notification = response.notification
        PushNotificationManager.shared.didReceiveNotification(notification)

        // Handle deep linking based on notification type
        let userInfo = notification.request.content.userInfo
        if let mountainId = userInfo["mountainId"] as? String {
            // TODO: Navigate to mountain detail view
            print("Navigate to mountain:", mountainId)
        }

        completionHandler()
    }
}
	