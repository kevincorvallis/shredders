//
//  HomeViewModelTests.swift
//  PowderTrackerTests
//
//  Tests for HomeViewModel - replaces orphaned DashboardViewModelTests
//

import XCTest
@testable import PowderTracker

@MainActor
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!

    override func setUpWithError() throws {
        sut = HomeViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Initialization Tests

    func testInit_ShouldHaveDefaultValues() {
        XCTAssertTrue(sut.mountainData.isEmpty, "Mountain data should be empty initially")
        XCTAssertTrue(sut.mountains.isEmpty, "Mountains list should be empty initially")
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        XCTAssertNil(sut.error, "Should have no error initially")
        XCTAssertNil(sut.lastRefreshDate, "Should have no refresh date initially")
        XCTAssertTrue(sut.arrivalTimes.isEmpty, "Arrival times should be empty initially")
        XCTAssertTrue(sut.parkingPredictions.isEmpty, "Parking predictions should be empty initially")
        XCTAssertTrue(sut.failedArrivalTimeLoads.isEmpty)
        XCTAssertTrue(sut.failedParkingLoads.isEmpty)
        XCTAssertFalse(sut.isLoadingEnhancedData)
    }

    // MARK: - Data Access Tests

    func testData_ForMountainId_ReturnsNilWhenNotLoaded() {
        let result = sut.data(for: "baker")
        XCTAssertNil(result, "Should return nil when mountain data not loaded")
    }

    func testHasLiveData_ReturnsFalseWhenNotLoaded() {
        let result = sut.hasLiveData(for: "baker")
        XCTAssertFalse(result, "Should return false when mountain data not loaded")
    }

    func testGetFavoritesWithData_ReturnsEmptyWhenNoData() {
        let result = sut.getFavoritesWithData()
        XCTAssertTrue(result.isEmpty, "Should return empty when no favorites loaded")
    }

    func testGetFavoritesWithForecast_ReturnsEmptyWhenNoData() {
        let result = sut.getFavoritesWithForecast()
        XCTAssertTrue(result.isEmpty, "Should return empty when no favorites loaded")
    }

    // MARK: - Load Mountains Tests (Integration)

    func testLoadMountains_ShouldFetchMountainsList() async {
        // When
        await sut.loadMountains()

        // Then
        XCTAssertFalse(sut.mountains.isEmpty, "Mountains should be loaded")
    }

    func testLoadMountains_PopulatesMountainsById() async {
        // When
        await sut.loadMountains()

        // Then - should be able to find mountains by ID
        let bakerId = sut.mountains.first { $0.id == "baker" }
        XCTAssertNotNil(bakerId, "Should be able to find baker in loaded mountains")
    }

    // MARK: - Load Favorites Data Tests (Integration)

    func testLoadFavoritesData_SetsLoadingState() async {
        // When loading starts, isLoading should be set
        let loadTask = Task {
            await sut.loadFavoritesData()
        }

        // After completion
        await loadTask.value
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
        XCTAssertNotNil(sut.lastRefreshDate, "Should have a refresh date after loading")
    }

    func testLoadFavoritesData_LoadsDataForFavorites() async {
        // Given - need to load mountains first
        await sut.loadMountains()

        // When
        await sut.loadFavoritesData()

        // Then - should have data for favorites (depends on FavoritesService state)
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
    }

    // MARK: - Refresh Tests

    func testRefresh_LoadsBothMountainsAndFavorites() async {
        // When
        await sut.refresh()

        // Then
        XCTAssertFalse(sut.mountains.isEmpty, "Mountains should be loaded after refresh")
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
    }

    func testLoadData_CallsRefresh() async {
        // When
        await sut.loadData()

        // Then
        XCTAssertFalse(sut.mountains.isEmpty, "Should load mountains via loadData")
    }

    // MARK: - Smart Helpers Tests

    func testGetLeaveNowMountains_ReturnsEmptyWhenNoArrivalTimes() {
        let result = sut.getLeaveNowMountains()
        XCTAssertTrue(result.isEmpty, "Should return empty when no arrival times")
    }

    func testGetBestPowderToday_ReturnsNilWhenNoData() {
        let result = sut.getBestPowderToday()
        XCTAssertNil(result, "Should return nil when no mountain data")
    }

    func testGetActiveAlerts_ReturnsEmptyWhenNoData() {
        let result = sut.getActiveAlerts()
        XCTAssertTrue(result.isEmpty, "Should return empty when no mountain data")
    }

    func testGetActiveStormAlerts_ReturnsEmptyWhenNoData() {
        let result = sut.getActiveStormAlerts()
        XCTAssertTrue(result.isEmpty, "Should return empty when no mountain data")
    }

    func testGetMostSignificantStorm_ReturnsNilWhenNoAlerts() {
        let result = sut.getMostSignificantStorm()
        XCTAssertNil(result, "Should return nil when no alerts")
    }

    func testGenerateSmartSuggestion_ReturnsNilWhenNoData() {
        let result = sut.generateSmartSuggestion()
        XCTAssertNil(result, "Should return nil when no mountain data")
    }

    // MARK: - Trend Calculation Tests

    func testGetSnowTrend_ReturnsStableWhenNoData() {
        let result = sut.getSnowTrend(for: "baker")
        XCTAssertEqual(result, .stable, "Should return stable when no data")
    }

    func testGetComparisonToBest_ReturnsNilWhenSameMountain() {
        let result = sut.getComparisonToBest(mountainId: "baker", bestMountainId: "baker")
        XCTAssertNil(result, "Should return nil when comparing same mountain")
    }

    func testGetComparisonToBest_ReturnsNilWhenNoData() {
        let result = sut.getComparisonToBest(mountainId: "baker", bestMountainId: "crystal")
        XCTAssertNil(result, "Should return nil when no mountain data")
    }

    func testGetWhyBestReasons_ReturnsEmptyWhenNoData() {
        let result = sut.getWhyBestReasons(for: "baker")
        XCTAssertTrue(result.isEmpty, "Should return empty when no data")
    }

    // MARK: - Webcam Helpers Tests

    func testGetAllFavoriteWebcams_ReturnsEmptyWhenNoData() {
        let result = sut.getAllFavoriteWebcams()
        XCTAssertTrue(result.isEmpty, "Should return empty when no mountain data")
    }

    func testGetPickReasons_ReturnsEmptyWhenNoData() {
        let result = sut.getPickReasons(for: "baker")
        XCTAssertTrue(result.isEmpty, "Should return empty when no data")
    }

    // MARK: - Enhanced Data Loading Tests

    func testLoadEnhancedData_SetsLoadingState() async {
        // When
        let loadTask = Task {
            await sut.loadEnhancedData()
        }

        // After
        await loadTask.value
        XCTAssertFalse(sut.isLoadingEnhancedData, "Enhanced data loading should complete")
    }

    func testRetryEnhancedData_DoesNothingWhenNoFailedLoads() async {
        // Given - no failed loads
        XCTAssertTrue(sut.failedArrivalTimeLoads.isEmpty)
        XCTAssertTrue(sut.failedParkingLoads.isEmpty)

        // When
        await sut.retryEnhancedData(for: "baker")

        // Then - no crash, state unchanged
        XCTAssertTrue(sut.failedArrivalTimeLoads.isEmpty)
    }

    // MARK: - Favorite Mountains Tests

    func testGetFavoriteMountains_ReturnsEmptyWhenNoData() {
        let result = sut.getFavoriteMountains()
        XCTAssertTrue(result.isEmpty, "Should return empty when no data loaded")
    }

    // MARK: - Integration Tests

    func testFullDataLoad_LoadsAllRequiredData() async {
        // When - full data load flow
        await sut.loadData()

        // Then
        XCTAssertFalse(sut.mountains.isEmpty, "Mountains should be loaded")
        XCTAssertNil(sut.error, "Should have no errors")
        XCTAssertFalse(sut.isLoading, "Should not be loading")
    }

    // MARK: - Concurrency Tests

    func testConcurrentRefresh_HandlesMultipleCalls() async {
        // When - multiple concurrent refreshes
        async let task1: () = sut.refresh()
        async let task2: () = sut.refresh()

        await task1
        await task2

        // Then - should complete without crashes
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
    }
}

// MARK: - PickReason Tests

final class PickReasonTests: XCTestCase {
    func testPickReason_HasUniqueId() {
        let reason1 = PickReason(icon: "snowflake", text: "Fresh snow")
        let reason2 = PickReason(icon: "snowflake", text: "Fresh snow")

        XCTAssertNotEqual(reason1.id, reason2.id, "Each PickReason should have unique ID")
    }

    func testPickReason_StoresPropertiesCorrectly() {
        let reason = PickReason(icon: "star.fill", text: "Excellent conditions")

        XCTAssertEqual(reason.icon, "star.fill")
        XCTAssertEqual(reason.text, "Excellent conditions")
    }
}
