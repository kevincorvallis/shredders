//
//  MapUITests.swift
//  PowderTrackerUITests
//
//  Smoke test for map tab loading.
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
    func testMapTabLoads() throws {
        launchApp()

        let mapTab = app.tabBars.buttons["Map"].firstMatch
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "Map tab should exist")
        mapTab.tap()

        Thread.sleep(forTimeInterval: 2)

        let mapView = app.maps.firstMatch
        XCTAssertTrue(mapView.waitForExistence(timeout: 5), "Map view should load")
    }
}
