//
//  EventCardSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for event card components.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class EventCardSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Event Card Tests

    func testEventCard_upcomingNotRsvpd() {
        let event = Event.mock(userRSVPStatus: nil)
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_rsvpGoing() {
        let event = Event.mockWithRSVP(.going)
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_rsvpMaybe() {
        let event = Event.mockWithRSVP(.maybe)
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_rsvpNotGoing() {
        let event = Event.mockWithRSVP(.declined)
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_fullCapacity() {
        let event = Event.mockFullCapacity()
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_almostFull() {
        let event = Event.mock(attendeeCount: 9, goingCount: 9, maybeCount: 0)
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_pastEvent() {
        let event = Event.mockPastEvent()
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_manyAttendees() {
        let event = Event.mock(attendeeCount: 20, goingCount: 15, maybeCount: 5)
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_creatorView() {
        let event = Event.mock(isCreator: true)
        let view = EventCard(event: event)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEventCard_darkMode() {
        let event = Event.mock()
        let view = EventCard(event: event)
            .componentSnapshot()

        assertDarkModeSnapshot(view)
    }
}
