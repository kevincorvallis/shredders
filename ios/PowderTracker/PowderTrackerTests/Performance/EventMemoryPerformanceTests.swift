//
//  EventMemoryPerformanceTests.swift
//  PowderTrackerTests
//
//  Memory and performance tests for the Events feature.
//  Tests for memory leaks, scrolling performance with large datasets,
//  and view lifecycle memory behavior.
//

import XCTest

/// Performance and memory tests for Events feature
/// Covers items 7.7 (memory leaks) and 7.8 (50+ events performance) from the checklist
final class EventMemoryPerformanceTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--disable-animations"]
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    // MARK: - 7.8 Performance test with 50+ events in list

    /// Tests scrolling performance with 50 events
    func testEventListScroll_50Events_Memory() throws {
        app.launchArguments.append("--mock-events-count=50")
        app.launch()

        // Navigate to Events tab
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5), "Events tab should exist")
        eventsTab.tap()

        // Wait for list to load
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Event list should load")

        // Measure memory during scrolling
        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app),
            XCTClockMetric()
        ]

        // Performance measurement with baseline
        measure(metrics: metrics, options: XCTMeasureOptions.default) {
            // Full scroll through 50 events
            for _ in 0..<5 {
                list.swipeUp(velocity: .fast)
            }

            // Scroll back to top
            for _ in 0..<5 {
                list.swipeDown(velocity: .fast)
            }
        }
    }

    /// Tests performance with 100 events (stress test)
    func testEventListScroll_100Events_Stress() throws {
        app.launchArguments.append("--mock-events-count=100")
        app.launch()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Extended scroll through 100 events
            for _ in 0..<10 {
                list.swipeUp(velocity: .fast)
            }

            for _ in 0..<10 {
                list.swipeDown(velocity: .fast)
            }
        }
    }

    // MARK: - 7.7 Memory Leak Tests

    /// Tests for memory leaks when repeatedly opening and closing event details
    func testEventDetailNavigation_MemoryLeaks() throws {
        app.launchArguments.append("--mock-events-count=10")
        app.launch()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Repeatedly open and close event details
            // This tests for retain cycles in the navigation stack
            for _ in 0..<5 {
                // Tap first event
                let firstEvent = app.collectionViews.cells.firstMatch
                if firstEvent.waitForExistence(timeout: 3) {
                    firstEvent.tap()

                    // Wait for detail to load
                    sleep(1)

                    // Navigate back
                    let backButton = app.navigationBars.buttons.firstMatch
                    if backButton.waitForExistence(timeout: 2) {
                        backButton.tap()
                    }

                    // Wait for list to be back
                    sleep(1)
                }
            }
        }
    }

    /// Tests memory behavior with event creation and cancellation
    func testEventCreateCancel_MemoryLeaks() throws {
        app.launch()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Repeatedly open and dismiss create event flow
            for _ in 0..<3 {
                // Look for create button (+ button or "Create Event")
                let createButton = app.buttons["Create Event"]
                let plusButton = app.navigationBars.buttons["Add"]

                if createButton.waitForExistence(timeout: 2) {
                    createButton.tap()
                } else if plusButton.waitForExistence(timeout: 2) {
                    plusButton.tap()
                } else {
                    // Skip if not authenticated
                    break
                }

                sleep(1)

                // Cancel/dismiss the create view
                let cancelButton = app.buttons["Cancel"]
                let closeButton = app.buttons["Close"]

                if cancelButton.waitForExistence(timeout: 2) {
                    cancelButton.tap()
                } else if closeButton.waitForExistence(timeout: 2) {
                    closeButton.tap()
                }

                sleep(1)
            }
        }
    }

    /// Tests memory when switching between event list filter tabs
    func testEventFilterSwitching_Memory() throws {
        app.launchArguments.append("--mock-events-count=30")
        app.launch()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        // Wait for list to load
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Switch between filter options repeatedly
            // This tests that old filtered lists are properly released
            let allButton = app.buttons["All"]
            let myEventsButton = app.buttons["My Events"]
            let attendingButton = app.buttons["Attending"]

            for _ in 0..<5 {
                if allButton.exists { allButton.tap() }
                sleep(1)

                if myEventsButton.exists { myEventsButton.tap() }
                sleep(1)

                if attendingButton.exists { attendingButton.tap() }
                sleep(1)
            }
        }
    }

    /// Tests memory with event social features (comments, activity, photos)
    func testEventSocialTabs_Memory() throws {
        app.launchArguments.append("--mock-events-count=5")
        app.launchArguments.append("--mock-comments-count=50")
        app.launchArguments.append("--mock-photos-count=20")
        app.launch()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        // Open first event
        let firstEvent = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstEvent.waitForExistence(timeout: 5))
        firstEvent.tap()

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Switch between social tabs repeatedly
            let discussionTab = app.buttons["Discussion"]
            let activityTab = app.buttons["Activity"]
            let photosTab = app.buttons["Photos"]

            for _ in 0..<5 {
                if discussionTab.exists { discussionTab.tap() }
                sleep(1)

                if activityTab.exists { activityTab.tap() }
                sleep(1)

                if photosTab.exists { photosTab.tap() }
                sleep(1)
            }
        }
    }

    // MARK: - Scroll Performance Tests

    /// Tests rapid scroll performance (frame drops)
    func testEventListRapidScroll_FrameDrops() throws {
        app.launchArguments.append("--mock-events-count=50")
        app.launch()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        // CPU metric helps detect frame drops (high CPU = potential jank)
        let metrics: [XCTMetric] = [
            XCTCPUMetric(application: app),
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            // Rapid alternating scrolls to stress test rendering
            for _ in 0..<15 {
                list.swipeUp(velocity: .fast)
                list.swipeDown(velocity: .fast)
            }
        }
    }

    /// Tests initial load time for 50 events
    func testEventListInitialLoad_50Events() throws {
        app.launchArguments.append("--mock-events-count=50")

        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            app.launch()

            let eventsTab = app.tabBars.buttons["Events"]
            XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
            eventsTab.tap()

            // Measure time until list is visible
            let list = app.collectionViews.firstMatch
            XCTAssertTrue(list.waitForExistence(timeout: 10), "List should load within 10 seconds")

            // Measure time until first cell is visible
            let firstCell = app.collectionViews.cells.firstMatch
            XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "First cell should appear within 5 seconds")

            app.terminate()
        }
    }

    // MARK: - Cache Memory Tests

    /// Tests memory behavior of the EventCacheService
    func testEventCaching_Memory() throws {
        app.launchArguments.append("--mock-events-count=50")
        app.launch()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Simulate cache population by scrolling through events
            for _ in 0..<5 {
                list.swipeUp(velocity: .slow)
            }

            // Open some event details (populates detail cache)
            for i in 0..<3 {
                // Scroll to top first
                for _ in 0..<5 {
                    list.swipeDown(velocity: .fast)
                }

                // Open event
                let cell = app.collectionViews.cells.element(boundBy: i)
                if cell.exists {
                    cell.tap()
                    sleep(2)

                    // Navigate back
                    let backButton = app.navigationBars.buttons.firstMatch
                    if backButton.exists {
                        backButton.tap()
                    }
                    sleep(1)
                }
            }

            // Scroll through again (should use cached data)
            for _ in 0..<5 {
                list.swipeUp(velocity: .fast)
            }
        }
    }
}

// MARK: - Memory Assertions

extension EventMemoryPerformanceTests {

    /// Helper to assert memory stays within bounds
    /// Used for manual verification after running tests
    static let maxAcceptableMemoryMB: Double = 100.0

    /// Helper to assert no significant memory growth
    /// Memory growth > 10MB per iteration suggests a leak
    static let maxMemoryGrowthPerIterationMB: Double = 10.0
}
