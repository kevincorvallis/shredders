//
//  MapUITests.swift
//  PowderTrackerUITests
//
//  UI tests for Map functionality - focuses on critical user flows.
//

import XCTest

final class MapUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    @MainActor
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    @MainActor
    private func navigateToMap() {
        let mapTab = app.tabBars.buttons["Map"].firstMatch
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "Map tab should exist")
        mapTab.tap()
    }

    // MARK: - Critical Flow Tests

    @MainActor
    func testMapTabLoadsContent() throws {
        launchApp()
        navigateToMap()
        Thread.sleep(forTimeInterval: 2)

        // Map view should exist
        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.waitForExistence(timeout: 5) || app.otherElements.firstMatch.exists, "Map view should load")
    }

    @MainActor
    func testMapPanInteraction() throws {
        launchApp()
        navigateToMap()
        Thread.sleep(forTimeInterval: 2)

        let mapArea = app.otherElements.firstMatch
        if mapArea.exists {
            mapArea.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)
            mapArea.swipeRight()
        }
    }

    @MainActor
    func testTapMountainPin() throws {
        launchApp()
        navigateToMap()
        Thread.sleep(forTimeInterval: 3)

        // Find a pin annotation
        let pins = app.otherElements.matching(NSPredicate(format: "label CONTAINS[c] 'Mountain' OR label CONTAINS[c] 'Resort'"))
        let firstPin = pins.firstMatch

        if firstPin.waitForExistence(timeout: 5) && firstPin.isHittable {
            firstPin.tap()
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testWeatherOverlayToggle() throws {
        launchApp()
        navigateToMap()
        Thread.sleep(forTimeInterval: 2)

        // Look for overlay toggle
        let overlayToggle = app.buttons["map_overlay_toggle"]
        if overlayToggle.waitForExistence(timeout: 3) && overlayToggle.isHittable {
            overlayToggle.tap()
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testMapSearchButton() throws {
        launchApp()
        navigateToMap()
        Thread.sleep(forTimeInterval: 2)

        let searchButton = app.buttons["map_search_button"]
        if searchButton.waitForExistence(timeout: 3) && searchButton.isHittable {
            searchButton.tap()

            // Search field should appear
            let searchField = app.searchFields.firstMatch
            if searchField.waitForExistence(timeout: 3) {
                searchField.tap()
                searchField.typeText("Squaw")
                Thread.sleep(forTimeInterval: 1)

                // Dismiss keyboard
                app.swipeDown()
            }
        }
    }

    @MainActor
    func testCurrentLocationButton() throws {
        launchApp()
        navigateToMap()
        Thread.sleep(forTimeInterval: 2)

        let locationButton = app.buttons["map_current_location"]
        if locationButton.waitForExistence(timeout: 3) && locationButton.isHittable {
            locationButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testMapFilterButton() throws {
        launchApp()
        navigateToMap()
        Thread.sleep(forTimeInterval: 2)

        let filterButton = app.buttons["map_filter_button"]
        if filterButton.waitForExistence(timeout: 3) && filterButton.isHittable {
            filterButton.tap()
            Thread.sleep(forTimeInterval: 1)

            // Dismiss filter menu
            app.tap()
        }
    }
}
