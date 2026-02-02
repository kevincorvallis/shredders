import Foundation
import SwiftUI

// MARK: - Urgency Level for Last Minute Events

enum UrgencyLevel {
    case departed   // Already left
    case critical   // < 1 hour
    case soon       // 1-3 hours
    case later      // > 3 hours
    case none       // No departure time set

    var color: Color {
        switch self {
        case .departed: return .gray
        case .critical: return .red
        case .soon: return .orange
        case .later: return .green
        case .none: return .secondary
        }
    }

    var label: String {
        switch self {
        case .departed: return "Departed"
        case .critical: return "Leaving Soon!"
        case .soon: return "Coming Up"
        case .later: return "Plenty of Time"
        case .none: return ""
        }
    }
}

// MARK: - Event Models

struct Event: Codable, Identifiable {
    let id: String
    let creatorId: String
    let mountainId: String
    let mountainName: String?
    let title: String
    let notes: String?
    let eventDate: String
    let departureTime: String?
    let departureLocation: String?
    let skillLevel: SkillLevel?
    let carpoolAvailable: Bool
    let carpoolSeats: Int?
    let status: EventStatus
    let createdAt: String
    let updatedAt: String
    let attendeeCount: Int
    let goingCount: Int
    let maybeCount: Int
    let creator: EventUser
    let userRSVPStatus: RSVPStatus?
    let isCreator: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case creatorId
        case mountainId
        case mountainName
        case title
        case notes
        case eventDate
        case departureTime
        case departureLocation
        case skillLevel
        case carpoolAvailable
        case carpoolSeats
        case status
        case createdAt
        case updatedAt
        case attendeeCount
        case goingCount
        case maybeCount
        case creator
        case userRSVPStatus
        case isCreator
    }

    // Static formatters to avoid expensive instantiation in computed properties
    private static let dateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private static let dateTimeParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    var formattedDate: String {
        guard let date = Self.dateParser.date(from: eventDate) else { return eventDate }
        return Self.eventDateFormatter.string(from: date)
    }

    var formattedTime: String? {
        guard let time = departureTime else { return nil }
        let components = time.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]) else { return time }

        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour >= 12 ? "PM" : "AM"
        return "\(h12):\(components[1]) \(ampm)"
    }

    // MARK: - Last Minute Crew Properties

    /// Whether this event is happening today
    var isToday: Bool {
        eventDate == Self.dateParser.string(from: Date())
    }

    /// Calculates time until departure in seconds
    var timeUntilDeparture: TimeInterval? {
        guard let time = departureTime else { return nil }

        guard let departureDate = Self.dateTimeParser.date(from: "\(eventDate) \(time)") else {
            return nil
        }

        return departureDate.timeIntervalSince(Date())
    }

    /// Urgency level based on time until departure
    var urgencyLevel: UrgencyLevel {
        guard let remaining = timeUntilDeparture else { return .none }
        switch remaining {
        case ..<0: return .departed
        case ..<3600: return .critical      // < 1 hour
        case ..<10800: return .soon         // 1-3 hours
        default: return .later              // > 3 hours
        }
    }

    /// Formatted countdown string (e.g., "2h 15m")
    var countdownText: String? {
        guard let remaining = timeUntilDeparture, remaining > 0 else { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Now!"
        }
    }
}

struct EventWithDetails: Codable, Identifiable {
    let id: String
    let creatorId: String
    let mountainId: String
    let mountainName: String?
    let title: String
    let notes: String?
    let eventDate: String
    let departureTime: String?
    let departureLocation: String?
    let skillLevel: SkillLevel?
    let carpoolAvailable: Bool
    let carpoolSeats: Int?
    let status: EventStatus
    let createdAt: String
    let updatedAt: String
    let attendeeCount: Int
    let goingCount: Int
    let maybeCount: Int
    let commentCount: Int?
    let photoCount: Int?
    let creator: EventUser
    let userRSVPStatus: RSVPStatus?
    let isCreator: Bool?
    let attendees: [EventAttendee]
    let conditions: EventConditions?
    let inviteToken: String?

    enum CodingKeys: String, CodingKey {
        case id
        case creatorId
        case mountainId
        case mountainName
        case title
        case notes
        case eventDate
        case departureTime
        case departureLocation
        case skillLevel
        case carpoolAvailable
        case carpoolSeats
        case status
        case createdAt
        case updatedAt
        case attendeeCount
        case goingCount
        case maybeCount
        case commentCount
        case photoCount
        case creator
        case userRSVPStatus
        case isCreator
        case attendees
        case conditions
        case inviteToken
    }

    // Static formatters to avoid expensive instantiation in computed properties
    private static let dateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    var formattedDate: String {
        guard let date = Self.dateParser.date(from: eventDate) else { return eventDate }
        return Self.fullDateFormatter.string(from: date)
    }

    var formattedTime: String? {
        guard let time = departureTime else { return nil }
        let components = time.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]) else { return time }

        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour >= 12 ? "PM" : "AM"
        return "\(h12):\(components[1]) \(ampm)"
    }
}

struct EventUser: Codable {
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

struct EventAttendee: Codable, Identifiable {
    let id: String
    let userId: String
    let status: RSVPStatus
    let isDriver: Bool
    let needsRide: Bool
    let pickupLocation: String?
    let respondedAt: String?
    let user: EventUser

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case status
        case isDriver
        case needsRide
        case pickupLocation
        case respondedAt
        case user
    }
}

struct EventConditions: Codable {
    let temperature: Double?
    let snowfall24h: Double?
    let snowDepth: Double?
    let powderScore: Double?
    let forecast: EventForecast?
}

struct EventForecast: Codable {
    let high: Double
    let low: Double
    let snowfall: Double
    let conditions: String
}

// MARK: - Enums

enum EventStatus: String, Codable {
    case active
    case cancelled
    case completed
}

enum SkillLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
    case expert
    case all

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        case .all: return "All Levels"
        }
    }
}

enum RSVPStatus: String, Codable {
    case invited
    case going
    case maybe
    case declined

    var displayName: String {
        switch self {
        case .invited: return "Invited"
        case .going: return "Going"
        case .maybe: return "Maybe"
        case .declined: return "Not Going"
        }
    }

    var color: String {
        switch self {
        case .going: return "green"
        case .maybe: return "yellow"
        case .invited, .declined: return "gray"
        }
    }
}

// MARK: - Response Types

struct EventsListResponse: Codable {
    let events: [Event]
    let pagination: EventPagination
}

struct EventPagination: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
}

struct EventResponse: Codable {
    let event: EventWithDetails
}

struct CreateEventResponse: Codable {
    let event: Event
    let inviteToken: String
    let inviteUrl: String
}

struct RSVPResponse: Codable {
    let attendee: EventAttendee
    let event: RSVPEventUpdate
}

struct RSVPEventUpdate: Codable {
    let id: String
    let goingCount: Int
    let maybeCount: Int
    let attendeeCount: Int
}

struct InviteResponse: Codable {
    let invite: InviteInfo
}

struct InviteInfo: Codable {
    let event: Event
    let conditions: EventConditions?
    let isValid: Bool
    let isExpired: Bool
    let requiresAuth: Bool
}

// MARK: - Request Types

struct CreateEventRequest: Encodable {
    let mountainId: String
    let title: String
    let notes: String?
    let eventDate: String
    let departureTime: String?
    let departureLocation: String?
    let skillLevel: String?
    let carpoolAvailable: Bool?
    let carpoolSeats: Int?
}

struct RSVPRequest: Encodable {
    let status: String
    let isDriver: Bool?
    let needsRide: Bool?
    let pickupLocation: String?
}
