//
//  ImageLoadingPerformanceTests.swift
//  PowderTrackerTests
//
//  Performance tests for image loading and caching.
//

import XCTest

final class ImageLoadingPerformanceTests: XCTestCase {

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

    // MARK: - Single Image Load

    func testSingleImageLoad() throws {
        // Measure loading a single mountain hero image
        app.launchArguments.append("--mock-mountains-count=1")
        app.launch()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Tap into mountain detail to load hero image
            let firstMountain = list.cells.firstMatch
            if firstMountain.waitForExistence(timeout: 3) {
                firstMountain.tap()

                // Wait for detail view and image to load
                let heroImage = app.images.firstMatch
                _ = heroImage.waitForExistence(timeout: 5)

                // Navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                }
            }
        }
    }

    // MARK: - Batch Image Load

    func testBatchImageLoad_10() throws {
        // Load 10 images in parallel (mountain list with thumbnails)
        app.launchArguments.append("--mock-mountains-count=10")
        app.launch()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app)
        ]

        measure(metrics: metrics) {
            let list = app.collectionViews.firstMatch
            _ = list.waitForExistence(timeout: 5)

            // Scroll to trigger image loading
            list.swipeUp(velocity: .slow)
            sleep(2) // Wait for images to load
            list.swipeDown(velocity: .slow)
            sleep(2)
        }
    }

    func testBatchImageLoad_20() throws {
        // Stress test with 20 images
        app.launchArguments.append("--mock-mountains-count=20")
        app.launch()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTCPUMetric(application: app)
        ]

        measure(metrics: metrics) {
            let list = app.collectionViews.firstMatch
            _ = list.waitForExistence(timeout: 5)

            // Scroll through all items to load images
            list.swipeUp(velocity: .fast)
            list.swipeUp(velocity: .fast)
            sleep(2)
            list.swipeDown(velocity: .fast)
            list.swipeDown(velocity: .fast)
            sleep(2)
        }
    }

    // MARK: - Image Cache Performance

    func testImageCachePerformance() throws {
        // Test cache hit performance by loading same images multiple times
        app.launchArguments.append("--mock-mountains-count=5")
        app.launch()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        // First pass to populate cache
        list.swipeUp(velocity: .slow)
        sleep(3)
        list.swipeDown(velocity: .slow)
        sleep(3)

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTCPUMetric(application: app)
        ]

        // Now measure cache performance
        measure(metrics: metrics) {
            // Navigate away and back to test cache
            let eventsTab = app.tabBars.buttons["Events"]
            eventsTab.tap()
            sleep(1)
            mountainsTab.tap()
            sleep(1)

            // Scroll through cached images (should be fast)
            list.swipeUp(velocity: .fast)
            list.swipeDown(velocity: .fast)
        }
    }

    // MARK: - Avatar Image Load

    func testAvatarImageLoad() throws {
        // Measure loading and rendering avatar images
        app.launchArguments.append("--mock-events-count=20")
        app.launch()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        // Tap into an event with attendees
        let firstEvent = list.cells.firstMatch
        XCTAssertTrue(firstEvent.waitForExistence(timeout: 3))
        firstEvent.tap()

        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            // Wait for attendee avatars to load
            sleep(3)

            // Navigate back and tap again to test cache
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
            sleep(1)
            firstEvent.tap()
            sleep(2)
        }
    }

    // MARK: - Image Memory Release

    func testImageMemoryRelease() throws {
        // Test that images are properly released from memory when not visible
        app.launchArguments.append("--mock-mountains-count=50")
        app.launch()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Scroll down to load images
            for _ in 0..<4 {
                list.swipeUp(velocity: .fast)
            }
            sleep(2)

            // Scroll back up - images at bottom should be released
            for _ in 0..<4 {
                list.swipeDown(velocity: .fast)
            }
            sleep(2)

            // Navigate away to allow memory cleanup
            let eventsTab = app.tabBars.buttons["Events"]
            eventsTab.tap()
            sleep(2)
        }
    }

    // MARK: - Large Image Handling

    func testLargeImageHandling() throws {
        // Test handling of large hero images in detail views
        app.launchArguments.append("--mock-mountains-count=5")
        app.launchArguments.append("--high-res-images")
        app.launch()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5))
        mountainsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app),
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            // Open multiple detail views with large images
            for i in 0..<3 {
                let cell = list.cells.element(boundBy: i)
                if cell.exists {
                    cell.tap()
                    sleep(2) // Wait for large image to load

                    let backButton = app.navigationBars.buttons.firstMatch
                    if backButton.exists {
                        backButton.tap()
                    }
                    sleep(1)
                }
            }
        }
    }
}
