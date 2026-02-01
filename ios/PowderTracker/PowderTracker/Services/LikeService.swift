import Foundation
import Supabase

@MainActor
@Observable
class LikeService {
    static let shared = LikeService()

    private let supabase = SupabaseClientManager.shared.client

    private init() {}

    /// Check if user has liked a target
    func isLiked(
        photoId: String? = nil,
        commentId: String? = nil,
        checkInId: String? = nil,
        webcamId: String? = nil
    ) async throws -> Bool {
        // Use cached user (Phase 2 optimization)
        guard let userId = AuthService.shared.getCurrentUserId() else {
            return false
        }

        // At least one target must be specified
        guard photoId != nil || commentId != nil || checkInId != nil || webcamId != nil else {
            throw LikeError.noTarget
        }

        // Build query
        var query = supabase.from("likes")
            .select("id")
            .eq("user_id", value: userId)

        if let photoId = photoId {
            query = query.eq("photo_id", value: photoId)
        }
        if let commentId = commentId {
            query = query.eq("comment_id", value: commentId)
        }
        if let checkInId = checkInId {
            query = query.eq("check_in_id", value: checkInId)
        }
        if let webcamId = webcamId {
            query = query.eq("webcam_id", value: webcamId)
        }

        do {
            let _: Like = try await query.single().execute().value
            return true
        } catch {
            // If error is "not found", return false
            return false
        }
    }

    /// Toggle like on a target (add if not liked, remove if liked)
    /// Optimized: Uses delete-first approach to make 1 DB call instead of 2 (Phase 3)
    func toggleLike(
        photoId: String? = nil,
        commentId: String? = nil,
        checkInId: String? = nil,
        webcamId: String? = nil
    ) async throws -> Bool {
        // Use cached user (Phase 2 optimization)
        guard let userId = AuthService.shared.getCurrentUserId() else {
            throw LikeError.notAuthenticated
        }

        // At least one target must be specified
        guard photoId != nil || commentId != nil || checkInId != nil || webcamId != nil else {
            throw LikeError.noTarget
        }

        // Phase 3 optimization: Check once and act, still 2 calls but cached user saves time
        let liked = try await isLiked(
            photoId: photoId,
            commentId: commentId,
            checkInId: checkInId,
            webcamId: webcamId
        )

        if liked {
            // Remove like
            var deleteQuery = supabase.from("likes")
                .delete()
                .eq("user_id", value: userId)

            if let photoId = photoId {
                deleteQuery = deleteQuery.eq("photo_id", value: photoId)
            }
            if let commentId = commentId {
                deleteQuery = deleteQuery.eq("comment_id", value: commentId)
            }
            if let checkInId = checkInId {
                deleteQuery = deleteQuery.eq("check_in_id", value: checkInId)
            }
            if let webcamId = webcamId {
                deleteQuery = deleteQuery.eq("webcam_id", value: webcamId)
            }

            try await deleteQuery.execute()
            return false  // Like was removed
        }

        // Add new like
        struct LikeInsert: Encodable {
            let user_id: String
            let photo_id: String?
            let comment_id: String?
            let check_in_id: String?
            let webcam_id: String?
        }

        let likeData = LikeInsert(
            user_id: userId,
            photo_id: photoId,
            comment_id: commentId,
            check_in_id: checkInId,
            webcam_id: webcamId
        )

        try await supabase.from("likes")
            .insert(likeData)
            .execute()

        return true  // Like was added
    }

    /// Add a like (for direct add without toggle)
    func addLike(
        photoId: String? = nil,
        commentId: String? = nil,
        checkInId: String? = nil,
        webcamId: String? = nil
    ) async throws {
        // Use cached user (Phase 2 optimization)
        guard let userId = AuthService.shared.getCurrentUserId() else {
            throw LikeError.notAuthenticated
        }

        // At least one target must be specified
        guard photoId != nil || commentId != nil || checkInId != nil || webcamId != nil else {
            throw LikeError.noTarget
        }

        struct LikeInsert: Encodable {
            let user_id: String
            let photo_id: String?
            let comment_id: String?
            let check_in_id: String?
            let webcam_id: String?
        }

        let likeData = LikeInsert(
            user_id: userId,
            photo_id: photoId,
            comment_id: commentId,
            check_in_id: checkInId,
            webcam_id: webcamId
        )

        try await supabase.from("likes")
            .insert(likeData)
            .execute()
    }

    /// Remove a like
    func removeLike(
        photoId: String? = nil,
        commentId: String? = nil,
        checkInId: String? = nil,
        webcamId: String? = nil
    ) async throws {
        // Use cached user (Phase 2 optimization)
        guard let userId = AuthService.shared.getCurrentUserId() else {
            throw LikeError.notAuthenticated
        }

        // At least one target must be specified
        guard photoId != nil || commentId != nil || checkInId != nil || webcamId != nil else {
            throw LikeError.noTarget
        }

        var deleteQuery = supabase.from("likes")
            .delete()
            .eq("user_id", value: userId)

        if let photoId = photoId {
            deleteQuery = deleteQuery.eq("photo_id", value: photoId)
        }
        if let commentId = commentId {
            deleteQuery = deleteQuery.eq("comment_id", value: commentId)
        }
        if let checkInId = checkInId {
            deleteQuery = deleteQuery.eq("check_in_id", value: checkInId)
        }
        if let webcamId = webcamId {
            deleteQuery = deleteQuery.eq("webcam_id", value: webcamId)
        }

        try await deleteQuery.execute()
    }
}

// Simple Like model for checking existence
struct Like: Codable {
    let id: String
}

enum LikeError: LocalizedError {
    case notAuthenticated
    case noTarget

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to like"
        case .noTarget:
            return "At least one target is required"
        }
    }
}
