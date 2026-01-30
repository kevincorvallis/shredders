//
//  EventCreateEditSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for event create and edit views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class EventCreateEditSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Event Create View Tests

    func testEventCreateView_emptyForm() {
        let view = EventCreateView(mountainId: "baker", mountainName: "Mt. Baker")
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEventCreateView_filledForm() {
        // Note: Would need to pre-populate form state
        let view = EventCreateView(mountainId: "baker", mountainName: "Mt. Baker")
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Event Edit View Tests

    func testEventEditView_existingEvent() {
        let event = EventWithDetails.mock()
        let view = EventEditView(event: event)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Location Picker Tests

    func testLocationPickerView_searchResults() {
        let view = LocationPickerView(selectedLocation: .constant(""))
            .snapshotContainer()

        assertViewSnapshot(view)
    }
}
