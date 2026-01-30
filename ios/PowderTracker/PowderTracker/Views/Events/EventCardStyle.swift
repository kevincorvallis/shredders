import SwiftUI

/// Shared styling constants for event cards - provides consistent dark slate theme
enum EventCardStyle {
    // MARK: - Helper

    private static func hexColor(_ hex: String) -> Color {
        Color(hex: hex) ?? .gray
    }

    // MARK: - Background Colors (Always dark slate theme)

    /// Primary background for event cards - dark slate
    static var backgroundColor: Color {
        hexColor("1E293B").opacity(0.7)
    }

    /// Border color for event cards
    static var borderColor: Color {
        hexColor("334155").opacity(0.5)
    }

    // MARK: - Text Colors (White-based for dark background)

    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.6)
    static let tertiaryText = Color.white.opacity(0.4)

    // MARK: - Accent Colors

    /// Mountain icon color (cyan)
    static var mountainIconColor: Color {
        hexColor("0EA5E9")
    }

    /// Carpool badge color (green)
    static var carpoolColor: Color {
        hexColor("10B981")
    }

    /// Host badge color
    static let hostBadgeColor = Color.blue

    // MARK: - Skill Level Colors

    static var beginnerColor: Color {
        hexColor("22C55E")
    }

    static var intermediateColor: Color {
        hexColor("3B82F6")
    }

    static var allLevelsColor: Color {
        hexColor("A855F7")
    }

    // MARK: - Layout

    static let cornerRadius: CGFloat = 16
    static let borderWidth: CGFloat = 1
    static let cardPadding: CGFloat = 16
    static let innerSpacing: CGFloat = 12
    static let badgeHorizontalPadding: CGFloat = 10
    static let badgeVerticalPadding: CGFloat = 6
}

// MARK: - View Modifier

/// View modifier that applies consistent event card styling
struct EventCardBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(EventCardStyle.cardPadding)
            .background(EventCardStyle.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: EventCardStyle.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: EventCardStyle.cornerRadius)
                    .stroke(EventCardStyle.borderColor, lineWidth: EventCardStyle.borderWidth)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// Applies the standard event card background styling
    func eventCardBackground() -> some View {
        modifier(EventCardBackgroundModifier())
    }
}
