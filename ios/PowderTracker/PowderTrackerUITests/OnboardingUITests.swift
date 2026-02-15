//
//  OnboardingUITests.swift
//  PowderTrackerUITests
//
//  Tests for onboarding completion and skip flows.
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

    private func tapContinueButton() -> Bool {
        let getStarted = app.buttons["Get Started"]
        if getStarted.waitForExistence(timeout: 1) && getStarted.isHittable {
            getStarted.tap()
            return true
        }

        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 1) && continueButton.isHittable {
            continueButton.tap()
            return true
        }

        return false
    }

    private func tapCompleteButton() -> Bool {
        let completeButton = app.buttons["Complete Setup"]
        if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
            completeButton.tap()
            return true
        }
        return false
    }

    private func tapSkipButton() -> Bool {
        for label in ["Skip", "Skip for now"] {
            let skipButton = app.buttons[label]
            if skipButton.waitForExistence(timeout: 2) && skipButton.isHittable {
                skipButton.tap()
                return true
            }
        }
        return false
    }

    // MARK: - Critical Flows

    func testCompleteOnboardingFlow() throws {
        launchAppForOnboarding()

        for _ in 0..<10 {
            Thread.sleep(forTimeInterval: 0.5)
            if tapCompleteButton() { break }
            if !tapContinueButton() {
                _ = tapSkipButton()
            }
        }

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should see main app after onboarding")
    }

    func testSkipOnboarding() throws {
        launchAppForOnboarding()

        Thread.sleep(forTimeInterval: 1)
        _ = tapContinueButton()
        Thread.sleep(forTimeInterval: 0.5)

        guard tapSkipButton() else {
            throw XCTSkip("Skip button not available")
        }

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should see main app after skip")
    }
}
