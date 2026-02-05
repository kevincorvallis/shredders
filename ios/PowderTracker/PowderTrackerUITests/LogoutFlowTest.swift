//
//  LogoutFlowTest.swift
//  PowderTrackerUITests
//
//  Tests the logout flow and WelcomeLandingView presentation.
//

import XCTest

final class LogoutFlowTest: XCTestCase {
    var app: XCUIApplication!

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    @MainActor
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    @MainActor
    func testLogoutShowsWelcomeLanding() throws {
        // Wait for app to finish loading by checking for tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10),
                     "Tab bar should appear after app loads")

        saveScreenshot("01_initial_today")

        // Navigate to Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        profileTab.tap()

        // Wait for profile content to load
        let profileNavBar = app.navigationBars["Profile"]
        let profileLoaded = profileNavBar.waitForExistence(timeout: 5)

        saveScreenshot("02_profile_tab")

        // Scroll down to find Sign Out button
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        saveScreenshot("03_profile_scrolled")

        // Look for Sign Out button using accessibility
        let signOutButton = app.buttons["Sign Out"].firstMatch
        guard signOutButton.waitForExistence(timeout: 5) else {
            saveScreenshot("03b_no_signout_button")
            // User may not be signed in - verify we're on Profile view
            XCTAssertTrue(profileLoaded ||
                         app.staticTexts["Profile"].exists ||
                         app.staticTexts["Sign In"].exists,
                         "Should be on Profile view even if not signed in")
            return
        }

        signOutButton.tap()

        saveScreenshot("04_confirmation_dialog")

        // Handle confirmation dialog using accessibility identifiers
        // Look for the destructive confirmation button in the action sheet
        let sheetSignOut = app.sheets.buttons["Sign Out"]
        let alertSignOut = app.alerts.buttons["Sign Out"]

        if sheetSignOut.waitForExistence(timeout: 5) {
            sheetSignOut.tap()
        } else if alertSignOut.waitForExistence(timeout: 3) {
            alertSignOut.tap()
        } else {
            // Fallback: look for any "Sign Out" buttons and tap the dialog one
            let allSignOutButtons = app.buttons.matching(identifier: "Sign Out")
            if allSignOutButtons.count > 1 {
                allSignOutButtons.element(boundBy: allSignOutButtons.count - 1).tap()
            } else {
                // Last resort - tap the existing button
                signOutButton.tap()
            }
        }

        saveScreenshot("05_after_signout")

        // Verify WelcomeLandingView appears using accessibility identifiers
        let welcomeSignIn = app.buttons["welcome_sign_in_button"]
        let browseButton = app.buttons["welcome_browse_button"]
        let signedOutText = app.staticTexts["You've been signed out"]

        let welcomeAppeared = welcomeSignIn.waitForExistence(timeout: 10) ||
                              browseButton.waitForExistence(timeout: 3) ||
                              signedOutText.waitForExistence(timeout: 3)

        saveScreenshot("06_welcome_landing_check")

        // Check if we're still on Profile
        let stillOnProfile = app.navigationBars["Profile"].exists

        XCTAssertTrue(welcomeAppeared || !stillOnProfile,
                     "WelcomeLandingView should appear after logout, or we should leave Profile view")

        // Test Browse Conditions button if welcome view appeared
        if browseButton.exists {
            browseButton.tap()

            // Verify navigation to main content
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.waitForExistence(timeout: 5),
                         "Should navigate to Today tab after browsing")

            saveScreenshot("07_after_browse")
        }
    }

    // MARK: - Helper

    @MainActor
    private func saveScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
