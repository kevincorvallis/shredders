import Foundation

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

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: eventDate) else { return eventDate }

        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
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
        case creator
        case userRSVPStatus
        case isCreator
        case attendees
        case conditions
        case inviteToken
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: eventDate) else { return eventDate }

        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
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
