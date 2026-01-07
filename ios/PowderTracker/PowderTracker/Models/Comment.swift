import Foundation

struct Comment: Codable, Identifiable {
    let id: String
    let userId: String
    let mountainId: String?
    let webcamId: String?
    let photoId: String?
    let checkInId: String?
    let parentCommentId: String?
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let isDeleted: Bool
    let isFlagged: Bool
    let likesCount: Int
    let user: CommentUser?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mountainId = "mountain_id"
        case webcamId = "webcam_id"
        case photoId = "photo_id"
        case checkInId = "check_in_id"
        case parentCommentId = "parent_comment_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
        case isFlagged = "is_flagged"
        case likesCount = "likes_count"
        case user
    }
}

struct CommentUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

// Response wrappers
struct CommentsResponse: Codable {
    let comments: [Comment]
}

struct CommentResponse: Codable {
    let comment: Comment
}
