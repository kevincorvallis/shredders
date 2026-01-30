//
//  EventDetailSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for event detail views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class EventDetailSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Event Detail View Tests

    func testEventDetailView_infoTab() {
        let event = EventWithDetails.mock()
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEventDetailView_discussionTab_empty() {
        let event = EventWithDetails.mock(commentCount: 0)
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEventDetailView_discussionTab_withComments() {
        let event = EventWithDetails.mock(commentCount: 10)
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEventDetailView_activityTab() {
        let event = EventWithDetails.mock()
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEventDetailView_photosTab_empty() {
        let event = EventWithDetails.mock(photoCount: 0)
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEventDetailView_photosTab_withPhotos() {
        let event = EventWithDetails.mock(photoCount: 15)
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEventDetailView_rsvpGated() {
        let event = EventWithDetails.mock(userRSVPStatus: nil)
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEventDetailView_darkMode() {
        let event = EventWithDetails.mock()
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertDarkModeSnapshot(view)
    }
}
