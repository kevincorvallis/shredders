//
//  EventActivity.swift
//  PowderTracker
//
//  Model for event activity timeline (RSVPs, comments, milestones).
//

import Foundation
import SwiftUI

// MARK: - Event Activity Models

struct EventActivity: Codable, Identifiable {
    let id: String
    let eventId: String
    let userId: String?
    let activityType: ActivityType
    let metadata: ActivityMetadata
    let createdAt: String
    let user: ActivityUser?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case userId
        case activityType
        case metadata
        case createdAt
        case user
    }

    /// Formatted relative time
    var relativeTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: createdAt) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: createdAt) else {
                return createdAt
            }
            return formatRelativeTime(from: date)
        }
        return formatRelativeTime(from: date)
    }

    private func formatRelativeTime(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 172800 {
            return "Yesterday"
        } else {
            let days = Int(interval / 86400)
            if days < 7 {
                return "\(days)d ago"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d"
                return dateFormatter.string(from: date)
            }
        }
    }

    /// Display text for the activity
    var displayText: String {
        let name = user?.displayNameOrUsername ?? "Someone"

        switch activityType {
        case .rsvpGoing:
            return "\(name) is going"
        case .rsvpMaybe:
            return "\(name) might be going"
        case .rsvpDeclined:
            return "\(name) can't make it"
        case .commentPosted:
            if metadata.isReply == true {
                return "\(name) replied to a comment"
            }
            return "\(name) commented"
        case .milestoneReached:
            return metadata.label ?? "Milestone reached!"
        case .eventCreated:
            return "\(name) created the event"
        case .eventUpdated:
            return "\(name) updated the event"
        }
    }

    /// Icon for the activity type
    var icon: String {
        switch activityType {
        case .rsvpGoing:
            return "checkmark.circle.fill"
        case .rsvpMaybe:
            return "questionmark.circle.fill"
        case .rsvpDeclined:
            return "xmark.circle.fill"
        case .commentPosted:
            return "bubble.left.fill"
        case .milestoneReached:
            return "star.fill"
        case .eventCreated:
            return "plus.circle.fill"
        case .eventUpdated:
            return "pencil.circle.fill"
        }
    }

    /// Color for the activity type
    var iconColor: Color {
        switch activityType {
        case .rsvpGoing:
            return .green
        case .rsvpMaybe:
            return .orange
        case .rsvpDeclined:
            return .secondary
        case .commentPosted:
            return .blue
        case .milestoneReached:
            return .yellow
        case .eventCreated:
            return .purple
        case .eventUpdated:
            return .cyan
        }
    }

    /// Whether this is a milestone (special styling)
    var isMilestone: Bool {
        activityType == .milestoneReached
    }
}

// MARK: - Activity Type

enum ActivityType: String, Codable {
    case rsvpGoing = "rsvp_going"
    case rsvpMaybe = "rsvp_maybe"
    case rsvpDeclined = "rsvp_declined"
    case commentPosted = "comment_posted"
    case milestoneReached = "milestone_reached"
    case eventCreated = "event_created"
    case eventUpdated = "event_updated"
}

// MARK: - Activity Metadata

struct ActivityMetadata: Codable {
    let milestone: Int?
    let label: String?
    let commentId: String?
    let preview: String?
    let isReply: Bool?
    let previousStatus: String?

    enum CodingKeys: String, CodingKey {
        case milestone
        case label
        case commentId = "comment_id"
        case preview
        case isReply = "is_reply"
        case previousStatus = "previous_status"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        milestone = try container.decodeIfPresent(Int.self, forKey: .milestone)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        commentId = try container.decodeIfPresent(String.self, forKey: .commentId)
        preview = try container.decodeIfPresent(String.self, forKey: .preview)
        isReply = try container.decodeIfPresent(Bool.self, forKey: .isReply)
        previousStatus = try container.decodeIfPresent(String.self, forKey: .previousStatus)
    }
}

// MARK: - Activity User

struct ActivityUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName
        case avatarUrl
    }

    var displayNameOrUsername: String {
        displayName ?? username
    }
}

// MARK: - API Response Types

struct EventActivityResponse: Codable {
    let activities: [EventActivity]
    let activityCount: Int
    let gated: Bool
    let message: String?
    let pagination: ActivityPagination?
}

struct ActivityPagination: Codable {
    let limit: Int
    let offset: Int
    let hasMore: Bool
}
