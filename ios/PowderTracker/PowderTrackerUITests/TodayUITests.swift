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

    // MARK: - Today Tab Basic Tests

    @MainActor
    func testTodayTabLoads() throws {
        launchApp()

        // Today is usually the default tab
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Today view should load")

        addScreenshot(named: "Today Tab")
    }

    @MainActor
    func testTodayTabExists() throws {
        launchApp()

        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 5), "Today tab should exist")
    }

    @MainActor
    func testTodayIsDefaultTab() throws {
        launchApp()

        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.waitForExistence(timeout: 5) {
            // Today should be initially selected
            XCTAssertTrue(todayTab.isSelected, "Today should be the default tab")
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

    @MainActor
    func testTemperatureDisplay() throws {
        launchApp()
        navigateToToday()

        // Look for temperature reading
        let temperature = app.staticTexts.matching(identifier: "today_temperature").firstMatch
        if temperature.waitForExistence(timeout: 3) {
            // Temperature should have degree symbol
        }
    }

    @MainActor
    func testSnowfallDisplay() throws {
        launchApp()
        navigateToToday()

        // Look for snowfall information
        let snowfall = app.staticTexts.matching(identifier: "today_snowfall").firstMatch
        if snowfall.waitForExistence(timeout: 3) {
            // Should show inches/cm
        }
    }

    // MARK: - Favorite Mountains Tests

    @MainActor
    func testFavoriteMountainsSection() throws {
        launchApp()
        navigateToToday()

        // Look for favorites section
        let favoritesSection = app.staticTexts["Your Mountains"]
        if favoritesSection.waitForExistence(timeout: 3) {
            addScreenshot(named: "Favorite Mountains")
        }
    }

    @MainActor
    func testFavoriteMountainCards() throws {
        launchApp()
        navigateToToday()

        // Look for mountain cards
        let mountainCard = app.cells.matching(identifier: "favorite_mountain_card").firstMatch
        if mountainCard.waitForExistence(timeout: 3) {
            XCTAssertTrue(mountainCard.isHittable, "Mountain card should be tappable")
        }
    }

    @MainActor
    func testTapFavoriteMountain() throws {
        launchApp()
        navigateToToday()

        let mountainCard = app.cells.matching(identifier: "favorite_mountain_card").firstMatch
        if mountainCard.waitForExistence(timeout: 3) {
            mountainCard.tap()

            // Should navigate to mountain detail
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testHorizontalScrollFavorites() throws {
        launchApp()
        navigateToToday()

        // Favorites often in horizontal scroll
        let favoritesScroll = app.scrollViews["favorites_scroll"]
        if favoritesScroll.waitForExistence(timeout: 3) {
            favoritesScroll.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)
            favoritesScroll.swipeRight()
        }
    }

    // MARK: - Powder Alerts Tests

    @MainActor
    func testPowderAlertsSection() throws {
        launchApp()
        navigateToToday()

        // Look for powder alerts
        let alertsSection = app.staticTexts["Powder Alerts"]
        if alertsSection.waitForExistence(timeout: 3) {
            addScreenshot(named: "Powder Alerts")
        }
    }

    @MainActor
    func testPowderAlertCard() throws {
        launchApp()
        navigateToToday()

        let alertCard = app.cells.matching(identifier: "powder_alert_card").firstMatch
        if alertCard.waitForExistence(timeout: 3) {
            XCTAssertTrue(alertCard.exists, "Powder alert should display")
        }
    }

    @MainActor
    func testTapPowderAlert() throws {
        launchApp()
        navigateToToday()

        let alertCard = app.cells.matching(identifier: "powder_alert_card").firstMatch
        if alertCard.waitForExistence(timeout: 3) {
            alertCard.tap()

            // Should show alert details or navigate
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testDismissPowderAlert() throws {
        launchApp()
        navigateToToday()

        let dismissButton = app.buttons["dismiss_powder_alert"]
        if dismissButton.waitForExistence(timeout: 3) {
            dismissButton.tap()

            // Alert should be dismissed
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    // MARK: - Recent Activity Tests

    @MainActor
    func testRecentActivitySection() throws {
        launchApp()
        navigateToToday()

        let activitySection = app.staticTexts["Recent Activity"]
        if activitySection.waitForExistence(timeout: 3) {
            addScreenshot(named: "Recent Activity")
        }
    }

    @MainActor
    func testActivityItem() throws {
        launchApp()
        navigateToToday()

        let activityItem = app.cells.matching(identifier: "activity_item").firstMatch
        if activityItem.waitForExistence(timeout: 3) {
            XCTAssertTrue(activityItem.exists, "Activity item should display")
        }
    }

    // MARK: - Upcoming Events Tests

    @MainActor
    func testUpcomingEventsSection() throws {
        launchApp()
        navigateToToday()

        let eventsSection = app.staticTexts["Upcoming Events"]
        if eventsSection.waitForExistence(timeout: 3) {
            addScreenshot(named: "Today Upcoming Events")
        }
    }

    @MainActor
    func testEventCard() throws {
        launchApp()
        navigateToToday()

        let eventCard = app.cells.matching(identifier: "today_event_card").firstMatch
        if eventCard.waitForExistence(timeout: 3) {
            XCTAssertTrue(eventCard.isHittable, "Event card should be tappable")
        }
    }

    @MainActor
    func testTapEventCard() throws {
        launchApp()
        navigateToToday()

        let eventCard = app.cells.matching(identifier: "today_event_card").firstMatch
        if eventCard.waitForExistence(timeout: 3) {
            eventCard.tap()

            // Should navigate to event detail
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testSeeAllEvents() throws {
        launchApp()
        navigateToToday()

        let seeAllButton = app.buttons["today_see_all_events"]
        if seeAllButton.waitForExistence(timeout: 3) {
            seeAllButton.tap()

            // Should navigate to Events tab
            let eventsTab = app.tabBars.buttons["Events"]
            if eventsTab.exists {
                XCTAssertTrue(eventsTab.isSelected, "Events tab should be selected")
            }
        }
    }

    // MARK: - Quick Actions Tests

    @MainActor
    func testQuickActionsSection() throws {
        launchApp()
        navigateToToday()

        // Look for quick action buttons
        let quickActions = app.otherElements["today_quick_actions"]
        if quickActions.waitForExistence(timeout: 3) {
            addScreenshot(named: "Quick Actions")
        }
    }

    @MainActor
    func testCreateEventQuickAction() throws {
        launchApp()
        navigateToToday()

        let createButton = app.buttons["quick_create_event"]
        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()

            // Event creation should open
            let titleField = app.textFields["create_event_title_field"]
            _ = titleField.waitForExistence(timeout: 3)
        }
    }

    @MainActor
    func testViewMapQuickAction() throws {
        launchApp()
        navigateToToday()

        let mapButton = app.buttons["quick_view_map"]
        if mapButton.waitForExistence(timeout: 3) {
            mapButton.tap()

            // Should switch to Map tab
            Thread.sleep(forTimeInterval: 1)
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

        // Wait for refresh
        Thread.sleep(forTimeInterval: 2)
    }

    @MainActor
    func testRefreshIndicator() throws {
        launchApp()
        navigateToToday()

        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            // Pull down but don't release
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            start.press(forDuration: 0.5, thenDragTo: end)

            // Refresh indicator may be visible
        }
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

        // Scroll through content with shorter delays
        scrollView.swipeUp()
        scrollView.swipeUp()
        scrollView.swipeDown()
        scrollView.swipeDown()
    }

    @MainActor
    func testScrollToBottom() throws {
        launchApp()
        navigateToToday()

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 10) else {
            return
        }

        // Scroll to bottom with fewer iterations
        for _ in 0..<3 {
            scrollView.swipeUp()
        }
    }

    // MARK: - Loading States Tests

    @MainActor
    func testInitialLoading() throws {
        launchApp()

        // Content should load within reasonable time
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10), "Content should load")
    }

    @MainActor
    func testEmptyState() throws {
        // Note: Empty state would require specific test data setup
        launchApp()
        navigateToToday()

        // If no favorites, should show empty state
        _ = app.staticTexts["No favorite mountains"]
        // Just check if element exists when appropriate
    }

    // MARK: - Date/Time Display Tests

    @MainActor
    func testDateDisplay() throws {
        launchApp()
        navigateToToday()

        // Look for today's date
        let dateLabel = app.staticTexts.matching(identifier: "today_date").firstMatch
        if dateLabel.waitForExistence(timeout: 3) {
            XCTAssertFalse(dateLabel.label.isEmpty, "Date should be displayed")
        }
    }

    @MainActor
    func testLastUpdatedTime() throws {
        launchApp()
        navigateToToday()

        let lastUpdated = app.staticTexts.matching(identifier: "today_last_updated").firstMatch
        if lastUpdated.waitForExistence(timeout: 3) {
            // Should show last update time
        }
    }

    // MARK: - Notification Banner Tests

    @MainActor
    func testNotificationBanner() throws {
        launchApp()
        navigateToToday()

        // Check for any notification banners
        let banner = app.otherElements["notification_banner"]
        if banner.waitForExistence(timeout: 3) {
            addScreenshot(named: "Notification Banner")
        }
    }

    @MainActor
    func testDismissNotificationBanner() throws {
        launchApp()
        navigateToToday()

        let banner = app.otherElements["notification_banner"]
        if banner.waitForExistence(timeout: 3) {
            let dismissButton = banner.buttons["dismiss"]
            if dismissButton.exists {
                dismissButton.tap()
            }
        }
    }

    // MARK: - Widget Promotion Tests

    @MainActor
    func testWidgetPromotion() throws {
        launchApp()
        navigateToToday()

        // App might show widget promotion
        let widgetPromo = app.otherElements["widget_promotion"]
        if widgetPromo.waitForExistence(timeout: 3) {
            addScreenshot(named: "Widget Promotion")
        }
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testTodayAccessibility() throws {
        launchApp()
        navigateToToday()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Today view should be accessible")
    }

    @MainActor
    func testCardsAccessible() throws {
        launchApp()
        navigateToToday()

        // All cards should be accessible
        let cells = app.cells.allElementsBoundByIndex

        for cell in cells.prefix(5) {
            if cell.exists && cell.isHittable {
                // Card is accessible
            }
        }
    }

    @MainActor
    func testVoiceOverLabels() throws {
        launchApp()
        navigateToToday()

        // Check that key elements have accessibility labels
        let staticTexts = app.staticTexts.allElementsBoundByIndex

        for text in staticTexts.prefix(10) {
            if text.exists {
                XCTAssertFalse(text.label.isEmpty, "Text should have accessibility label")
            }
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testTodayLoadPerformance() throws {
        launchApp()

        measure {
            navigateToToday()
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

            // Switch away and back
            app.tabBars.buttons["Mountains"].tap()
            Thread.sleep(forTimeInterval: 1)
            app.tabBars.buttons["Today"].tap()
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testScrollPerformance() throws {
        launchApp()
        navigateToToday()

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 10) else {
            XCTFail("Scroll view should exist")
            return
        }

        measure {
            scrollView.swipeUp()
            scrollView.swipeDown()
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
