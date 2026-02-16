//
//  AnimationConstants.swift
//  PowderTracker
//
//  Animation presets and powder day shimmer effect
//

import SwiftUI

// MARK: - Animation Constants

extension Animation {
    /// Standard spring animation for UI interactions
    static let standardSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Smooth ease for subtle transitions
    static let smoothEase = Animation.easeInOut(duration: 0.3)

    /// Bouncy spring for playful interactions (cards, buttons)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.25)

    /// Snappy spring for quick state changes (toggles, selections)
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Smooth spring for elegant transitions (modals, sheets)
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.85)

    /// Quick interactive response for immediate feedback
    static let interactive = Animation.interactiveSpring(response: 0.15, dampingFraction: 0.86)
}

// MARK: - Powder Day Alert Animation

/// Animated shimmer effect for powder day alerts
struct PowderDayShimmer: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

extension View {
    /// Applies animated shimmer effect for powder day alerts
    func powderDayShimmer() -> some View {
        modifier(PowderDayShimmer())
    }
}
