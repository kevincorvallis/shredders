//
//  ButtonStyles.swift
//  PowderTracker
//
//  Glassmorphic button styles, navigation haptic, and gradient status pills
//

import SwiftUI

// MARK: - Glassmorphic Button Style

/// A button style with glassmorphic appearance for primary actions
struct GlassmorphicButtonStyle: ButtonStyle {
    var isProminent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(isProminent ? .white : .primary)
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingM)
            .background {
                if isProminent {
                    LinearGradient.powderBlue
                } else {
                    Color.clear
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusButton))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.05 : 0.1), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.snappy, value: configuration.isPressed)
    }
}

/// Secondary glassmorphic button style (less prominent)
struct GlassmorphicSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMicro))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusMicro)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.snappy, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassmorphicButtonStyle {
    /// Primary glassmorphic button style
    static var glassmorphic: GlassmorphicButtonStyle { GlassmorphicButtonStyle() }

    /// Non-prominent glassmorphic button style
    static var glassmorphicSubtle: GlassmorphicButtonStyle { GlassmorphicButtonStyle(isProminent: false) }
}

extension ButtonStyle where Self == GlassmorphicSecondaryButtonStyle {
    /// Secondary glassmorphic button style for less prominent actions
    static var glassmorphicSecondary: GlassmorphicSecondaryButtonStyle { GlassmorphicSecondaryButtonStyle() }
}

// MARK: - Navigation Haptic Modifier

extension View {
    /// Adds light haptic feedback when tapped - use for navigation actions
    func navigationHaptic() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticFeedback.light.trigger()
                }
        )
    }

    /// Wraps view with sensory feedback for iOS 17+ navigation
    @ViewBuilder
    func withNavigationFeedback() -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.impact(flexibility: .soft), trigger: true)
        } else {
            self.navigationHaptic()
        }
    }
}

/// Button style that triggers light haptic on press - ideal for navigation buttons
struct NavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticFeedback.light.trigger()
                }
            }
    }
}

extension ButtonStyle where Self == NavigationButtonStyle {
    /// Button style with light haptic feedback for navigation
    static var navigation: NavigationButtonStyle { NavigationButtonStyle() }
}

// MARK: - Gradient Status Pills

extension View {
    /// Status pill with gradient background based on score
    func gradientStatusPill(score: Double, padding: CGFloat = .spacingS) -> some View {
        self
            .padding(.horizontal, padding)
            .padding(.vertical, padding * 0.5)
            .background(
                LinearGradient.forScore(score)
                    .opacity(0.9)
            )
            .clipShape(Capsule())
    }

    /// Status pill with custom gradient
    func gradientPill(_ gradient: LinearGradient, padding: CGFloat = .spacingS) -> some View {
        self
            .padding(.horizontal, padding)
            .padding(.vertical, padding * 0.5)
            .background(gradient)
            .clipShape(Capsule())
    }
}
