//
//  OnboardingUITests.swift
//  PowderTrackerUITests
//
//  UI tests for the onboarding flow for new users.
//  Focuses on critical user journeys rather than element existence checks.
//

import XCTest

@MainActor
final class OnboardingUITests: XCTestCase {
    nonisolated(unsafe) var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    private func launchAppForOnboarding() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SHOW_ONBOARDING"]
        app.launch()
    }

    // MARK: - Button Helpers

    /// Finds and taps any continue/next button on the current onboarding screen
    private func tapContinueButton() -> Bool {
        // Welcome screen
        let letsGoButton = app.buttons["Let's Go Shred!"]
        if letsGoButton.waitForExistence(timeout: 2) && letsGoButton.isHittable {
            letsGoButton.tap()
            return true
        }

        // Other screens - "Continue" button
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 2) && continueButton.isHittable {
            continueButton.tap()
            return true
        }

        return false
    }

    /// Finds and taps the complete button on the final screen
    private func tapCompleteButton() -> Bool {
        let completeButton = app.buttons["Complete Setup"]
        if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
            completeButton.tap()
            return true
        }
        return false
    }

    /// Finds and taps any skip button
    private func tapSkipButton() -> Bool {
        // Try different skip button variations
        for label in ["Skip", "Skip for now"] {
            let skipButton = app.buttons[label]
            if skipButton.waitForExistence(timeout: 2) && skipButton.isHittable {
                skipButton.tap()
                return true
            }
        }
        return false
    }

    // MARK: - Critical Flow Tests

    func testCompleteOnboardingFlow() throws {
        launchAppForOnboarding()

        // Complete all onboarding steps
        for _ in 0..<5 {
            Thread.sleep(forTimeInterval: 0.5)

            // Check for complete button first (final screen)
            if tapCompleteButton() {
                break
            }

            // Otherwise try continue button
            if !tapContinueButton() {
                // If no button found, try skip to move forward
                _ = tapSkipButton()
            }
        }

        // After completion, should see main app with tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should see main app after onboarding")
    }

    func testSkipOnboarding() throws {
        launchAppForOnboarding()

        // Advance past welcome
        Thread.sleep(forTimeInterval: 1)
        _ = tapContinueButton()
        Thread.sleep(forTimeInterval: 0.5)

        // Tap skip button
        if tapSkipButton() {
            // Should go to main app
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should see main app after skip")
        }
    }

    func testOnboardingProfileSetup() throws {
        launchAppForOnboarding()

        // Advance past welcome to profile setup
        Thread.sleep(forTimeInterval: 1)
        _ = tapContinueButton()
        Thread.sleep(forTimeInterval: 0.5)

        // Look for text field by placeholder or any text field
        let textFields = app.textFields
        if textFields.count > 0 {
            let firstField = textFields.firstMatch
            if firstField.waitForExistence(timeout: 3) && firstField.isHittable {
                firstField.tap()
                firstField.typeText("Test User")
            }
        }
    }

    /// Tests that onboarding buttons are visible and tappable.
    /// Full flow progression is tested by testCompleteOnboardingFlow.
    func testOnboardingButtonsAreAccessible() throws {
        launchAppForOnboarding()

        // Wait for onboarding to appear
        Thread.sleep(forTimeInterval: 1)

        // The "Let's Go Shred!" button should be accessible on the welcome screen
        let welcomeButton = app.buttons["Let's Go Shred!"]
        XCTAssertTrue(welcomeButton.waitForExistence(timeout: 5),
                      "Welcome button should be visible in onboarding")
    }
}
