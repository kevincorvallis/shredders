//
//  SkeletonSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for skeleton loading views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class SkeletonSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Basic Skeleton Tests

    func testSkeletonView_rectangle() {
        let view = SkeletonView()
            .frame(width: 200, height: 100)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Dashboard Skeleton Tests

    func testDashboardSkeleton() {
        let view = DashboardSkeleton()
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Forecast Skeleton Tests

    func testForecastSkeleton() {
        let view = ForecastSkeleton()
            .componentSnapshot()

        assertComponentSnapshot(view)
    }
}
