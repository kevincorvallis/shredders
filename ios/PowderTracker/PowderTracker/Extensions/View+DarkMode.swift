import SwiftUI
import UIKit

// MARK: - Dark Mode View Extensions

extension View {
    /// Apply an adaptive shadow that only appears in light mode
    /// - Parameters:
    ///   - colorScheme: The current color scheme
    ///   - color: Shadow color (default: black with 10% opacity)
    ///   - radius: Shadow blur radius
    ///   - x: Horizontal offset
    ///   - y: Vertical offset
    /// - Returns: View with conditional shadow
    func adaptiveShadow(
        colorScheme: ColorScheme,
        color: Color = Color.black.opacity(0.1),
        radius: CGFloat = 4,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> some View {
        self.shadow(
            color: colorScheme == .dark ? .clear : color,
            radius: radius,
            x: x,
            y: y
        )
    }

    /// Apply an adaptive border with colors that work in both light and dark mode
    /// - Parameters:
    ///   - colorScheme: The current color scheme
    ///   - cornerRadius: Border corner radius
    ///   - lineWidth: Border width (default: 0.5)
    /// - Returns: View with adaptive border
    func adaptiveBorder(
        colorScheme: ColorScheme,
        cornerRadius: CGFloat = 12,
        lineWidth: CGFloat = 0.5
    ) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.1)
                        : Color.black.opacity(0.05),
                    lineWidth: lineWidth
                )
        )
    }

    /// Apply an adaptive card background with system colors
    /// - Parameters:
    ///   - cornerRadius: Card corner radius
    ///   - includeBorder: Whether to include a subtle border
    /// - Returns: View with card background
    func adaptiveCard(
        cornerRadius: CGFloat = 16,
        includeBorder: Bool = true
    ) -> some View {
        modifier(AdaptiveCardModifier(cornerRadius: cornerRadius, includeBorder: includeBorder))
    }

    /// Apply adaptive brightness and contrast for better visibility in dark mode
    /// - Parameter colorScheme: The current color scheme
    /// - Returns: View with adaptive image enhancements
    func adaptiveImageEnhancement(colorScheme: ColorScheme) -> some View {
        self
            .brightness(colorScheme == .dark ? 0.05 : 0)
            .contrast(colorScheme == .dark ? 1.05 : 1.0)
    }
}

// MARK: - Adaptive Card Modifier

struct AdaptiveCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let includeBorder: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                Group {
                    if includeBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.1)
                                    : Color.black.opacity(0.05),
                                lineWidth: 0.5
                            )
                    }
                }
            )
            .shadow(
                color: colorScheme == .dark ? .clear : Color.black.opacity(0.08),
                radius: 8,
                y: 4
            )
    }
}

// MARK: - Color Extensions

extension Color {
    /// Adaptive overlay color for images (dark overlay in light mode, light in dark mode)
    static func adaptiveOverlay(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.15)
            : Color.black.opacity(0.5)
    }

    /// Adaptive text color for overlays
    static func adaptiveOverlayText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .white
            : .white
    }

    /// Adaptive background for logo/image containers
    static func adaptiveLogoBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(UIColor.systemGray5)
            : Color(UIColor.systemGray6)
    }

    /// Adaptive divider color
    static func adaptiveDivider(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.1)
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {
    /// Create an adaptive gradient for mountain branding
    static func mountainBranding(
        hexColor: String,
        colorScheme: ColorScheme
    ) -> LinearGradient {
        let brandColor = Color(hex: hexColor) ?? .blue
        LinearGradient(
            colors: [
                brandColor.opacity(colorScheme == .dark ? 0.3 : 0.2),
                brandColor.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Create an adaptive dark overlay gradient for images
    static func imageOverlay(colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.clear,
                Color.adaptiveOverlay(for: colorScheme)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Accessibility Extensions

extension View {
    /// Mark view as an accessible card with proper labeling
    func accessibleCard(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(hint ?? "")
    }

    /// Mark button with proper accessibility
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension View {
    /// Preview in both light and dark modes side by side
    func previewInBothModes(name: String = "Component") -> some View {
        Group {
            self
                .preferredColorScheme(.light)
                .previewDisplayName("\(name) - Light")

            self
                .preferredColorScheme(.dark)
                .previewDisplayName("\(name) - Dark")
        }
    }
}
#endif
