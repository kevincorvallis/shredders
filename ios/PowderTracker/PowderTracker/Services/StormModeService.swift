//
//  StormModeService.swift
//  PowderTracker
//
//  Service for tracking active winter storms across mountains
//

import Foundation
import SwiftUI

/// Service for tracking active storms and providing storm mode UI data
@MainActor
class StormModeService: ObservableObject {
    static let shared = StormModeService()

    @Published private(set) var activeStorms: [String: StormInfo] = [:]
    @Published private(set) var mostSignificantStorm: (mountainId: String, storm: StormInfo)?

    private init() {}

    // MARK: - Storm Tracking

    /// Update storm info for a mountain from powder score data
    func updateStorm(for mountainId: String, stormInfo: StormInfo?) {
        if let storm = stormInfo, storm.isActive {
            activeStorms[mountainId] = storm
        } else {
            activeStorms.removeValue(forKey: mountainId)
        }
        updateMostSignificant()
    }

    /// Clear all storm data
    func clearAll() {
        activeStorms.removeAll()
        mostSignificantStorm = nil
    }

    /// Check if any mountain has an active storm
    var hasActiveStorm: Bool {
        !activeStorms.isEmpty
    }

    /// Get count of mountains with active storms
    var activeStormCount: Int {
        activeStorms.count
    }

    // MARK: - Private

    private func updateMostSignificant() {
        // Sort by intensity (extreme > heavy > moderate > light), then by expected snowfall
        let sorted = activeStorms.sorted { a, b in
            let aIntensity = a.value.intensity.sortOrder
            let bIntensity = b.value.intensity.sortOrder
            if aIntensity != bIntensity {
                return aIntensity < bIntensity // Lower = more severe
            }
            return (a.value.expectedSnowfall ?? 0) > (b.value.expectedSnowfall ?? 0)
        }

        if let first = sorted.first {
            mostSignificantStorm = (mountainId: first.key, storm: first.value)
        } else {
            mostSignificantStorm = nil
        }
    }
}

// MARK: - StormIntensity Extensions

extension StormIntensity {
    /// Sort order (lower = more severe)
    var sortOrder: Int {
        switch self {
        case .extreme: return 0
        case .heavy: return 1
        case .moderate: return 2
        case .light: return 3
        }
    }

    /// Color for this intensity level
    var color: Color {
        switch self {
        case .light: return .blue
        case .moderate: return .cyan
        case .heavy: return .purple
        case .extreme: return .red
        }
    }

    /// Gradient colors for banner background
    var gradientColors: [Color] {
        switch self {
        case .light:
            return [Color.blue.opacity(0.7), Color.cyan.opacity(0.5)]
        case .moderate:
            return [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)]
        case .heavy:
            return [Color.purple.opacity(0.8), Color.blue.opacity(0.7)]
        case .extreme:
            return [Color.red.opacity(0.8), Color.purple.opacity(0.7)]
        }
    }

    /// Secondary color for accents
    var accentColor: Color {
        switch self {
        case .light: return .white
        case .moderate: return .white
        case .heavy: return .yellow
        case .extreme: return .yellow
        }
    }
}
