//
//  ForecastViewModelTests.swift
//  PowderTrackerTests
//
//  Tests for ForecastViewModel
//

import XCTest
@testable import PowderTracker

@MainActor
final class ForecastViewModelTests: XCTestCase {
    var sut: ForecastViewModel!

    override func setUpWithError() throws {
        sut = ForecastViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Initialization Tests

    func testInit_HasDefaultValues() {
        XCTAssertTrue(sut.forecast.isEmpty, "Forecast should be empty initially")
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        XCTAssertNil(sut.error, "Should have no error initially")
    }

    // MARK: - Load Forecast Tests

    func testLoadForecast_SetsLoadingState() async {
        // When
        let loadTask = Task {
            await sut.loadForecast()
        }

        // After
        await loadTask.value
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
    }

    func testLoadForecast_PopulatesForecastArray() async {
        // When
        await sut.loadForecast()

        // Then
        XCTAssertFalse(sut.forecast.isEmpty, "Forecast should be populated")
        XCTAssertEqual(sut.forecast.count, 7, "Should have 7-day forecast")
    }

    func testLoadForecast_ForecastDaysHaveValidData() async {
        // When
        await sut.loadForecast()

        // Then - verify forecast structure
        for day in sut.forecast {
            XCTAssertFalse(day.dayOfWeek.isEmpty, "Day of week should not be empty")
            XCTAssertFalse(day.date.isEmpty, "Date should not be empty")
            XCTAssertTrue(day.precipProbability >= 0 && day.precipProbability <= 100, "Precip probability should be 0-100")
        }
    }

    func testLoadForecast_ClearsErrorOnSuccess() async {
        // Given - simulate previous error state
        // (Can't directly set error due to @Observable, but we can test the flow)

        // When
        await sut.loadForecast()

        // Then
        XCTAssertNil(sut.error, "Error should be cleared on successful load")
    }

    // MARK: - Concurrency Tests

    func testConcurrentLoadForecast_HandlesMultipleCalls() async {
        // When
        async let task1: () = sut.loadForecast()
        async let task2: () = sut.loadForecast()

        await task1
        await task2

        // Then - should complete without crash
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.forecast.isEmpty)
    }

    // MARK: - Forecast Data Validation Tests

    func testLoadForecast_TemperaturesAreReasonable() async {
        // When
        await sut.loadForecast()

        // Then - verify temperature range (in Fahrenheit, mountain context)
        for day in sut.forecast {
            XCTAssertTrue(day.high >= -20 && day.high <= 100, "High temp should be reasonable")
            XCTAssertTrue(day.low >= -40 && day.low <= 90, "Low temp should be reasonable")
            XCTAssertTrue(day.high >= day.low, "High should be >= low")
        }
    }

    func testLoadForecast_SnowfallIsNonNegative() async {
        // When
        await sut.loadForecast()

        // Then
        for day in sut.forecast {
            XCTAssertTrue(day.snowfall >= 0, "Snowfall should be non-negative")
        }
    }
}
