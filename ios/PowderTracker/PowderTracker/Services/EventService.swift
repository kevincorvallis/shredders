import Foundation
import Supabase

@MainActor
@Observable
class EventService {
    static let shared = EventService()

    private let baseURL: String
    private let decoder: JSONDecoder
    private let supabase = SupabaseClientManager.shared.client
    private let cache = EventCacheService.shared
    private let userCache = UserProfileCacheService.shared
    private let rsvpCache = RSVPCacheService.shared

    // OPTIMIZATION: Memory cache for auth token to avoid Keychain queries on every request
    private static var cachedToken: String?
    private static var tokenExpiry: Date?
    private static let tokenCacheDuration: TimeInterval = 300 // 5 minutes

    private init() {
        self.baseURL = AppConfig.apiBaseURL
        self.decoder = JSONDecoder()
    }

    /// Clear the cached auth token (call on sign out or token refresh)
    static func clearCachedToken() {
        cachedToken = nil
        tokenExpiry = nil
    }

    /// Clear all caches (call on sign out)
    static func clearAllCaches() {
        clearCachedToken()
        Task { @MainActor in
            EventCacheService.shared.clearCache()
            UserProfileCacheService.shared.clearAllCaches()
            RSVPCacheService.shared.clearCache()
        }
    }

    // MARK: - List Events

    /// Fetch events with optional filters
    /// Falls back to cached events when offline
    /// - Parameter bustCache: If true, adds a timestamp to bypass HTTP cache (use after creating/modifying events)
    func fetchEvents(
        mountainId: String? = nil,
        upcoming: Bool = true,
        createdByMe: Bool = false,
        attendingOnly: Bool = false,
        limit: Int = 20,
        offset: Int = 0,
        bustCache: Bool = false
    ) async throws -> EventsListResponse {
        var components = URLComponents(string: "\(baseURL)/events")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        // Add cache-busting timestamp to bypass HTTP cache when needed
        if bustCache {
            queryItems.append(URLQueryItem(name: "_t", value: String(Int(Date().timeIntervalSince1970))))
        }

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

        do {
            // Use retry logic for network resilience
            let result = try await fetchWithRetry {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw EventServiceError.networkError
                }

                guard httpResponse.statusCode == 200 else {
                    throw EventServiceError.serverError(httpResponse.statusCode)
                }

                return try self.decoder.decode(EventsListResponse.self, from: data)
            }

            // Cache events for offline access (only cache main list without filters)
            if mountainId == nil && !createdByMe && !attendingOnly && offset == 0 {
                cache.cacheEvents(result.events)
            }

            // OPTIMIZATION: Cache user profiles from event creators
            for event in result.events {
                userCache.cacheCreatorFromEvent(event)
            }

            // OPTIMIZATION: Cache RSVP statuses from events (if attending filter)
            if attendingOnly {
                rsvpCache.cacheRSVPsFromEvents(result.events)
            }

            return result
        } catch {
            // Try to return cached events if network fails
            if let cachedEvents = cache.getCachedEvents() {
                // Filter cached events based on parameters
                var filteredEvents = cachedEvents
                if let mountainId = mountainId {
                    filteredEvents = filteredEvents.filter { $0.mountainId == mountainId }
                }

                return EventsListResponse(
                    events: Array(filteredEvents.prefix(limit)),
                    pagination: EventPagination(total: filteredEvents.count, limit: limit, offset: offset, hasMore: filteredEvents.count > limit)
                )
            }

            // No cache available, rethrow original error
            throw error
        }
    }

    // MARK: - Get Event Details

    /// Fetch a single event with full details
    /// Falls back to cached event details when offline
    func fetchEvent(id: String) async throws -> EventWithDetails {
        guard let url = URL(string: "\(baseURL)/events/\(id)") else {
            throw EventServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try? await addAuthHeader(to: &request) // Optional auth for viewing

        do {
            // Use retry logic for network resilience
            let event = try await fetchWithRetry {
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

                let eventResponse = try self.decoder.decode(EventResponse.self, from: data)
                return eventResponse.event
            }

            // Cache event details for offline access
            cache.cacheEventDetails(event)

            // OPTIMIZATION: Cache user profiles from the event
            userCache.cacheCreatorFromEvent(event)
            if !event.attendees.isEmpty {
                userCache.cacheAttendeesFromEvent(event.attendees)
            }

            // OPTIMIZATION: Cache RSVP status if present
            if let rsvpStatus = event.userRSVPStatus {
                rsvpCache.cacheRSVP(eventId: event.id, status: rsvpStatus.rawValue)
            }

            return event
        } catch {
            // Don't use cache for 404 errors (event was deleted)
            if case EventServiceError.notFound = error {
                throw error
            }

            // Try to return cached event details if network fails
            if let cachedEvent = cache.getCachedEventDetails(id: id) {
                return cachedEvent
            }

            // No cache available, rethrow original error
            throw error
        }
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
        carpoolSeats: Int? = nil,
        maxAttendees: Int? = nil
    ) async throws -> CreateEventResponse {
        // Phase 5: Client-side validation (prevents unnecessary network calls)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.count >= 3 else {
            throw EventServiceError.validationError("Title must be at least 3 characters")
        }
        guard trimmedTitle.count <= 100 else {
            throw EventServiceError.validationError("Title must be less than 100 characters")
        }

        if let notes = notes, notes.count > 2000 {
            throw EventServiceError.validationError("Notes must be less than 2000 characters")
        }

        // Check event date is not in the past
        let today = Calendar.current.startOfDay(for: Date())
        let eventDay = Calendar.current.startOfDay(for: eventDate)
        guard eventDay >= today else {
            throw EventServiceError.validationError("Event date cannot be in the past")
        }

        // Validate departure time format (HH:MM)
        if let departureTime = departureTime {
            let timePattern = "^\\d{2}:\\d{2}$"
            let timeRegex = try? NSRegularExpression(pattern: timePattern)
            let range = NSRange(departureTime.startIndex..., in: departureTime)
            guard timeRegex?.firstMatch(in: departureTime, range: range) != nil else {
                throw EventServiceError.validationError("Departure time must be in HH:MM format")
            }
        }

        // Validate carpool seats
        if let seats = carpoolSeats, (seats < 0 || seats > 8) {
            throw EventServiceError.validationError("Carpool seats must be between 0 and 8")
        }

        guard let url = URL(string: "\(baseURL)/events") else {
            throw EventServiceError.invalidURL
        }

        // Format date
        // Phase 6 optimization: Use static DateFormatter
        let eventDateString = DateFormatters.dateParser.string(from: eventDate)

        let requestBody = CreateEventRequest(
            mountainId: mountainId,
            title: title,
            notes: notes,
            eventDate: eventDateString,
            departureTime: departureTime,
            departureLocation: departureLocation,
            skillLevel: skillLevel?.rawValue,
            carpoolAvailable: carpoolAvailable,
            carpoolSeats: carpoolSeats,
            maxAttendees: maxAttendees
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

        let result = try decoder.decode(CreateEventResponse.self, from: data)

        // Invalidate cache after creating event so next fetch gets fresh data
        cache.invalidateAll()

        return result
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
            // Phase 6 optimization: Use static DateFormatter
            body["eventDate"] = DateFormatters.dateParser.string(from: eventDate)
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

        // Invalidate cache after deleting event so it no longer appears in lists
        cache.invalidateAll()
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

        let (data, urlResponse) = try await URLSession.shared.data(for: request)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
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

        let rsvpResponse = try decoder.decode(RSVPResponse.self, from: data)

        // OPTIMIZATION: Update RSVP cache and invalidate event cache
        rsvpCache.handleRSVPResponse(rsvpResponse)

        return rsvpResponse
    }

    /// Remove RSVP from an event
    func removeRSVP(eventId: String) async throws {
        guard let url = URL(string: "\(baseURL)/events/\(eventId)/rsvp") else {
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

        if httpResponse.statusCode == 400 {
            // Check for specific error (e.g., creator cannot remove RSVP)
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw EventServiceError.validationError(errorMessage)
            }
            throw EventServiceError.validationError("Cannot remove RSVP")
        }

        if httpResponse.statusCode == 404 {
            throw EventServiceError.notFound
        }

        guard httpResponse.statusCode == 200 else {
            throw EventServiceError.serverError(httpResponse.statusCode)
        }

        // OPTIMIZATION: Update RSVP cache and invalidate event cache
        rsvpCache.handleRSVPRemoved(eventId: eventId)
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

    // MARK: - Retry Logic with Exponential Backoff

    /// Retries a network request with exponential backoff and jitter
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - baseDelay: Initial delay in seconds (default: 1.0)
    ///   - operation: The async operation to retry
    /// - Returns: The result of the operation
    private func fetchWithRetry<T>(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch let error as EventServiceError {
                lastError = error

                // Don't retry on client errors (4xx) except 429 rate limit
                if case .serverError(let code) = error {
                    // Only retry on 429 (rate limit) or 5xx server errors
                    if code >= 400 && code < 500 && code != 429 {
                        throw error
                    }
                }

                // Don't retry auth errors or validation errors
                if case .notAuthenticated = error { throw error }
                if case .notOwner = error { throw error }
                if case .notFound = error { throw error }
                if case .invalidInvite = error { throw error }
                if case .validationError = error { throw error }
                if case .rsvpRequired = error { throw error }
                if case .invalidURL = error { throw error }
                if case .invalidResponse = error { throw error }

                // Don't retry on last attempt
                if attempt == maxRetries - 1 { break }

                // Calculate exponential backoff with jitter
                let delay = baseDelay * pow(2.0, Double(attempt))
                let jitter = Double.random(in: 0...0.3) * delay
                let totalDelay = delay + jitter

                #if DEBUG
                print("[EventService] Retry \(attempt + 1)/\(maxRetries) after \(String(format: "%.2f", totalDelay))s delay")
                #endif

                try await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
            } catch {
                // For non-EventServiceError errors (network errors), retry
                lastError = error

                if attempt == maxRetries - 1 { break }

                let delay = baseDelay * pow(2.0, Double(attempt))
                let jitter = Double.random(in: 0...0.3) * delay
                let totalDelay = delay + jitter

                #if DEBUG
                print("[EventService] Retry \(attempt + 1)/\(maxRetries) after \(String(format: "%.2f", totalDelay))s delay (error: \(error.localizedDescription))")
                #endif

                try await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
            }
        }

        throw lastError ?? EventServiceError.networkError
    }

    // MARK: - Auth Helper

    private func addAuthHeader(to request: inout URLRequest) async throws {
        // OPTIMIZATION: Check memory cache first to avoid Keychain queries
        if let token = Self.cachedToken,
           let expiry = Self.tokenExpiry,
           expiry > Date() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return
        }

        // First try Keychain JWT tokens (from email/password login)
        if let accessToken = KeychainHelper.getAccessToken(), !KeychainHelper.isAccessTokenExpired() {
            // Cache the token in memory
            Self.cachedToken = accessToken
            Self.tokenExpiry = Date().addingTimeInterval(Self.tokenCacheDuration)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            return
        }

        // Try to refresh Keychain tokens if we have a refresh token
        if KeychainHelper.getRefreshToken() != nil {
            do {
                // Delegate to AuthService for token refresh (single source of truth)
                try await AuthService.shared.refreshTokens()
                if let accessToken = KeychainHelper.getAccessToken() {
                    // Cache the refreshed token
                    Self.cachedToken = accessToken
                    Self.tokenExpiry = Date().addingTimeInterval(Self.tokenCacheDuration)
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
            // Cache the Supabase token as well
            Self.cachedToken = session.accessToken
            Self.tokenExpiry = Date().addingTimeInterval(Self.tokenCacheDuration)
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
