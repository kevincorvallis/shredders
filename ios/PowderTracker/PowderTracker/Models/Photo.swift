import Foundation

struct Photo: Codable, Identifiable {
    let id: String
    let userId: String
    let mountainId: String
    let webcamId: String?
    let s3Key: String
    let s3Bucket: String
    let cloudfrontUrl: String
    let thumbnailUrl: String?
    let caption: String?
    let takenAt: Date
    let uploadedAt: Date
    let fileSizeBytes: Int
    let mimeType: String
    let isApproved: Bool
    let isFlagged: Bool
    let moderationStatus: String?
    let likesCount: Int
    let commentsCount: Int
    let locationName: String?
    let user: PhotoUser?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mountainId = "mountain_id"
        case webcamId = "webcam_id"
        case s3Key = "s3_key"
        case s3Bucket = "s3_bucket"
        case cloudfrontUrl = "cloudfront_url"
        case thumbnailUrl = "thumbnail_url"
        case caption
        case takenAt = "taken_at"
        case uploadedAt = "uploaded_at"
        case fileSizeBytes = "file_size_bytes"
        case mimeType = "mime_type"
        case isApproved = "is_approved"
        case isFlagged = "is_flagged"
        case moderationStatus = "moderation_status"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case locationName = "location_name"
        case user = "users"
    }
}

struct PhotoUser: Codable {
    let username: String
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

struct PhotosResponse: Codable {
    let photos: [Photo]
    let total: Int
}
