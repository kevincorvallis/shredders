import Foundation

// MARK: - Date Poll Models

struct DatePoll: Codable, Identifiable {
    let id: String
    let eventId: String
    let status: DatePollStatus
    let createdAt: String
    let closedAt: String?
    let options: [DateOption]

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case status
        case createdAt = "created_at"
        case closedAt = "closed_at"
        case options
    }

    var isOpen: Bool { status == .open }
}

enum DatePollStatus: String, Codable {
    case open
    case closed
}

struct DateOption: Codable, Identifiable {
    let id: String
    let proposedDate: String
    let proposedBy: String
    let votes: [DateVoteEntry]
    let availableCount: Int
    let maybeCount: Int
    let unavailableCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case proposedDate = "proposed_date"
        case proposedBy = "proposed_by"
        case votes
        case availableCount = "available_count"
        case maybeCount = "maybe_count"
        case unavailableCount = "unavailable_count"
    }

    /// Formatted display date
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: proposedDate) else { return proposedDate }
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    /// Total votes cast
    var totalVotes: Int { availableCount + maybeCount + unavailableCount }
}

struct DateVoteEntry: Codable {
    let userId: String
    let vote: DateVoteChoice
    let user: DateVoteUser?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case vote
        case user
    }
}

enum DateVoteChoice: String, Codable {
    case available
    case maybe
    case unavailable
}

struct DateVoteUser: Codable {
    let id: String
    let username: String?
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - API Response Wrappers

struct DatePollResponse: Codable {
    let poll: DatePoll
}

struct DateVoteResponse: Codable {
    let vote: DateVoteResponseData
}

struct DateVoteResponseData: Codable {
    let id: String
    let optionId: String
    let userId: String
    let vote: DateVoteChoice

    enum CodingKeys: String, CodingKey {
        case id
        case optionId = "option_id"
        case userId = "user_id"
        case vote
    }
}

struct DatePollResolveResponse: Codable {
    let message: String
    let selectedDate: String
    let eventId: String

    enum CodingKeys: String, CodingKey {
        case message
        case selectedDate = "selected_date"
        case eventId = "event_id"
    }
}
