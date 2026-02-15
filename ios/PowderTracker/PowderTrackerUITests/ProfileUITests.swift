//
//  ProfileUITests.swift
//  PowderTrackerUITests
//
//  Tests for profile sign-in and sign-out flows.
//

import XCTest

final class ProfileUITests: XCTestCase {
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

    // MARK: - Sign In

    @MainActor
    func testSignInButtonOpensAuthSheet() throws {
        launchApp()
        UITestHelper.navigateToProfile(app: app)

        let signInButton = app.buttons["profile_sign_in_button"]
        guard signInButton.waitForExistence(timeout: 3) && signInButton.isHittable else {
            throw XCTSkip("Sign in button not available (user may be logged in)")
        }
        signInButton.tap()

        XCTAssertTrue(app.textFields["auth_email_field"].waitForExistence(timeout: 5), "Auth sheet should open with email field")
    }

    // MARK: - Sign Out

    @MainActor
    func testSignOutFlow() throws {
        launchApp()
        UITestHelper.navigateToProfile(app: app)

        let scrollView = app.scrollViews.firstMatch
        let signOutButton = app.buttons["profile_sign_out_button"]

        if scrollView.exists {
            for _ in 0..<10 {
                if signOutButton.exists && signOutButton.isHittable { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        guard signOutButton.waitForExistence(timeout: 3) && signOutButton.isHittable else {
            throw XCTSkip("Sign out button not found (user may not be logged in)")
        }
        signOutButton.tap()

        let confirmButton = app.sheets.buttons["Sign Out"]
        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
        }

        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
        }

        XCTAssertTrue(app.buttons["profile_sign_in_button"].waitForExistence(timeout: 5), "Sign in button should appear after logout")
    }
}
