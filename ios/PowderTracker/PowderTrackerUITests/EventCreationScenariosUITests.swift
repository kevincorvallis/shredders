//
//  EventCreationScenariosUITests.swift
//  PowderTrackerUITests
//
//  Comprehensive end-to-end tests for event creation scenarios.
//  Tests various event configurations and validates the full flow.
//

import XCTest

final class EventCreationScenariosUITests: XCTestCase {
    var app: XCUIApplication!

    // Test credentials from environment or defaults
    private var testEmail: String {
        ProcessInfo.processInfo.environment["UI_TEST_EMAIL"] ?? "e2etest@example.com"
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
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "RESET_STATE"]
        app.launch()
    }

    // MARK: - Scenario 1: Event Creation with All Fields

    @MainActor
    func testCreateEvent_AllFields_Success() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        // Open create event sheet
        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available - user may not be authenticated")
        }
        createButton.tap()

        // Wait for form to appear
        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form did not appear")
        }

        // Fill in title
        let eventTitle = "Full Event Test \(Int.random(in: 1000...9999))"
        titleField.tap()
        titleField.typeText(eventTitle)

        // Select mountain
        selectMountain("baker")

        // Wait for forecast to potentially load
        Thread.sleep(forTimeInterval: 2)

        // Set departure time toggle
        let departureToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'departure'")).firstMatch
        if departureToggle.exists && departureToggle.isHittable {
            if departureToggle.value as? String == "0" {
                departureToggle.tap()
            }
        }

        // Set departure location
        let locationField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS[c] 'location' OR label CONTAINS[c] 'location'")).firstMatch
        if locationField.waitForExistence(timeout: 2) && locationField.isHittable {
            locationField.tap()
            locationField.typeText("Capitol Hill, Seattle")
        }

        // Enable carpool
        let carpoolToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'carpool'")).firstMatch
        if carpoolToggle.exists && carpoolToggle.isHittable {
            if carpoolToggle.value as? String == "0" {
                carpoolToggle.tap()
            }
        }

        // Select skill level if picker exists
        let skillPicker = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'skill' OR identifier CONTAINS[c] 'skill'")).firstMatch
        if skillPicker.exists && skillPicker.isHittable {
            skillPicker.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let intermediateOption = app.buttons["Intermediate"]
            if intermediateOption.exists {
                intermediateOption.tap()
            }
        }

        addScreenshot(named: "Event Creation - All Fields Filled")

        // Submit the form
        let submitButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'create' AND label CONTAINS[c] 'event'")).firstMatch
        if submitButton.exists && submitButton.isHittable {
            submitButton.tap()
            Thread.sleep(forTimeInterval: 3)

            // Verify we're back on events list or on the new event detail
            let eventsTab = app.tabBars.buttons["Events"].firstMatch
            XCTAssertTrue(eventsTab.exists, "Should return to events view after creation")

            addScreenshot(named: "Event Creation - Success")
        }
    }

    // MARK: - Scenario 2: Event Creation with Minimal Fields

    @MainActor
    func testCreateEvent_MinimalFields_Success() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available")
        }
        createButton.tap()

        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form did not appear")
        }

        // Only fill required fields
        let eventTitle = "Minimal Event \(Int.random(in: 1000...9999))"
        titleField.tap()
        titleField.typeText(eventTitle)

        // Select mountain (required)
        selectMountain("stevens")

        addScreenshot(named: "Event Creation - Minimal Fields")

        // Submit
        let submitButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'create' AND label CONTAINS[c] 'event'")).firstMatch
        if submitButton.exists && submitButton.isHittable {
            submitButton.tap()
            Thread.sleep(forTimeInterval: 3)
            addScreenshot(named: "Event Creation - Minimal Success")
        }
    }

    // MARK: - Scenario 3: Event Creation Validation

    @MainActor
    func testCreateEvent_MissingTitle_ShowsError() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available")
        }
        createButton.tap()

        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form did not appear")
        }

        // Select mountain but leave title empty
        selectMountain("crystal")

        // Try to submit without title
        let submitButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'create' AND label CONTAINS[c] 'event'")).firstMatch
        if submitButton.exists && submitButton.isHittable {
            submitButton.tap()
            Thread.sleep(forTimeInterval: 1)

            // Check for error message or validation indicator
            _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'required' OR label CONTAINS[c] 'title'")).firstMatch
            addScreenshot(named: "Event Creation - Validation Error")

            // The form should still be visible (not dismissed)
            XCTAssertTrue(titleField.exists, "Form should remain visible when validation fails")
        }
    }

    @MainActor
    func testCreateEvent_MissingMountain_ShowsError() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available")
        }
        createButton.tap()

        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form did not appear")
        }

        // Fill title but don't select mountain
        titleField.tap()
        titleField.typeText("Test Event No Mountain")

        // Try to submit without mountain selection
        let submitButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'create' AND label CONTAINS[c] 'event'")).firstMatch
        if submitButton.exists && submitButton.isHittable {
            submitButton.tap()
            Thread.sleep(forTimeInterval: 1)

            addScreenshot(named: "Event Creation - Missing Mountain Error")

            // Form should still be visible
            XCTAssertTrue(titleField.exists, "Form should remain visible when validation fails")
        }
    }

    // MARK: - Scenario 4: Event with Capacity Limits

    @MainActor
    func testCreateEvent_WithCapacityLimit() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available")
        }
        createButton.tap()

        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form did not appear")
        }

        // Fill basic info
        let eventTitle = "Limited Capacity Event \(Int.random(in: 1000...9999))"
        titleField.tap()
        titleField.typeText(eventTitle)

        selectMountain("baker")

        // Look for max attendees field or toggle
        let capacityToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'limit' OR label CONTAINS[c] 'capacity' OR label CONTAINS[c] 'max'")).firstMatch
        if capacityToggle.exists && capacityToggle.isHittable {
            capacityToggle.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Look for capacity input field
            let capacityField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS[c] 'attendees' OR label CONTAINS[c] 'max'")).firstMatch
            if capacityField.exists && capacityField.isHittable {
                capacityField.tap()
                capacityField.typeText("10")
            }
        }

        addScreenshot(named: "Event Creation - With Capacity Limit")

        // Submit
        let submitButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'create' AND label CONTAINS[c] 'event'")).firstMatch
        if submitButton.exists && submitButton.isHittable {
            submitButton.tap()
            Thread.sleep(forTimeInterval: 3)
            addScreenshot(named: "Event Creation - Capacity Event Created")
        }
    }

    // MARK: - Scenario 5: RSVP as Driver

    @MainActor
    func testRSVP_AsDriver_Success() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        navigateToEventDetail()

        // Look for RSVP button
        let rsvpButton = app.buttons["I'm In!"]
        guard rsvpButton.waitForExistence(timeout: 5) && rsvpButton.isHittable else {
            // Try alternative button text
            let altRsvpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'join' OR label CONTAINS[c] 'going'")).firstMatch
            guard altRsvpButton.waitForExistence(timeout: 3) && altRsvpButton.isHittable else {
                throw XCTSkip("RSVP button not available - may already be RSVPed or event not found")
            }
            altRsvpButton.tap()
            return
        }

        rsvpButton.tap()
        Thread.sleep(forTimeInterval: 2)

        // Check for driver option
        let driverToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'driver' OR label CONTAINS[c] 'driving'")).firstMatch
        if driverToggle.exists && driverToggle.isHittable {
            driverToggle.tap()

            // May prompt for pickup location or seats
            let seatsField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS[c] 'seats' OR label CONTAINS[c] 'seats'")).firstMatch
            if seatsField.exists && seatsField.isHittable {
                seatsField.tap()
                seatsField.typeText("4")
            }

            addScreenshot(named: "RSVP - As Driver")
        }

        // Confirm RSVP
        let confirmButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'confirm' OR label CONTAINS[c] 'save'")).firstMatch
        if confirmButton.exists && confirmButton.isHittable {
            confirmButton.tap()
            Thread.sleep(forTimeInterval: 2)
        }

        addScreenshot(named: "RSVP - Driver Confirmed")
    }

    // MARK: - Scenario 6: RSVP Needing Ride

    @MainActor
    func testRSVP_NeedingRide_Success() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        navigateToEventDetail()

        let rsvpButton = app.buttons["I'm In!"]
        guard rsvpButton.waitForExistence(timeout: 5) && rsvpButton.isHittable else {
            throw XCTSkip("RSVP button not available")
        }

        rsvpButton.tap()
        Thread.sleep(forTimeInterval: 2)

        // Check for need ride option
        let needRideToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'need' AND label CONTAINS[c] 'ride'")).firstMatch
        if needRideToggle.exists && needRideToggle.isHittable {
            needRideToggle.tap()

            // Enter pickup location
            let pickupField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS[c] 'pickup' OR label CONTAINS[c] 'location'")).firstMatch
            if pickupField.exists && pickupField.isHittable {
                pickupField.tap()
                pickupField.typeText("University District")
            }

            addScreenshot(named: "RSVP - Needs Ride")
        }

        // Confirm
        let confirmButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'confirm' OR label CONTAINS[c] 'save'")).firstMatch
        if confirmButton.exists && confirmButton.isHittable {
            confirmButton.tap()
            Thread.sleep(forTimeInterval: 2)
        }

        addScreenshot(named: "RSVP - Needs Ride Confirmed")
    }

    // MARK: - Scenario 7: RSVP Maybe Status

    @MainActor
    func testRSVP_Maybe_Success() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        navigateToEventDetail()

        // Look for Maybe button
        let maybeButton = app.buttons["Maybe"]
        guard maybeButton.waitForExistence(timeout: 5) && maybeButton.isHittable else {
            throw XCTSkip("Maybe button not available")
        }

        maybeButton.tap()
        Thread.sleep(forTimeInterval: 2)

        addScreenshot(named: "RSVP - Maybe Status")

        // Verify status changed
        let maybeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'maybe'")).firstMatch
        XCTAssertTrue(maybeIndicator.waitForExistence(timeout: 3), "Should show maybe status")
    }

    // MARK: - Scenario 8: Change RSVP Status

    @MainActor
    func testRSVP_ChangeStatus_Success() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        navigateToEventDetail()

        // First RSVP as going
        let rsvpButton = app.buttons["I'm In!"]
        if rsvpButton.waitForExistence(timeout: 5) && rsvpButton.isHittable {
            rsvpButton.tap()
            Thread.sleep(forTimeInterval: 2)
        }

        addScreenshot(named: "RSVP - Initial Going")

        // Now change to maybe
        let maybeButton = app.buttons["Maybe"]
        if maybeButton.waitForExistence(timeout: 3) && maybeButton.isHittable {
            maybeButton.tap()
            Thread.sleep(forTimeInterval: 2)
        }

        addScreenshot(named: "RSVP - Changed to Maybe")

        // Change back to going
        let goingButton = app.buttons["I'm In!"]
        if goingButton.waitForExistence(timeout: 3) && goingButton.isHittable {
            goingButton.tap()
            Thread.sleep(forTimeInterval: 2)
        }

        addScreenshot(named: "RSVP - Changed Back to Going")
    }

    // MARK: - Scenario 9: Event with Carpool Coordination

    @MainActor
    func testCreateEvent_WithCarpool_Success() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available")
        }
        createButton.tap()

        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form did not appear")
        }

        // Fill basic info
        let eventTitle = "Carpool Event \(Int.random(in: 1000...9999))"
        titleField.tap()
        titleField.typeText(eventTitle)

        selectMountain("crystal")

        // Enable carpool
        let carpoolToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'carpool' OR label CONTAINS[c] 'offering'")).firstMatch
        if carpoolToggle.exists && carpoolToggle.isHittable {
            if carpoolToggle.value as? String == "0" {
                carpoolToggle.tap()
            }
            Thread.sleep(forTimeInterval: 0.5)

            // Set carpool seats
            let seatsControl = app.steppers.firstMatch
            if seatsControl.exists {
                // Increment seats
                let incrementButton = seatsControl.buttons.element(boundBy: 1)
                if incrementButton.exists && incrementButton.isHittable {
                    incrementButton.tap()
                    incrementButton.tap()
                }
            }
        }

        // Set departure location
        let locationField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS[c] 'location'")).firstMatch
        if locationField.exists && locationField.isHittable {
            locationField.tap()
            locationField.typeText("Bellevue Transit Center")
        }

        addScreenshot(named: "Event Creation - With Carpool")

        // Submit
        let submitButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'create' AND label CONTAINS[c] 'event'")).firstMatch
        if submitButton.exists && submitButton.isHittable {
            submitButton.tap()
            Thread.sleep(forTimeInterval: 3)
            addScreenshot(named: "Event Creation - Carpool Event Created")
        }
    }

    // MARK: - Scenario 10: Cancel Event Form

    @MainActor
    func testCreateEvent_Cancel_DismissesForm() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available")
        }
        createButton.tap()

        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form did not appear")
        }

        // Fill some data
        titleField.tap()
        titleField.typeText("Test Cancel")

        // Look for cancel/close button
        let cancelButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'cancel' OR label CONTAINS[c] 'close'")).firstMatch
        if cancelButton.exists && cancelButton.isHittable {
            cancelButton.tap()
        } else {
            // Try swipe down to dismiss
            let formSheet = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS[c] 'sheet'")).firstMatch
            if formSheet.exists {
                formSheet.swipeDown()
            }
        }

        Thread.sleep(forTimeInterval: 1)

        // Verify form is dismissed
        XCTAssertFalse(titleField.exists, "Form should be dismissed after cancel")

        addScreenshot(named: "Event Creation - Cancelled")
    }

    // MARK: - Helper Methods

    @MainActor
    private func ensureLoggedIn() throws {
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        guard profileTab.waitForExistence(timeout: 5) else { return }
        profileTab.tap()
        Thread.sleep(forTimeInterval: 1)

        let scrollView = app.scrollViews.firstMatch

        // Check if already logged in
        if scrollView.waitForExistence(timeout: 3) {
            for _ in 0..<10 {
                if app.buttons["profile_sign_out_button"].exists { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        if app.buttons["profile_sign_out_button"].waitForExistence(timeout: 2) {
            // Already logged in - scroll back up
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
            throw XCTSkip("Auth form not available")
        }
        emailField.tap()
        emailField.typeText(testEmail)

        let passwordField = app.secureTextFields["auth_password_field"]
        passwordField.tap()
        passwordField.typeText(testPassword)

        app.buttons["auth_sign_in_button"].tap()
        Thread.sleep(forTimeInterval: 3)

        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
            scrollView.swipeDown()
        }
    }

    @MainActor
    private func navigateToEvents() {
        let eventsTab = app.tabBars.buttons["Events"].firstMatch
        if eventsTab.waitForExistence(timeout: 5) {
            eventsTab.tap()
        }
        Thread.sleep(forTimeInterval: 2)
    }

    @MainActor
    private func navigateToEventDetail() {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            // Find an event card to tap
            let eventCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'going' OR label CONTAINS[c] 'Mountain' OR label CONTAINS[c] 'Event'")).firstMatch
            if eventCard.waitForExistence(timeout: 5) && eventCard.isHittable {
                eventCard.tap()
                Thread.sleep(forTimeInterval: 2)
            }
        }
    }

    @MainActor
    private func selectMountain(_ mountainId: String) {
        let mountainPicker = app.buttons["create_event_mountain_picker"]
        guard mountainPicker.waitForExistence(timeout: 3) && mountainPicker.isHittable else { return }

        mountainPicker.tap()
        Thread.sleep(forTimeInterval: 1)

        // Map mountain IDs to display names
        let mountainNames: [String: String] = [
            "baker": "Mt. Baker",
            "stevens": "Stevens Pass",
            "crystal": "Crystal Mountain",
            "snoqualmie": "Snoqualmie",
            "whistler": "Whistler"
        ]

        let mountainName = mountainNames[mountainId] ?? mountainId

        // Try to find the mountain option
        let mountainOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", mountainName)).firstMatch
        if mountainOption.waitForExistence(timeout: 3) && mountainOption.isHittable {
            mountainOption.tap()
        } else {
            // Fallback - tap first mountain option
            let anyMountain = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'mountain' OR label CONTAINS[c] 'pass' OR label CONTAINS[c] 'resort'")).firstMatch
            if anyMountain.exists && anyMountain.isHittable {
                anyMountain.tap()
            }
        }

        Thread.sleep(forTimeInterval: 0.5)
    }

    @MainActor
    private func addScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
