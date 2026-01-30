//
//  SnapshotTestConfig.swift
//  PowderTrackerTests
//
//  Configuration and helpers for snapshot testing.
//

import SnapshotTesting
import SwiftUI
import XCTest

// MARK: - Device Configurations

/// Standard device configurations for snapshot testing
enum SnapshotDevice {
    case iPhoneSE
    case iPhone15Pro
    case iPhone15ProMax
    case iPadPro11

    var config: ViewImageConfig {
        switch self {
        case .iPhoneSE:
            return .iPhoneSe
        case .iPhone15Pro:
            return .iPhone13Pro // Use iPhone 13 Pro as proxy
        case .iPhone15ProMax:
            return .iPhone13ProMax // Use iPhone 13 Pro Max as proxy
        case .iPadPro11:
            return .iPadPro11
        }
    }

    var name: String {
        switch self {
        case .iPhoneSE: return "iPhoneSE"
        case .iPhone15Pro: return "iPhone15Pro"
        case .iPhone15ProMax: return "iPhone15ProMax"
        case .iPadPro11: return "iPadPro11"
        }
    }
}

// MARK: - Trait Configurations

/// UI trait configurations for different appearances
struct SnapshotTraits {
    /// Light mode traits
    static let light = UITraitCollection(userInterfaceStyle: .light)

    /// Dark mode traits
    static let dark = UITraitCollection(userInterfaceStyle: .dark)

    /// Small Dynamic Type
    static let smallText = UITraitCollection(preferredContentSizeCategory: .small)

    /// Default Dynamic Type
    static let defaultText = UITraitCollection(preferredContentSizeCategory: .large)

    /// Accessibility XXL Dynamic Type
    static let accessibilityXXL = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraLarge)

    /// Accessibility XXXL Dynamic Type (largest)
    static let accessibilityXXXL = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

    /// Combine multiple traits
    static func combined(_ traits: UITraitCollection...) -> UITraitCollection {
        var combined = UITraitCollection()
        for trait in traits {
            combined = UITraitCollection(traitsFrom: [combined, trait])
        }
        return combined
    }
}

// MARK: - Snapshot Test Helpers

/// Helper class for multi-configuration snapshot testing
class SnapshotTestHelper {
    /// Standard devices for multi-device testing
    static let standardDevices: [SnapshotDevice] = [
        .iPhoneSE,
        .iPhone15Pro,
        .iPhone15ProMax
    ]

    /// All devices including iPad
    static let allDevices: [SnapshotDevice] = [
        .iPhoneSE,
        .iPhone15Pro,
        .iPhone15ProMax,
        .iPadPro11
    ]

    /// Assert snapshot for multiple devices
    static func assertMultiDeviceSnapshot<V: View>(
        of view: V,
        devices: [SnapshotDevice] = standardDevices,
        traits: UITraitCollection = SnapshotTraits.light,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        for device in devices {
            let combinedTraits = UITraitCollection(traitsFrom: [traits])
            assertSnapshot(
                of: view,
                as: .image(layout: .device(config: device.config), traits: combinedTraits),
                named: device.name,
                record: record,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    /// Assert snapshot for light and dark mode
    static func assertLightDarkSnapshot<V: View>(
        of view: V,
        device: SnapshotDevice = .iPhone15Pro,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        // Light mode
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: device.config), traits: SnapshotTraits.light),
            named: "light",
            record: record,
            file: file,
            testName: testName,
            line: line
        )

        // Dark mode
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: device.config), traits: SnapshotTraits.dark),
            named: "dark",
            record: record,
            file: file,
            testName: testName,
            line: line
        )
    }

    /// Assert snapshot for different Dynamic Type sizes
    static func assertDynamicTypeSnapshot<V: View>(
        of view: V,
        device: SnapshotDevice = .iPhone15Pro,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let sizes: [(UITraitCollection, String)] = [
            (SnapshotTraits.smallText, "small"),
            (SnapshotTraits.defaultText, "default"),
            (SnapshotTraits.accessibilityXXL, "accessibilityXXL")
        ]

        for (trait, name) in sizes {
            assertSnapshot(
                of: view,
                as: .image(layout: .device(config: device.config), traits: trait),
                named: name,
                record: record,
                file: file,
                testName: testName,
                line: line
            )
        }
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Wrap view for snapshot testing with a hosting controller
    func snapshotContainer() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }

    /// Wrap view in a fixed size for component snapshots
    func componentSnapshot(width: CGFloat = 375, height: CGFloat? = nil) -> some View {
        self
            .frame(width: width, height: height)
            .background(Color(.systemBackground))
    }
}

// MARK: - XCTestCase Extensions

extension XCTestCase {
    /// Assert a single snapshot with standard configuration
    func assertViewSnapshot<V: View>(
        _ view: V,
        device: SnapshotDevice = .iPhone15Pro,
        traits: UITraitCollection = SnapshotTraits.light,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: device.config), traits: traits),
            record: record,
            file: file,
            testName: testName,
            line: line
        )
    }

    /// Assert dark mode snapshot
    func assertDarkModeSnapshot<V: View>(
        _ view: V,
        device: SnapshotDevice = .iPhone15Pro,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: device.config), traits: SnapshotTraits.dark),
            record: record,
            file: file,
            testName: testName,
            line: line
        )
    }

    /// Assert accessibility snapshot
    func assertAccessibilitySnapshot<V: View>(
        _ view: V,
        device: SnapshotDevice = .iPhone15Pro,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: device.config), traits: SnapshotTraits.accessibilityXXL),
            record: record,
            file: file,
            testName: testName,
            line: line
        )
    }

    /// Assert component snapshot (fixed width, flexible height)
    func assertComponentSnapshot<V: View>(
        _ view: V,
        width: CGFloat = 375,
        traits: UITraitCollection = SnapshotTraits.light,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let wrappedView = view
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(.systemBackground))

        assertSnapshot(
            of: wrappedView,
            as: .image(traits: traits),
            record: record,
            file: file,
            testName: testName,
            line: line
        )
    }
}

// MARK: - Recording Mode Helper

/// Global flag for recording new snapshots (set to true when updating baselines)
var isRecordingSnapshots: Bool {
    // Check environment variable for CI override
    ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "true"
}
