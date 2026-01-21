import Foundation
import UserNotifications
import UIKit
import Supabase

@MainActor
@Observable
class PushNotificationManager: NSObject {
    static let shared = PushNotificationManager()

    private let supabase: SupabaseClient
    private let apiClient: APIClient

    var isRegistered = false
    var deviceToken: String?
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        // URL is hardcoded in AppConfig - safe to force unwrap
        let supabaseURL = URL(string: AppConfig.supabaseURL)!
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey
        )
        self.apiClient = APIClient.shared
        super.init()
    }

    /// Request push notification permissions
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await center.requestAuthorization(options: options)

        if granted {
            #if DEBUG
            print("Push notification permission granted")
            #endif
            await registerForPushNotifications()
        } else {
            #if DEBUG
            print("Push notification permission denied")
            #endif
        }

        // Update authorization status
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        if authorizationStatus == .authorized {
            await registerForPushNotifications()
        }
    }

    /// Register for push notifications with APNs
    private func registerForPushNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Handle device token registration (called from AppDelegate)
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        // Convert device token to string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        #if DEBUG
        print("Device token received: \(tokenString)")
        #endif

        // Register with backend
        Task {
            await registerDeviceToken(tokenString)
        }
    }

    /// Handle registration failure (called from AppDelegate)
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        #if DEBUG
        print("Failed to register for push notifications: \(error)")
        #endif
        isRegistered = false
    }

    /// Register device token with backend API
    private func registerDeviceToken(_ token: String) async {
        do {
            // Get device info
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let osVersion = UIDevice.current.systemVersion
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

            // Register with API
            struct RegisterRequest: Encodable {
                let deviceToken: String
                let platform: String
                let deviceId: String
                let appVersion: String?
                let osVersion: String
            }

            let request = RegisterRequest(
                deviceToken: token,
                platform: "ios",
                deviceId: deviceId,
                appVersion: appVersion,
                osVersion: osVersion
            )

            let data = try JSONEncoder().encode(request)

            guard let url = URL(string: "\(AppConfig.apiBaseURL)/push/register") else {
                throw PushError.invalidURL
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Add auth token
            if let session = try? await supabase.auth.session {
                urlRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            }

            urlRequest.httpBody = data

            let (_, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw PushError.registrationFailed
            }

            isRegistered = true
            #if DEBUG
            print("Device token registered with backend successfully")
            #endif
        } catch {
            #if DEBUG
            print("Failed to register device token with backend: \(error)")
            #endif
            isRegistered = false
        }
    }

    /// Unregister device from push notifications
    func unregister() async {
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            return
        }

        do {
            guard let url = URL(string: "\(AppConfig.apiBaseURL)/push/register?deviceId=\(deviceId)") else {
                throw PushError.invalidURL
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "DELETE"

            // Add auth token
            if let session = try? await supabase.auth.session {
                urlRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            }

            let (_, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw PushError.unregistrationFailed
            }

            isRegistered = false
            deviceToken = nil
            #if DEBUG
            print("Device unregistered from push notifications")
            #endif
        } catch {
            #if DEBUG
            print("Failed to unregister device: \(error)")
            #endif
        }
    }

    /// Handle received notification (called from AppDelegate)
    func didReceiveNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        handleNotificationData(userInfo)
    }

    /// Handle notification data extracted from notification (for concurrency safety)
    func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
        #if DEBUG
        print("Received notification:", userInfo)
        #endif

        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "weather-alert":
                handleWeatherAlert(userInfo)
            case "powder-alert":
                handlePowderAlert(userInfo)
            default:
                #if DEBUG
                print("Unknown notification type:", type)
                #endif
                break
            }
        }

        // Update badge count
        Task {
            await updateBadgeCount()
        }
    }

    /// Handle weather alert notification
    private func handleWeatherAlert(_ userInfo: [AnyHashable: Any]) {
        guard let mountainId = userInfo["mountainId"] as? String else { return }

        #if DEBUG
        print("Weather alert for mountain:", mountainId)
        #endif

        // TODO: Navigate to alerts view or show alert details
        // This could be implemented with a notification center pattern
        NotificationCenter.default.post(
            name: NSNotification.Name("WeatherAlertReceived"),
            object: nil,
            userInfo: ["mountainId": mountainId]
        )
    }

    /// Handle powder alert notification
    private func handlePowderAlert(_ userInfo: [AnyHashable: Any]) {
        guard let mountainId = userInfo["mountainId"] as? String,
              let snowfallInches = userInfo["snowfallInches"] as? Double else {
            return
        }

        #if DEBUG
        print("Powder alert for mountain \(mountainId): \(snowfallInches)\"")
        #endif

        // TODO: Navigate to mountain conditions or show powder details
        NotificationCenter.default.post(
            name: NSNotification.Name("PowderAlertReceived"),
            object: nil,
            userInfo: ["mountainId": mountainId, "snowfallInches": snowfallInches]
        )
    }

    /// Update app badge count
    private func updateBadgeCount() async {
        let center = UNUserNotificationCenter.current()
        let deliveredNotifications = await center.deliveredNotifications()

        try? await center.setBadgeCount(deliveredNotifications.count)
    }

    /// Clear all notifications
    func clearAllNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()

        try? await center.setBadgeCount(0)
    }

    /// Clear notification badge
    func clearBadge() async {
        let center = UNUserNotificationCenter.current()
        try? await center.setBadgeCount(0)
    }
}

enum PushError: LocalizedError {
    case invalidURL
    case registrationFailed
    case unregistrationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .registrationFailed:
            return "Failed to register device token"
        case .unregistrationFailed:
            return "Failed to unregister device"
        }
    }
}
