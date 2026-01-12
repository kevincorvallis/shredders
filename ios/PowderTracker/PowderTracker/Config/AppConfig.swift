import Foundation

enum AppConfig {
    /// Base URL for the Shredders API
    /// Can be overridden with SHREDDERS_API_URL environment variable
    /// Set to "production" to force production API in DEBUG builds
    static var apiBaseURL: String {
        // Check for environment variable override
        if let envURL = ProcessInfo.processInfo.environment["SHREDDERS_API_URL"] {
            if envURL.lowercased() == "production" {
                return "https://shredders-bay.vercel.app/api"
            }
            return envURL
        }

        // Default behavior
        #if DEBUG
        return "https://shredders-bay.vercel.app/api"  // Use production by default to avoid localhost issues
        #else
        return "https://shredders-bay.vercel.app/api"
        #endif
    }

    /// App version for display
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    /// Build number
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    /// Supabase configuration
    static let supabaseURL = "https://nmkavdrvgjkolreoexfe.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ta2F2ZHJ2Z2prb2xyZW9leGZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNTEyMjEsImV4cCI6MjA4MjkyNzIyMX0.VlmkBrD3i7eFfMg7SuZHACqa29r0GHZiU4FFzfB6P7Q"
}
