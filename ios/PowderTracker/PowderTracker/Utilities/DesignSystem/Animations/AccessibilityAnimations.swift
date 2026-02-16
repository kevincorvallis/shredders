//
//  AccessibilityAnimations.swift
//  PowderTracker
//
//  Accessibility-aware animation helpers
//

import SwiftUI
import UIKit

// MARK: - Accessibility-Aware Animations

extension View {
    /// Applies animation only when Reduce Motion is not enabled
    @ViewBuilder
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }

    /// Spring animation that respects Reduce Motion
    @ViewBuilder
    func accessibleSpring<V: Equatable>(response: Double = 0.4, dampingFraction: Double = 0.7, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(.spring(response: response, dampingFraction: dampingFraction), value: value)
        }
    }
}

/// Environment value for checking reduce motion preference
struct AccessibleAnimationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
    }
}
