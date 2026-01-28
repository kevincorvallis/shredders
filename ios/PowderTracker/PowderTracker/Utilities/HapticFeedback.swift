//
//  HapticFeedback.swift
//  PowderTracker
//
//  Reusable haptic feedback system following Apple HIG
//

import UIKit

/// Haptic feedback types for consistent tactile experiences
@MainActor
enum HapticFeedback {
    /// Light impact - for subtle UI elements
    case light
    /// Medium impact - for standard interactions
    case medium
    /// Heavy impact - for significant actions
    case heavy
    /// Selection changed - for picker/toggle changes
    case selection
    /// Success notification - for completed actions
    case success
    /// Warning notification - for cautionary feedback
    case warning
    /// Error notification - for failed actions
    case error

    /// Whether haptics are currently enabled (respects system Reduce Motion setting)
    private static var isEnabled: Bool {
        !UIAccessibility.isReduceMotionEnabled
    }

    /// Triggers the haptic feedback
    /// Call on user-initiated actions for tactile response
    /// Respects system "Reduce Motion" accessibility setting
    func trigger() {
        guard Self.isEnabled else { return }

        switch self {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()

        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()

        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()

        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()

        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)

        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)

        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
    }

    /// Triggers haptic with intensity (0.0 to 1.0) - iOS 13+
    /// Only works with impact styles
    /// Respects system "Reduce Motion" accessibility setting
    func trigger(intensity: CGFloat) {
        guard Self.isEnabled else { return }

        switch self {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)

        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)

        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)

        default:
            // Notification and selection types don't support intensity
            trigger()
        }
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Adds haptic feedback when a value changes
    func hapticFeedback<T: Equatable>(
        _ feedback: HapticFeedback,
        trigger value: T
    ) -> some View {
        self.onChange(of: value) { _, _ in
            feedback.trigger()
        }
    }

    /// Adds haptic feedback on tap
    func hapticOnTap(_ feedback: HapticFeedback = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                feedback.trigger()
            }
        )
    }
}
