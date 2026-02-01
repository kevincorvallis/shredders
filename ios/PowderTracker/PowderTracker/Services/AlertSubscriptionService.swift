import Foundation
import Supabase

@MainActor
@Observable
class AlertSubscriptionService {
    static let shared = AlertSubscriptionService()

    private let supabase = SupabaseClientManager.shared.client

    private init() {}

    /// Fetch alert subscriptions for current user
    /// Phase 4 optimization: Select specific columns instead of *
    /// Phase 5 optimization: Add pagination
    func fetchSubscriptions(for mountainId: String? = nil) async throws -> [AlertSubscription] {
        var query = supabase.from("alert_subscriptions")
            .select("""
                id,
                mountain_id,
                is_enabled,
                powder_threshold,
                notify_opening_day,
                created_at,
                weather_alerts,
                powder_alerts
            """)

        // Add mountain filter if provided
        if let mountainId = mountainId {
            query = query.eq("mountain_id", value: mountainId)
        }

        let response: [AlertSubscription] = try await query
            .order("created_at", ascending: false)
            .range(from: 0, to: 49)  // Phase 5: Limit to 50
            .execute()
            .value
        return response
    }

    /// Create or update alert subscription
    func subscribe(
        mountainId: String,
        weatherAlerts: Bool = true,
        powderAlerts: Bool = true,
        powderThreshold: Int = 6
    ) async throws -> AlertSubscription {
        // Use cached user (Phase 2 optimization)
        guard let userId = AuthService.shared.getCurrentUserId() else {
            throw AlertSubscriptionError.notAuthenticated
        }

        // Validate powder threshold
        guard powderThreshold >= 0 && powderThreshold <= 100 else {
            throw AlertSubscriptionError.invalidThreshold
        }

        // Check if subscription already exists
        let existing: AlertSubscription? = try? await supabase.from("alert_subscriptions")
            .select("id")
            .eq("user_id", value: userId)
            .eq("mountain_id", value: mountainId)
            .single()
            .execute()
            .value

        if let existing = existing {
            // Update existing subscription
            struct SubscriptionUpdate: Encodable {
                let weather_alerts: Bool
                let powder_alerts: Bool
                let powder_threshold: Int
                let updated_at: String
            }

            let updateData = SubscriptionUpdate(
                weather_alerts: weatherAlerts,
                powder_alerts: powderAlerts,
                powder_threshold: powderThreshold,
                updated_at: DateFormatters.iso8601.string(from: Date())
            )

            let response: AlertSubscription = try await supabase.from("alert_subscriptions")
                .update(updateData)
                .eq("id", value: existing.id)
                .select()
                .single()
                .execute()
                .value

            return response
        } else {
            // Create new subscription
            struct SubscriptionInsert: Encodable {
                let user_id: String
                let mountain_id: String
                let weather_alerts: Bool
                let powder_alerts: Bool
                let powder_threshold: Int
            }

            let insertData = SubscriptionInsert(
                user_id: userId,
                mountain_id: mountainId,
                weather_alerts: weatherAlerts,
                powder_alerts: powderAlerts,
                powder_threshold: powderThreshold
            )

            let response: AlertSubscription = try await supabase.from("alert_subscriptions")
                .insert(insertData)
                .select()
                .single()
                .execute()
                .value

            return response
        }
    }

    /// Unsubscribe from alerts for a mountain
    func unsubscribe(mountainId: String) async throws {
        // Use cached user (Phase 2 optimization)
        guard let userId = AuthService.shared.getCurrentUserId() else {
            throw AlertSubscriptionError.notAuthenticated
        }

        try await supabase.from("alert_subscriptions")
            .delete()
            .eq("user_id", value: userId)
            .eq("mountain_id", value: mountainId)
            .execute()
    }

    /// Check if user is subscribed to a mountain
    func isSubscribed(to mountainId: String) async throws -> Bool {
        // Use cached user (Phase 2 optimization)
        guard let userId = AuthService.shared.getCurrentUserId() else {
            return false
        }

        do {
            let _: AlertSubscription = try await supabase.from("alert_subscriptions")
                .select("id")
                .eq("user_id", value: userId)
                .eq("mountain_id", value: mountainId)
                .single()
                .execute()
                .value

            return true
        } catch {
            return false
        }
    }
}

enum AlertSubscriptionError: LocalizedError {
    case notAuthenticated
    case invalidThreshold

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to manage alert subscriptions"
        case .invalidThreshold:
            return "Powder threshold must be between 0 and 100 inches"
        }
    }
}
