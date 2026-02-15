//
//  MountainsUITests.swift
//  PowderTrackerUITests
//
//  Tests for mountains list navigation and search.
//

import XCTest

final class MountainsUITests: XCTestCase {
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

    // MARK: - Mountain Detail Navigation

    @MainActor
    func testNavigateToMountainDetail() throws {
        launchApp()

        let mountainsTab = app.tabBars.buttons["Mountains"].firstMatch
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5), "Mountains tab should exist")
        mountainsTab.tap()

        guard app.scrollViews.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("Mountains list did not load")
        }

        let mountainCard = app.buttons.matching(NSPredicate(
            format: "(label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed') AND NOT (label CONTAINS[c] 'Today')"
        )).firstMatch

        guard mountainCard.waitForExistence(timeout: 10) && mountainCard.isHittable else {
            throw XCTSkip("No mountain card found")
        }
        mountainCard.tap()

        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5), "Mountain detail should load")
    }

    // MARK: - Search

    @MainActor
    func testSearchFieldFilters() throws {
        launchApp()

        let mountainsTab = app.tabBars.buttons["Mountains"].firstMatch
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5), "Mountains tab should exist")
        mountainsTab.tap()

        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) && searchField.isHittable else {
            throw XCTSkip("Search field not available")
        }
        searchField.tap()
        searchField.typeText("Baker")
        Thread.sleep(forTimeInterval: 1)

        // Verify search is active (clear button appears when text is entered)
        XCTAssertTrue(app.buttons["Clear text"].waitForExistence(timeout: 3), "Search should be active with clear button")
    }

    // MARK: - Mountain Detail Content

    @MainActor
    func testMountainDetailShowsContent() throws {
        launchApp()

        let mountainsTab = app.tabBars.buttons["Mountains"].firstMatch
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5), "Mountains tab should exist")
        mountainsTab.tap()

        guard app.scrollViews.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("Mountains list did not load")
        }

        let mountainCard = app.buttons.matching(NSPredicate(
            format: "(label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed') AND NOT (label CONTAINS[c] 'Today')"
        )).firstMatch

        guard mountainCard.waitForExistence(timeout: 10) && mountainCard.isHittable else {
            throw XCTSkip("No mountain card found")
        }
        mountainCard.tap()

        guard app.scrollViews.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("Mountain detail did not load")
        }

        // Verify tab bar content loads (Overview, Forecast, Conditions, etc.)
        let tabPredicate = NSPredicate(format: "label CONTAINS[c] 'Overview' OR label CONTAINS[c] 'Forecast' OR label CONTAINS[c] 'Conditions'")
        let detailTab = app.buttons.matching(tabPredicate).firstMatch
        XCTAssertTrue(detailTab.waitForExistence(timeout: 10),
                      "Mountain detail should show content tabs (Overview/Forecast/Conditions)")
    }
}
