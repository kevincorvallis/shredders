//
//  DataOperationPerformanceTests.swift
//  PowderTrackerTests
//
//  Performance tests for data parsing and filtering operations.
//

import XCTest
@testable import PowderTracker

final class DataOperationPerformanceTests: XCTestCase {

    // MARK: - JSON Parsing Tests

    func testMountainJSONParsing_50() throws {
        // Generate 50 mountain JSON objects
        let mountains = generateMountainJSON(count: 50)
        let jsonData = try JSONSerialization.data(withJSONObject: mountains)

        measure(metrics: [XCTClockMetric()]) {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                _ = try decoder.decode([Mountain].self, from: jsonData)
            } catch {
                XCTFail("Failed to decode mountains: \(error)")
            }
        }
    }

    func testEventJSONParsing_100() throws {
        // Generate 100 event objects with nested attendees
        let events = generateEventJSON(count: 100, attendeesPerEvent: 5)
        let jsonData = try JSONSerialization.data(withJSONObject: events)

        measure(metrics: [XCTClockMetric()]) {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                _ = try decoder.decode([Event].self, from: jsonData)
            } catch {
                XCTFail("Failed to decode events: \(error)")
            }
        }
    }

    func testForecastDataParsing() throws {
        // Generate complex forecast data - 7 days with hourly data
        let forecast = generateForecastJSON(days: 7, hoursPerDay: 24)
        let jsonData = try JSONSerialization.data(withJSONObject: forecast)

        measure(metrics: [XCTClockMetric()]) {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                _ = try decoder.decode([ForecastDay].self, from: jsonData)
            } catch {
                XCTFail("Failed to decode forecast: \(error)")
            }
        }
    }

    // MARK: - Filter Performance Tests

    func testFavoritesFilterPerformance() throws {
        // Create 200 mountains, 50 marked as favorite
        let mountains = (0..<200).map { i in
            Mountain.mock(id: UUID(), name: "Mountain \(i)", isFavorite: i < 50)
        }

        measure(metrics: [XCTClockMetric()]) {
            let _ = mountains.filter { $0.isFavorite }
        }
    }

    func testPassTypeFilterPerformance() throws {
        // Create 200 mountains with mixed pass types
        let mountains = (0..<200).map { i in
            let passType: Mountain.PassType
            switch i % 3 {
            case 0: passType = .epic
            case 1: passType = .ikon
            default: passType = .none
            }
            return Mountain.mock(id: UUID(), name: "Mountain \(i)", passType: passType)
        }

        measure(metrics: [XCTClockMetric()]) {
            let _ = mountains.filter { $0.passType == .epic }
        }
    }

    // MARK: - Sort Performance Tests

    func testSortByPowderScorePerformance() throws {
        // Create 200 mountains with random powder scores
        let mountains = (0..<200).map { i in
            Mountain.mock(id: UUID(), name: "Mountain \(i)", powderScore: Int.random(in: 0...100))
        }

        measure(metrics: [XCTClockMetric()]) {
            let _ = mountains.sorted { $0.powderScore > $1.powderScore }
        }
    }

    func testSortByNamePerformance() throws {
        // Create 200 mountains
        let mountains = (0..<200).map { i in
            Mountain.mock(id: UUID(), name: "Mountain \(200 - i)")
        }

        measure(metrics: [XCTClockMetric()]) {
            let _ = mountains.sorted { $0.name < $1.name }
        }
    }

    // MARK: - Combined Filter and Sort

    func testCombinedFilterAndSort() throws {
        // Real-world scenario: filter by pass type, then sort by powder score
        let mountains = (0..<200).map { i in
            let passType: Mountain.PassType = i % 2 == 0 ? .epic : .ikon
            return Mountain.mock(
                id: UUID(),
                name: "Mountain \(i)",
                powderScore: Int.random(in: 0...100),
                passType: passType
            )
        }

        measure(metrics: [XCTClockMetric()]) {
            let _ = mountains
                .filter { $0.passType == .epic }
                .sorted { $0.powderScore > $1.powderScore }
        }
    }

    // MARK: - Search Performance

    func testSearchPerformance() throws {
        let mountains = (0..<200).map { i in
            Mountain.mock(id: UUID(), name: "Mountain \(i) Resort")
        }

        let searchTerm = "50"

        measure(metrics: [XCTClockMetric()]) {
            let _ = mountains.filter {
                $0.name.localizedCaseInsensitiveContains(searchTerm)
            }
        }
    }

    // MARK: - Event Filtering

    func testUpcomingEventsFilter() throws {
        let now = Date()
        let events = (0..<100).map { i in
            let date = i < 50
                ? now.addingTimeInterval(Double(i) * 86400)   // Future
                : now.addingTimeInterval(-Double(i) * 86400) // Past
            return Event.mock(id: UUID(), title: "Event \(i)", date: date)
        }

        measure(metrics: [XCTClockMetric()]) {
            let _ = events.filter { $0.date > now }
        }
    }

    func testEventsWithCapacityFilter() throws {
        let events = (0..<100).map { i in
            Event.mock(
                id: UUID(),
                title: "Event \(i)",
                attendeeCount: i % 10,
                maxCapacity: i % 2 == 0 ? 10 : nil
            )
        }

        measure(metrics: [XCTClockMetric()]) {
            let _ = events.filter { event in
                guard let max = event.maxCapacity else { return true }
                return event.attendeeCount < max
            }
        }
    }

    // MARK: - Helper Functions

    private func generateMountainJSON(count: Int) -> [[String: Any]] {
        (0..<count).map { i in
            [
                "id": UUID().uuidString,
                "name": "Mountain \(i)",
                "powder_score": Int.random(in: 0...100),
                "is_favorite": i % 5 == 0,
                "pass_type": ["epic", "ikon", "none"][i % 3],
                "region": "West",
                "latitude": 39.0 + Double(i) * 0.1,
                "longitude": -105.0 + Double(i) * 0.1,
                "vertical_feet": 3000 + i * 10,
                "base_elevation": 8000 + i * 5,
                "summit_elevation": 11000 + i * 15,
                "acres": 1000 + i * 20,
                "annual_snowfall": 300 + i
            ]
        }
    }

    private func generateEventJSON(count: Int, attendeesPerEvent: Int) -> [[String: Any]] {
        (0..<count).map { i in
            [
                "id": UUID().uuidString,
                "title": "Event \(i)",
                "description": "Description for event \(i)",
                "date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(i) * 86400)),
                "mountain_id": UUID().uuidString,
                "creator_id": UUID().uuidString,
                "attendee_count": attendeesPerEvent,
                "max_capacity": 20,
                "rsvp_status": ["going", "maybe", "not_going", nil][i % 4] as Any,
                "attendees": (0..<attendeesPerEvent).map { j in
                    [
                        "id": UUID().uuidString,
                        "display_name": "User \(j)",
                        "avatar_url": "https://example.com/avatar/\(j).jpg"
                    ]
                }
            ]
        }
    }

    private func generateForecastJSON(days: Int, hoursPerDay: Int) -> [[String: Any]] {
        (0..<days).map { day in
            [
                "date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(day) * 86400)),
                "snowfall_inches": Double.random(in: 0...12),
                "high_temp": Int.random(in: 20...45),
                "low_temp": Int.random(in: 5...30),
                "conditions": ["Sunny", "Cloudy", "Snow", "Mixed"][day % 4],
                "wind_speed": Int.random(in: 0...30),
                "hourly": (0..<hoursPerDay).map { hour in
                    [
                        "hour": hour,
                        "temp": Int.random(in: 10...40),
                        "snow_chance": Int.random(in: 0...100),
                        "wind": Int.random(in: 0...25)
                    ]
                }
            ]
        }
    }
}
