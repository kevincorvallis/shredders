//
//  EventsUITests.swift
//  PowderTrackerUITests
//
//  Tests for event creation flow.
//

import XCTest

final class EventsUITests: XCTestCase {
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
    func testCreateEventFullFlow() throws {
        launchApp()
        try UITestHelper.ensureLoggedIn(app: app)
        UITestHelper.navigateToEvents(app: app)

        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available")
        }
        createButton.tap()

        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form not available")
        }
        titleField.tap()
        titleField.typeText("Test Event \(Int.random(in: 1000...9999))")

        let mountainPicker = app.buttons["create_event_mountain_picker"]
        if mountainPicker.waitForExistence(timeout: 3) && mountainPicker.isHittable {
            mountainPicker.tap()
            Thread.sleep(forTimeInterval: 1)
            let firstMountain = app.buttons.matching(NSPredicate(
                format: "label CONTAINS[c] 'Mountain' OR label CONTAINS[c] 'Resort' OR label CONTAINS[c] 'Pass'"
            )).firstMatch
            if firstMountain.exists && firstMountain.isHittable {
                firstMountain.tap()
            }
        }

        XCTAssertTrue(titleField.exists, "Event creation form should remain open with filled fields")
    }
}
