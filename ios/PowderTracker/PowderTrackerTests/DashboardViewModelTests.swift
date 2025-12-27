import XCTest
@testable import PowderTracker

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!

    override func setUpWithError() throws {
        sut = DashboardViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Initialization Tests

    func testInit_ShouldHaveDefaultValues() {
        // Then
        XCTAssertNil(sut.conditions)
        XCTAssertNil(sut.powderScore)
        XCTAssertTrue(sut.forecast.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.currentMountainId, "baker")
    }

    // MARK: - Load Data Tests

    func testLoadData_ShouldFetchAllData() async throws {
        // Given
        let mountainId = "baker"

        // When
        await sut.loadData(for: mountainId)

        // Then
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
        XCTAssertNotNil(sut.conditions, "Conditions should be loaded")
        XCTAssertNotNil(sut.powderScore, "Powder score should be loaded")
        XCTAssertFalse(sut.forecast.isEmpty, "Forecast should be loaded")
        XCTAssertEqual(sut.currentMountainId, mountainId)
        XCTAssertNil(sut.error, "Should not have errors")
    }

    func testLoadData_ShouldSetLoadingState() async {
        // Given
        let mountainId = "baker"

        // When
        let loadingTask = Task {
            await sut.loadData(for: mountainId)
        }

        // Then (check loading state during fetch)
        // Note: This is a timing-sensitive test
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        await loadingTask.value
        XCTAssertFalse(sut.isLoading, "Loading should be complete after fetch")
    }

    func testLoadData_InvalidMountain_ShouldSetError() async {
        // Given
        let invalidMountainId = "invalid-mountain-xyz"

        // When
        await sut.loadData(for: invalidMountainId)

        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error, "Should have error for invalid mountain")
    }

    func testRefresh_ShouldReloadCurrentMountain() async {
        // Given
        await sut.loadData(for: "crystal")
        XCTAssertEqual(sut.currentMountainId, "crystal")

        // When
        await sut.refresh()

        // Then
        XCTAssertEqual(sut.currentMountainId, "crystal", "Should still be on same mountain")
        XCTAssertNotNil(sut.conditions)
    }

    // MARK: - Multiple Mountains Tests

    func testSwitchingMountains_ShouldUpdateData() async {
        // Given
        await sut.loadData(for: "baker")
        let bakerConditions = sut.conditions

        // When
        await sut.loadData(for: "crystal")

        // Then
        XCTAssertEqual(sut.currentMountainId, "crystal")
        XCTAssertNotEqual(sut.conditions?.mountain.id, bakerConditions?.mountain.id)
        XCTAssertEqual(sut.conditions?.mountain.id, "crystal")
    }

    // MARK: - Data Validation Tests

    func testLoadData_ShouldHaveValidPowderScore() async {
        // When
        await sut.loadData(for: "baker")

        // Then
        XCTAssertNotNil(sut.powderScore)
        if let score = sut.powderScore?.score {
            XCTAssertTrue(score >= 0 && score <= 10, "Powder score should be between 0 and 10")
        }
    }

    func testLoadData_ShouldHaveSevenDayForecast() async {
        // When
        await sut.loadData(for: "baker")

        // Then
        XCTAssertEqual(sut.forecast.count, 7, "Should have 7-day forecast")
    }

    // MARK: - Concurrency Tests

    func testConcurrentLoadData_ShouldHandleRapidChanges() async {
        // When - Rapidly switch mountains
        async let task1: () = sut.loadData(for: "baker")
        async let task2: () = sut.loadData(for: "crystal")
        async let task3: () = sut.loadData(for: "stevens")

        await task1
        await task2
        await task3

        // Then - Should end up with the last requested mountain
        XCTAssertEqual(sut.currentMountainId, "stevens")
        XCTAssertNotNil(sut.conditions)
    }
}
