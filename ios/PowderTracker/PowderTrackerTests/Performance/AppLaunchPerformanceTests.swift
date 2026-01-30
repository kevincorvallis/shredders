//
//  AppLaunchPerformanceTests.swift
//  PowderTrackerTests
//
//  Performance tests for app launch time metrics.
//

import XCTest

final class AppLaunchPerformanceTests: XCTestCase {

    // MARK: - Cold Launch Tests

    func testColdLaunchTime() throws {
        // Measure cold launch performance using XCTApplicationLaunchMetric
        // This measures the time from app launch to main thread ready
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testLaunchToFirstContent() throws {
        // Measure launch time until the app becomes responsive
        // waitUntilResponsive: true waits for first content to appear
        let app = XCUIApplication()

        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.launch()

            // Wait for the main tab bar to appear as indicator of content ready
            let tabBar = app.tabBars.firstMatch
            _ = tabBar.waitForExistence(timeout: 10)
        }
    }

    // MARK: - Warm Launch Tests

    func testWarmLaunchTime() throws {
        // Measure warm launch performance
        // This simulates relaunching the app after it was recently terminated
        let app = XCUIApplication()

        // First launch to warm the system
        app.launch()
        app.terminate()

        // Now measure warm launch
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    // MARK: - Launch Memory Tests

    func testLaunchMemoryFootprint() throws {
        // Measure memory usage during app launch
        let app = XCUIApplication()

        let metrics: [XCTMetric] = [
            XCTApplicationLaunchMetric(),
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            app.launch()
        }
    }

    // MARK: - Launch with Different States

    func testLaunchWithColdCache() throws {
        // Simulate launching with no cached data
        let app = XCUIApplication()
        app.launchArguments = ["--reset-state", "--no-cache"]

        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    func testLaunchWithExistingUser() throws {
        // Simulate launching as an existing user with cached data
        let app = XCUIApplication()
        app.launchArguments = ["--mock-logged-in"]

        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.launch()

            // Wait for personalized content (mountains tab with data)
            let mountainsList = app.collectionViews.firstMatch
            _ = mountainsList.waitForExistence(timeout: 10)
        }
    }

    func testLaunchToSpecificTab() throws {
        // Measure time to launch and navigate to a specific tab
        let app = XCUIApplication()

        measure(metrics: [
            XCTClockMetric(),
            XCTCPUMetric(application: app)
        ]) {
            app.launch()

            // Navigate to Events tab
            let eventsTab = app.tabBars.buttons["Events"]
            if eventsTab.waitForExistence(timeout: 5) {
                eventsTab.tap()
            }

            // Wait for events content to load
            let eventsList = app.collectionViews.firstMatch
            _ = eventsList.waitForExistence(timeout: 5)
        }
    }
}
