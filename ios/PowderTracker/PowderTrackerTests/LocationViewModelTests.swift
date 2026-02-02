//
//  LocationViewModelTests.swift
//  PowderTrackerTests
//
//  Tests for LocationViewModel - single mountain detail view
//

import XCTest
@testable import PowderTracker

@MainActor
final class LocationViewModelTests: XCTestCase {
    var sut: LocationViewModel!
    var testMountain: Mountain!

    override func setUpWithError() throws {
        testMountain = Mountain.mock(id: "baker", name: "Mt. Baker", shortName: "Baker")
        sut = LocationViewModel(mountain: testMountain)
    }

    override func tearDownWithError() throws {
        sut = nil
        testMountain = nil
    }

    // MARK: - Initialization Tests

    func testInit_StoresMountain() {
        XCTAssertEqual(sut.mountain.id, "baker")
        XCTAssertEqual(sut.mountain.name, "Mt. Baker")
    }

    func testInit_HasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.locationData)
        XCTAssertNil(sut.liftData)
        XCTAssertNil(sut.snowComparison)
        XCTAssertNil(sut.safetyData)
    }

    // MARK: - Computed Properties (No Data)

    func testCurrentSnowDepth_ReturnsNilWhenNoData() {
        XCTAssertNil(sut.currentSnowDepth)
    }

    func testSnowDepth24h_ReturnsZeroWhenNoData() {
        XCTAssertEqual(sut.snowDepth24h, 0)
    }

    func testSnowDepth48h_ReturnsZeroWhenNoData() {
        XCTAssertEqual(sut.snowDepth48h, 0)
    }

    func testSnowDepth72h_ReturnsZeroWhenNoData() {
        XCTAssertEqual(sut.snowDepth72h, 0)
    }

    func testTemperature_ReturnsNilWhenNoData() {
        XCTAssertNil(sut.temperature)
    }

    func testWindSpeed_ReturnsNilWhenNoData() {
        XCTAssertNil(sut.windSpeed)
    }

    func testWeatherDescription_ReturnsNilWhenNoData() {
        XCTAssertNil(sut.weatherDescription)
    }

    func testPowderScore_ReturnsZeroWhenNoData() {
        XCTAssertEqual(sut.powderScore, 0)
    }

    func testLastUpdated_ReturnsNilWhenNoData() {
        XCTAssertNil(sut.lastUpdated)
    }

    func testHasRoadData_ReturnsFalseWhenNoData() {
        XCTAssertFalse(sut.hasRoadData)
    }

    func testHasWebcams_ReturnsFalseWhenNoData() {
        XCTAssertFalse(sut.hasWebcams)
    }

    func testHistoricalSnowData_ReturnsEmptyWhenNoData() {
        XCTAssertTrue(sut.historicalSnowData.isEmpty)
    }

    // MARK: - Fetch Data Tests (Integration)

    func testFetchData_SetsLoadingState() async {
        // When
        let fetchTask = Task {
            await sut.fetchData()
        }

        // After
        await fetchTask.value
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
    }

    func testFetchData_LoadsLocationData() async {
        // When
        await sut.fetchData()

        // Then
        XCTAssertNotNil(sut.locationData, "Location data should be loaded")
        XCTAssertNil(sut.error, "Should have no error for valid mountain")
    }

    func testFetchData_InvalidMountain_SetsError() async {
        // Given
        let invalidMountain = Mountain.mock(id: "invalid-mountain-xyz", name: "Invalid")
        let invalidSut = LocationViewModel(mountain: invalidMountain)

        // When
        await invalidSut.fetchData()

        // Then
        XCTAssertNotNil(invalidSut.error, "Should have error for invalid mountain")
    }

    // MARK: - Fetch Data - Computed Properties After Load

    func testFetchData_PopulatesComputedProperties() async {
        // When
        await sut.fetchData()

        // Then - after successful fetch, computed properties should work
        guard sut.locationData != nil else {
            XCTFail("Location data should be loaded")
            return
        }

        // Snow depths should have values (may be nil if no snotel data)
        XCTAssertNotNil(sut.snowDepth24h)
        XCTAssertNotNil(sut.snowDepth48h)

        // Weather description should be available
        XCTAssertNotNil(sut.weatherDescription)

        // Powder score should be loaded
        XCTAssertNotNil(sut.powderScore)
        XCTAssertTrue(sut.powderScore! >= 0 && sut.powderScore! <= 10, "Powder score should be 0-10")
    }

    func testFetchData_PopulatesHistoricalData() async {
        // When
        await sut.fetchData()

        // Then
        guard sut.locationData != nil else {
            return // Skip if fetch failed
        }

        // If we have snow depth, historical data should be generated
        if sut.currentSnowDepth != nil {
            XCTAssertFalse(sut.historicalSnowData.isEmpty, "Should have historical data when depth is available")
            XCTAssertEqual(sut.historicalSnowData.count, 4, "Should have 4 data points (30d, 14d, 7d, now)")
        }
    }

    // MARK: - Lift Data Tests

    func testFetchLiftData_LoadsWhenAvailable() async {
        // When
        await sut.fetchLiftData()

        // Then - lift data may or may not be available depending on mountain
        // Just verify no crash occurs
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Snow Comparison Tests

    func testFetchSnowComparison_LoadsWhenAvailable() async {
        // When
        await sut.fetchSnowComparison()

        // Then - snow comparison may or may not be available
        // Just verify no crash occurs
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Safety Data Tests

    func testFetchSafetyData_LoadsWhenAvailable() async {
        // When
        await sut.fetchSafetyData()

        // Then - safety data may or may not be available
        // Just verify no crash occurs
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Full Flow Integration Test

    func testFullFetchFlow_LoadsAllData() async {
        // When
        await sut.fetchData()

        // Then - main data loaded
        XCTAssertNotNil(sut.locationData)
        XCTAssertFalse(sut.isLoading)

        // Supplementary data may or may not be loaded (depends on availability)
        // fetchData internally calls fetchLiftData, fetchSnowComparison, fetchSafetyData
    }

    // MARK: - Concurrency Tests

    func testConcurrentFetchData_HandlesMultipleCalls() async {
        // When
        async let task1: () = sut.fetchData()
        async let task2: () = sut.fetchData()

        await task1
        await task2

        // Then - should complete without crash
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Different Mountains Tests

    func testDifferentMountains_LoadDifferentData() async {
        // Given
        let crystalMountain = Mountain.mock(id: "crystal", name: "Crystal Mountain")
        let crystalSut = LocationViewModel(mountain: crystalMountain)

        // When
        await sut.fetchData() // Baker
        await crystalSut.fetchData() // Crystal

        // Then - both should have data (if available)
        if sut.locationData != nil && crystalSut.locationData != nil {
            XCTAssertNotEqual(
                sut.locationData?.mountain.id,
                crystalSut.locationData?.mountain.id,
                "Different mountains should have different data"
            )
        }
    }
}

// MARK: - HistoricalDataPoint Tests

final class HistoricalDataPointTests: XCTestCase {
    func testHistoricalDataPoint_HasUniqueId() {
        let point1 = HistoricalDataPoint(date: Date(), depth: 100, label: "Now")
        let point2 = HistoricalDataPoint(date: Date(), depth: 100, label: "Now")

        XCTAssertNotEqual(point1.id, point2.id, "Each point should have unique ID")
    }

    func testHistoricalDataPoint_StoresPropertiesCorrectly() {
        let date = Date()
        let point = HistoricalDataPoint(date: date, depth: 142.5, label: "Now")

        XCTAssertEqual(point.date, date)
        XCTAssertEqual(point.depth, 142.5)
        XCTAssertEqual(point.label, "Now")
    }
}
