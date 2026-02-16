//
//  DesignSystem.swift
//  PowderTracker
//
//  Design system constants following iOS HIG and 8pt grid system
//

import SwiftUI
import UIKit

// MARK: - Shadow Styles

extension View {
    /// Subtle shadow for cards (dark mode compatible)
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    /// Elevated shadow for hero cards
    func heroShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
    }

    /// Adaptive shadow that adjusts for dark mode
    /// - Parameters:
    ///   - colorScheme: The current color scheme
    ///   - radius: Base shadow radius (default: 8)
    ///   - y: Vertical offset (default: 4)
    func adaptiveShadow(colorScheme: ColorScheme, radius: CGFloat = 8, y: CGFloat = 4) -> some View {
        self.shadow(
            color: colorScheme == .dark
                ? Color.black.opacity(0.4)
                : Color.black.opacity(0.1),
            radius: colorScheme == .dark ? radius * 1.5 : radius,
            x: 0,
            y: y
        )
    }

    /// Subtle glow effect for highlighted elements
    func glowEffect(color: Color, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius)
    }
}

// MARK: - Material Background Styles

extension View {
    /// Glass morphism background with blur effect
    func glassBackground(cornerRadius: CGFloat = .cornerRadiusCard) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Thick glass background for prominent cards
    func thickGlassBackground(cornerRadius: CGFloat = .cornerRadiusHero) -> some View {
        self
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Subtle glass card with shadow
    func glassCard(padding: CGFloat = .spacingM, cornerRadius: CGFloat = .cornerRadiusCard) -> some View {
        self
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Dynamic Type Support

extension View {
    /// Limits dynamic type size to prevent layout breaks
    /// Caps at accessibility2 for most UI elements
    func limitDynamicType() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Stricter limit for compact UI elements
    /// Caps at accessibility1
    func limitDynamicTypeCompact() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    /// Strictest limit for very constrained spaces
    /// Caps at xxxLarge
    func limitDynamicTypeStrict() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

// MARK: - SF Symbols Enhancements

extension Image {
    /// Creates a hierarchical symbol with specified color
    func hierarchicalSymbol(_ color: Color = .blue) -> some View {
        self
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
    }

    /// Creates a palette symbol with primary and secondary colors
    func paletteSymbol(primary: Color, secondary: Color) -> some View {
        self
            .symbolRenderingMode(.palette)
            .foregroundStyle(primary, secondary)
    }

    /// Creates a multicolor symbol (uses system colors)
    func multicolorSymbol() -> some View {
        self.symbolRenderingMode(.multicolor)
    }
}

// MARK: - Accessibility Helpers

extension View {
    /// Combines children and provides a comprehensive accessibility label
    func accessibleCard(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    /// Makes a button more accessible with label and hint
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}
