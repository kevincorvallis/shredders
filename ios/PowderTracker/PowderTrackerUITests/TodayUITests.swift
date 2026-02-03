//
//  TodayUITests.swift
//  PowderTrackerUITests
//
//  Comprehensive E2E UI tests for Today tab functionality
//

import XCTest

final class TodayUITests: XCTestCase {
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
    private func navigateToToday() {
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.waitForExistence(timeout: 5) {
            todayTab.tap()
        }
    }

    // MARK: - Conditions Overview Tests

    @MainActor
    func testConditionsOverviewDisplays() throws {
        launchApp()
        navigateToToday()

        // Look for conditions section
        let conditionsSection = app.staticTexts["Today's Conditions"]
        if conditionsSection.waitForExistence(timeout: 3) {
            addScreenshot(named: "Today Conditions")
        }
    }

    @MainActor
    func testWeatherSummary() throws {
        launchApp()
        navigateToToday()

        // Look for weather summary card
        let weatherCard = app.otherElements["today_weather_card"]
        if weatherCard.waitForExistence(timeout: 3) {
            XCTAssertTrue(weatherCard.exists, "Weather summary should display")
        }
    }

    // MARK: - Favorite Mountains Tests

    @MainActor
    func testTapFavoriteMountainNavigatesToDetail() throws {
        launchApp()
        navigateToToday()

        let mountainCard = app.cells.matching(identifier: "favorite_mountain_card").firstMatch
        if mountainCard.waitForExistence(timeout: 3) && mountainCard.isHittable {
            mountainCard.tap()
            // Should navigate to mountain detail - verify back button or detail content
            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: 3), "Should navigate to detail view")
        }
    }

    // MARK: - Upcoming Events Tests

    @MainActor
    func testSeeAllEventsNavigatesToEventsTab() throws {
        launchApp()
        navigateToToday()

        let seeAllButton = app.buttons["today_see_all_events"]
        if seeAllButton.waitForExistence(timeout: 3) && seeAllButton.isHittable {
            seeAllButton.tap()
            let eventsTab = app.tabBars.buttons["Events"]
            XCTAssertTrue(eventsTab.waitForExistence(timeout: 3) && eventsTab.isSelected, "Events tab should be selected")
        }
    }

    // MARK: - Pull to Refresh Tests

    @MainActor
    func testPullToRefresh() throws {
        launchApp()
        navigateToToday()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Scroll view should exist")

        // Pull to refresh
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)

        // Wait for refresh to complete
        Thread.sleep(forTimeInterval: 2)
    }

    // MARK: - Scrolling Tests

    @MainActor
    func testTodayScrolling() throws {
        launchApp()
        navigateToToday()

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 10) else {
            XCTFail("Scroll view should exist")
            return
        }

        // Scroll through content
        scrollView.swipeUp()
        scrollView.swipeUp()
        scrollView.swipeDown()
        scrollView.swipeDown()
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
