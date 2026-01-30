//
//  ComponentSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for reusable components.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class ComponentSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Powder Score Gauge Tests

    func testPowderScoreGauge_low() {
        let view = PowderScoreGauge(score: 25)
            .componentSnapshot(width: 150, height: 150)

        assertComponentSnapshot(view)
    }

    func testPowderScoreGauge_medium() {
        let view = PowderScoreGauge(score: 55)
            .componentSnapshot(width: 150, height: 150)

        assertComponentSnapshot(view)
    }

    func testPowderScoreGauge_high() {
        let view = PowderScoreGauge(score: 85)
            .componentSnapshot(width: 150, height: 150)

        assertComponentSnapshot(view)
    }

    // MARK: - Lift Status Card Tests

    func testLiftStatusCard_open() {
        let view = LiftStatusCard(name: "Chair 1", status: "Open", waitTime: "5 min")
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testLiftStatusCard_closed() {
        let view = LiftStatusCard(name: "Chair 2", status: "Closed", waitTime: nil)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testLiftStatusCard_onHold() {
        let view = LiftStatusCard(name: "Chair 3", status: "On Hold", waitTime: nil)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Mountain Conditions Card Tests

    func testMountainConditionsCard_goodConditions() {
        let view = MountainConditionsCard(
            snowDepth: 85,
            newSnow24h: 12,
            temperature: 28
        )
        .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testMountainConditionsCard_poorConditions() {
        let view = MountainConditionsCard(
            snowDepth: 35,
            newSnow24h: 0,
            temperature: 40
        )
        .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Quick Stats Dashboard Tests

    func testQuickStatsDashboard() {
        let view = QuickStatsDashboard()
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Navigation Card Tests

    func testNavigationCard() {
        let view = NavigationCard(
            destination: "Mt. Baker",
            distance: "2h 15min"
        )
        .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Arrival Time Card Tests

    func testArrivalTimeCard() {
        let view = ArrivalTimeCard(
            arrivalTime: "10:30 AM",
            travelTime: "2h 15m"
        )
        .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Today's Pick Card Tests

    func testTodaysPickCard() {
        let mountain = Mountain.mock()
        let view = TodaysPickCard(mountain: mountain)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    // MARK: - Powder Day Outlook Card Tests

    func testPowderDayOutlookCard() {
        let forecast = ForecastDay.mockPowderDay()
        let view = PowderDayOutlookCard(forecast: forecast)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }
}
