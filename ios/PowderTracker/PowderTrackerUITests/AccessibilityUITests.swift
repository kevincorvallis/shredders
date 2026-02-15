//
//  AccessibilityUITests.swift
//  PowderTrackerUITests
//
//  Accessibility identifier verification and automated audits.
//

import XCTest

final class AccessibilityUITests: XCTestCase {
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

    // MARK: - Tab Identifiers

    @MainActor
    func testAllTabsHaveAccessibilityIdentifiers() throws {
        launchApp()

        let todayTab = app.buttons["tab_today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 5), "Today tab should have accessibility identifier")
        XCTAssertTrue(app.buttons["tab_mountains"].exists, "Mountains tab should have accessibility identifier")
        XCTAssertTrue(app.buttons["tab_events"].exists, "Events tab should have accessibility identifier")
        XCTAssertTrue(app.buttons["tab_map"].exists, "Map tab should have accessibility identifier")
        XCTAssertTrue(app.buttons["tab_profile"].exists, "Profile tab should have accessibility identifier")
    }

    // MARK: - Automated Accessibility Audits

    @MainActor
    func testAccessibilityAuditTodayTab() throws {
        launchApp()
        try app.performAccessibilityAudit()
    }

    @MainActor
    func testAccessibilityAuditMountainsTab() throws {
        launchApp()
        let tab = app.tabBars.buttons["Mountains"].firstMatch
        guard tab.waitForExistence(timeout: 5) else { throw XCTSkip("Mountains tab not found") }
        tab.tap()
        Thread.sleep(forTimeInterval: 1)
        try app.performAccessibilityAudit()
    }

    @MainActor
    func testAccessibilityAuditEventsTab() throws {
        launchApp()
        let tab = app.tabBars.buttons["Events"].firstMatch
        guard tab.waitForExistence(timeout: 5) else { throw XCTSkip("Events tab not found") }
        tab.tap()
        Thread.sleep(forTimeInterval: 1)
        try app.performAccessibilityAudit()
    }

    @MainActor
    func testAccessibilityAuditProfileTab() throws {
        launchApp()
        let tab = app.tabBars.buttons["Profile"].firstMatch
        guard tab.waitForExistence(timeout: 5) else { throw XCTSkip("Profile tab not found") }
        tab.tap()
        Thread.sleep(forTimeInterval: 1)
        try app.performAccessibilityAudit()
    }
}
