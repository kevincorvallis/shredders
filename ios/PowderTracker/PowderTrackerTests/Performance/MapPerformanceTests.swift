//
//  MapPerformanceTests.swift
//  PowderTrackerTests
//
//  Performance tests for map rendering and overlays.
//

import XCTest

final class MapPerformanceTests: XCTestCase {

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

    // MARK: - Map Initial Render

    func testMapInitialRender() throws {
        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            app.launch()

            // Navigate to Map tab
            let mapTab = app.tabBars.buttons["Map"]
            XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
            mapTab.tap()

            // Wait for map to load (map view exists)
            let mapView = app.maps.firstMatch
            _ = mapView.waitForExistence(timeout: 10)
        }

        app.terminate()
    }

    // MARK: - Mountain Pins Performance

    func testMapWithMountainPins_50() throws {
        app.launchArguments.append("--mock-mountains-count=50")
        app.launch()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()

        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTCPUMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Zoom in
            mapView.pinch(withScale: 2.0, velocity: 1.0)
            sleep(1)

            // Zoom out
            mapView.pinch(withScale: 0.5, velocity: 1.0)
            sleep(1)
        }
    }

    func testMapWithMountainPins_200() throws {
        // Stress test with 200 pins
        app.launchArguments.append("--mock-mountains-count=200")
        app.launch()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()

        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTCPUMetric(application: app),
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Multiple zoom operations
            mapView.pinch(withScale: 2.0, velocity: 1.0)
            sleep(1)
            mapView.pinch(withScale: 2.0, velocity: 1.0)
            sleep(1)
            mapView.pinch(withScale: 0.25, velocity: 1.0)
            sleep(1)
        }
    }

    // MARK: - Radar Overlay Performance

    func testRadarOverlayRender() throws {
        app.launch()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()

        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.waitForExistence(timeout: 10))

        // Find and tap overlay picker
        let overlayButton = app.buttons["Overlay"]
        guard overlayButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Overlay picker not available")
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            overlayButton.tap()

            // Select radar overlay
            let radarOption = app.buttons["Radar"]
            if radarOption.waitForExistence(timeout: 2) {
                radarOption.tap()
            }

            // Wait for tiles to load
            sleep(3)
        }
    }

    // MARK: - Overlay Switching Performance

    func testOverlaySwitching() throws {
        app.launch()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()

        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.waitForExistence(timeout: 10))

        let overlayButton = app.buttons["Overlay"]
        guard overlayButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Overlay picker not available")
        }

        let overlays = ["Radar", "Clouds", "Temperature", "Wind", "Snow"]
        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            for overlayName in overlays {
                overlayButton.tap()
                let option = app.buttons[overlayName]
                if option.waitForExistence(timeout: 2) {
                    option.tap()
                    sleep(2) // Wait for overlay transition
                }
            }
        }
    }

    // MARK: - Map Pan and Zoom Performance

    func testMapPanAndZoom() throws {
        app.launch()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()

        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTCPUMetric(application: app),
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            // Pan across map region
            mapView.swipeLeft(velocity: .fast)
            mapView.swipeRight(velocity: .fast)
            mapView.swipeUp(velocity: .fast)
            mapView.swipeDown(velocity: .fast)

            // Zoom in 3 levels
            mapView.pinch(withScale: 2.0, velocity: 1.0)
            sleep(1)
            mapView.pinch(withScale: 2.0, velocity: 1.0)
            sleep(1)
            mapView.pinch(withScale: 2.0, velocity: 1.0)
            sleep(1)

            // Zoom out 3 levels
            mapView.pinch(withScale: 0.5, velocity: 1.0)
            sleep(1)
            mapView.pinch(withScale: 0.5, velocity: 1.0)
            sleep(1)
            mapView.pinch(withScale: 0.5, velocity: 1.0)
            sleep(1)
        }
    }

    // MARK: - Map Memory Under Load

    func testMapMemoryUnderLoad() throws {
        // Test for memory leaks during extended map usage
        app.launchArguments.append("--mock-mountains-count=100")
        app.launch()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()

        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTMemoryMetric(application: app)
        ]

        measure(metrics: metrics) {
            // Extended map interaction session
            for _ in 0..<5 {
                mapView.swipeLeft(velocity: .fast)
                mapView.swipeRight(velocity: .fast)
                mapView.pinch(withScale: 2.0, velocity: 1.0)
                mapView.pinch(withScale: 0.5, velocity: 1.0)
            }
        }
    }
}
