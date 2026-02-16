//
//  TypographyHelpers.swift
//  PowderTracker
//
//  Typography view modifiers and animated number transitions
//

import SwiftUI

// MARK: - Typography Helpers

extension View {
    /// Apply consistent font styling
    func heroNumber() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .fontDesign(.rounded)
    }

    func sectionHeader() -> some View {
        self
            .font(.system(.headline, design: .serif))
            .fontWeight(.medium)
    }

    func cardTitle() -> some View {
        self
            .font(.system(.title3, design: .serif))
            .fontWeight(.medium)
    }

    func metric() -> some View {
        self
            .font(.subheadline)
            .fontWeight(.semibold)
    }

    func badge() -> some View {
        self
            .font(.caption2)
            .fontWeight(.bold)
    }
}

// MARK: - Animated Number Transitions

extension View {
    /// Applies numeric text transition for animated number changes
    func animatedNumber() -> some View {
        self.contentTransition(.numericText())
    }

    /// Animated metric value with numeric transition
    func animatedMetricValue(size: Font.TextStyle = .subheadline) -> some View {
        self
            .font(.system(size, design: .rounded))
            .fontWeight(.semibold)
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}
