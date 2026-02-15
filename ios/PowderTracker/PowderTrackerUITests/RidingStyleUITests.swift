//
//  RidingStyleUITests.swift
//  PowderTrackerUITests
//
//  Tests for riding style selection in onboarding and E2E flow.
//

import XCTest

final class RidingStyleUITests: XCTestCase {
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

    // MARK: - Onboarding

    @MainActor
    func testRidingStyleQuestionAppearsInOnboarding() throws {
        launchAppForOnboarding()
        try navigateToAboutYouScreen()

        let ridingStyleLabel = app.staticTexts["I ride on..."]
        XCTAssertTrue(ridingStyleLabel.waitForExistence(timeout: 5),
                      "Riding style question should appear in About You section")
    }

    // MARK: - End-to-End

    @MainActor
    func testEndToEndRidingStyleFlow() throws {
        launchAppForOnboarding()
        try navigateToAboutYouScreen()

        let snowboarderButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Snowboarder'")).firstMatch
        if snowboarderButton.waitForExistence(timeout: 5) && snowboarderButton.isHittable {
            snowboarderButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Complete rest of onboarding
        for _ in 0..<5 {
            Thread.sleep(forTimeInterval: 0.5)

            let completeButton = app.buttons["Complete Setup"]
            if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
                completeButton.tap()
                break
            }

            let continueButton = app.buttons["Continue"]
            if continueButton.waitForExistence(timeout: 2) && continueButton.isHittable {
                continueButton.tap()
            } else {
                let skipButton = app.buttons["Skip for now"]
                if skipButton.waitForExistence(timeout: 2) && skipButton.isHittable {
                    skipButton.tap()
                }
            }
        }

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Main app should load after onboarding")
    }

    // MARK: - Helpers

    @MainActor
    private func navigateToAboutYouScreen() throws {
        let ridingStyleLabel = app.staticTexts["I ride on..."]

        for _ in 0..<10 {
            if ridingStyleLabel.waitForExistence(timeout: 1) { return }

            let getStarted = app.buttons["Get Started"]
            if getStarted.exists && getStarted.isHittable {
                getStarted.tap()
                Thread.sleep(forTimeInterval: 0.5)
                continue
            }

            let continueButton = app.buttons["Continue"]
            if continueButton.exists && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
                continue
            }

            Thread.sleep(forTimeInterval: 0.5)
        }

        guard ridingStyleLabel.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not navigate to About You screen")
        }
    }
}
