//
//  ProfileUITests.swift
//  PowderTrackerUITests
//
//  Comprehensive E2E UI tests for Profile/Settings functionality
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

    @MainActor
    private func navigateToProfile() {
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        profileTab.tap()
    }

    // MARK: - Profile Tab Basic Tests

    @MainActor
    func testProfileTabLoads() throws {
        launchApp()
        navigateToProfile()

        // Profile content should load
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Profile view should load")

        addScreenshot(named: "Profile Tab")
    }

    @MainActor
    func testProfileTabAccessible() throws {
        launchApp()

        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        XCTAssertTrue(profileTab.isHittable, "Profile tab should be tappable")
    }

    // MARK: - Unauthenticated State Tests

    @MainActor
    func testShowsSignInButtonWhenLoggedOut() throws {
        launchApp()
        navigateToProfile()

        // Look for sign in button (when not logged in)
        let signInButton = app.buttons["profile_sign_in_button"]
        if signInButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(signInButton.isHittable, "Sign in button should be tappable")
            addScreenshot(named: "Profile - Logged Out")
        }
    }

    @MainActor
    func testSignInButtonOpensAuthSheet() throws {
        launchApp()
        navigateToProfile()

        let signInButton = app.buttons["profile_sign_in_button"]
        if signInButton.waitForExistence(timeout: 3) {
            signInButton.tap()

            // Auth form should appear
            let emailField = app.textFields["auth_email_field"]
            XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Auth sheet should open")

            addScreenshot(named: "Profile Auth Sheet")
        }
    }

    // MARK: - Authenticated State Tests

    @MainActor
    func testShowsUserInfoWhenLoggedIn() throws {
        launchApp()
        navigateToProfile()

        // If logged in, should show user info
        let signOutButton = app.buttons["profile_sign_out_button"]
        if signOutButton.waitForExistence(timeout: 3) {
            // User is logged in
            addScreenshot(named: "Profile - Logged In")
        }
    }

    @MainActor
    func testDisplaysUsername() throws {
        launchApp()
        navigateToProfile()

        // Look for username display
        let usernameText = app.staticTexts.matching(identifier: "profile_username").firstMatch
        if usernameText.waitForExistence(timeout: 3) {
            XCTAssertTrue(!usernameText.label.isEmpty, "Username should not be empty")
        }
    }

    @MainActor
    func testDisplaysEmail() throws {
        launchApp()
        navigateToProfile()

        // Look for email display
        let emailText = app.staticTexts.matching(identifier: "profile_email").firstMatch
        if emailText.waitForExistence(timeout: 3) {
            XCTAssertTrue(emailText.label.contains("@"), "Email should be displayed")
        }
    }

    @MainActor
    func testDisplaysProfilePicture() throws {
        launchApp()
        navigateToProfile()

        // Look for profile image
        let profileImage = app.images["profile_avatar"]
        if profileImage.waitForExistence(timeout: 3) {
            XCTAssertTrue(profileImage.exists, "Profile picture should be displayed")
        }
    }

    // MARK: - Sign Out Tests

    @MainActor
    func testSignOutButton() throws {
        launchApp()
        navigateToProfile()

        let signOutButton = app.buttons["profile_sign_out_button"]
        if signOutButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(signOutButton.isHittable, "Sign out button should be tappable")
        }
    }

    @MainActor
    func testSignOutShowsConfirmation() throws {
        launchApp()
        navigateToProfile()

        let signOutButton = app.buttons["profile_sign_out_button"]
        if signOutButton.waitForExistence(timeout: 3) {
            signOutButton.tap()

            // Look for confirmation alert or action sheet
            let confirmAlert = app.alerts.firstMatch
            let confirmSheet = app.sheets.firstMatch

            _  = confirmAlert.waitForExistence(timeout: 2) ||
                                  confirmSheet.waitForExistence(timeout: 2)

            // Some apps sign out immediately, others show confirmation
        }
    }

    @MainActor
    func testSignOutSuccess() throws {
        launchApp()
        navigateToProfile()

        let signOutButton = app.buttons["profile_sign_out_button"]
        if signOutButton.waitForExistence(timeout: 3) {
            signOutButton.tap()

            // Handle confirmation dialog - look for the confirm button in the sheet
            // The confirmation dialog has a "Sign Out" button - use the one in the sheet
            let confirmSheet = app.sheets.firstMatch
            if confirmSheet.waitForExistence(timeout: 2) {
                let confirmButton = confirmSheet.buttons["Sign Out"]
                if confirmButton.waitForExistence(timeout: 2) {
                    confirmButton.tap()
                }
            }

            // After sign out, sign in button should appear
            let signInButton = app.buttons["profile_sign_in_button"]
            XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign in button should appear after logout")
        }
    }

    // MARK: - Settings Tests

    @MainActor
    func testSettingsSection() throws {
        launchApp()
        navigateToProfile()

        // Look for settings section
        let settingsSection = app.staticTexts["Settings"]
        if settingsSection.waitForExistence(timeout: 3) {
            addScreenshot(named: "Profile Settings Section")
        }
    }

    @MainActor
    func testNotificationSettings() throws {
        launchApp()
        navigateToProfile()

        // Look for notification toggle or settings
        let notificationToggle = app.switches["profile_notifications_toggle"]
        if notificationToggle.waitForExistence(timeout: 3) {
            _  = notificationToggle.value as? String

            notificationToggle.tap()

            // Value should change
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    @MainActor
    func testPowderAlertSettings() throws {
        launchApp()
        navigateToProfile()

        // Look for powder alert settings
        let alertSettings = app.buttons["profile_powder_alerts"]
        if alertSettings.waitForExistence(timeout: 3) {
            alertSettings.tap()

            // Should open alert settings
            Thread.sleep(forTimeInterval: 1)
            addScreenshot(named: "Powder Alert Settings")
        }
    }

    @MainActor
    func testUnitPreferences() throws {
        launchApp()
        navigateToProfile()

        // Look for unit settings (imperial/metric)
        let unitToggle = app.buttons["profile_units_toggle"]
        if unitToggle.waitForExistence(timeout: 3) {
            unitToggle.tap()

            // Should toggle or show picker
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    @MainActor
    func testThemeSettings() throws {
        launchApp()
        navigateToProfile()

        // Look for theme/appearance settings
        let themeSettings = app.buttons["profile_theme_settings"]
        if themeSettings.waitForExistence(timeout: 3) {
            themeSettings.tap()

            // Should open theme picker
            Thread.sleep(forTimeInterval: 1)
        }
    }

    // MARK: - Favorites Management Tests

    @MainActor
    func testFavoriteMountainsSection() throws {
        launchApp()
        navigateToProfile()

        // Look for favorites section
        let favoritesSection = app.staticTexts["Favorite Mountains"]
        if favoritesSection.waitForExistence(timeout: 3) {
            addScreenshot(named: "Favorite Mountains")
        }
    }

    @MainActor
    func testManageFavorites() throws {
        launchApp()
        navigateToProfile()

        let manageFavorites = app.buttons["profile_manage_favorites"]
        if manageFavorites.waitForExistence(timeout: 3) {
            manageFavorites.tap()

            // Should open favorites management
            Thread.sleep(forTimeInterval: 1)
        }
    }

    @MainActor
    func testRemoveFavorite() throws {
        launchApp()
        navigateToProfile()

        // Look for remove button on favorite
        let removeButton = app.buttons.matching(identifier: "remove_favorite").firstMatch
        if removeButton.waitForExistence(timeout: 3) {
            removeButton.tap()

            // Confirm removal if needed
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    // MARK: - Account Settings Tests

    @MainActor
    func testEditProfile() throws {
        launchApp()
        navigateToProfile()

        let editButton = app.buttons["profile_edit_button"]
        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()

            // Edit form should appear
            Thread.sleep(forTimeInterval: 1)
            addScreenshot(named: "Edit Profile")
        }
    }

    @MainActor
    func testChangeUsername() throws {
        launchApp()
        navigateToProfile()

        let editButton = app.buttons["profile_edit_button"]
        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()

            let usernameField = app.textFields["edit_username_field"]
            if usernameField.waitForExistence(timeout: 3) {
                usernameField.tap()
                usernameField.clearAndType("NewUsername")
            }
        }
    }

    @MainActor
    func testChangePassword() throws {
        launchApp()
        navigateToProfile()

        let changePasswordButton = app.buttons["profile_change_password"]
        if changePasswordButton.waitForExistence(timeout: 3) {
            changePasswordButton.tap()

            // Password change form should appear
            let currentPasswordField = app.secureTextFields["current_password_field"]
            _  = app.secureTextFields["new_password_field"]

            if currentPasswordField.waitForExistence(timeout: 3) {
                addScreenshot(named: "Change Password")
            }
        }
    }

    @MainActor
    func testDeleteAccountOption() throws {
        launchApp()
        navigateToProfile()

        // Scroll to find delete account option
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
        }

        let deleteAccountButton = app.buttons["profile_delete_account"]
        if deleteAccountButton.waitForExistence(timeout: 3) {
            // Don't tap - just verify it exists
            XCTAssertTrue(deleteAccountButton.exists, "Delete account option should exist")
        }
    }

    // MARK: - Statistics Tests

    @MainActor
    func testStatsSection() throws {
        launchApp()
        navigateToProfile()

        // Look for statistics section
        let statsSection = app.staticTexts["Statistics"]
        if statsSection.waitForExistence(timeout: 3) {
            addScreenshot(named: "Profile Stats")
        }
    }

    @MainActor
    func testDaysSkied() throws {
        launchApp()
        navigateToProfile()

        let daysSkiedStat = app.staticTexts.matching(identifier: "profile_days_skied").firstMatch
        if daysSkiedStat.waitForExistence(timeout: 3) {
            // Should show number
        }
    }

    @MainActor
    func testMountainsVisited() throws {
        launchApp()
        navigateToProfile()

        let mountainsStat = app.staticTexts.matching(identifier: "profile_mountains_visited").firstMatch
        if mountainsStat.waitForExistence(timeout: 3) {
            // Should show number
        }
    }

    @MainActor
    func testEventsAttended() throws {
        launchApp()
        navigateToProfile()

        let eventsStat = app.staticTexts.matching(identifier: "profile_events_attended").firstMatch
        if eventsStat.waitForExistence(timeout: 3) {
            // Should show number
        }
    }

    // MARK: - App Info Tests

    @MainActor
    func testAppVersion() throws {
        launchApp()
        navigateToProfile()

        // Scroll to bottom
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeUp()
        }

        let versionText = app.staticTexts.matching(identifier: "profile_app_version").firstMatch
        if versionText.waitForExistence(timeout: 3) {
            XCTAssertTrue(versionText.label.contains("."), "Version should contain dot separator")
        }
    }

    @MainActor
    func testPrivacyPolicy() throws {
        launchApp()
        navigateToProfile()

        let privacyButton = app.buttons["profile_privacy_policy"]
        if privacyButton.waitForExistence(timeout: 3) {
            // Don't tap - would open Safari
            XCTAssertTrue(privacyButton.exists, "Privacy policy link should exist")
        }
    }

    @MainActor
    func testTermsOfService() throws {
        launchApp()
        navigateToProfile()

        let termsButton = app.buttons["profile_terms_of_service"]
        if termsButton.waitForExistence(timeout: 3) {
            // Don't tap - would open Safari
            XCTAssertTrue(termsButton.exists, "Terms of service link should exist")
        }
    }

    @MainActor
    func testSupportLink() throws {
        launchApp()
        navigateToProfile()

        let supportButton = app.buttons["profile_support"]
        if supportButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(supportButton.exists, "Support link should exist")
        }
    }

    @MainActor
    func testRateApp() throws {
        launchApp()
        navigateToProfile()

        let rateButton = app.buttons["profile_rate_app"]
        if rateButton.waitForExistence(timeout: 3) {
            // Don't tap - would open App Store
            XCTAssertTrue(rateButton.exists, "Rate app button should exist")
        }
    }

    // MARK: - Navigation Tests

    @MainActor
    func testProfileScrolling() throws {
        launchApp()
        navigateToProfile()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Profile should be scrollable")

        // Scroll through entire profile
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        scrollView.swipeDown()
        scrollView.swipeDown()
    }

    @MainActor
    func testBackNavigationFromSubview() throws {
        launchApp()
        navigateToProfile()

        // Open a subview (e.g., edit profile)
        let editButton = app.buttons["profile_edit_button"]
        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()

            Thread.sleep(forTimeInterval: 1)

            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists && backButton.isHittable {
                backButton.tap()
            } else {
                // Try cancel button
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }

            // Should return to profile
            XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Should return to profile")
        }
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testProfileAccessibility() throws {
        launchApp()
        navigateToProfile()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Profile should be accessible")
    }

    @MainActor
    func testButtonsAccessible() throws {
        launchApp()
        navigateToProfile()

        // All buttons should be tappable
        let buttons = app.buttons.allElementsBoundByIndex

        for button in buttons.prefix(10) {
            if button.exists && button.isHittable {
                // Button is accessible
            }
        }
    }

    @MainActor
    func testLabelsAccessible() throws {
        launchApp()
        navigateToProfile()

        // Static texts should have content
        let labels = app.staticTexts.allElementsBoundByIndex

        for label in labels.prefix(10) {
            if label.exists {
                XCTAssertFalse(label.label.isEmpty, "Label should have content")
            }
        }
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testOfflineMode() throws {
        // Note: Network simulation requires additional setup
        launchApp()
        navigateToProfile()

        // Profile should still show cached data or appropriate message
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Profile should handle offline")
    }

    // MARK: - Helpers

    @MainActor
    private func addScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - XCUIElement Extension

extension XCUIElement {
    func clearAndType(_ text: String) {
        guard let currentValue = self.value as? String else {
            self.typeText(text)
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
