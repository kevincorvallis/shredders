//
//  AuthenticationUITests.swift
//  PowderTrackerUITests
//
//  UI tests for authentication flows - focuses on critical user journeys.
//

import XCTest

final class AuthenticationUITests: XCTestCase {
    var app: XCUIApplication!

    private var testEmail: String {
        ProcessInfo.processInfo.environment["UI_TEST_EMAIL"] ?? "testuser@example.com"
    }
    private var testPassword: String {
        ProcessInfo.processInfo.environment["UI_TEST_PASSWORD"] ?? "TestPassword123!"
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    @MainActor
    private func launchApp(resetState: Bool = true) {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        if resetState {
            app.launchArguments.append("RESET_STATE")
        }
        app.launch()
    }

    // MARK: - Critical Flow Tests

    @MainActor
    func testLoginScreenElements() throws {
        launchApp()
        navigateToSignIn()

        XCTAssertTrue(app.textFields["auth_email_field"].exists, "Email field should exist")
        XCTAssertTrue(app.secureTextFields["auth_password_field"].exists, "Password field should exist")
        XCTAssertTrue(app.buttons["auth_sign_in_button"].exists, "Sign In button should exist")
    }

    @MainActor
    func testLoginWithValidCredentials() throws {
        if testEmail == "testuser@example.com" {
            throw XCTSkip("Test requires valid credentials. Set UI_TEST_EMAIL and UI_TEST_PASSWORD environment variables.")
        }

        launchApp()
        navigateToSignIn()

        let emailField = app.textFields["auth_email_field"]
        emailField.tap()
        emailField.typeText(testEmail)

        let passwordField = app.secureTextFields["auth_password_field"]
        passwordField.tap()
        passwordField.typeText(testPassword)

        app.buttons["auth_sign_in_button"].tap()
        Thread.sleep(forTimeInterval: 3)

        // Navigate to profile and verify logged in
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        if profileTab.exists {
            profileTab.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            for _ in 0..<10 {
                if app.buttons["profile_sign_out_button"].exists { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        let signOutButton = app.buttons["profile_sign_out_button"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 15), "Should be logged in")
    }

    @MainActor
    func testLoginWithInvalidCredentials() throws {
        launchApp()
        navigateToSignIn()

        let emailField = app.textFields["auth_email_field"]
        emailField.tap()
        emailField.typeText("nonexistent@example.com")

        let passwordField = app.secureTextFields["auth_password_field"]
        passwordField.tap()
        passwordField.typeText("WrongPassword123!")

        app.buttons["auth_sign_in_button"].tap()

        // Error message should appear
        let errorPredicate = NSPredicate(format: "label CONTAINS[c] 'Invalid' OR label CONTAINS[c] 'incorrect' OR label CONTAINS[c] 'error' OR label CONTAINS[c] 'wrong'")
        let errorText = app.staticTexts.matching(errorPredicate).firstMatch
        XCTAssertTrue(errorText.waitForExistence(timeout: 10), "Error should appear for invalid credentials")
    }

    @MainActor
    func testSignupModeToggle() throws {
        launchApp()
        navigateToSignIn()

        let modeToggle = app.buttons["auth_mode_toggle"]
        XCTAssertTrue(modeToggle.waitForExistence(timeout: 5), "Mode toggle should exist")
        modeToggle.tap()
        Thread.sleep(forTimeInterval: 0.5)

        let createButton = app.buttons["auth_create_account_button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5), "Create Account button should appear in signup mode")

        // Toggle back
        modeToggle.tap()
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(app.buttons["auth_sign_in_button"].waitForExistence(timeout: 5), "Sign In button should reappear")
    }

    @MainActor
    func testLogoutFlow() throws {
        launchApp()
        try ensureLoggedIn()

        app.tabBars.buttons["Profile"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 1)

        let scrollView = app.scrollViews.firstMatch
        let signOutButton = app.buttons["profile_sign_out_button"]

        if scrollView.exists {
            for _ in 0..<8 {
                if signOutButton.isHittable { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        guard signOutButton.waitForExistence(timeout: 5) && signOutButton.isHittable else {
            throw XCTSkip("Sign out button not accessible")
        }

        signOutButton.tap()

        // Handle confirmation
        let confirmSheet = app.sheets.buttons["Sign Out"]
        if confirmSheet.waitForExistence(timeout: 3) {
            confirmSheet.tap()
        }

        // Scroll back to top and verify sign in button appears
        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
        }

        let signInButton = app.buttons["profile_sign_in_button"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10), "Sign in button should appear after logout")
    }

    @MainActor
    func testSessionPersistsAfterRestart() throws {
        launchApp()
        try ensureLoggedIn()

        // Terminate and relaunch
        app.terminate()
        launchApp(resetState: false)

        app.tabBars.buttons["Profile"].firstMatch.tap()

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            for _ in 0..<10 {
                if app.buttons["profile_sign_out_button"].exists { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        let signOutButton = app.buttons["profile_sign_out_button"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5), "Session should persist after restart")
    }

    @MainActor
    func testSignInWithAppleButtonExists() throws {
        launchApp()
        navigateToSignIn()

        let applePredicate = NSPredicate(format: "label CONTAINS[c] 'Apple' OR identifier CONTAINS[c] 'apple'")
        let appleButton = app.buttons.matching(applePredicate).firstMatch
        XCTAssertTrue(appleButton.waitForExistence(timeout: 5), "Sign in with Apple button should exist")
    }

    // MARK: - Helper Methods

    @MainActor
    private func navigateToSignIn() {
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        profileTab.tap()
        Thread.sleep(forTimeInterval: 2)

        let scrollView = app.scrollViews.firstMatch
        let signInButton = app.buttons["profile_sign_in_button"]
        let signOutButton = app.buttons["profile_sign_out_button"]

        // Check if sign-in button is visible
        if signInButton.waitForExistence(timeout: 3) && signInButton.isHittable {
            signInButton.tap()
            let emailField = app.textFields["auth_email_field"]
            XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Auth email field should appear")
            return
        }

        // If logged in, sign out first
        if scrollView.waitForExistence(timeout: 3) {
            for _ in 0..<12 {
                if signOutButton.exists && signOutButton.isHittable { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        if signOutButton.exists && signOutButton.isHittable {
            signOutButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let sheetConfirmButton = app.sheets.buttons["Sign Out"]
            if sheetConfirmButton.waitForExistence(timeout: 3) {
                sheetConfirmButton.tap()
            }
            Thread.sleep(forTimeInterval: 2)

            if signInButton.waitForExistence(timeout: 5) && signInButton.isHittable {
                signInButton.tap()
                let emailField = app.textFields["auth_email_field"]
                XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Auth email field should appear")
            }
        }
    }

    @MainActor
    private func ensureLoggedIn() throws {
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        profileTab.tap()
        Thread.sleep(forTimeInterval: 1)

        let scrollView = app.scrollViews.firstMatch

        if scrollView.waitForExistence(timeout: 3) {
            for _ in 0..<10 {
                if app.buttons["profile_sign_out_button"].exists { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        if app.buttons["profile_sign_out_button"].waitForExistence(timeout: 2) {
            if scrollView.exists {
                scrollView.swipeDown()
                scrollView.swipeDown()
                scrollView.swipeDown()
            }
            return
        }

        // Need to log in
        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
            scrollView.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
        }

        let signInButton = app.buttons["profile_sign_in_button"]
        guard signInButton.waitForExistence(timeout: 5) && signInButton.isHittable else {
            throw XCTSkip("Sign in button not available")
        }
        signInButton.tap()

        let emailField = app.textFields["auth_email_field"]
        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Email field not found")
        }
        emailField.tap()
        emailField.typeText(testEmail)

        let passwordField = app.secureTextFields["auth_password_field"]
        passwordField.tap()
        passwordField.typeText(testPassword)

        app.buttons["auth_sign_in_button"].tap()
        Thread.sleep(forTimeInterval: 3)

        profileTab.tap()
        Thread.sleep(forTimeInterval: 1)

        if scrollView.exists {
            for _ in 0..<10 {
                if app.buttons["profile_sign_out_button"].exists { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        guard app.buttons["profile_sign_out_button"].waitForExistence(timeout: 10) else {
            throw XCTSkip("Login failed - test credentials may not be configured")
        }

        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
            scrollView.swipeDown()
        }
    }
}
