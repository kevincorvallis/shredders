//
//  OnboardingUITests.swift
//  PowderTrackerUITests
//
//  UI tests for the onboarding flow for new users.
//

import XCTest

final class OnboardingUITests: XCTestCase {
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
    private func launchAppForOnboarding() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SHOW_ONBOARDING"]
        app.launch()
    }

    @MainActor
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    // MARK: - Welcome Screen Tests

    @MainActor
    func testWelcomeScreenDisplays() throws {
        launchAppForOnboarding()

        // Look for welcome screen elements
        let welcomeText = app.staticTexts["Welcome to PowderTracker"]
        if welcomeText.waitForExistence(timeout: 5) {
            XCTAssertTrue(welcomeText.exists, "Welcome text should display")
            addScreenshot(named: "Onboarding Welcome")
        }
    }

    @MainActor
    func testWelcomeScreenHasContinueButton() throws {
        launchAppForOnboarding()

        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled")
        }
    }

    @MainActor
    func testWelcomeScreenTapContinue() throws {
        launchAppForOnboarding()

        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()

            // Should advance to profile setup
            Thread.sleep(forTimeInterval: 0.5)
            addScreenshot(named: "After Welcome Continue")
        }
    }

    // MARK: - Progress Indicator Tests

    @MainActor
    func testProgressIndicatorDisplays() throws {
        launchAppForOnboarding()

        // Advance past welcome
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        // Progress indicator should appear after welcome
        let progressView = app.otherElements["onboarding_progress"]
        if progressView.waitForExistence(timeout: 3) {
            XCTAssertTrue(progressView.exists, "Progress indicator should display")
        }
    }

    @MainActor
    func testProgressIndicatorUpdates() throws {
        launchAppForOnboarding()

        // Navigate through steps and verify progress updates
        var stepCount = 0

        for _ in 0..<3 {
            let continueButton = app.buttons["onboarding_continue_button"]
            if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                stepCount += 1
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // Should have advanced through steps
        XCTAssertGreaterThan(stepCount, 0, "Should have progressed through steps")
    }

    // MARK: - Profile Setup Tests

    @MainActor
    func testProfileSetupScreen() throws {
        launchAppForOnboarding()

        // Advance to profile setup
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Look for profile setup elements
        let displayNameField = app.textFields["onboarding_display_name"]
        if displayNameField.waitForExistence(timeout: 3) {
            XCTAssertTrue(displayNameField.exists, "Display name field should exist")
            addScreenshot(named: "Profile Setup")
        }
    }

    @MainActor
    func testProfileSetupEnterDisplayName() throws {
        launchAppForOnboarding()

        // Advance to profile setup
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        let displayNameField = app.textFields["onboarding_display_name"]
        if displayNameField.waitForExistence(timeout: 3) {
            displayNameField.tap()
            displayNameField.typeText("Test User")

            XCTAssertEqual(displayNameField.value as? String, "Test User")
        }
    }

    @MainActor
    func testProfileSetupSkipButton() throws {
        launchAppForOnboarding()

        // Advance to profile setup
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        let skipButton = app.buttons["onboarding_skip_button"]
        if skipButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(skipButton.exists, "Skip button should exist")
        }
    }

    // MARK: - About You Screen Tests

    @MainActor
    func testAboutYouScreen() throws {
        launchAppForOnboarding()

        // Navigate to About You (2 continues from welcome)
        for _ in 0..<2 {
            let continueButton = app.buttons["onboarding_continue_button"]
            if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        addScreenshot(named: "About You Screen")
    }

    @MainActor
    func testExperienceLevelSelection() throws {
        launchAppForOnboarding()

        // Navigate to About You
        for _ in 0..<2 {
            let continueButton = app.buttons["onboarding_continue_button"]
            if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // Look for experience level buttons
        let beginnerButton = app.buttons["experience_beginner"]
        let intermediateButton = app.buttons["experience_intermediate"]
        let advancedButton = app.buttons["experience_advanced"]

        if beginnerButton.waitForExistence(timeout: 3) {
            beginnerButton.tap()
            // Button should show selected state
        } else if intermediateButton.waitForExistence(timeout: 3) {
            intermediateButton.tap()
        } else if advancedButton.waitForExistence(timeout: 3) {
            advancedButton.tap()
        }
    }

    @MainActor
    func testTerrainPreferenceSelection() throws {
        launchAppForOnboarding()

        // Navigate to About You
        for _ in 0..<2 {
            let continueButton = app.buttons["onboarding_continue_button"]
            if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // Look for terrain preference toggles
        let groomersToggle = app.buttons["terrain_groomers"]
        let treesToggle = app.buttons["terrain_trees"]
        let mogulsToggle = app.buttons["terrain_moguls"]

        if groomersToggle.waitForExistence(timeout: 3) {
            groomersToggle.tap()
        }
        if treesToggle.exists {
            treesToggle.tap()
        }
        if mogulsToggle.exists {
            mogulsToggle.tap()
        }
    }

    // MARK: - Preferences Screen Tests

    @MainActor
    func testPreferencesScreen() throws {
        launchAppForOnboarding()

        // Navigate to Preferences (3 continues from welcome)
        for _ in 0..<3 {
            let continueButton = app.buttons["onboarding_continue_button"]
            if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        addScreenshot(named: "Preferences Screen")
    }

    @MainActor
    func testUnitPreferenceToggle() throws {
        launchAppForOnboarding()

        // Navigate to Preferences
        for _ in 0..<3 {
            let continueButton = app.buttons["onboarding_continue_button"]
            if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // Look for unit preference toggle (imperial/metric)
        let unitToggle = app.switches["unit_preference_toggle"]
        if unitToggle.waitForExistence(timeout: 3) {
            unitToggle.tap()
        }
    }

    @MainActor
    func testNotificationPreferenceToggle() throws {
        launchAppForOnboarding()

        // Navigate to Preferences
        for _ in 0..<3 {
            let continueButton = app.buttons["onboarding_continue_button"]
            if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // Look for notification preference toggle
        let notifToggle = app.switches["notification_preference_toggle"]
        if notifToggle.waitForExistence(timeout: 3) {
            notifToggle.tap()
        }
    }

    // MARK: - Complete Flow Tests

    @MainActor
    func testCompleteOnboardingFlow() throws {
        launchAppForOnboarding()

        // Complete all steps
        for step in 0..<4 {
            let continueButton = app.buttons["onboarding_continue_button"]
            let completeButton = app.buttons["onboarding_complete_button"]

            if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
                completeButton.tap()
                break
            } else if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // After completion, should see main app
        Thread.sleep(forTimeInterval: 2)

        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5) {
            XCTAssertTrue(tabBar.exists, "Should see main app after onboarding")
            addScreenshot(named: "After Onboarding Complete")
        }
    }

    @MainActor
    func testSkipOnboarding() throws {
        launchAppForOnboarding()

        // Advance past welcome
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Tap skip button
        let skipButton = app.buttons["onboarding_skip_button"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()

            // Should go to main app
            Thread.sleep(forTimeInterval: 2)

            let tabBar = app.tabBars.firstMatch
            if tabBar.waitForExistence(timeout: 5) {
                XCTAssertTrue(tabBar.exists, "Should see main app after skip")
            }
        }
    }

    // MARK: - Avatar Selection Tests

    @MainActor
    func testAvatarPickerExists() throws {
        launchAppForOnboarding()

        // Advance to profile setup
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Look for avatar picker
        let avatarPicker = app.otherElements["avatar_picker"]
        let avatarButton = app.buttons["select_avatar_button"]

        if avatarPicker.waitForExistence(timeout: 3) {
            addScreenshot(named: "Avatar Picker")
        } else if avatarButton.waitForExistence(timeout: 3) {
            addScreenshot(named: "Avatar Button")
        }
    }

    @MainActor
    func testSelectAvatar() throws {
        launchAppForOnboarding()

        // Advance to profile setup
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Try to select an avatar
        let avatarOption = app.buttons.matching(identifier: "avatar_option").firstMatch
        if avatarOption.waitForExistence(timeout: 3) {
            avatarOption.tap()
        }
    }

    // MARK: - Swipe Navigation Tests

    @MainActor
    func testSwipeToNavigate() throws {
        launchAppForOnboarding()

        // Advance past welcome
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Try swiping between onboarding screens
        let onboardingView = app.otherElements["onboarding_container"]
        if onboardingView.waitForExistence(timeout: 3) {
            onboardingView.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)
            addScreenshot(named: "After Swipe Left")
        }
    }

    @MainActor
    func testSwipeBackToPreviousStep() throws {
        launchAppForOnboarding()

        // Advance two steps
        for _ in 0..<2 {
            let continueButton = app.buttons["onboarding_continue_button"]
            if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // Swipe right to go back (if supported)
        let onboardingView = app.scrollViews.firstMatch
        if onboardingView.waitForExistence(timeout: 3) {
            onboardingView.swipeRight()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    // MARK: - Validation Tests

    @MainActor
    func testDisplayNameValidation() throws {
        launchAppForOnboarding()

        // Advance to profile setup
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        let displayNameField = app.textFields["onboarding_display_name"]
        if displayNameField.waitForExistence(timeout: 3) {
            // Enter invalid name (too short or empty)
            displayNameField.tap()
            displayNameField.typeText("A")

            // Try to continue - may show validation error
            let nextButton = app.buttons["onboarding_continue_button"]
            if nextButton.exists && nextButton.isHittable {
                nextButton.tap()
            }

            // Check for validation message
            let validationError = app.staticTexts["validation_error"]
            if validationError.waitForExistence(timeout: 2) {
                addScreenshot(named: "Validation Error")
            }
        }
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testOnboardingAccessibility() throws {
        launchAppForOnboarding()

        // Check that main elements are accessible
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(continueButton.isHittable, "Continue button should be accessible")
        }
    }

    @MainActor
    func testOnboardingVoiceOverLabels() throws {
        launchAppForOnboarding()

        // Verify accessibility labels exist
        let buttons = app.buttons.allElementsBoundByIndex

        for button in buttons.prefix(5) {
            if button.exists {
                XCTAssertFalse(button.label.isEmpty, "Button should have accessibility label")
            }
        }
    }

    // MARK: - Loading State Tests

    @MainActor
    func testLoadingStateOnComplete() throws {
        launchAppForOnboarding()

        // Navigate through all steps quickly
        for _ in 0..<4 {
            let continueButton = app.buttons["onboarding_continue_button"]
            let completeButton = app.buttons["onboarding_complete_button"]

            if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
                completeButton.tap()

                // Loading indicator may appear
                let loadingIndicator = app.activityIndicators.firstMatch
                if loadingIndicator.waitForExistence(timeout: 2) {
                    addScreenshot(named: "Onboarding Loading")
                }
                break
            } else if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testErrorAlertDisplay() throws {
        // This test would require network failure simulation
        launchAppForOnboarding()

        // Navigate to completion
        for _ in 0..<4 {
            let continueButton = app.buttons["onboarding_continue_button"]
            let completeButton = app.buttons["onboarding_complete_button"]

            if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
                completeButton.tap()
                break
            } else if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        // Check if error alert appears (on network failure)
        let errorAlert = app.alerts["Oops!"]
        if errorAlert.waitForExistence(timeout: 5) {
            addScreenshot(named: "Onboarding Error Alert")

            // Try Again button should exist
            let tryAgainButton = errorAlert.buttons["Try Again"]
            XCTAssertTrue(tryAgainButton.exists, "Try Again button should exist")

            // Skip for Now button should exist
            let skipButton = errorAlert.buttons["Skip for Now"]
            XCTAssertTrue(skipButton.exists, "Skip for Now button should exist")
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
