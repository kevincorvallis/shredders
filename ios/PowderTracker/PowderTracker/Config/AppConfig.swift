import Foundation

enum AppConfig {
    // MARK: - Production URLs (safe defaults)

    private static let productionAPIURL = "https://shredders-bay.vercel.app/api"
    private static let productionSupabaseURL = "https://nmkavdrvgjkolreoexfe.supabase.co"
    private static let productionSupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ta2F2ZHJ2Z2prb2xyZW9leGZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNTEyMjEsImV4cCI6MjA4MjkyNzIyMX0.VlmkBrD3i7eFfMg7SuZHACqa29r0GHZiU4FFzfB6P7Q"

    // MARK: - API Configuration

    /// Base URL for the Shredders API
    /// Can be overridden with SHREDDERS_API_URL environment variable
    /// Set to "production" to force production API in DEBUG builds
    static var apiBaseURL: String {
        // Check for environment variable override
        if let envURL = ProcessInfo.processInfo.environment["SHREDDERS_API_URL"] {
            if envURL.lowercased() == "production" {
                return productionAPIURL
            }
            return normalizeApiBaseURL(envURL)
        }

        // Default behavior - always use production
        return productionAPIURL
    }

    private static func normalizeApiBaseURL(_ rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        var normalized = trimmed
        if normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        if !normalized.hasSuffix("/api") {
            normalized += "/api"
        }
        return normalized
    }

    // MARK: - App Info

    /// App version for display
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Build number
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Supabase Configuration

    /// Supabase URL - returns a validated URL string
    static var supabaseURL: String {
        // Check for environment override
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           URL(string: envURL) != nil {
            return envURL
        }
        return productionSupabaseURL
    }

    /// Supabase anon key
    static var supabaseAnonKey: String {
        // Check for environment override
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
           !envKey.isEmpty {
            return envKey
        }
        return productionSupabaseAnonKey
    }

    // MARK: - Weather API Configuration

    /// OpenWeatherMap API key for weather overlays (temperature, wind, etc.)
    /// Set OPENWEATHERMAP_API_KEY environment variable or configure in Xcode scheme
    static var openWeatherMapAPIKey: String? {
        if let envKey = ProcessInfo.processInfo.environment["OPENWEATHERMAP_API_KEY"],
           !envKey.isEmpty {
            return envKey
        }
        // Key must be configured via environment variable
        return nil
    }

    // MARK: - URL Helpers

    /// Safely creates a URL from the API base URL
    /// Returns nil if URL is invalid (should never happen with proper config)
    static func apiURL(for endpoint: String) -> URL? {
        let urlString = apiBaseURL + (endpoint.hasPrefix("/") ? endpoint : "/" + endpoint)
        return URL(string: urlString)
    }

    /// Safely creates a URL for Supabase
    static func supabaseURLInstance() -> URL? {
        URL(string: supabaseURL)
    }
}
