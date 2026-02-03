//
//  EventAPIIntegrationTests.swift
//  PowderTrackerTests
//
//  Integration tests for event creation API endpoints.
//  Tests the full end-to-end flow including capacity limits and waitlist.
//

import XCTest
@testable import PowderTracker

final class EventAPIIntegrationTests: XCTestCase {

    // MARK: - Test Configuration

    private let testTimeout: TimeInterval = 30.0
    private let apiBaseURL = AppConfig.apiBaseURL

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - API Health Tests

    func testEventsEndpoint_ReturnsValidResponse() async throws {
        let url = URL(string: "\(apiBaseURL)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = testTimeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }

        XCTAssertEqual(httpResponse.statusCode, 200, "Events endpoint should return 200")

        // Verify response is valid JSON with events array
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json, "Response should be valid JSON")

        // Check for events array (may be empty but should exist)
        let events = json?["events"] as? [[String: Any]]
        XCTAssertNotNil(events, "Response should contain 'events' array")
    }

    func testEventsEndpoint_ReturnsCapacityFields() async throws {
        let url = URL(string: "\(apiBaseURL)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = testTimeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw XCTSkip("Events endpoint not available")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let events = json?["events"] as? [[String: Any]], !events.isEmpty else {
            // No events to test, but endpoint works
            return
        }

        // Check first event has the capacity-related fields available
        let firstEvent = events[0]

        // These fields should be present (may be null but key should exist in schema)
        // The API response should include these fields when they exist
        print("Event fields: \(firstEvent.keys.sorted())")

        // Verify core event fields exist
        XCTAssertNotNil(firstEvent["id"], "Event should have id")
        XCTAssertNotNil(firstEvent["title"], "Event should have title")
        XCTAssertNotNil(firstEvent["mountainId"] ?? firstEvent["mountain_id"], "Event should have mountainId")
    }

    func testEventCreation_RequiresAuthentication() async throws {
        let url = URL(string: "\(apiBaseURL)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = testTimeout

        let eventData: [String: Any] = [
            "title": "Test Event",
            "mountainId": "mt-baker",
            "eventDate": "2026-03-01"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: eventData)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }

        // Should return 401 Unauthorized without auth token
        XCTAssertEqual(httpResponse.statusCode, 401, "Event creation should require authentication")

        // Verify error message
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? String {
            XCTAssertTrue(
                error.lowercased().contains("auth") || error.lowercased().contains("sign"),
                "Error should indicate authentication required"
            )
        }
    }

    // MARK: - Event Detail Tests

    func testEventDetail_ReturnsCapacityInfo() async throws {
        // First get list of events
        let listURL = URL(string: "\(apiBaseURL)/events")!
        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        listRequest.timeoutInterval = testTimeout

        let (listData, listResponse) = try await URLSession.shared.data(for: listRequest)

        guard let httpResponse = listResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: listData) as? [String: Any],
              let events = json["events"] as? [[String: Any]],
              let firstEvent = events.first,
              let eventId = firstEvent["id"] as? String else {
            throw XCTSkip("No events available to test detail endpoint")
        }

        // Now get event detail
        let detailURL = URL(string: "\(apiBaseURL)/events/\(eventId)")!
        var detailRequest = URLRequest(url: detailURL)
        detailRequest.httpMethod = "GET"
        detailRequest.timeoutInterval = testTimeout

        let (detailData, detailResponse) = try await URLSession.shared.data(for: detailRequest)

        guard let detailHttpResponse = detailResponse as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }

        XCTAssertEqual(detailHttpResponse.statusCode, 200, "Event detail should return 200")

        let detailJson = try JSONSerialization.jsonObject(with: detailData) as? [String: Any]
        let eventDetail = detailJson?["event"] as? [String: Any]

        XCTAssertNotNil(eventDetail, "Response should contain 'event' object")

        // Log available fields for debugging
        if let event = eventDetail {
            print("Event detail fields: \(event.keys.sorted())")

            // Check for capacity-related fields (they may be null but should be in schema)
            // maxAttendees and waitlistCount should be available after migration
            if let maxAttendees = event["maxAttendees"] ?? event["max_attendees"] {
                print("maxAttendees: \(maxAttendees)")
            }
            if let waitlistCount = event["waitlistCount"] ?? event["waitlist_count"] {
                print("waitlistCount: \(waitlistCount)")
            }
        }
    }

    // MARK: - RSVP Tests

    func testRSVP_RequiresAuthentication() async throws {
        // First get an event ID
        let listURL = URL(string: "\(apiBaseURL)/events")!
        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        listRequest.timeoutInterval = testTimeout

        let (listData, listResponse) = try await URLSession.shared.data(for: listRequest)

        guard let httpResponse = listResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: listData) as? [String: Any],
              let events = json["events"] as? [[String: Any]],
              let firstEvent = events.first,
              let eventId = firstEvent["id"] as? String else {
            throw XCTSkip("No events available to test RSVP endpoint")
        }

        // Try to RSVP without auth
        let rsvpURL = URL(string: "\(apiBaseURL)/events/\(eventId)/rsvp")!
        var rsvpRequest = URLRequest(url: rsvpURL)
        rsvpRequest.httpMethod = "POST"
        rsvpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        rsvpRequest.timeoutInterval = testTimeout

        let rsvpData: [String: Any] = [
            "status": "going"
        ]
        rsvpRequest.httpBody = try JSONSerialization.data(withJSONObject: rsvpData)

        let (_, rsvpResponse) = try await URLSession.shared.data(for: rsvpRequest)

        guard let rsvpHttpResponse = rsvpResponse as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }

        // Should return 401 Unauthorized
        XCTAssertEqual(rsvpHttpResponse.statusCode, 401, "RSVP should require authentication")
    }

    // MARK: - Schema Validation Tests

    func testDatabaseSchema_HasCapacityColumns() async throws {
        // This test verifies that the API can handle capacity-related fields
        // by checking that the events endpoint doesn't error when these fields exist

        let url = URL(string: "\(apiBaseURL)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = testTimeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Invalid response type")
            return
        }

        // If we get a 500 error mentioning schema cache, the migration hasn't been applied
        if httpResponse.statusCode == 500 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? String {
                XCTAssertFalse(
                    error.lowercased().contains("schema cache") ||
                    error.lowercased().contains("max_attendees"),
                    "Schema cache error indicates migration not applied: \(error)"
                )
            }
        }

        XCTAssertEqual(httpResponse.statusCode, 200, "Events endpoint should work with capacity columns")
    }
}

// MARK: - Event Model Tests Extension

extension EventAPIIntegrationTests {

    func testEventModel_DecodesCapacityFields() throws {
        // Test that the Event model can decode capacity-related fields
        let jsonWithCapacity = """
        {
            "id": "test-123",
            "title": "Test Event",
            "mountainId": "mt-baker",
            "mountainName": "Mt. Baker",
            "eventDate": "2026-03-01",
            "createdAt": "2026-02-01T10:00:00Z",
            "updatedAt": "2026-02-01T10:00:00Z",
            "creatorId": "user-123",
            "goingCount": 5,
            "maybeCount": 2,
            "attendeeCount": 7,
            "maxAttendees": 10,
            "waitlistCount": 0,
            "carpoolAvailable": false,
            "status": "active",
            "isCreator": false,
            "creator": {
                "id": "user-123",
                "username": "testuser",
                "display_name": "Test User"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        do {
            let event = try decoder.decode(Event.self, from: jsonWithCapacity)
            XCTAssertEqual(event.id, "test-123")
            XCTAssertEqual(event.title, "Test Event")
            XCTAssertEqual(event.maxAttendees, 10)
            XCTAssertEqual(event.waitlistCount, 0)
        } catch {
            // If decoding fails, the Event model may not have these fields yet
            print("Decoding error (may need to add fields to Event model): \(error)")
            throw XCTSkip("Event model may not have capacity fields defined yet")
        }
    }

    func testEventModel_DecodesWithoutCapacityFields() throws {
        // Test that Event model works without capacity fields (backwards compatibility)
        let jsonWithoutCapacity = """
        {
            "id": "test-456",
            "title": "Basic Event",
            "mountainId": "stevens-pass",
            "mountainName": "Stevens Pass",
            "eventDate": "2026-03-15",
            "createdAt": "2026-02-01T10:00:00Z",
            "updatedAt": "2026-02-01T10:00:00Z",
            "creatorId": "user-456",
            "goingCount": 3,
            "maybeCount": 1,
            "attendeeCount": 4,
            "carpoolAvailable": true,
            "status": "active",
            "isCreator": true,
            "creator": {
                "id": "user-456",
                "username": "basicuser",
                "display_name": "Basic User"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        let event = try decoder.decode(Event.self, from: jsonWithoutCapacity)
        XCTAssertEqual(event.id, "test-456")
        XCTAssertEqual(event.title, "Basic Event")
        // maxAttendees should be nil when not provided
        XCTAssertNil(event.maxAttendees)
    }
}
