import Foundation

struct AlertSubscription: Codable, Identifiable {
    let id: String
    let userId: String
    let mountainId: String
    let weatherAlerts: Bool
    let powderAlerts: Bool
    let powderThreshold: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mountainId = "mountain_id"
        case weatherAlerts = "weather_alerts"
        case powderAlerts = "powder_alerts"
        case powderThreshold = "powder_threshold"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Response wrappers
struct AlertSubscriptionsResponse: Codable {
    let subscriptions: [AlertSubscription]
}

struct AlertSubscriptionResponse: Codable {
    let subscription: AlertSubscription
}
