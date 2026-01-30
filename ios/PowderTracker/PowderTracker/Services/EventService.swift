import Foundation
import Supabase

@MainActor
@Observable
class EventService {
    static let shared = EventService()

    private let baseURL: String
    private let decoder: JSONDecoder
    private let supabase: SupabaseClient

    private init() {
        self.baseURL = AppConfig.apiBaseURL
        self.decoder = JSONDecoder()
        guard let supabaseURL = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL configuration: \(AppConfig.supabaseURL)")
        }
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    // MARK: - List Events

    /// Fetch events with optional filters
    func fetchEvents(
        mountainId: String? = nil,
        upcoming: Bool = true,
        createdByMe: Bool = false,
        attendingOnly: Bool = false,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> EventsListResponse {
        var components = URLComponents(string: "\(baseURL)/events")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        if let mountainId = mountainId {
            queryItems.append(URLQueryItem(name: "mountainId", value: mountainId))
        }
        if upcoming {
            queryItems.append(URLQueryItem(name: "upcoming", value: "true"))
        }
        if createdByMe {
            queryItems.append(URLQueryItem(name: "createdByMe", value: "true"))
        }
        if attendingOnly {
            queryItems.append(URLQueryItem(name: "attendingOnly", value: "true"))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        return try decoder.decode(EventsListResponse.self, from: data)
    }

    // MARK: - Get Event Details

    /// Fetch a single event with full details
    func fetchEvent(id: String) async throws -> EventWithDetails {
        guard let url = URL(string: "\(baseURL)/events/\(id)") else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try? await addAuthHeader(to: &request) // Optional auth for viewing

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        let eventResponse = try decoder.decode(EventResponse.self, from: data)
        return eventResponse.event
    }

    // MARK: - Create Event

    /// Create a new event
    func createEvent(
        mountainId: String,
        title: String,
        notes: String? = nil,
        eventDate: Date,
        departureTime: String? = nil,
        departureLocation: String? = nil,
        skillLevel: SkillLevel? = nil,
        carpoolAvailable: Bool = false,
        carpoolSeats: Int? = nil
    ) async throws -> CreateEventResponse {
        guard let url = URL(string: "\(baseURL)/events") else {
            throw EventServiceError.invalidURL
        }

        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let eventDateString = dateFormatter.string(from: eventDate)

        let requestBody = CreateEventRequest(
            mountainId: mountainId,
            title: title,
            notes: notes,
            eventDate: eventDateString,
            departureTime: departureTime,
            departureLocation: departureLocation,
            skillLevel: skillLevel?.rawValue,
            carpoolAvailable: carpoolAvailable,
            carpoolSeats: carpoolSeats
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        guard httpResponse.statusCode == 201 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw EventServiceError.validationError(errorMessage)
            }
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        return try decoder.decode(CreateEventResponse.self, from: data)
    }

    // MARK: - Update Event

    /// Update an event (creator only)
    func updateEvent(
        id: String,
        title: String? = nil,
        notes: String? = nil,
        eventDate: Date? = nil,
        departureTime: String? = nil,
        departureLocation: String? = nil,
        skillLevel: SkillLevel? = nil,
        carpoolAvailable: Bool? = nil,
        carpoolSeats: Int? = nil
    ) async throws -> Event {
        guard let url = URL(string: "\(baseURL)/events/\(id)") else {
            throw EventServiceError.invalidURL
        }

        var body: [String: Any] = [:]
        if let title = title { body["title"] = title }
        if let notes = notes { body["notes"] = notes }
        if let eventDate = eventDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            body["eventDate"] = dateFormatter.string(from: eventDate)
        }
        if let departureTime = departureTime { body["departureTime"] = departureTime }
        if let departureLocation = departureLocation { body["departureLocation"] = departureLocation }
        if let skillLevel = skillLevel { body["skillLevel"] = skillLevel.rawValue }
        if let carpoolAvailable = carpoolAvailable { body["carpoolAvailable"] = carpoolAvailable }
        if let carpoolSeats = carpoolSeats { body["carpoolSeats"] = carpoolSeats }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        if httpResponse.statusCode == 403 {
            throw EventServiceError.notOwner
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        let eventResponse = try decoder.decode([String: Event].self, from: data)
        guard let event = eventResponse["event"] else {
            throw EventServiceError.invalidResponse
        }
        return event
    }

    // MARK: - Cancel Event

    /// Cancel an event (creator only)
    func cancelEvent(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/events/\(id)") else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeader(to: &request)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        if httpResponse.statusCode == 403 {
            throw EventServiceError.notOwner
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - RSVP

    /// RSVP to an event
    func rsvp(
        eventId: String,
        status: RSVPStatus,
        isDriver: Bool = false,
        needsRide: Bool = false,
        pickupLocation: String? = nil
    ) async throws -> RSVPResponse {
        guard let url = URL(string: "\(baseURL)/events/\(eventId)/rsvp") else {
            throw EventServiceError.invalidURL
        }

        let requestBody = RSVPRequest(
            status: status.rawValue,
            isDriver: isDriver,
            needsRide: needsRide,
            pickupLocation: pickupLocation
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw EventServiceError.validationError(errorMessage)
            }
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        return try decoder.decode(RSVPResponse.self, from: data)
    }

    /// Remove RSVP from an event
    func removeRSVP(eventId: String) async throws {
        guard let url = URL(string: "\(baseURL)/events/\(eventId)/rsvp") else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeader(to: &request)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Invite

    /// Fetch invite info from a token (public)
    func fetchInvite(token: String) async throws -> InviteInfo {
        guard let url = URL(string: "\(baseURL)/events/invite/\(token)") else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.invalidInvite
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        let inviteResponse = try decoder.decode(InviteResponse.self, from: data)
        return inviteResponse.invite
    }

    /// Use an invite token (validates and increments usage)
    func useInvite(token: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/events/invite/\(token)") else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.invalidInvite
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        let responseData = try JSONDecoder().decode([String: String].self, from: data)
        guard let eventId = responseData["eventId"] else {
            throw EventServiceError.invalidResponse
        }
        return eventId
    }

    // MARK: - Photos

    /// Fetch photos for an event
    /// Returns gated response if user hasn't RSVP'd
    func fetchPhotos(eventId: String, limit: Int = 20, offset: Int = 0) async throws -> EventPhotosResponse {
        var components = URLComponents(string: "\(baseURL)/events/\(eventId)/photos")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        guard let url = components.url else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try? await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        return try decoder.decode(EventPhotosResponse.self, from: data)
    }

    /// Upload a photo to an event
    func uploadPhoto(eventId: String, imageData: Data, caption: String? = nil) async throws -> EventPhoto {
        guard let url = URL(string: "\(baseURL)/events/\(eventId)/photos") else {
            throw EventServiceError.invalidURL
        }

        // Create multipart form data
        let boundary = UUID().uuidString
        var body = Data()

        // Add photo file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add caption if provided
        if let caption = caption, !caption.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
            body.append(caption.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        if httpResponse.statusCode == 403 {
            throw EventServiceError.rsvpRequired
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 201 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw EventServiceError.validationError(errorMessage)
            }
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        let uploadResponse = try decoder.decode(UploadPhotoResponse.self, from: data)
        return uploadResponse.photo
    }

    /// Delete a photo
    func deletePhoto(eventId: String, photoId: String) async throws {
        guard let url = URL(string: "\(baseURL)/events/\(eventId)/photos/\(photoId)") else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        if httpResponse.statusCode == 403 {
            throw EventServiceError.notOwner
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw EventServiceError.validationError(errorMessage)
            }
            throw EventServiceError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Activity Timeline

    /// Fetch activity timeline for an event
    /// Returns gated response if user hasn't RSVP'd
    func fetchActivity(eventId: String, limit: Int = 20, offset: Int = 0) async throws -> EventActivityResponse {
        var components = URLComponents(string: "\(baseURL)/events/\(eventId)/activity")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        guard let url = components.url else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try? await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        return try decoder.decode(EventActivityResponse.self, from: data)
    }

    // MARK: - Comments (Discussion)

    /// Fetch comments for an event
    /// Returns gated response if user hasn't RSVP'd
    func fetchComments(eventId: String, limit: Int = 50, offset: Int = 0) async throws -> EventCommentsResponse {
        var components = URLComponents(string: "\(baseURL)/events/\(eventId)/comments")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        guard let url = components.url else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try? await addAuthHeader(to: &request) // Optional - non-auth users get gated response

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        return try decoder.decode(EventCommentsResponse.self, from: data)
    }

    /// Post a comment on an event (requires RSVP)
    func postComment(eventId: String, content: String, parentId: String? = nil) async throws -> EventComment {
        guard let url = URL(string: "\(baseURL)/events/\(eventId)/comments") else {
            throw EventServiceError.invalidURL
        }

        let requestBody = PostCommentRequest(content: content, parentId: parentId)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        if httpResponse.statusCode == 403 {
            throw EventServiceError.rsvpRequired
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 201 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw EventServiceError.validationError(errorMessage)
            }
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        let commentResponse = try decoder.decode(PostCommentResponse.self, from: data)
        return commentResponse.comment
    }

    /// Delete a comment (own comments only, or event creator can delete any)
    func deleteComment(eventId: String, commentId: String) async throws {
        guard let url = URL(string: "\(baseURL)/events/\(eventId)/comments/\(commentId)") else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeader(to: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EventServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw EventServiceError.notAuthenticated
        }

        if httpResponse.statusCode == 403 {
            throw EventServiceError.notOwner
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw EventServiceError.validationError(errorMessage)
            }
            throw EventServiceError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Auth Helper

    private func addAuthHeader(to request: inout URLRequest) async throws {
        // First try Keychain JWT tokens (from email/password login)
        if let accessToken = KeychainHelper.getAccessToken(), !KeychainHelper.isAccessTokenExpired() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            return
        }

        // Try to refresh Keychain tokens if we have a refresh token
        if KeychainHelper.getRefreshToken() != nil {
            do {
                // Delegate to AuthService for token refresh (single source of truth)
                try await AuthService.shared.refreshTokens()
                if let accessToken = KeychainHelper.getAccessToken() {
                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    return
                }
            } catch {
                // Refresh failed, fall through to try Supabase session
            }
        }

        // Fallback to Supabase session token (for Sign In with Apple users)
        do {
            let session = try await supabase.auth.session
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            return
        } catch {
            // No Supabase session either
        }

        throw EventServiceError.notAuthenticated
    }
}

// MARK: - Errors

enum EventServiceError: LocalizedError {
    case invalidURL
    case networkError
    case serverError(Int)
    case notAuthenticated
    case notOwner
    case notFound
    case invalidInvite
    case invalidResponse
    case validationError(String)
    case rsvpRequired

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .networkError:
            return "Network connection error"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .notOwner:
            return "You can only modify your own events"
        case .notFound:
            return "Event not found"
        case .invalidInvite:
            return "Invalid or expired invite link"
        case .invalidResponse:
            return "Invalid server response"
        case .validationError(let message):
            return message
        case .rsvpRequired:
            return "You must RSVP to participate in this event's discussion"
        }
    }
}
