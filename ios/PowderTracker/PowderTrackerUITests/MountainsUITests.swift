//
//  MountainsUITests.swift
//  PowderTrackerUITests
//
//  UI tests for Mountains functionality - focuses on critical user flows.
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

    @MainActor
    private func navigateToMountains() {
        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5), "Mountains tab should exist")
        mountainsTab.tap()
    }

    @MainActor
    private func tapFirstMountainCard() -> Bool {
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

        // Look for mountain cards with status indicators
        let mountainCardPredicate = NSPredicate(format: "(label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed') AND NOT (label CONTAINS[c] 'Today')")
        let mountainCard = app.buttons.matching(mountainCardPredicate).firstMatch

        if mountainCard.waitForExistence(timeout: 10) && mountainCard.isHittable {
            mountainCard.tap()
            return true
        }
        return false
    }

    // MARK: - Critical Flow Tests

    @MainActor
    func testMountainsTabLoadsContent() throws {
        launchApp()
        navigateToMountains()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Mountains view should load")
    }

    @MainActor
    func testNavigateToMountainDetail() throws {
        launchApp()
        navigateToMountains()
        Thread.sleep(forTimeInterval: 2)

        if tapFirstMountainCard() {
            let detailScrollView = app.scrollViews.firstMatch
            XCTAssertTrue(detailScrollView.waitForExistence(timeout: 5), "Mountain detail should load")
        }
    }

    @MainActor
    func testMountainDetailScrolling() throws {
        launchApp()
        navigateToMountains()
        Thread.sleep(forTimeInterval: 2)

        if tapFirstMountainCard() {
            let scrollView = app.scrollViews.firstMatch
            if scrollView.waitForExistence(timeout: 5) {
                scrollView.swipeUp()
                scrollView.swipeUp()
                scrollView.swipeDown()
            }
        }
    }

    @MainActor
    func testFavoriteToggle() throws {
        launchApp()
        navigateToMountains()
        Thread.sleep(forTimeInterval: 2)

        if tapFirstMountainCard() {
            Thread.sleep(forTimeInterval: 1)

            let favoriteButton = app.buttons["mountain_favorite_button"]
            if favoriteButton.waitForExistence(timeout: 3) && favoriteButton.isHittable {
                favoriteButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    @MainActor
    func testBackNavigationFromDetail() throws {
        launchApp()
        navigateToMountains()
        Thread.sleep(forTimeInterval: 2)

        if tapFirstMountainCard() {
            Thread.sleep(forTimeInterval: 1)

            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists && backButton.isHittable {
                backButton.tap()
                XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5), "Should return to list")
            }
        }
    }

    @MainActor
    func testSearchField() throws {
        launchApp()
        navigateToMountains()

        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 5) && searchField.isHittable {
            searchField.tap()
            searchField.typeText("Tahoe")
            Thread.sleep(forTimeInterval: 1)

            let clearButton = app.buttons["Clear text"]
            if clearButton.exists {
                clearButton.tap()
            }
        }
    }

    @MainActor
    func testPullToRefresh() throws {
        launchApp()
        navigateToMountains()

        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            start.press(forDuration: 0.1, thenDragTo: end)
            Thread.sleep(forTimeInterval: 2)
        }
    }
}
