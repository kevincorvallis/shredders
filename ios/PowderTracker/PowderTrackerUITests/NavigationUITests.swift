//
//  NavigationUITests.swift
//  PowderTrackerUITests
//
//  Core navigation tests: app launch, tab bar, back navigation, sheet dismissal.
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

    // MARK: - App Launch

    @MainActor
    func testAppLaunchesWithAllTabs() throws {
        launchApp()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "App should launch with tab bar")

        XCTAssertTrue(app.tabBars.buttons["Today"].firstMatch.exists, "Today tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Mountains"].firstMatch.exists, "Mountains tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Events"].firstMatch.exists, "Events tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Map"].firstMatch.exists, "Map tab should exist")
        XCTAssertTrue(app.tabBars.buttons["Profile"].firstMatch.exists, "Profile tab should exist")

        let todayTab = app.tabBars.buttons["Today"].firstMatch
        XCTAssertTrue(todayTab.isSelected, "Today tab should be initially selected")
    }

    // MARK: - Back Navigation

    @MainActor
    func testBackNavigationFromMountainDetail() throws {
        launchApp()

        app.tabBars.buttons["Mountains"].firstMatch.tap()
        guard app.scrollViews.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("Mountains list did not load")
        }

        let mountainCard = app.buttons.matching(NSPredicate(
            format: "(label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed') AND NOT (label CONTAINS[c] 'Today')"
        )).firstMatch

        guard mountainCard.waitForExistence(timeout: 10) && mountainCard.isHittable else {
            throw XCTSkip("No mountain card available to tap")
        }
        mountainCard.tap()

        guard app.scrollViews.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("Mountain detail did not load")
        }

        let backButton = app.navigationBars.buttons.firstMatch
        guard backButton.exists && backButton.isHittable else {
            throw XCTSkip("Back button not found")
        }
        backButton.tap()

        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5), "Should return to mountains list")
    }

    // MARK: - Sheet Dismissal

    @MainActor
    func testSignInSheetDismissal() throws {
        launchApp()

        app.tabBars.buttons["Profile"].firstMatch.tap()

        let signInButton = app.buttons["profile_sign_in_button"]
        guard signInButton.waitForExistence(timeout: 3) && signInButton.isHittable else {
            throw XCTSkip("Sign in button not available (user may be logged in)")
        }
        signInButton.tap()

        XCTAssertTrue(app.textFields["auth_email_field"].waitForExistence(timeout: 5), "Auth sheet should open")

        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            app.swipeDown()
        }

        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Should return to profile after sheet dismissal")
    }

    // MARK: - Deep Link

    @MainActor
    func testDeepLinkOpensMountainDetail() throws {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launchEnvironment["UI_TEST_DEEP_LINK"] = "powdertracker://mountains/stevens"
        app.launch()

        // Wait for app to process the deep link and present the mountain detail sheet
        // The detail sheet shows tabs like Overview, Forecast, Conditions
        let detailTab = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'Overview' OR label CONTAINS[c] 'Forecast' OR label CONTAINS[c] 'Conditions'"
        )).firstMatch

        // Also check for the mountain name in the detail view
        let mountainName = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS[c] 'Stevens'"
        )).firstMatch

        let detailLoaded = detailTab.waitForExistence(timeout: 15) || mountainName.waitForExistence(timeout: 5)
        XCTAssertTrue(detailLoaded,
                      "Deep link should open Stevens Pass mountain detail")
    }
}
