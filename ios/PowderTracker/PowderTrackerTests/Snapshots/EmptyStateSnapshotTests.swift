//
//  EmptyStateSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for empty state views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class EmptyStateSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Specific Empty State Tests

    func testEmptyStateView_noFavorites() {
        let view = FavoritesEmptyState()
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEmptyStateView_noEvents() {
        let view = EmptyStateView(
            icon: "calendar.badge.exclamationmark",
            title: "No Events",
            message: "No upcoming ski events to show"
        )
        .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Generic State Views Tests

    func testGenericEmptyStateView() {
        let view = GenericEmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try adjusting your search criteria"
        )
        .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testGenericErrorStateView() {
        let view = GenericErrorStateView(
            error: "Connection failed",
            retryAction: {}
        )
        .componentSnapshot()

        assertComponentSnapshot(view)
    }
}
