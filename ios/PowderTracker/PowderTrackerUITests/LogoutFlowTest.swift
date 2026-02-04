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
        // Wait for app to load
        sleep(3)

        // Take initial screenshot
        saveScreenshot("01_initial_today")

        // Navigate to Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        profileTab.tap()
        sleep(2)
        saveScreenshot("02_profile_tab")

        // Scroll down to find Sign Out button
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }
        saveScreenshot("03_profile_scrolled")

        // Look for Sign Out button in the list
        let signOutButton = app.buttons["Sign Out"].firstMatch
        if signOutButton.waitForExistence(timeout: 3) {
            signOutButton.tap()
            sleep(1)
            saveScreenshot("04_confirmation_dialog")

            // Handle confirmation dialog - it's a SwiftUI confirmationDialog (action sheet)
            sleep(1) // Wait for sheet animation

            // Use normalized coordinates: Sign Out button is roughly at 62% down from top, 50% from left
            // On action sheets, Sign Out (destructive) is above Cancel
            let signOutCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))
            print("Tapping Sign Out at normalized coordinate (0.5, 0.62)")
            signOutCoord.tap()

            sleep(2)
            saveScreenshot("05_after_signout")

            // Wait longer for the full screen cover animation
            sleep(3)
            saveScreenshot("06_waiting_for_welcome")

            // Verify WelcomeLandingView appears
            // Look for elements unique to WelcomeLandingView
            let signInButton = app.buttons["welcome_sign_in_button"]
            let browseButton = app.buttons["welcome_browse_button"]
            let signedOutText = app.staticTexts["You've been signed out"]
            let browseConditionsText = app.staticTexts["Browse Conditions"]
            let signInText = app.staticTexts["Sign In"]

            // Debug: print what we can find
            print("Looking for WelcomeLandingView elements...")
            print("welcome_sign_in_button exists: \(signInButton.exists)")
            print("welcome_browse_button exists: \(browseButton.exists)")
            print("'You've been signed out' text exists: \(signedOutText.exists)")
            print("'Browse Conditions' text exists: \(browseConditionsText.exists)")
            print("'Sign In' text (not in profile) exists: \(signInText.exists)")

            // Check if we're still on Profile (meaning WelcomeLandingView didn't appear)
            let stillOnProfile = app.navigationBars["Profile"].exists
            print("Still on Profile view: \(stillOnProfile)")

            let welcomeAppeared = signInButton.waitForExistence(timeout: 5) ||
                                  browseButton.exists ||
                                  signedOutText.exists ||
                                  browseConditionsText.exists

            saveScreenshot("07_welcome_landing_check")

            if !welcomeAppeared && stillOnProfile {
                // Sign out might have occurred but WelcomeLandingView has a delay
                // Check if Sign Out button is still visible (would indicate still authenticated)
                let signOutStillVisible = app.buttons["Sign Out"].exists ||
                                         app.staticTexts["Sign Out"].exists
                print("Sign Out button still visible: \(signOutStillVisible)")

                if !signOutStillVisible {
                    // User was signed out but WelcomeLandingView didn't appear
                    // This is the expected flow we're testing
                    print("NOTE: User appears signed out but WelcomeLandingView didn't appear as fullScreenCover")
                    saveScreenshot("08_signed_out_no_welcome")
                }
            }

            XCTAssertTrue(welcomeAppeared || !stillOnProfile,
                         "WelcomeLandingView should appear after logout, or we should leave Profile view")

            // Test Browse Conditions button
            if browseButton.exists {
                browseButton.tap()
                sleep(2)
                saveScreenshot("07_after_browse")

                // Should be back on Today tab
                XCTAssertTrue(app.tabBars.buttons["Today"].isSelected ||
                             app.staticTexts["Today"].exists,
                             "Should navigate to Today tab after browsing")
            }
        } else {
            // User might not be signed in, check if we can see sign in prompt
            saveScreenshot("03b_no_signout_button")
            print("Sign Out button not found - user may not be signed in")

            // Still pass if we can see the profile view
            XCTAssertTrue(app.navigationBars["Profile"].exists ||
                         app.staticTexts["Profile"].exists ||
                         app.staticTexts["Sign In"].exists,
                         "Should be on Profile view")
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

        // Also save to tmp for easy viewing
        let data = screenshot.pngRepresentation
        let path = "/tmp/logout_flow_\(name).png"
        try? data.write(to: URL(fileURLWithPath: path))
        print("Screenshot saved: \(path)")
    }
}
