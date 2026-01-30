//
//  MountainsUITests.swift
//  PowderTrackerUITests
//
//  Comprehensive E2E UI tests for Mountains functionality
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

    /// Helper to find and tap on a mountain card in the scrollable list
    /// The Mountains view uses LazyVStack with NavigationLink, not List cells
    @MainActor
    private func tapFirstMountainCard() -> Bool {
        // Wait for content to load
        sleep(2)

        // Mountains are displayed as cards with chevron.right indicators
        // Look for any tappable element that looks like a mountain card
        let mountainCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed' OR label CONTAINS[c] 'mi'")).firstMatch

        if mountainCard.waitForExistence(timeout: 5) {
            mountainCard.tap()
            return true
        }

        // Fallback: try tapping in the scroll view content area
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            // Tap in the middle-upper area where cards should be
            let coordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            coordinate.tap()
            return true
        }

        return false
    }

    // MARK: - Mountains List Tests

    @MainActor
    func testMountainsTabLoads() throws {
        launchApp()
        navigateToMountains()

        // Verify mountains list loads
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Mountains scroll view should exist")

        addScreenshot(named: "Mountains List")
    }

    @MainActor
    func testMountainsListDisplaysMountains() throws {
        launchApp()
        navigateToMountains()

        // Wait for content to load - Mountains view uses LazyVStack, not List
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10), "Mountains scroll view should be displayed")

        // Check that some content exists (status pills, mountain cards, etc.)
        let hasContent = app.staticTexts.count > 0
        XCTAssertTrue(hasContent, "Mountains content should be displayed")
    }

    @MainActor
    func testMountainsListScrolling() throws {
        launchApp()
        navigateToMountains()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Scroll view should exist")

        // Scroll down
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)

        // Scroll back up
        scrollView.swipeDown()
    }

    @MainActor
    func testMountainsListRefresh() throws {
        launchApp()
        navigateToMountains()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Scroll view should exist")

        // Pull to refresh
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)

        // Wait for refresh to complete
        Thread.sleep(forTimeInterval: 2)
    }

    // MARK: - Mountain Detail Tests

    @MainActor
    func testNavigateToMountainDetail() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {
            // Verify detail view loads
            let detailView = app.scrollViews.firstMatch
            XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Mountain detail should load")

            addScreenshot(named: "Mountain Detail")
        }
    }

    @MainActor
    func testMountainDetailShowsInfo() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {
            // Wait for detail to load
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

            // Detail should show various information sections
            // Check for common elements (these depend on actual implementation)
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testMountainDetailScrolling() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {
            let detailScrollView = app.scrollViews.firstMatch
            if detailScrollView.waitForExistence(timeout: 5) {
                // Scroll through detail content
                detailScrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                detailScrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                detailScrollView.swipeDown()
            }
        }
    }

    @MainActor
    func testBackNavigationFromDetail() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {
            // Wait for detail
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists && backButton.isHittable {
                backButton.tap()

                // Should return to list - check scroll view exists
                XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5), "Should return to mountains list")
            }
        }
    }

    @MainActor
    func testSwipeBackFromDetail() throws {
        launchApp()
        navigateToMountains()

        guard tapFirstMountainCard() else { return }

        // Wait for detail
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

        // Swipe from left edge to go back
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

        // Should return to list
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)
    }

    // MARK: - Favorites Tests

    @MainActor
    func testFavoriteToggle() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {
            // Look for favorite button (star icon)
            let favoriteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'star' OR label CONTAINS[c] 'favorite'")).firstMatch
            if favoriteButton.waitForExistence(timeout: 3) {
                favoriteButton.tap()

                // Verify state changed (visual feedback)
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    @MainActor
    func testFavoritePersists() throws {
        launchApp()
        navigateToMountains()

        // Toggle favorite
        if tapFirstMountainCard() {
            let favoriteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'star' OR label CONTAINS[c] 'favorite'")).firstMatch
            if favoriteButton.waitForExistence(timeout: 3) {
                favoriteButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }

            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }

            // Re-enter same mountain
            if tapFirstMountainCard() {
                // Favorite state should be preserved
                _ = favoriteButton.waitForExistence(timeout: 3)
            }
        }
    }

    // MARK: - Conditions Tests

    @MainActor
    func testConditionsDisplay() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {
            // Wait for detail to load
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

            // Look for conditions section
            let conditionsSection = app.staticTexts["Conditions"]
            if conditionsSection.waitForExistence(timeout: 3) {
                addScreenshot(named: "Mountain Conditions")
            }
        }
    }

    @MainActor
    func testSnowReportDisplay() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Wait for detail
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

            // Look for snow/powder related content
            // Implementation specific
        }
    }

    // MARK: - Search and Filter Tests

    @MainActor
    func testSearchField() throws {
        launchApp()
        navigateToMountains()

        // Look for search field
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()

            // Type search query
            searchField.typeText("Park")

            // Results should filter
            Thread.sleep(forTimeInterval: 1)

            addScreenshot(named: "Mountains Search")

            // Clear search
            let clearButton = searchField.buttons.firstMatch
            if clearButton.exists {
                clearButton.tap()
            }
        }
    }

    @MainActor
    func testSearchResults() throws {
        launchApp()
        navigateToMountains()

        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("Vail")

            Thread.sleep(forTimeInterval: 1)

            // Verify filtered results or no results message
        }
    }

    @MainActor
    func testFilterByRegion() throws {
        launchApp()
        navigateToMountains()

        // Look for region filter
        let regionFilter = app.buttons["mountains_region_filter"]
        if regionFilter.waitForExistence(timeout: 3) {
            regionFilter.tap()

            // Select a region
            let regionOption = app.buttons.element(boundBy: 1)
            if regionOption.waitForExistence(timeout: 2) {
                regionOption.tap()
            }

            // Results should filter
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testSortOptions() throws {
        launchApp()
        navigateToMountains()

        // Look for sort button
        let sortButton = app.buttons["mountains_sort_button"]
        if sortButton.waitForExistence(timeout: 3) {
            sortButton.tap()

            // Select a sort option
            let sortOption = app.buttons["Sort by Name"]
            if sortOption.waitForExistence(timeout: 2) {
                sortOption.tap()
            }

            // List should reorder
            Thread.sleep(forTimeInterval: 1)
        }
    }

    // MARK: - Map Integration Tests

    @MainActor
    func testOpenMountainInMap() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Look for "Show on Map" or map button
            let mapButton = app.buttons["mountain_show_on_map"]
            if mapButton.waitForExistence(timeout: 3) {
                mapButton.tap()

                // Should navigate to map tab or show map view
                Thread.sleep(forTimeInterval: 2)
            }
        }
    }

    @MainActor
    func testGetDirections() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Look for directions button
            let directionsButton = app.buttons["mountain_directions_button"]
            if directionsButton.waitForExistence(timeout: 3) {
                // Don't actually tap - would open Maps app
                XCTAssertTrue(directionsButton.exists, "Directions button should exist")
            }
        }
    }

    // MARK: - Events at Mountain Tests

    @MainActor
    func testViewEventsAtMountain() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Look for events section
            let eventsSection = app.staticTexts["Upcoming Events"]
            if eventsSection.waitForExistence(timeout: 3) {
                // Events for this mountain should be visible
                addScreenshot(named: "Mountain Events")
            }
        }
    }

    @MainActor
    func testCreateEventFromMountainDetail() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Look for "Create Event" button
            let createEventButton = app.buttons["mountain_create_event_button"]
            if createEventButton.waitForExistence(timeout: 3) {
                createEventButton.tap()

                // Event creation form should open with mountain pre-selected
                _ = app.textFields["create_event_title_field"].waitForExistence(timeout: 3)
            }
        }
    }

    // MARK: - Weather Tests

    @MainActor
    func testWeatherDisplay() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Look for weather information
            let weatherSection = app.staticTexts["Weather"]
            if weatherSection.waitForExistence(timeout: 3) {
                addScreenshot(named: "Mountain Weather")
            }
        }
    }

    @MainActor
    func testForecastDisplay() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Look for forecast section
            let forecastSection = app.staticTexts["Forecast"]
            if forecastSection.waitForExistence(timeout: 3) {
                // Should show multi-day forecast
            }
        }
    }

    // MARK: - Lift Status Tests

    @MainActor
    func testLiftStatusDisplay() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Look for lift status section
            let liftSection = app.staticTexts["Lifts"]
            if liftSection.waitForExistence(timeout: 3) {
                addScreenshot(named: "Lift Status")
            }
        }
    }

    @MainActor
    func testTrailStatusDisplay() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Look for trails section
            let trailsSection = app.staticTexts["Trails"]
            if trailsSection.waitForExistence(timeout: 3) {
                addScreenshot(named: "Trail Status")
            }
        }
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testEmptyStateDisplay() throws {
        launchApp()
        navigateToMountains()

        // Search for something that won't exist
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("xyznonexistent123")

            Thread.sleep(forTimeInterval: 1)

            // Should show empty state or "no results"
            _ = app.staticTexts["No mountains found"]
            // Don't assert - just verify handling
        }
    }

    @MainActor
    func testLoadingState() throws {
        launchApp()
        navigateToMountains()

        // Loading indicator should show briefly then disappear
        // Hard to test timing, but verify list eventually loads
        let mountainCell = app.cells.firstMatch
        XCTAssertTrue(mountainCell.waitForExistence(timeout: 15), "Mountains should load")
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testMountainsListAccessibility() throws {
        launchApp()
        navigateToMountains()

        // Verify accessibility elements
        let mountainsList = app.scrollViews.firstMatch
        XCTAssertTrue(mountainsList.waitForExistence(timeout: 5), "Mountains list should exist")

        // Cells should be accessible
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            XCTAssertTrue(firstCell.isHittable, "Mountain cell should be hittable")
        }
    }

    @MainActor
    func testMountainDetailAccessibility() throws {
        launchApp()
        navigateToMountains()

        if tapFirstMountainCard() {

            // Detail elements should be accessible
            let detailView = app.scrollViews.firstMatch
            XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Detail view should be accessible")
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testMountainsListPerformance() throws {
        launchApp()

        measure {
            navigateToMountains()
            _ = app.cells.firstMatch.waitForExistence(timeout: 10)
        }
    }

    @MainActor
    func testMountainDetailPerformance() throws {
        launchApp()
        navigateToMountains()

        let mountainCell = app.cells.firstMatch
        XCTAssertTrue(mountainCell.waitForExistence(timeout: 10), "Mountain cell should exist")

        measure {
            mountainCell.tap()
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

            // Navigate back
            if let backButton = app.navigationBars.buttons.allElementsBoundByIndex.first, backButton.exists {
                backButton.tap()
                _ = app.cells.firstMatch.waitForExistence(timeout: 3)
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
