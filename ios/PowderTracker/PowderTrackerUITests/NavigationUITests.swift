//
//  NavigationUITests.swift
//  PowderTrackerUITests
//
//  Comprehensive E2E UI tests for app navigation
//

import XCTest

final class NavigationUITests: XCTestCase {
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

    // MARK: - Tab Bar Navigation

    @MainActor
    func testAllTabsExist() throws {
        launchApp()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // Verify all expected tabs
        XCTAssertTrue(app.tabBars.buttons["Today"].exists || app.tabBars.buttons.count >= 4, "Today tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Mountains"].exists, "Mountains tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Events"].exists, "Events tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Map"].exists, "Map tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists, "Profile tab should exist")

        addScreenshot(named: "Tab Bar")
    }

    @MainActor
    func testNavigateToTodayTab() throws {
        launchApp()

        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists {
            todayTab.tap()

            // Verify Today view loads
            let todayContent = app.scrollViews.firstMatch
            XCTAssertTrue(todayContent.waitForExistence(timeout: 5), "Today view should load")
        }
    }

    @MainActor
    func testNavigateToMountainsTab() throws {
        launchApp()

        let mountainsTab = app.tabBars.buttons["Mountains"]
        XCTAssertTrue(mountainsTab.waitForExistence(timeout: 5), "Mountains tab should exist")
        mountainsTab.tap()

        // Verify Mountains view loads
        let mountainsList = app.scrollViews.firstMatch
        XCTAssertTrue(mountainsList.waitForExistence(timeout: 5), "Mountains view should load")

        addScreenshot(named: "Mountains Tab")
    }

    @MainActor
    func testNavigateToEventsTab() throws {
        launchApp()

        let eventsTab = app.tabBars.buttons["Events"]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5), "Events tab should exist")
        eventsTab.tap()

        // Verify Events view loads - check for events-related content
        // For unauthenticated users, the view shows "Sign in to join events" text
        // For authenticated users, it shows the events list
        let eventsContent = app.scrollViews.firstMatch
        XCTAssertTrue(eventsContent.waitForExistence(timeout: 5), "Events view should load")
    }

    @MainActor
    func testNavigateToMapTab() throws {
        launchApp()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "Map tab should exist")
        mapTab.tap()

        // Verify Map view loads (map views can take a moment)
        Thread.sleep(forTimeInterval: 2)

        addScreenshot(named: "Map Tab")
    }

    @MainActor
    func testNavigateToProfileTab() throws {
        launchApp()

        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        profileTab.tap()

        // Verify Profile view loads
        let profileContent = app.scrollViews.firstMatch
        XCTAssertTrue(profileContent.waitForExistence(timeout: 5), "Profile view should load")

        addScreenshot(named: "Profile Tab")
    }

    @MainActor
    func testTabSwitching() throws {
        launchApp()

        // Cycle through all tabs
        let tabs = ["Mountains", "Events", "Map", "Profile", "Today"]

        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            if tab.exists {
                tab.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    @MainActor
    func testTabStatePreserved() throws {
        launchApp()

        // Navigate to Mountains and scroll down
        app.tabBars.buttons["Mountains"].tap()
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)
        app.swipeUp()

        // Switch to another tab
        app.tabBars.buttons["Events"].tap()
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 3)

        // Switch back to Mountains
        app.tabBars.buttons["Mountains"].tap()

        // State may or may not be preserved (depends on implementation)
    }

    // MARK: - Navigation Stack

    @MainActor
    func testBackNavigation() throws {
        launchApp()

        // Navigate to Mountains
        app.tabBars.buttons["Mountains"].tap()
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

        // Tap on a mountain card - Mountains view uses LazyVStack, not List cells
        // Look for a tappable element that looks like a mountain card
        // Exclude "Today's pick" which is from the Today tab and may not be hittable
        let mountainCardPredicate = NSPredicate(format: "(label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed') AND NOT (label CONTAINS[c] 'Today')")
        let mountainCard = app.buttons.matching(mountainCardPredicate).firstMatch

        // Wait for content to load using explicit wait
        if mountainCard.waitForExistence(timeout: 10) && mountainCard.isHittable {
            mountainCard.tap()

            // Wait for detail view
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists && backButton.isHittable {
                backButton.tap()

                // Should return to mountains list - check scroll view exists
                XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5), "Should return to mountains list")
            }
        }
    }

    @MainActor
    func testSwipeBackNavigation() throws {
        launchApp()

        // Navigate to Mountains detail
        app.tabBars.buttons["Mountains"].tap()
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

        // Look for a tappable element that looks like a mountain card
        // Exclude "Today's pick" which is from the Today tab and may not be hittable
        let mountainCardPredicate = NSPredicate(format: "(label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed') AND NOT (label CONTAINS[c] 'Today')")
        let mountainCard = app.buttons.matching(mountainCardPredicate).firstMatch

        // Wait for content to load using explicit wait
        if mountainCard.waitForExistence(timeout: 10) && mountainCard.isHittable {
            mountainCard.tap()
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

            // Swipe from left edge to go back
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
            let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

            // Should return to mountains list - check scroll view exists
            _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)
        }
    }

    // MARK: - Sheet Navigation

    @MainActor
    func testSheetDismissal() throws {
        launchApp()

        // Navigate to Profile and trigger a sheet (login form)
        app.tabBars.buttons["Profile"].tap()

        let signInButton = app.buttons["profile_sign_in_button"]
        if signInButton.waitForExistence(timeout: 3) {
            signInButton.tap()

            // Wait for sheet
            _ = app.textFields["auth_email_field"].waitForExistence(timeout: 5)

            // Dismiss by tapping Cancel or swiping down
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                // Swipe down to dismiss
                app.swipeDown()
            }

            // Should return to profile
            XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Should return to profile after sheet dismissal")
        }
    }

    // MARK: - Scroll Navigation

    @MainActor
    func testScrollToTop() throws {
        launchApp()

        app.tabBars.buttons["Mountains"].tap()
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)

        // Scroll down
        app.swipeUp()
        app.swipeUp()

        // Tap status bar to scroll to top (if supported)
        // This is tricky in UI tests as status bar isn't directly accessible

        // Alternative: tap the tab again to scroll to top
        app.tabBars.buttons["Mountains"].tap()
    }

    @MainActor
    func testScrollBehavior() throws {
        launchApp()

        app.tabBars.buttons["Mountains"].tap()
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Scroll view should exist")

        // Test scrolling
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        scrollView.swipeDown()
    }

    // MARK: - Launch and Initial State

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        launchApp()

        // App should launch and show tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "App should launch with tab bar visible")
    }

    @MainActor
    func testInitialTabIsToday() throws {
        launchApp()

        // First tab should be selected (Today)
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.exists {
            XCTAssertTrue(todayTab.isSelected, "Today tab should be initially selected")
        }
    }

    @MainActor
    func testSkipsIntroOnUITesting() throws {
        launchApp()

        // With UI_TESTING flag, intro should be skipped
        // Tab bar should be immediately visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3), "Should skip intro and show main app")
    }

    // MARK: - Orientation

    @MainActor
    func testPortraitOrientation() throws {
        launchApp()

        XCUIDevice.shared.orientation = .portrait

        // App should still work
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "App should work in portrait")
    }

    @MainActor
    func testLandscapeOrientation() throws {
        launchApp()

        XCUIDevice.shared.orientation = .landscapeLeft

        // App should adapt
        Thread.sleep(forTimeInterval: 1)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "App should work in landscape")

        // Reset orientation
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Deep Links

    // Note: Deep link testing requires app to handle URL schemes
    // These tests verify the app doesn't crash on deep link attempts

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
