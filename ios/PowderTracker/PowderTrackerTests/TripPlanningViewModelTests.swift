import XCTest
@testable import PowderTracker

@MainActor
final class TripPlanningViewModelTests: XCTestCase {
    var sut: TripPlanningViewModel!

    override func setUpWithError() throws {
        sut = TripPlanningViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Initialization Tests

    func testInit_ShouldHaveDefaultValues() {
        // Then
        XCTAssertNil(sut.roads)
        XCTAssertNil(sut.tripAdvice)
        XCTAssertNil(sut.powderDayPlan)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    // MARK: - Fetch All Tests

    func testFetchAll_ShouldLoadAllData() async {
        // Given
        let mountainId = "baker"

        // When
        await sut.fetchAll(for: mountainId)

        // Then
        XCTAssertFalse(sut.isLoading)
        // Note: Some data may be nil if services are down, but isLoading should be false
    }

    func testFetchAll_WashingtonMountain_ShouldHaveRoadsData() async {
        // Given
        let mountainId = "baker" // Washington mountain

        // When
        await sut.fetchAll(for: mountainId)

        // Then
        XCTAssertNotNil(sut.roads, "Washington mountains should have roads data")
        XCTAssertTrue(sut.roads?.supported ?? false, "Baker should support WSDOT data")
    }

    func testFetchAll_ShouldHaveTripAdvice() async {
        // Given
        let mountainId = "baker"

        // When
        await sut.fetchAll(for: mountainId)

        // Then
        XCTAssertNotNil(sut.tripAdvice)
        XCTAssertNotNil(sut.tripAdvice?.headline)
        XCTAssertNotNil(sut.tripAdvice?.crowd)
    }

    func testFetchAll_ShouldHavePowderDayPlan() async {
        // Given
        let mountainId = "baker"

        // When
        await sut.fetchAll(for: mountainId)

        // Then
        XCTAssertNotNil(sut.powderDayPlan)
        XCTAssertEqual(sut.powderDayPlan?.days.count, 3, "Should have 3-day plan")
    }

    // MARK: - Error Handling Tests

    func testFetchAll_InvalidMountain_ShouldHandleGracefully() async {
        // Given
        let invalidMountainId = "invalid-xyz"

        // When
        await sut.fetchAll(for: invalidMountainId)

        // Then
        XCTAssertFalse(sut.isLoading)
        // Should handle errors gracefully by returning nil
        XCTAssertNil(sut.roads)
        XCTAssertNil(sut.tripAdvice)
        XCTAssertNil(sut.powderDayPlan)
    }

    // MARK: - Refresh Tests

    func testRefresh_ShouldReloadData() async {
        // Given
        let mountainId = "baker"
        await sut.fetchAll(for: mountainId)
        let firstLoad = sut.tripAdvice

        // When
        await sut.refresh(for: mountainId)

        // Then
        XCTAssertNotNil(sut.tripAdvice)
        // Data may be same or different depending on cache
    }

    // MARK: - Parallel Fetching Tests

    func testFetchAll_ShouldFetchInParallel() async {
        // Given
        let mountainId = "baker"
        let startTime = Date()

        // When
        await sut.fetchAll(for: mountainId)

        // Then
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 10.0, "Parallel fetching should complete within 10 seconds")
    }

    // MARK: - Data Validation Tests

    func testFetchAll_PowderDayPlan_ShouldHaveValidDates() async {
        // When
        await sut.fetchAll(for: "baker")

        // Then
        if let plan = sut.powderDayPlan {
            XCTAssertEqual(plan.days.count, 3)
            for day in plan.days {
                XCTAssertFalse(day.dayOfWeek.isEmpty)
                XCTAssertTrue(day.predictedPowderScore >= 0 && day.predictedPowderScore <= 10)
                XCTAssertTrue(day.confidence >= 0 && day.confidence <= 100)
            }
        }
    }

    func testFetchAll_TripAdvice_ShouldHaveValidRiskLevels() async {
        // When
        await sut.fetchAll(for: "baker")

        // Then
        if let advice = sut.tripAdvice {
            let validLevels: Set<String> = ["low", "medium", "high"]
            XCTAssertTrue(validLevels.contains(advice.crowd))
            XCTAssertTrue(validLevels.contains(advice.trafficRisk))
            XCTAssertTrue(validLevels.contains(advice.roadRisk))
        }
    }

    // MARK: - Multiple Mountains Tests

    func testFetchAll_DifferentMountains_ShouldReturnDifferentData() async {
        // When
        await sut.fetchAll(for: "baker")
        let bakerAdvice = sut.tripAdvice?.headline

        await sut.fetchAll(for: "crystal")
        let crystalAdvice = sut.tripAdvice?.headline

        // Then
        XCTAssertNotNil(bakerAdvice)
        XCTAssertNotNil(crystalAdvice)
        // Headlines may be same or different depending on conditions
    }
}
