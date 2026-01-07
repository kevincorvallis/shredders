import Foundation

struct UserProfile: Codable, Identifiable {
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
    }
}
