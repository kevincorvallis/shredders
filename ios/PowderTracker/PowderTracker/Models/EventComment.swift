//
//  EventComment.swift
//  PowderTracker
//
//  Model for event discussion comments with threading support.
//

import Foundation

// MARK: - Event Comment Models

struct EventComment: Codable, Identifiable {
    let id: String
    let eventId: String
    let userId: String
    let content: String
    let parentId: String?
    let createdAt: String
    let updatedAt: String
    let user: EventCommentUser
    var replies: [EventComment]?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case content
        case parentId = "parent_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case replies
    }

    /// Formatted relative time (e.g., "2h ago", "Yesterday")
    var relativeTime: String {
        guard let date = DateFormatters.parseISO8601(createdAt) else { return createdAt }
        return DateFormatters.relativeTimeString(from: date)
    }

    /// Whether this comment has replies
    var hasReplies: Bool {
        guard let replies = replies else { return false }
        return !replies.isEmpty
    }

    /// Number of replies
    var replyCount: Int {
        replies?.count ?? 0
    }
}

struct EventCommentUser: Codable {
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

    var displayNameOrUsername: String {
        displayName ?? username
    }
}

// MARK: - API Response Types

struct EventCommentsResponse: Codable {
    let comments: [EventComment]
    let commentCount: Int
    let gated: Bool
    let message: String?

    enum CodingKeys: String, CodingKey {
        case comments
        case commentCount
        case gated
        case message
    }
}

struct PostCommentResponse: Codable {
    let comment: EventComment
}

struct DeleteCommentResponse: Codable {
    let message: String
}

// MARK: - Request Types

struct PostCommentRequest: Encodable {
    let content: String
    let parentId: String?
}
