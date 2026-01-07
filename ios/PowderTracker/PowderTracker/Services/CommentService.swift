import Foundation
import Supabase

@MainActor
@Observable
class CommentService {
    static let shared = CommentService()

    private let supabase: SupabaseClient

    private init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    /// Fetch comments for a target (mountain, webcam, photo, or check-in)
    func fetchComments(
        for mountainId: String? = nil,
        webcamId: String? = nil,
        photoId: String? = nil,
        checkInId: String? = nil,
        parentCommentId: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [Comment] {
        var query = supabase.from("comments")
            .select("""
                *,
                user:user_id (
                    id,
                    username,
                    display_name,
                    avatar_url
                )
            """)
            .eq("is_deleted", value: false)

        // Apply filters
        if let mountainId = mountainId {
            query = query.eq("mountain_id", value: mountainId)
        }
        if let webcamId = webcamId {
            query = query.eq("webcam_id", value: webcamId)
        }
        if let photoId = photoId {
            query = query.eq("photo_id", value: photoId)
        }
        if let checkInId = checkInId {
            query = query.eq("check_in_id", value: checkInId)
        }
        if let parentCommentId = parentCommentId {
            query = query.eq("parent_comment_id", value: parentCommentId)
        }

        let response: [Comment] = try await query
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        return response
    }

    /// Create a new comment
    func createComment(
        content: String,
        mountainId: String? = nil,
        webcamId: String? = nil,
        photoId: String? = nil,
        checkInId: String? = nil,
        parentCommentId: String? = nil
    ) async throws -> Comment {
        // Validate content
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommentError.emptyContent
        }

        guard content.count <= 2000 else {
            throw CommentError.contentTooLong
        }

        // Get current user
        guard let user = try? await supabase.auth.session.user else {
            throw CommentError.notAuthenticated
        }

        // At least one target must be specified
        guard mountainId != nil || webcamId != nil || photoId != nil || checkInId != nil else {
            throw CommentError.noTarget
        }

        // Create comment insert struct
        struct CommentInsert: Encodable {
            let user_id: String
            let content: String
            let mountain_id: String?
            let webcam_id: String?
            let photo_id: String?
            let check_in_id: String?
            let parent_comment_id: String?
        }

        let commentData = CommentInsert(
            user_id: user.id.uuidString,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            mountain_id: mountainId,
            webcam_id: webcamId,
            photo_id: photoId,
            check_in_id: checkInId,
            parent_comment_id: parentCommentId
        )

        let response: Comment = try await supabase.from("comments")
            .insert(commentData)
            .select("""
                *,
                user:user_id (
                    id,
                    username,
                    display_name,
                    avatar_url
                )
            """)
            .single()
            .execute()
            .value

        return response
    }

    /// Update a comment (owner only)
    func updateComment(id: String, content: String) async throws -> Comment {
        // Validate content
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommentError.emptyContent
        }

        guard content.count <= 2000 else {
            throw CommentError.contentTooLong
        }

        // Get current user
        guard let user = try? await supabase.auth.session.user else {
            throw CommentError.notAuthenticated
        }

        // Fetch existing comment to verify ownership
        let existingComment: Comment = try await supabase.from("comments")
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
            .value

        guard existingComment.userId == user.id.uuidString else {
            throw CommentError.notOwner
        }

        guard !existingComment.isDeleted else {
            throw CommentError.commentDeleted
        }

        // Update comment
        struct CommentUpdate: Encodable {
            let content: String
            let updated_at: String
        }

        let updateData = CommentUpdate(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        let response: Comment = try await supabase.from("comments")
            .update(updateData)
            .eq("id", value: id)
            .select("""
                *,
                user:user_id (
                    id,
                    username,
                    display_name,
                    avatar_url
                )
            """)
            .single()
            .execute()
            .value

        return response
    }

    /// Delete a comment (owner only) - soft delete
    func deleteComment(id: String) async throws {
        // Get current user
        guard let user = try? await supabase.auth.session.user else {
            throw CommentError.notAuthenticated
        }

        // Fetch existing comment to verify ownership
        let existingComment: Comment = try await supabase.from("comments")
            .select("user_id, is_deleted")
            .eq("id", value: id)
            .single()
            .execute()
            .value

        guard existingComment.userId == user.id.uuidString else {
            throw CommentError.notOwner
        }

        guard !existingComment.isDeleted else {
            throw CommentError.commentDeleted
        }

        // Soft delete
        struct CommentDelete: Encodable {
            let is_deleted: Bool
            let content: String
            let updated_at: String
        }

        let deleteData = CommentDelete(
            is_deleted: true,
            content: "[deleted]",
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase.from("comments")
            .update(deleteData)
            .eq("id", value: id)
            .execute()
    }
}

enum CommentError: LocalizedError {
    case emptyContent
    case contentTooLong
    case notAuthenticated
    case noTarget
    case notOwner
    case commentDeleted

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Comment cannot be empty"
        case .contentTooLong:
            return "Comment must be less than 2000 characters"
        case .notAuthenticated:
            return "You must be signed in to comment"
        case .noTarget:
            return "At least one target is required"
        case .notOwner:
            return "You can only edit or delete your own comments"
        case .commentDeleted:
            return "This comment has been deleted"
        }
    }
}
