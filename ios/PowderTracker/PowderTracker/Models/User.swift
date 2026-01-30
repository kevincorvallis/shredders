import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: String
    let authUserId: String
    let username: String
    let email: String
    let displayName: String?
    let bio: String?
    let avatarUrl: String?
    let homeMountainId: String?
    let createdAt: Date
    let updatedAt: Date
    let lastLoginAt: Date?
    let isActive: Bool

    // Onboarding fields
    let hasCompletedOnboarding: Bool?
    let experienceLevel: String?
    let preferredTerrain: [String]?
    let seasonPassType: String?
    let onboardingCompletedAt: Date?
    let onboardingSkippedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case username
        case email
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case homeMountainId = "home_mountain_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastLoginAt = "last_login_at"
        case isActive = "is_active"
        case hasCompletedOnboarding = "has_completed_onboarding"
        case experienceLevel = "experience_level"
        case preferredTerrain = "preferred_terrain"
        case seasonPassType = "season_pass_type"
        case onboardingCompletedAt = "onboarding_completed_at"
        case onboardingSkippedAt = "onboarding_skipped_at"
    }

    /// Returns true if user needs to complete onboarding
    var needsOnboarding: Bool {
        !(hasCompletedOnboarding ?? false) && onboardingSkippedAt == nil
    }

    /// Display name or username as fallback
    var displayNameOrUsername: String {
        displayName ?? username
    }
}

// MARK: - Onboarding enum helpers (main app only, not available in widget)
#if !WIDGET_EXTENSION
extension UserProfile {
    /// Returns the experience level as enum
    var experienceLevelEnum: ExperienceLevel? {
        guard let level = experienceLevel else { return nil }
        return ExperienceLevel(rawValue: level)
    }

    /// Returns preferred terrain as enum array
    var preferredTerrainEnums: [TerrainType] {
        (preferredTerrain ?? []).compactMap { TerrainType(rawValue: $0) }
    }

    /// Returns season pass type as enum
    var seasonPassTypeEnum: SeasonPassType? {
        guard let pass = seasonPassType else { return nil }
        return SeasonPassType(rawValue: pass)
    }
}
#endif
