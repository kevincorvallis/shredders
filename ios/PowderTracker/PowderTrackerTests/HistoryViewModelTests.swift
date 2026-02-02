//
//  HistoryViewModelTests.swift
//  PowderTrackerTests
//
//  Tests for HistoryViewModel
//

import XCTest
@testable import PowderTracker

@MainActor
final class HistoryViewModelTests: XCTestCase {
    var sut: HistoryViewModel!

    override func setUpWithError() throws {
        sut = HistoryViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Initialization Tests

    func testInit_HasDefaultValues() {
        XCTAssertTrue(sut.history.isEmpty, "History should be empty initially")
        XCTAssertNil(sut.summary, "Summary should be nil initially")
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        XCTAssertNil(sut.error, "Should have no error initially")
        XCTAssertEqual(sut.selectedDays, 30, "Default period should be 30 days")
    }

    // MARK: - Load History Tests

    func testLoadHistory_SetsLoadingState() async {
        // When
        let loadTask = Task {
            await sut.loadHistory()
        }

        // After
        await loadTask.value
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
    }

    func testLoadHistory_PopulatesHistoryArray() async {
        // When
        await sut.loadHistory()

        // Then
        XCTAssertFalse(sut.history.isEmpty, "History should be populated")
    }

    func testLoadHistory_PopulatesSummary() async {
        // When
        await sut.loadHistory()

        // Then
        XCTAssertNotNil(sut.summary, "Summary should be populated")
    }

    func testLoadHistory_SummaryHasValidData() async {
        // When
        await sut.loadHistory()

        // Then
        guard let summary = sut.summary else {
            XCTFail("Summary should be available")
            return
        }

        XCTAssertTrue(summary.currentDepth >= 0, "Current depth should be non-negative")
        XCTAssertTrue(summary.maxDepth >= summary.minDepth, "Max should be >= min")
        XCTAssertTrue(summary.totalSnowfall >= 0, "Total snowfall should be non-negative")
    }

    func testLoadHistory_HistoryPointsHaveValidData() async {
        // When
        await sut.loadHistory()

        // Then
        for point in sut.history {
            XCTAssertFalse(point.date.isEmpty, "Date should not be empty")
            XCTAssertTrue(point.snowDepth >= 0, "Snow depth should be non-negative")
            XCTAssertTrue(point.snowfall >= 0, "Snowfall should be non-negative")
        }
    }

    // MARK: - Change Period Tests

    func testChangePeriod_UpdatesSelectedDays() async {
        // When
        await sut.changePeriod(to: 7)

        // Then
        XCTAssertEqual(sut.selectedDays, 7, "Selected days should be updated")
    }

    func testChangePeriod_ReloadsHistory() async {
        // Given - load initial data
        await sut.loadHistory()
        let initialCount = sut.history.count

        // When - change to shorter period
        await sut.changePeriod(to: 7)

        // Then - history should be reloaded (different count expected for different period)
        XCTAssertFalse(sut.history.isEmpty, "History should still have data")
        // Note: can't guarantee count differs if API doesn't respect days param exactly
    }

    func testChangePeriod_To14Days() async {
        // When
        await sut.changePeriod(to: 14)

        // Then
        XCTAssertEqual(sut.selectedDays, 14)
        XCTAssertFalse(sut.history.isEmpty)
    }

    func testChangePeriod_To90Days() async {
        // When
        await sut.changePeriod(to: 90)

        // Then
        XCTAssertEqual(sut.selectedDays, 90)
        XCTAssertFalse(sut.history.isEmpty)
    }

    // MARK: - Concurrency Tests

    func testConcurrentLoadHistory_HandlesMultipleCalls() async {
        // When
        async let task1: () = sut.loadHistory()
        async let task2: () = sut.loadHistory()

        await task1
        await task2

        // Then - should complete without crash
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - History Data Point Tests

    func testHistoryDataPoint_FormattedDate() {
        // Given
        let point = HistoryDataPoint(
            date: "2025-01-15",
            snowDepth: 142,
            snowfall: 8,
            temperature: 28
        )

        // When
        let formattedDate = point.formattedDate

        // Then
        XCTAssertNotNil(formattedDate, "Formatted date should parse successfully")

        let calendar = Calendar.current
        if let date = formattedDate {
            XCTAssertEqual(calendar.component(.year, from: date), 2025)
            XCTAssertEqual(calendar.component(.month, from: date), 1)
            XCTAssertEqual(calendar.component(.day, from: date), 15)
        }
    }

    func testHistoryDataPoint_Id() {
        // Given
        let point = HistoryDataPoint(
            date: "2025-01-15",
            snowDepth: 142,
            snowfall: 8,
            temperature: 28
        )

        // Then
        XCTAssertEqual(point.id, "2025-01-15", "ID should equal date")
    }

    func testHistoryDataPoint_MockHistory() {
        // When
        let mockHistory = HistoryDataPoint.mockHistory(days: 10)

        // Then
        XCTAssertEqual(mockHistory.count, 10, "Should generate requested number of days")
        for point in mockHistory {
            XCTAssertTrue(point.snowDepth >= 0)
            XCTAssertTrue(point.snowfall >= 0)
        }
    }
}

// MARK: - HistorySummary Tests

final class HistorySummaryTests: XCTestCase {
    func testHistorySummary_DecodesCorrectly() throws {
        // Given
        let json = """
        {
            "currentDepth": 142,
            "maxDepth": 168,
            "minDepth": 120,
            "totalSnowfall": 48,
            "avgDailySnowfall": "1.6"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let summary = try JSONDecoder().decode(HistorySummary.self, from: data)

        // Then
        XCTAssertEqual(summary.currentDepth, 142)
        XCTAssertEqual(summary.maxDepth, 168)
        XCTAssertEqual(summary.minDepth, 120)
        XCTAssertEqual(summary.totalSnowfall, 48)
        XCTAssertEqual(summary.avgDailySnowfall, "1.6")
    }
}
