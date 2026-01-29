//
//  EventServiceTests.swift
//  PowderTrackerTests
//
//  Unit tests for EventService and EventServiceError
//

import XCTest
@testable import PowderTracker

final class EventServiceTests: XCTestCase {

    // MARK: - EventServiceError Tests

    func testEventServiceError_InvalidURL_Description() {
        // Given
        let error = EventServiceError.invalidURL

        // Then
        XCTAssertEqual(error.errorDescription, "Invalid request URL")
    }

    func testEventServiceError_NetworkError_Description() {
        // Given
        let error = EventServiceError.networkError

        // Then
        XCTAssertEqual(error.errorDescription, "Network connection error")
    }

    func testEventServiceError_ServerError_Description() {
        // Given
        let error404 = EventServiceError.serverError(404)
        let error500 = EventServiceError.serverError(500)

        // Then
        XCTAssertEqual(error404.errorDescription, "Server error (code: 404)")
        XCTAssertEqual(error500.errorDescription, "Server error (code: 500)")
    }

    func testEventServiceError_NotAuthenticated_Description() {
        // Given
        let error = EventServiceError.notAuthenticated

        // Then
        XCTAssertEqual(error.errorDescription, "You must be signed in to perform this action")
    }

    func testEventServiceError_NotOwner_Description() {
        // Given
        let error = EventServiceError.notOwner

        // Then
        XCTAssertEqual(error.errorDescription, "You can only modify your own events")
    }

    func testEventServiceError_NotFound_Description() {
        // Given
        let error = EventServiceError.notFound

        // Then
        XCTAssertEqual(error.errorDescription, "Event not found")
    }

    func testEventServiceError_InvalidInvite_Description() {
        // Given
        let error = EventServiceError.invalidInvite

        // Then
        XCTAssertEqual(error.errorDescription, "Invalid or expired invite link")
    }

    func testEventServiceError_InvalidResponse_Description() {
        // Given
        let error = EventServiceError.invalidResponse

        // Then
        XCTAssertEqual(error.errorDescription, "Invalid server response")
    }

    func testEventServiceError_ValidationError_Description() {
        // Given
        let error = EventServiceError.validationError("Title is required")

        // Then
        XCTAssertEqual(error.errorDescription, "Title is required")
    }

    func testEventServiceError_ValidationError_CustomMessage() {
        // Given
        let customMessage = "Event date must be in the future"
        let error = EventServiceError.validationError(customMessage)

        // Then
        XCTAssertEqual(error.errorDescription, customMessage)
    }

    // MARK: - Error Type Conformance

    func testEventServiceError_ConformsToLocalizedError() {
        // Given
        let error: any LocalizedError = EventServiceError.networkError

        // Then
        XCTAssertNotNil(error.errorDescription)
    }

    func testEventServiceError_AllCases_HaveDescriptions() {
        // Given
        let errors: [EventServiceError] = [
            .invalidURL,
            .networkError,
            .serverError(400),
            .notAuthenticated,
            .notOwner,
            .notFound,
            .invalidInvite,
            .invalidResponse,
            .validationError("test")
        ]

        // Then
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error description should not be empty")
        }
    }

    // MARK: - Request Building Tests

    func testCreateEventRequest_EncodesAllFields() throws {
        // Given
        let request = CreateEventRequest(
            mountainId: "baker",
            title: "Powder Day Hunt",
            notes: "Early bird gets the powder",
            eventDate: "2025-03-15",
            departureTime: "05:30:00",
            departureLocation: "Capitol Hill, Seattle",
            skillLevel: "intermediate",
            carpoolAvailable: true,
            carpoolSeats: 4
        )

        // When
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["mountainId"] as? String, "baker")
        XCTAssertEqual(dict?["title"] as? String, "Powder Day Hunt")
        XCTAssertEqual(dict?["notes"] as? String, "Early bird gets the powder")
        XCTAssertEqual(dict?["eventDate"] as? String, "2025-03-15")
        XCTAssertEqual(dict?["departureTime"] as? String, "05:30:00")
        XCTAssertEqual(dict?["departureLocation"] as? String, "Capitol Hill, Seattle")
        XCTAssertEqual(dict?["skillLevel"] as? String, "intermediate")
        XCTAssertEqual(dict?["carpoolAvailable"] as? Bool, true)
        XCTAssertEqual(dict?["carpoolSeats"] as? Int, 4)
    }

    func testCreateEventRequest_NilOptionalFields() throws {
        // Given
        let request = CreateEventRequest(
            mountainId: "stevens",
            title: "Quick Trip",
            notes: nil,
            eventDate: "2025-03-20",
            departureTime: nil,
            departureLocation: nil,
            skillLevel: nil,
            carpoolAvailable: nil,
            carpoolSeats: nil
        )

        // When
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(dict?["mountainId"] as? String, "stevens")
        XCTAssertEqual(dict?["title"] as? String, "Quick Trip")
        // Nil values should not be present or be null
        XCTAssertTrue(dict?["notes"] == nil || dict?["notes"] is NSNull)
    }

    func testRSVPRequest_GoingAsDriver() throws {
        // Given
        let request = RSVPRequest(
            status: "going",
            isDriver: true,
            needsRide: false,
            pickupLocation: "University District"
        )

        // When
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(dict?["status"] as? String, "going")
        XCTAssertEqual(dict?["isDriver"] as? Bool, true)
        XCTAssertEqual(dict?["needsRide"] as? Bool, false)
        XCTAssertEqual(dict?["pickupLocation"] as? String, "University District")
    }

    func testRSVPRequest_NeedsRide() throws {
        // Given
        let request = RSVPRequest(
            status: "going",
            isDriver: false,
            needsRide: true,
            pickupLocation: "Downtown Seattle"
        )

        // When
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(dict?["status"] as? String, "going")
        XCTAssertEqual(dict?["isDriver"] as? Bool, false)
        XCTAssertEqual(dict?["needsRide"] as? Bool, true)
    }

    func testRSVPRequest_MaybeStatus() throws {
        // Given
        let request = RSVPRequest(
            status: "maybe",
            isDriver: nil,
            needsRide: nil,
            pickupLocation: nil
        )

        // When
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertEqual(dict?["status"] as? String, "maybe")
    }

    // MARK: - Response Parsing Tests

    func testEventsListResponse_Parsing() throws {
        // Given
        let json = """
        {
            "events": [
                {
                    "id": "event-1",
                    "creatorId": "user-1",
                    "mountainId": "baker",
                    "mountainName": "Mt. Baker",
                    "title": "Powder Day",
                    "notes": null,
                    "eventDate": "2025-03-15",
                    "departureTime": "06:00:00",
                    "departureLocation": null,
                    "skillLevel": "intermediate",
                    "carpoolAvailable": true,
                    "carpoolSeats": 4,
                    "status": "active",
                    "createdAt": "2025-01-01T00:00:00Z",
                    "updatedAt": "2025-01-01T00:00:00Z",
                    "attendeeCount": 5,
                    "goingCount": 4,
                    "maybeCount": 1,
                    "creator": {
                        "id": "user-1",
                        "username": "skiking",
                        "display_name": "Ski King",
                        "avatar_url": null
                    },
                    "userRSVPStatus": "going",
                    "isCreator": false
                }
            ],
            "pagination": {
                "total": 1,
                "limit": 20,
                "offset": 0,
                "hasMore": false
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(EventsListResponse.self, from: data)

        // Then
        XCTAssertEqual(response.events.count, 1)
        XCTAssertEqual(response.events[0].id, "event-1")
        XCTAssertEqual(response.events[0].title, "Powder Day")
        XCTAssertEqual(response.pagination.total, 1)
        XCTAssertFalse(response.pagination.hasMore)
    }

    func testRSVPResponse_Parsing() throws {
        // Given
        let json = """
        {
            "attendee": {
                "id": "att-123",
                "userId": "user-456",
                "status": "going",
                "isDriver": true,
                "needsRide": false,
                "pickupLocation": null,
                "respondedAt": "2025-01-15T10:30:00Z",
                "user": {
                    "id": "user-456",
                    "username": "snowlover",
                    "display_name": "Snow Lover",
                    "avatar_url": null
                }
            },
            "event": {
                "id": "event-789",
                "goingCount": 5,
                "maybeCount": 2,
                "attendeeCount": 7
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(RSVPResponse.self, from: data)

        // Then
        XCTAssertEqual(response.attendee.id, "att-123")
        XCTAssertEqual(response.attendee.status, .going)
        XCTAssertTrue(response.attendee.isDriver)
        XCTAssertEqual(response.event.goingCount, 5)
        XCTAssertEqual(response.event.attendeeCount, 7)
    }

    func testInviteResponse_Parsing() throws {
        // Given
        let json = """
        {
            "invite": {
                "event": {
                    "id": "event-1",
                    "creatorId": "user-1",
                    "mountainId": "crystal",
                    "mountainName": "Crystal Mountain",
                    "title": "Weekend Trip",
                    "notes": "Bring lunch",
                    "eventDate": "2025-03-22",
                    "departureTime": "07:00:00",
                    "departureLocation": "Tacoma",
                    "skillLevel": "advanced",
                    "carpoolAvailable": true,
                    "carpoolSeats": 3,
                    "status": "active",
                    "createdAt": "2025-01-10T00:00:00Z",
                    "updatedAt": "2025-01-10T00:00:00Z",
                    "attendeeCount": 4,
                    "goingCount": 3,
                    "maybeCount": 1,
                    "creator": {
                        "id": "user-1",
                        "username": "organizer",
                        "display_name": "Event Organizer",
                        "avatar_url": null
                    },
                    "userRSVPStatus": null,
                    "isCreator": false
                },
                "conditions": {
                    "temperature": 30,
                    "snowfall24h": 4,
                    "snowDepth": 95,
                    "powderScore": 6.5,
                    "forecast": {
                        "high": 34,
                        "low": 26,
                        "snowfall": 3,
                        "conditions": "Partly Cloudy"
                    }
                },
                "isValid": true,
                "isExpired": false,
                "requiresAuth": true
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(InviteResponse.self, from: data)

        // Then
        XCTAssertTrue(response.invite.isValid)
        XCTAssertFalse(response.invite.isExpired)
        XCTAssertTrue(response.invite.requiresAuth)
        XCTAssertEqual(response.invite.event.title, "Weekend Trip")
        XCTAssertNotNil(response.invite.conditions)
        XCTAssertEqual(response.invite.conditions?.powderScore, 6.5)
    }

    // MARK: - Date Formatting Tests

    func testDateFormatting_EventDate() {
        // Given
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // When
        let date = Date()
        let formatted = formatter.string(from: date)

        // Then
        XCTAssertTrue(formatted.matches(pattern: "\\d{4}-\\d{2}-\\d{2}"))
    }

    func testTimeFormatting_DepartureTime() {
        // Given
        let validTimes = ["06:00:00", "12:30:00", "18:45:00", "00:00:00", "23:59:59"]

        // Then
        for time in validTimes {
            XCTAssertTrue(time.matches(pattern: "\\d{2}:\\d{2}:\\d{2}"), "Time \(time) should be valid")
        }
    }

    // MARK: - Pagination Tests

    func testPagination_HasMore() {
        // Given
        let paginationWithMore = EventPagination(total: 50, limit: 20, offset: 0, hasMore: true)
        let paginationNoMore = EventPagination(total: 15, limit: 20, offset: 0, hasMore: false)

        // Then
        XCTAssertTrue(paginationWithMore.hasMore)
        XCTAssertFalse(paginationNoMore.hasMore)
    }

    func testPagination_OffsetCalculation() {
        // Given
        let page1 = EventPagination(total: 50, limit: 20, offset: 0, hasMore: true)
        let page2 = EventPagination(total: 50, limit: 20, offset: 20, hasMore: true)
        let page3 = EventPagination(total: 50, limit: 20, offset: 40, hasMore: false)

        // Then
        XCTAssertEqual(page1.offset, 0)
        XCTAssertEqual(page2.offset, 20)
        XCTAssertEqual(page3.offset, 40)
        XCTAssertFalse(page3.hasMore)
    }

    // MARK: - EventService Singleton Tests

    @MainActor
    func testEventService_SharedInstance() {
        // Given/When
        let instance1 = EventService.shared
        let instance2 = EventService.shared

        // Then
        XCTAssertTrue(instance1 === instance2, "Should return same instance")
    }
}

// MARK: - Test Helpers

extension String {
    func matches(pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(self.startIndex..., in: self)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
}
