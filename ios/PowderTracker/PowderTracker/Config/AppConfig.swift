import Foundation

enum AppConfig {
    /// Base URL for the Shredders API
    static let apiBaseURL = "https://shredders-bay.vercel.app/api"

    /// App version for display
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    /// Build number
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
