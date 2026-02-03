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

    // MARK: - Multi-Device Tests

    func testEventDetailView_multiDevice() {
        let event = EventWithDetails.mock()
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        SnapshotTestHelper.assertMultiDeviceSnapshot(
            of: view,
            devices: SnapshotTestHelper.allDevices
        )
    }

    func testEventDetailView_multiDevice_manyAttendees() {
        let event = EventWithDetails.mock(attendeeCount: 25, goingCount: 20, maybeCount: 5)
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        SnapshotTestHelper.assertMultiDeviceSnapshot(
            of: view,
            devices: SnapshotTestHelper.allDevices
        )
    }

    func testEventDetailView_iPad() {
        let event = EventWithDetails.mock()
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertViewSnapshot(view, device: .iPadPro11)
    }

    // MARK: - Dynamic Type Tests

    func testEventDetailView_dynamicType() {
        let event = EventWithDetails.mock()
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        SnapshotTestHelper.assertDynamicTypeSnapshot(of: view)
    }

    func testEventDetailView_accessibilityXXL() {
        let event = EventWithDetails.mock()
        let view = EventDetailView(eventId: event.id)
            .snapshotContainer()

        assertAccessibilitySnapshot(view)
    }
}
