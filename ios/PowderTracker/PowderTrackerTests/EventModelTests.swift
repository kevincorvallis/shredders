//
//  EventModelTests.swift
//  PowderTrackerTests
//
//  Unit tests for Event models, enums, and computed properties
//

import XCTest
@testable import PowderTracker

final class EventModelTests: XCTestCase {

    // MARK: - Event Tests

    func testEvent_Identifiable() {
        // Given
        let event = createMockEvent(id: "test-123")

        // Then
        XCTAssertEqual(event.id, "test-123")
    }

    func testEvent_FormattedDate_ValidDate() {
        // Given
        let event = createMockEvent(eventDate: "2025-03-15")

        // Then
        XCTAssertEqual(event.formattedDate, "Sat, Mar 15")
    }

    func testEvent_FormattedDate_InvalidDate() {
        // Given
        let event = createMockEvent(eventDate: "invalid-date")

        // Then
        XCTAssertEqual(event.formattedDate, "invalid-date")
    }

    func testEvent_FormattedTime_MorningTime() {
        // Given
        let event = createMockEvent(departureTime: "06:30:00")

        // Then
        XCTAssertEqual(event.formattedTime, "6:30 AM")
    }

    func testEvent_FormattedTime_AfternoonTime() {
        // Given
        let event = createMockEvent(departureTime: "14:00:00")

        // Then
        XCTAssertEqual(event.formattedTime, "2:00 PM")
    }

    func testEvent_FormattedTime_Midnight() {
        // Given
        let event = createMockEvent(departureTime: "00:00:00")

        // Then
        XCTAssertEqual(event.formattedTime, "12:00 AM")
    }

    func testEvent_FormattedTime_Noon() {
        // Given
        let event = createMockEvent(departureTime: "12:00:00")

        // Then
        XCTAssertEqual(event.formattedTime, "12:00 PM")
    }

    func testEvent_FormattedTime_NilDepartureTime() {
        // Given
        let event = createMockEvent(departureTime: nil)

        // Then
        XCTAssertNil(event.formattedTime)
    }

    func testEvent_IsToday_True() {
        // Given
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let event = createMockEvent(eventDate: today)

        // Then
        XCTAssertTrue(event.isToday)
    }

    func testEvent_IsToday_False() {
        // Given
        let event = createMockEvent(eventDate: "2020-01-01")

        // Then
        XCTAssertFalse(event.isToday)
    }

    func testEvent_UrgencyLevel_NoDepartureTime() {
        // Given
        let event = createMockEvent(departureTime: nil)

        // Then
        XCTAssertEqual(event.urgencyLevel, .none)
    }

    func testEvent_UrgencyLevel_Departed() {
        // Given - an event that departed yesterday
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let eventDate = formatter.string(from: yesterday)
        let event = createMockEvent(eventDate: eventDate, departureTime: "06:00")

        // Then
        XCTAssertEqual(event.urgencyLevel, .departed)
    }

    func testEvent_CountdownText_NilWhenNoDepartureTime() {
        // Given
        let event = createMockEvent(departureTime: nil)

        // Then
        XCTAssertNil(event.countdownText)
    }

    func testEvent_CountdownText_NilWhenDeparted() {
        // Given - past event
        let event = createMockEvent(eventDate: "2020-01-01", departureTime: "06:00:00")

        // Then
        XCTAssertNil(event.countdownText)
    }

    func testEvent_Codable_EncodesAndDecodes() throws {
        // Given
        let event = createMockEvent()

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(event)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Event.self, from: data)

        // Then
        XCTAssertEqual(decoded.id, event.id)
        XCTAssertEqual(decoded.title, event.title)
        XCTAssertEqual(decoded.mountainId, event.mountainId)
        XCTAssertEqual(decoded.eventDate, event.eventDate)
        XCTAssertEqual(decoded.goingCount, event.goingCount)
    }

    // MARK: - EventWithDetails Tests

    func testEventWithDetails_FormattedDate_FullFormat() {
        // Given
        let event = createMockEventWithDetails(eventDate: "2025-03-15")

        // Then
        XCTAssertEqual(event.formattedDate, "Saturday, March 15, 2025")
    }

    func testEventWithDetails_HasAttendees() {
        // Given
        let attendees = [createMockAttendee(status: .going), createMockAttendee(status: .maybe)]
        let event = createMockEventWithDetails(attendees: attendees)

        // Then
        XCTAssertEqual(event.attendees.count, 2)
    }

    func testEventWithDetails_HasConditions() {
        // Given
        let conditions = EventConditions(
            temperature: 28,
            snowfall24h: 8,
            snowDepth: 100,
            powderScore: 7.5,
            forecast: EventForecast(high: 32, low: 22, snowfall: 6, conditions: "Snow")
        )
        let event = createMockEventWithDetails(conditions: conditions)

        // Then
        XCTAssertNotNil(event.conditions)
        XCTAssertEqual(event.conditions?.temperature, 28)
        XCTAssertNotNil(event.conditions?.forecast)
    }

    func testEventWithDetails_InviteToken() {
        // Given
        let event = createMockEventWithDetails(inviteToken: "abc123xyz")

        // Then
        XCTAssertEqual(event.inviteToken, "abc123xyz")
    }

    // MARK: - UrgencyLevel Tests

    func testUrgencyLevel_Colors() {
        XCTAssertNotNil(UrgencyLevel.departed.color)
        XCTAssertNotNil(UrgencyLevel.critical.color)
        XCTAssertNotNil(UrgencyLevel.soon.color)
        XCTAssertNotNil(UrgencyLevel.later.color)
        XCTAssertNotNil(UrgencyLevel.none.color)
    }

    func testUrgencyLevel_Labels() {
        XCTAssertEqual(UrgencyLevel.departed.label, "Departed")
        XCTAssertEqual(UrgencyLevel.critical.label, "Leaving Soon!")
        XCTAssertEqual(UrgencyLevel.soon.label, "Coming Up")
        XCTAssertEqual(UrgencyLevel.later.label, "Plenty of Time")
        XCTAssertEqual(UrgencyLevel.none.label, "")
    }

    // MARK: - EventStatus Tests

    func testEventStatus_RawValues() {
        XCTAssertEqual(EventStatus.active.rawValue, "active")
        XCTAssertEqual(EventStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(EventStatus.completed.rawValue, "completed")
    }

    func testEventStatus_Codable() throws {
        // Given
        let statuses: [EventStatus] = [.active, .cancelled, .completed]

        for status in statuses {
            // When
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(EventStatus.self, from: data)

            // Then
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - SkillLevel Tests

    func testSkillLevel_AllCases() {
        let allCases = SkillLevel.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.beginner))
        XCTAssertTrue(allCases.contains(.intermediate))
        XCTAssertTrue(allCases.contains(.advanced))
        XCTAssertTrue(allCases.contains(.expert))
        XCTAssertTrue(allCases.contains(.all))
    }

    func testSkillLevel_DisplayNames() {
        XCTAssertEqual(SkillLevel.beginner.displayName, "Beginner")
        XCTAssertEqual(SkillLevel.intermediate.displayName, "Intermediate")
        XCTAssertEqual(SkillLevel.advanced.displayName, "Advanced")
        XCTAssertEqual(SkillLevel.expert.displayName, "Expert")
        XCTAssertEqual(SkillLevel.all.displayName, "All Levels")
    }

    func testSkillLevel_RawValues() {
        XCTAssertEqual(SkillLevel.beginner.rawValue, "beginner")
        XCTAssertEqual(SkillLevel.intermediate.rawValue, "intermediate")
        XCTAssertEqual(SkillLevel.advanced.rawValue, "advanced")
        XCTAssertEqual(SkillLevel.expert.rawValue, "expert")
        XCTAssertEqual(SkillLevel.all.rawValue, "all")
    }

    // MARK: - RSVPStatus Tests

    func testRSVPStatus_RawValues() {
        XCTAssertEqual(RSVPStatus.invited.rawValue, "invited")
        XCTAssertEqual(RSVPStatus.going.rawValue, "going")
        XCTAssertEqual(RSVPStatus.maybe.rawValue, "maybe")
        XCTAssertEqual(RSVPStatus.declined.rawValue, "declined")
    }

    func testRSVPStatus_DisplayNames() {
        XCTAssertEqual(RSVPStatus.invited.displayName, "Invited")
        XCTAssertEqual(RSVPStatus.going.displayName, "Going")
        XCTAssertEqual(RSVPStatus.maybe.displayName, "Maybe")
        XCTAssertEqual(RSVPStatus.declined.displayName, "Not Going")
    }

    func testRSVPStatus_Colors() {
        XCTAssertEqual(RSVPStatus.going.color, "green")
        XCTAssertEqual(RSVPStatus.maybe.color, "yellow")
        XCTAssertEqual(RSVPStatus.invited.color, "gray")
        XCTAssertEqual(RSVPStatus.declined.color, "gray")
    }

    // MARK: - EventUser Tests

    func testEventUser_DisplayNameOrUsername_WithDisplayName() {
        // Given
        let user = EventUser(id: "1", username: "johndoe", displayName: "John Doe", avatarUrl: nil, ridingStyle: nil)

        // Then
        XCTAssertEqual(user.displayNameOrUsername, "John Doe")
    }

    func testEventUser_DisplayNameOrUsername_WithoutDisplayName() {
        // Given
        let user = EventUser(id: "1", username: "johndoe", displayName: nil, avatarUrl: nil, ridingStyle: nil)

        // Then
        XCTAssertEqual(user.displayNameOrUsername, "johndoe")
    }

    func testEventUser_Codable() throws {
        // Given
        let user = EventUser(id: "123", username: "testuser", displayName: "Test User", avatarUrl: "https://example.com/avatar.jpg", ridingStyle: nil)

        // When
        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(EventUser.self, from: data)

        // Then
        XCTAssertEqual(decoded.id, user.id)
        XCTAssertEqual(decoded.username, user.username)
        XCTAssertEqual(decoded.displayName, user.displayName)
    }

    // MARK: - EventAttendee Tests

    func testEventAttendee_Identifiable() {
        // Given
        let attendee = createMockAttendee(id: "attendee-123")

        // Then
        XCTAssertEqual(attendee.id, "attendee-123")
    }

    func testEventAttendee_DriverStatus() {
        // Given
        let driver = createMockAttendee(isDriver: true, needsRide: false)
        let rider = createMockAttendee(isDriver: false, needsRide: true)
        let regular = createMockAttendee(isDriver: false, needsRide: false)

        // Then
        XCTAssertTrue(driver.isDriver)
        XCTAssertFalse(driver.needsRide)
        XCTAssertFalse(rider.isDriver)
        XCTAssertTrue(rider.needsRide)
        XCTAssertFalse(regular.isDriver)
        XCTAssertFalse(regular.needsRide)
    }

    // MARK: - EventConditions Tests

    func testEventConditions_AllFieldsPresent() {
        // Given
        let conditions = EventConditions(
            temperature: 25,
            snowfall24h: 12,
            snowDepth: 150,
            powderScore: 8.5,
            forecast: EventForecast(high: 30, low: 20, snowfall: 8, conditions: "Heavy Snow")
        )

        // Then
        XCTAssertEqual(conditions.temperature, 25)
        XCTAssertEqual(conditions.snowfall24h, 12)
        XCTAssertEqual(conditions.snowDepth, 150)
        XCTAssertEqual(conditions.powderScore, 8.5)
        XCTAssertNotNil(conditions.forecast)
    }

    func testEventConditions_NilValues() {
        // Given
        let conditions = EventConditions(
            temperature: nil,
            snowfall24h: nil,
            snowDepth: nil,
            powderScore: nil,
            forecast: nil
        )

        // Then
        XCTAssertNil(conditions.temperature)
        XCTAssertNil(conditions.forecast)
    }

    // MARK: - EventForecast Tests

    func testEventForecast_AllFields() {
        // Given
        let forecast = EventForecast(high: 32, low: 22, snowfall: 6, conditions: "Snow Showers")

        // Then
        XCTAssertEqual(forecast.high, 32)
        XCTAssertEqual(forecast.low, 22)
        XCTAssertEqual(forecast.snowfall, 6)
        XCTAssertEqual(forecast.conditions, "Snow Showers")
        XCTAssertTrue(forecast.high >= forecast.low)
    }

    func testEventForecast_Codable() throws {
        // Given
        let forecast = EventForecast(high: 35, low: 25, snowfall: 10, conditions: "Blizzard")

        // When
        let data = try JSONEncoder().encode(forecast)
        let decoded = try JSONDecoder().decode(EventForecast.self, from: data)

        // Then
        XCTAssertEqual(decoded.high, forecast.high)
        XCTAssertEqual(decoded.low, forecast.low)
        XCTAssertEqual(decoded.snowfall, forecast.snowfall)
        XCTAssertEqual(decoded.conditions, forecast.conditions)
    }

    // MARK: - Response Types Tests

    func testEventsListResponse_Pagination() throws {
        // Given
        let json = """
        {
            "events": [],
            "pagination": {
                "total": 50,
                "limit": 20,
                "offset": 0,
                "hasMore": true
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(EventsListResponse.self, from: data)

        // Then
        XCTAssertEqual(response.pagination.total, 50)
        XCTAssertEqual(response.pagination.limit, 20)
        XCTAssertEqual(response.pagination.offset, 0)
        XCTAssertTrue(response.pagination.hasMore)
    }

    func testCreateEventResponse_ContainsInviteUrl() throws {
        // Given
        let json = """
        {
            "event": {
                "id": "test-1",
                "creatorId": "user-1",
                "mountainId": "baker",
                "mountainName": "Mt. Baker",
                "title": "Test Event",
                "notes": null,
                "eventDate": "2025-03-15",
                "departureTime": "06:30:00",
                "departureLocation": null,
                "skillLevel": "intermediate",
                "carpoolAvailable": true,
                "carpoolSeats": 4,
                "status": "active",
                "createdAt": "2025-01-01T00:00:00Z",
                "updatedAt": "2025-01-01T00:00:00Z",
                "attendeeCount": 1,
                "goingCount": 1,
                "maybeCount": 0,
                "creator": {
                    "id": "user-1",
                    "username": "testuser",
                    "display_name": "Test User",
                    "avatar_url": null
                },
                "userRSVPStatus": null,
                "isCreator": true
            },
            "inviteToken": "abc123",
            "inviteUrl": "https://example.com/events/invite/abc123"
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(CreateEventResponse.self, from: data)

        // Then
        XCTAssertEqual(response.inviteToken, "abc123")
        XCTAssertTrue(response.inviteUrl.contains("abc123"))
        XCTAssertEqual(response.event.title, "Test Event")
    }

    func testInviteInfo_ValidInvite() {
        // Given
        let event = createMockEvent()
        let invite = InviteInfo(
            event: event,
            conditions: nil,
            isValid: true,
            isExpired: false,
            requiresAuth: true
        )

        // Then
        XCTAssertTrue(invite.isValid)
        XCTAssertFalse(invite.isExpired)
        XCTAssertTrue(invite.requiresAuth)
    }

    func testInviteInfo_ExpiredInvite() {
        // Given
        let event = createMockEvent()
        let invite = InviteInfo(
            event: event,
            conditions: nil,
            isValid: false,
            isExpired: true,
            requiresAuth: false
        )

        // Then
        XCTAssertFalse(invite.isValid)
        XCTAssertTrue(invite.isExpired)
    }

    // MARK: - Request Types Tests

    func testCreateEventRequest_Encodable() throws {
        // Given
        let request = CreateEventRequest(
            mountainId: "baker",
            title: "Powder Day!",
            notes: "Fresh tracks",
            eventDate: "2025-03-15",
            departureTime: "06:30:00",
            departureLocation: "Seattle",
            skillLevel: "intermediate",
            carpoolAvailable: true,
            carpoolSeats: 4,
            maxAttendees: nil
        )

        // When
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(dict?["mountainId"] as? String, "baker")
        XCTAssertEqual(dict?["title"] as? String, "Powder Day!")
        XCTAssertEqual(dict?["carpoolSeats"] as? Int, 4)
    }

    func testRSVPRequest_Encodable() throws {
        // Given
        let request = RSVPRequest(
            status: "going",
            isDriver: true,
            needsRide: false,
            pickupLocation: "Capitol Hill"
        )

        // When
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(dict?["status"] as? String, "going")
        XCTAssertEqual(dict?["isDriver"] as? Bool, true)
        XCTAssertEqual(dict?["needsRide"] as? Bool, false)
    }

    // MARK: - JSON Parsing Integration Tests

    func testJSONParsing_FullEventResponse() throws {
        // Given
        let json = """
        {
            "event": {
                "id": "event-123",
                "creatorId": "user-456",
                "mountainId": "stevens",
                "mountainName": "Stevens Pass",
                "title": "Weekend Shred",
                "notes": "Meet at lodge",
                "eventDate": "2025-03-22",
                "departureTime": "07:00:00",
                "departureLocation": "Bellevue",
                "skillLevel": "advanced",
                "carpoolAvailable": true,
                "carpoolSeats": 3,
                "status": "active",
                "createdAt": "2025-01-15T10:00:00Z",
                "updatedAt": "2025-01-15T10:00:00Z",
                "attendeeCount": 5,
                "goingCount": 4,
                "maybeCount": 1,
                "creator": {
                    "id": "user-456",
                    "username": "powderhound",
                    "display_name": "Powder Hound",
                    "avatar_url": "https://example.com/avatar.jpg"
                },
                "userRSVPStatus": "going",
                "isCreator": false,
                "attendees": [
                    {
                        "id": "att-1",
                        "userId": "user-789",
                        "status": "going",
                        "isDriver": true,
                        "needsRide": false,
                        "pickupLocation": null,
                        "respondedAt": "2025-01-16T08:00:00Z",
                        "user": {
                            "id": "user-789",
                            "username": "skibuddy",
                            "display_name": "Ski Buddy",
                            "avatar_url": null
                        }
                    }
                ],
                "conditions": {
                    "temperature": 28,
                    "snowfall24h": 8,
                    "snowDepth": 120,
                    "powderScore": 7.5,
                    "forecast": {
                        "high": 32,
                        "low": 24,
                        "snowfall": 6,
                        "conditions": "Snow Showers"
                    }
                },
                "inviteToken": "invite-token-xyz"
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(EventResponse.self, from: data)
        let event = response.event

        // Then
        XCTAssertEqual(event.id, "event-123")
        XCTAssertEqual(event.title, "Weekend Shred")
        XCTAssertEqual(event.mountainName, "Stevens Pass")
        XCTAssertEqual(event.skillLevel, .advanced)
        XCTAssertEqual(event.goingCount, 4)
        XCTAssertEqual(event.attendees.count, 1)
        XCTAssertTrue(event.attendees[0].isDriver)
        XCTAssertNotNil(event.conditions)
        XCTAssertEqual(event.conditions?.forecast?.snowfall, 6)
        XCTAssertEqual(event.inviteToken, "invite-token-xyz")
    }

    // MARK: - Edge Cases

    func testEvent_EmptyTitle() {
        // Given
        let event = createMockEvent(title: "")

        // Then
        XCTAssertEqual(event.title, "")
    }

    func testEvent_ZeroCounts() {
        // Given
        let event = createMockEvent(goingCount: 0, maybeCount: 0)

        // Then
        XCTAssertEqual(event.goingCount, 0)
        XCTAssertEqual(event.maybeCount, 0)
    }

    func testEvent_LargeCounts() {
        // Given
        let event = createMockEvent(goingCount: 1000, maybeCount: 500)

        // Then
        XCTAssertEqual(event.goingCount, 1000)
        XCTAssertEqual(event.maybeCount, 500)
    }

    // MARK: - Mock Helpers

    private func createMockEvent(
        id: String = "test-event-1",
        title: String = "Test Event",
        mountainId: String = "baker",
        mountainName: String = "Mt. Baker",
        eventDate: String = "2025-03-15",
        departureTime: String? = "06:30:00",
        goingCount: Int = 5,
        maybeCount: Int = 2
    ) -> Event {
        Event(
            id: id,
            creatorId: "user-1",
            mountainId: mountainId,
            mountainName: mountainName,
            title: title,
            notes: nil,
            eventDate: eventDate,
            departureTime: departureTime,
            departureLocation: nil,
            skillLevel: .intermediate,
            carpoolAvailable: true,
            carpoolSeats: 4,
            maxAttendees: nil,
            status: .active,
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            attendeeCount: goingCount + maybeCount,
            goingCount: goingCount,
            maybeCount: maybeCount,
            waitlistCount: nil,
            creator: EventUser(id: "user-1", username: "testuser", displayName: "Test User", avatarUrl: nil, ridingStyle: nil),
            userRSVPStatus: nil,
            isCreator: false
        )
    }

    private func createMockEventWithDetails(
        eventDate: String = "2025-03-15",
        attendees: [EventAttendee] = [],
        conditions: EventConditions? = nil,
        inviteToken: String? = nil
    ) -> EventWithDetails {
        EventWithDetails(
            id: "test-event-1",
            creatorId: "user-1",
            mountainId: "baker",
            mountainName: "Mt. Baker",
            title: "Test Event",
            notes: nil,
            eventDate: eventDate,
            departureTime: "06:30:00",
            departureLocation: nil,
            skillLevel: .intermediate,
            carpoolAvailable: true,
            carpoolSeats: 4,
            maxAttendees: nil,
            status: .active,
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            attendeeCount: 5,
            goingCount: 3,
            maybeCount: 2,
            waitlistCount: nil,
            commentCount: nil,
            photoCount: nil,
            creator: EventUser(id: "user-1", username: "testuser", displayName: "Test User", avatarUrl: nil, ridingStyle: nil),
            userRSVPStatus: nil,
            isCreator: true,
            attendees: attendees,
            conditions: conditions,
            inviteToken: inviteToken
        )
    }

    private func createMockAttendee(
        id: String = "att-1",
        status: RSVPStatus = .going,
        isDriver: Bool = false,
        needsRide: Bool = false
    ) -> EventAttendee {
        EventAttendee(
            id: id,
            userId: "user-1",
            status: status,
            isDriver: isDriver,
            needsRide: needsRide,
            pickupLocation: nil,
            waitlistPosition: nil,
            respondedAt: "2025-01-01T00:00:00Z",
            user: EventUser(id: "user-1", username: "testuser", displayName: "Test User", avatarUrl: nil, ridingStyle: nil)
        )
    }
}
