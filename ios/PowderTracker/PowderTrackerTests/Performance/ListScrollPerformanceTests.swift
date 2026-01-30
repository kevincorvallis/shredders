//
//  ListScrollPerformanceTests.swift
//  PowderTrackerTests
//
//  Performance tests for list scrolling and memory usage.
//

import XCTest

final class ListScrollPerformanceTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    // MARK: - Mountain List Scrolling

    func testMountainListScroll_50Items() throws {
        // Configure app to load 50 mock mountains
        app.launchArguments.append("--mock-mountains-count=50")
        app.launch()

        // Navigate to Mountains tab
        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app),
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            // Scroll to bottom
            list.swipeUp(velocity: .fast)
            list.swipeUp(velocity: .fast)
            list.swipeUp(velocity: .fast)

            // Scroll back to top
            list.swipeDown(velocity: .fast)
            list.swipeDown(velocity: .fast)
            list.swipeDown(velocity: .fast)
        }
    }

    func testMountainListScroll_100Items() throws {
        // Stress test with 100 mountains
        app.launchArguments.append("--mock-mountains-count=100")
        app.launch()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app),
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            // Extended scroll through 100 items
            for _ in 0..<6 {
                list.swipeUp(velocity: .fast)
            }

            // Scroll back
            for _ in 0..<6 {
                list.swipeDown(velocity: .fast)
            }
        }
    }

    // MARK: - Event List Scrolling

    func testEventListScroll_50Events() throws {
        app.launchArguments.append("--mock-events-count=50")
        app.launch()

        // Navigate to Events tab
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Scroll through event list
            list.swipeUp(velocity: .fast)
            list.swipeUp(velocity: .fast)
            list.swipeUp(velocity: .fast)
            list.swipeDown(velocity: .fast)
            list.swipeDown(velocity: .fast)
            list.swipeDown(velocity: .fast)
        }
    }

    // MARK: - Photo Gallery Scrolling

    func testPhotoGalleryScroll_100Photos() throws {
        // Photo scrolling is critical for memory - images can leak
        app.launchArguments.append("--mock-photos-count=100")
        app.launch()

        // Navigate to an event with photos
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        // Tap first event
        let firstEvent = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstEvent.waitForExistence(timeout: 5))
        firstEvent.tap()

        // Navigate to Photos tab within event
        let photosTab = app.buttons["Photos"]
        if photosTab.waitForExistence(timeout: 3) {
            photosTab.tap()
        }

        let photoGrid = app.collectionViews.firstMatch
        guard photoGrid.waitForExistence(timeout: 5) else {
            throw XCTSkip("Photo grid not available in this configuration")
        }

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Scroll through photo grid
            for _ in 0..<5 {
                photoGrid.swipeUp(velocity: .fast)
            }

            for _ in 0..<5 {
                photoGrid.swipeDown(velocity: .fast)
            }
        }
    }

    // MARK: - Comment List Scrolling

    func testCommentListScroll_200Comments() throws {
        // Test text rendering performance with long discussion threads
        app.launchArguments.append("--mock-comments-count=200")
        app.launch()

        // Navigate to an event with comments
        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let firstEvent = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstEvent.waitForExistence(timeout: 5))
        firstEvent.tap()

        // Navigate to Discussion tab
        let discussionTab = app.buttons["Discussion"]
        if discussionTab.waitForExistence(timeout: 3) {
            discussionTab.tap()
        }

        let commentList = app.scrollViews.firstMatch
        guard commentList.waitForExistence(timeout: 5) else {
            throw XCTSkip("Comment list not available in this configuration")
        }

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            // Scroll through long comment thread
            for _ in 0..<8 {
                commentList.swipeUp(velocity: .fast)
            }

            for _ in 0..<8 {
                commentList.swipeDown(velocity: .fast)
            }
        }
    }

    // MARK: - Rapid Scroll Tests

    func testRapidScrollStress() throws {
        // Stress test with rapid scrolling to detect frame drops
        app.launchArguments.append("--mock-mountains-count=100")
        app.launch()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let metrics: [XCTMetric] = [
            XCTCPUMetric(application: app),
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            // Rapid alternating scrolls to stress test rendering
            for _ in 0..<10 {
                list.swipeUp(velocity: .fast)
                list.swipeDown(velocity: .fast)
            }
        }
    }
}
