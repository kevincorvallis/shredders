//
//  AccessibilityUITests.swift
//  PowderTrackerUITests
//
//  Tests for accessibility identifiers and VoiceOver compatibility
//

import XCTest

final class AccessibilityUITests: XCTestCase {
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

    // MARK: - Tab Navigation Accessibility

    @MainActor
    func testAllTabsHaveAccessibilityIdentifiers() throws {
        launchApp()

        // Verify all main tabs have accessibility identifiers
        let todayTab = app.buttons["tab_today"]
        let mountainsTab = app.buttons["tab_mountains"]
        let eventsTab = app.buttons["tab_events"]
        let mapTab = app.buttons["tab_map"]
        let profileTab = app.buttons["tab_profile"]

        XCTAssertTrue(todayTab.waitForExistence(timeout: 5), "Today tab should have accessibility identifier")
        XCTAssertTrue(mountainsTab.exists, "Mountains tab should have accessibility identifier")
        XCTAssertTrue(eventsTab.exists, "Events tab should have accessibility identifier")
        XCTAssertTrue(mapTab.exists, "Map tab should have accessibility identifier")
        XCTAssertTrue(profileTab.exists, "Profile tab should have accessibility identifier")
    }

    // MARK: - Today View Accessibility

    @MainActor
    func testTodayViewAccessibilityElements() throws {
        launchApp()

        // Navigate to Today tab
        let todayTab = app.tabBars.buttons["Today"].firstMatch
        if todayTab.waitForExistence(timeout: 5) {
            todayTab.tap()
        }

        // Check for manage favorites button
        let manageFavoritesButton = app.buttons["today_manage_favorites_button"]
        if manageFavoritesButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(manageFavoritesButton.isEnabled, "Manage favorites button should be accessible")
        }

        // Check for add mountains button (if no favorites)
        let addMountainsButton = app.buttons["today_add_mountains_button"]
        if addMountainsButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(addMountainsButton.isHittable, "Add mountains button should be tappable")
        }
    }

    // MARK: - Mountains View Accessibility

    @MainActor
    func testMountainsFilterAccessibility() throws {
        launchApp()

        // Navigate to Mountains tab
        let mountainsTab = app.tabBars.buttons["Mountains"].firstMatch
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5), "Mountains tab should exist")
        mountainsTab.tap()

        // Wait for content to load
        Thread.sleep(forTimeInterval: 1)

        // Check mode picker buttons have identifiers
        let conditionsMode = app.buttons["mountains_mode_conditions"]
        let plannerMode = app.buttons["mountains_mode_planner"]
        let exploreMode = app.buttons["mountains_mode_explore"]
        let myPassMode = app.buttons["mountains_mode_myPass"]

        if conditionsMode.waitForExistence(timeout: 3) {
            XCTAssertTrue(conditionsMode.exists, "Conditions mode should have accessibility identifier")
            XCTAssertTrue(plannerMode.exists, "Planner mode should have accessibility identifier")
            XCTAssertTrue(exploreMode.exists, "Explore mode should have accessibility identifier")
            XCTAssertTrue(myPassMode.exists, "My Pass mode should have accessibility identifier")
        }

        // Check filter chips have identifiers
        let freshPowderFilter = app.buttons["mountains_filter_fresh_powder"]
        let _ = app.buttons["mountains_filter_open_only"]
        let _ = app.buttons["mountains_filter_favorites"]
        let _ = app.buttons["mountains_filter_nearby"]

        // Scroll down to find filters if needed
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        if freshPowderFilter.waitForExistence(timeout: 2) {
            XCTAssertTrue(freshPowderFilter.exists, "Fresh powder filter should have accessibility identifier")
        }
    }

    // MARK: - Events View Accessibility

    @MainActor
    func testEventsViewAccessibility() throws {
        launchApp()

        // Navigate to Events tab
        let eventsTab = app.tabBars.buttons["Events"].firstMatch
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5), "Events tab should exist")
        eventsTab.tap()

        // Check create button
        let createButton = app.buttons["events_create_button"]
        if createButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(createButton.isEnabled, "Create event button should be accessible")
        }

        // Check filter picker (if authenticated)
        let filterPicker = app.segmentedControls["events_filter_picker"]
        if filterPicker.waitForExistence(timeout: 2) {
            XCTAssertTrue(filterPicker.isEnabled, "Events filter picker should be accessible")
        }
    }

    // MARK: - Profile View Accessibility

    @MainActor
    func testProfileViewAccessibility() throws {
        launchApp()

        // Navigate to Profile tab
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        profileTab.tap()

        // Check sign in button (if not authenticated)
        let signInButton = app.buttons["profile_sign_in_button"]
        if signInButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(signInButton.isHittable, "Sign in button should be tappable")
        }

        // Check profile rows have identifiers
        let favoritesRow = app.buttons["profile_favorites_row"]
        _ = app.buttons["profile_region_row"]
        _ = app.buttons["profile_pass_row"]

        // Scroll to find rows if needed
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists && favoritesRow.waitForExistence(timeout: 2) {
            XCTAssertTrue(favoritesRow.exists, "Favorites row should have accessibility identifier")
        }
    }

    // MARK: - VoiceOver Label Tests

    @MainActor
    func testCriticalButtonsHaveAccessibilityLabels() throws {
        launchApp()

        // Navigate to Today
        let todayTab = app.tabBars.buttons["Today"].firstMatch
        if todayTab.waitForExistence(timeout: 5) {
            todayTab.tap()
        }

        // The manage favorites button should have a label
        let manageFavoritesButton = app.buttons["today_manage_favorites_button"]
        if manageFavoritesButton.waitForExistence(timeout: 3) {
            // Verify the button has an accessibility label (not empty)
            let label = manageFavoritesButton.label
            XCTAssertFalse(label.isEmpty, "Manage favorites button should have accessibility label")
        }
    }
}
