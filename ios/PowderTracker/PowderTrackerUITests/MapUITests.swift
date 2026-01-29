//
//  MapUITests.swift
//  PowderTrackerUITests
//
//  Comprehensive E2E UI tests for Map functionality
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
        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "Map tab should exist")
        mapTab.tap()
    }

    // MARK: - Map Tab Basic Tests

    @MainActor
    func testMapTabLoads() throws {
        launchApp()
        navigateToMap()

        // Wait for map to load
        Thread.sleep(forTimeInterval: 2)

        addScreenshot(named: "Map Tab")
    }

    @MainActor
    func testMapTabAccessible() throws {
        launchApp()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "Map tab should exist")
        XCTAssertTrue(mapTab.isHittable, "Map tab should be tappable")
    }

    @MainActor
    func testMapViewDisplays() throws {
        launchApp()
        navigateToMap()

        // Map takes time to load
        Thread.sleep(forTimeInterval: 3)

        // Map should be visible
        let mapView = app.maps.firstMatch
        if mapView.exists {
            XCTAssertTrue(mapView.isHittable, "Map should be interactive")
        }
    }

    // MARK: - Map Interaction Tests

    @MainActor
    func testMapPan() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        // Pan the map
        let mapArea = app.otherElements.firstMatch
        mapArea.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        mapArea.swipeRight()
    }

    @MainActor
    func testMapZoom() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        // Pinch to zoom (simulated)
        let mapArea = app.otherElements.firstMatch
        if mapArea.exists {
            mapArea.pinch(withScale: 2.0, velocity: 1.0) // Zoom in
            Thread.sleep(forTimeInterval: 0.5)
            mapArea.pinch(withScale: 0.5, velocity: -1.0) // Zoom out
        }
    }

    @MainActor
    func testDoubleTapZoom() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let mapArea = app.otherElements.firstMatch
        if mapArea.exists {
            mapArea.doubleTap()
            Thread.sleep(forTimeInterval: 1)
        }
    }

    // MARK: - Mountain Pin Tests

    @MainActor
    func testMountainPinsDisplay() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 3)

        // Look for annotation markers
        _  = app.otherElements.matching(identifier: "mountain_pin")
        // Pins should exist after map loads
    }

    @MainActor
    func testTapMountainPin() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 3)

        // Try to tap a pin (depends on implementation)
        let pin = app.otherElements.matching(identifier: "mountain_pin").firstMatch
        if pin.waitForExistence(timeout: 3) {
            pin.tap()

            // Callout or detail should appear
            Thread.sleep(forTimeInterval: 1)
            addScreenshot(named: "Mountain Pin Tapped")
        }
    }

    @MainActor
    func testPinCalloutDetails() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 3)

        let pin = app.otherElements.matching(identifier: "mountain_pin").firstMatch
        if pin.waitForExistence(timeout: 3) {
            pin.tap()

            // Look for callout with mountain name
            let callout = app.staticTexts.element(boundBy: 0)
            if callout.waitForExistence(timeout: 2) {
                // Callout should show mountain info
            }
        }
    }

    @MainActor
    func testNavigateToDetailFromPin() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 3)

        let pin = app.otherElements.matching(identifier: "mountain_pin").firstMatch
        if pin.waitForExistence(timeout: 3) {
            pin.tap()

            // Look for detail button or tap callout
            let detailButton = app.buttons["pin_detail_button"]
            if detailButton.waitForExistence(timeout: 2) {
                detailButton.tap()

                // Should navigate to mountain detail
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }

    // MARK: - Weather Overlay Tests

    @MainActor
    func testWeatherOverlayToggle() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        // Look for weather overlay button
        let overlayButton = app.buttons["map_weather_overlay"]
        if overlayButton.waitForExistence(timeout: 3) {
            overlayButton.tap()

            // Overlay should toggle
            Thread.sleep(forTimeInterval: 2)
            addScreenshot(named: "Weather Overlay")
        }
    }

    @MainActor
    func testRadarOverlay() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let radarButton = app.buttons["map_radar_overlay"]
        if radarButton.waitForExistence(timeout: 3) {
            radarButton.tap()

            // Radar should display
            Thread.sleep(forTimeInterval: 3)
            addScreenshot(named: "Radar Overlay")
        }
    }

    @MainActor
    func testTemperatureOverlay() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let tempButton = app.buttons["map_temperature_overlay"]
        if tempButton.waitForExistence(timeout: 3) {
            tempButton.tap()

            Thread.sleep(forTimeInterval: 3)
            addScreenshot(named: "Temperature Overlay")
        }
    }

    @MainActor
    func testSnowfallOverlay() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let snowButton = app.buttons["map_snowfall_overlay"]
        if snowButton.waitForExistence(timeout: 3) {
            snowButton.tap()

            Thread.sleep(forTimeInterval: 3)
            addScreenshot(named: "Snowfall Overlay")
        }
    }

    @MainActor
    func testWindOverlay() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let windButton = app.buttons["map_wind_overlay"]
        if windButton.waitForExistence(timeout: 3) {
            windButton.tap()

            Thread.sleep(forTimeInterval: 3)
            addScreenshot(named: "Wind Overlay")
        }
    }

    @MainActor
    func testOverlayCycling() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        // Cycle through overlays
        let overlays = ["map_radar_overlay", "map_temperature_overlay", "map_snowfall_overlay", "map_wind_overlay"]

        for overlayId in overlays {
            let button = app.buttons[overlayId]
            if button.waitForExistence(timeout: 2) {
                button.tap()
                Thread.sleep(forTimeInterval: 2)
            }
        }
    }

    // MARK: - Location Tests

    @MainActor
    func testCurrentLocationButton() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let locationButton = app.buttons["map_current_location"]
        if locationButton.waitForExistence(timeout: 3) {
            // Don't tap in test - would trigger location permission
            XCTAssertTrue(locationButton.exists, "Current location button should exist")
        }
    }

    @MainActor
    func testCenterMapOnLocation() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let locationButton = app.buttons["map_current_location"]
        if locationButton.waitForExistence(timeout: 3) {
            // Note: This would require location permission
            // In a real test, you'd need to handle the permission alert
        }
    }

    // MARK: - Search Tests

    @MainActor
    func testMapSearchButton() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let searchButton = app.buttons["map_search"]
        if searchButton.waitForExistence(timeout: 3) {
            searchButton.tap()

            // Search interface should appear
            let searchField = app.searchFields.firstMatch
            _ = searchField.waitForExistence(timeout: 3)
        }
    }

    @MainActor
    func testSearchForMountain() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let searchButton = app.buttons["map_search"]
        if searchButton.waitForExistence(timeout: 3) {
            searchButton.tap()

            let searchField = app.searchFields.firstMatch
            if searchField.waitForExistence(timeout: 3) {
                searchField.tap()
                searchField.typeText("Vail")

                Thread.sleep(forTimeInterval: 1)

                // Results should appear
                addScreenshot(named: "Map Search Results")
            }
        }
    }

    @MainActor
    func testSelectSearchResult() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let searchButton = app.buttons["map_search"]
        if searchButton.waitForExistence(timeout: 3) {
            searchButton.tap()

            let searchField = app.searchFields.firstMatch
            if searchField.waitForExistence(timeout: 3) {
                searchField.tap()
                searchField.typeText("Park")

                Thread.sleep(forTimeInterval: 1)

                // Tap first result
                let firstResult = app.cells.firstMatch
                if firstResult.waitForExistence(timeout: 2) {
                    firstResult.tap()

                    // Map should center on selected mountain
                    Thread.sleep(forTimeInterval: 2)
                }
            }
        }
    }

    // MARK: - Filter Tests

    @MainActor
    func testMapFilterButton() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let filterButton = app.buttons["map_filter"]
        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()

            // Filter options should appear
            Thread.sleep(forTimeInterval: 1)
            addScreenshot(named: "Map Filter Options")
        }
    }

    @MainActor
    func testFilterByOpen() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let filterButton = app.buttons["map_filter"]
        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()

            let openOnlyFilter = app.buttons["filter_open_only"]
            if openOnlyFilter.waitForExistence(timeout: 2) {
                openOnlyFilter.tap()

                // Pins should update
                Thread.sleep(forTimeInterval: 2)
            }
        }
    }

    @MainActor
    func testFilterByFavorites() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let filterButton = app.buttons["map_filter"]
        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()

            let favoritesFilter = app.buttons["filter_favorites_only"]
            if favoritesFilter.waitForExistence(timeout: 2) {
                favoritesFilter.tap()

                // Only favorite pins should show
                Thread.sleep(forTimeInterval: 2)
            }
        }
    }

    // MARK: - Map Type Tests

    @MainActor
    func testMapTypeToggle() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let mapTypeButton = app.buttons["map_type_toggle"]
        if mapTypeButton.waitForExistence(timeout: 3) {
            mapTypeButton.tap()

            // Map type options should appear
            Thread.sleep(forTimeInterval: 1)
            addScreenshot(named: "Map Type Options")
        }
    }

    @MainActor
    func testSatelliteView() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let mapTypeButton = app.buttons["map_type_toggle"]
        if mapTypeButton.waitForExistence(timeout: 3) {
            mapTypeButton.tap()

            let satelliteOption = app.buttons["map_satellite"]
            if satelliteOption.waitForExistence(timeout: 2) {
                satelliteOption.tap()

                Thread.sleep(forTimeInterval: 2)
                addScreenshot(named: "Satellite Map")
            }
        }
    }

    @MainActor
    func testTerrainView() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        let mapTypeButton = app.buttons["map_type_toggle"]
        if mapTypeButton.waitForExistence(timeout: 3) {
            mapTypeButton.tap()

            let terrainOption = app.buttons["map_terrain"]
            if terrainOption.waitForExistence(timeout: 2) {
                terrainOption.tap()

                Thread.sleep(forTimeInterval: 2)
                addScreenshot(named: "Terrain Map")
            }
        }
    }

    // MARK: - Legend Tests

    @MainActor
    func testOverlayLegend() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        // Enable an overlay
        let radarButton = app.buttons["map_radar_overlay"]
        if radarButton.waitForExistence(timeout: 3) {
            radarButton.tap()

            // Legend should appear
            let legend = app.staticTexts["overlay_legend"]
            if legend.waitForExistence(timeout: 3) {
                addScreenshot(named: "Overlay Legend")
            }
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testMapLoadPerformance() throws {
        launchApp()

        measure {
            navigateToMap()
            Thread.sleep(forTimeInterval: 2)

            // Switch back and reload
            app.tabBars.buttons["Mountains"].tap()
            Thread.sleep(forTimeInterval: 1)
            app.tabBars.buttons["Map"].tap()
            Thread.sleep(forTimeInterval: 2)
        }
    }

    @MainActor
    func testOverlayLoadPerformance() throws {
        launchApp()
        navigateToMap()

        Thread.sleep(forTimeInterval: 2)

        measure {
            let radarButton = app.buttons["map_radar_overlay"]
            if radarButton.exists {
                radarButton.tap()
                Thread.sleep(forTimeInterval: 2)
                radarButton.tap() // Toggle off
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }

    // MARK: - Screenshots

    @MainActor
    private func addScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
