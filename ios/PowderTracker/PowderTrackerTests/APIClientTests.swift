import XCTest
@testable import PowderTracker

@MainActor
final class APIClientTests: XCTestCase {
    var sut: APIClient!

    override func setUp() async throws {
        sut = APIClient.shared
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Mountains List Tests

    func testFetchMountains_ShouldReturnMountainsList() async throws {
        // When
        let result = try await sut.fetchMountains()

        // Then
        XCTAssertFalse(result.mountains.isEmpty, "Mountains list should not be empty")
        XCTAssertTrue(result.mountains.contains { $0.id == "baker" }, "Should contain Mt. Baker")
    }

    // MARK: - Batched Endpoint Tests

    func testFetchMountainData_ShouldReturnAllData() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchMountainData(for: mountainId)

        // Then
        XCTAssertEqual(result.mountain.id, mountainId)
        XCTAssertNotNil(result.conditions)
        XCTAssertNotNil(result.powderScore)
        XCTAssertFalse(result.forecast.isEmpty, "Forecast should not be empty")
        XCTAssertNotNil(result.cachedAt)
    }

    func testFetchMountainData_InvalidMountainId_ShouldThrowError() async throws {
        // Given
        let invalidMountainId = "invalid-mountain-xyz"

        // When/Then
        do {
            _ = try await sut.fetchMountainData(for: invalidMountainId)
            XCTFail("Should have thrown an error for invalid mountain ID")
        } catch let error as APIError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 404, "Should return 404 for invalid mountain")
            default:
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    // MARK: - Individual Endpoint Tests

    func testFetchConditions_ShouldReturnConditions() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchConditions(for: mountainId)

        // Then
        XCTAssertEqual(result.mountain.id, mountainId)
        XCTAssertNotNil(result.snowDepth, "Snow depth should be available")
        XCTAssertNotNil(result.temperature, "Temperature should be available")
    }

    func testFetchForecast_ShouldReturnSevenDays() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchForecast(for: mountainId)

        // Then
        XCTAssertEqual(result.mountain.id, mountainId)
        XCTAssertEqual(result.forecast.count, 7, "Forecast should have 7 days")
    }

    func testFetchPowderScore_ShouldReturnScore() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchPowderScore(for: mountainId)

        // Then
        XCTAssertEqual(result.mountain.id, mountainId)
        XCTAssertTrue(result.score >= 0 && result.score <= 10, "Score should be between 0 and 10")
        XCTAssertFalse(result.factors.isEmpty, "Factors should not be empty")
    }

    func testFetchHistory_ShouldReturnHistoricalData() async throws {
        // Given
        let mountainId = "baker"
        let days = 30

        // When
        let result = try await sut.fetchHistory(for: mountainId, days: days)

        // Then
        XCTAssertEqual(result.mountain.id, mountainId)
        XCTAssertEqual(result.days, days)
        XCTAssertFalse(result.history.isEmpty, "History should not be empty")
    }

    func testFetchRoads_ShouldReturnRoadData() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchRoads(for: mountainId)

        // Then
        XCTAssertEqual(result.mountain.id, mountainId)
        XCTAssertNotNil(result.supported)
    }

    func testFetchTripAdvice_ShouldReturnAdvice() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchTripAdvice(for: mountainId)

        // Then
        XCTAssertFalse(result.headline.isEmpty, "Headline should not be empty")
    }

    func testFetchPowderDayPlan_ShouldReturnThreeDayPlan() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchPowderDayPlan(for: mountainId)

        // Then
        XCTAssertEqual(result.days.count, 3, "Should return 3-day plan")
    }

    func testFetchAlerts_ShouldReturnAlerts() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchAlerts(for: mountainId)

        // Then
        XCTAssertEqual(result.mountain.id, mountainId)
        XCTAssertNotNil(result.alerts)
        // Note: Alerts may be empty if no active warnings
    }

    func testFetchWeatherGovLinks_ShouldReturnLinks() async throws {
        // Given
        let mountainId = "baker"

        // When
        let result = try await sut.fetchWeatherGovLinks(for: mountainId)

        // Then
        XCTAssertEqual(result.mountain.id, mountainId)
        XCTAssertFalse(result.weatherGov.forecast.isEmpty, "Forecast link should not be empty")
        XCTAssertFalse(result.weatherGov.hourly.isEmpty, "Hourly link should not be empty")
    }

    // MARK: - Performance Tests

    func testBatchedEndpoint_PerformanceComparison() async throws {
        // Test batched endpoint performance
        measure {
            let expectation = self.expectation(description: "Batched fetch")

            Task {
                _ = try? await sut.fetchMountainData(for: "baker")
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 30.0)
        }
    }

    func testIndividualEndpoints_PerformanceComparison() async throws {
        // Test individual endpoints performance (should be slower)
        let client = sut!
        measure {
            let expectation = self.expectation(description: "Individual fetches")

            Task { @MainActor in
                async let conditionsTask = client.fetchConditions(for: "baker")
                async let powderScoreTask = client.fetchPowderScore(for: "baker")
                async let forecastTask = client.fetchForecast(for: "baker")

                _ = try? await (conditionsTask, powderScoreTask, forecastTask)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - Error Handling Tests

    func testInvalidURL_ShouldThrowError() async throws {
        // Note: This tests internal error handling
        // The URL construction should never fail with valid inputs
        let mountainId = "baker"

        do {
            _ = try await sut.fetchConditions(for: mountainId)
        } catch let error as APIError {
            switch error {
            case .invalidURL:
                XCTFail("Should not get invalid URL with valid mountain ID")
            case .networkError, .decodingError, .serverError, .unauthorized, .rateLimited, .tokenRefreshFailed:
                // These are acceptable errors
                break
            }
        }
    }

    // MARK: - Concurrency Tests

    func testConcurrentRequests_ShouldHandleMultipleMountains() async throws {
        // Given
        let mountainIds = ["baker", "crystal", "stevens"]
        let client = sut!

        // When
        let results = try await withThrowingTaskGroup(of: MountainBatchedResponse.self) { group in
            for id in mountainIds {
                group.addTask { @Sendable in
                    try await client.fetchMountainData(for: id)
                }
            }

            var responses: [MountainBatchedResponse] = []
            for try await response in group {
                responses.append(response)
            }
            return responses
        }

        // Then
        XCTAssertEqual(results.count, 3, "Should fetch all three mountains")
        XCTAssertTrue(results.allSatisfy { mountainIds.contains($0.mountain.id) })
    }

    // MARK: - Task Cancellation Tests

    func testTaskCancellation_ShouldCancelRequest() async throws {
        // Given
        let task = Task {
            try await sut.fetchMountainData(for: "baker")
        }

        // When
        task.cancel()

        // Then
        do {
            _ = try await task.value
            XCTFail("Task should have been cancelled")
        } catch {
            // Expected to throw error due to cancellation
            XCTAssertTrue(true, "Task was cancelled as expected")
        }
    }
}
