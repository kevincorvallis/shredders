import SwiftUI

/// A reusable badge/pill component that consolidates multiple badge variants
/// Consolidates: Badge, StatPill, InfoPill, LiftStatusBadge, TimeWindowPill, FactorPill
struct BadgeView: View {
    enum Style {
        case iconOnly           // Just icon with colored background
        case textOnly           // Just text with colored background
        case iconAndText        // Icon + text side by side
        case statusDot          // Small colored dot + text
        case valueWithLabel     // Value on top, label below (vertical)
    }

    let icon: String?
    let text: String?
    let value: String?
    let label: String?
    let color: Color
    var style: Style = .textOnly
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small
        case medium
        case large
    }

    var body: some View {
        Group {
            switch style {
            case .iconOnly:
                iconOnlyView
            case .textOnly:
                textOnlyView
            case .iconAndText:
                iconAndTextView
            case .statusDot:
                statusDotView
            case .valueWithLabel:
                valueWithLabelView
            }
        }
    }

    // MARK: - Style Variants

    private var iconOnlyView: some View {
        Image(systemName: icon ?? "circle.fill")
            .font(iconFont)
            .foregroundColor(color)
            .frame(width: iconSize, height: iconSize)
            .background(
                Circle()
                    .fill(color.opacity(.opacityMedium))
            )
    }

    private var textOnlyView: some View {
        Text(text ?? "")
            .font(textFont)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(color.opacity(.opacityMedium))
            )
    }

    private var iconAndTextView: some View {
        HStack(spacing: .spacingXS) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(iconFont)
            }
            if let text = text {
                Text(text)
                    .font(textFont)
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            Capsule()
                .fill(color.opacity(.opacityMedium))
        )
    }

    private var statusDotView: some View {
        HStack(spacing: .spacingXS) {
            Circle()
                .fill(color)
                .frame(width: .statusDotSize, height: .statusDotSize)

            if let text = text {
                Text(text)
                    .font(textFont)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            Capsule()
                .fill(color.opacity(.opacityMedium))
        )
    }

    private var valueWithLabelView: some View {
        VStack(spacing: .spacingXS) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(iconFont)
                    .foregroundColor(color)
            }

            if let value = value {
                Text(value)
                    .font(valueFont)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            if let label = label {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, verticalPadding)
    }

    // MARK: - Size Calculations

    private var iconFont: Font {
        switch size {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .title3
        }
    }

    private var textFont: Font {
        switch size {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        }
    }

    private var valueFont: Font {
        switch size {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .headline
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: return 24
        case .medium: return 32
        case .large: return 40
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return .spacingXS
        case .medium: return .spacingS
        case .large: return .spacingM
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 2
        case .medium: return .spacingXS
        case .large: return .spacingS
        }
    }
}

// MARK: - Preview

#Preview("Badge Styles") {
    VStack(spacing: .spacingL) {
        // Icon Only
        BadgeView(
            icon: "checkmark.circle.fill",
            text: nil,
            value: nil,
            label: nil,
            color: .green,
            style: .iconOnly,
            size: .medium
        )

        // Text Only
        BadgeView(
            icon: nil,
            text: "High Confidence",
            value: nil,
            label: nil,
            color: .green,
            style: .textOnly,
            size: .medium
        )

        // Icon and Text
        BadgeView(
            icon: "snow",
            text: "Fresh Powder",
            value: nil,
            label: nil,
            color: .blue,
            style: .iconAndText,
            size: .medium
        )

        // Status Dot
        BadgeView(
            icon: nil,
            text: "Open",
            value: nil,
            label: nil,
            color: .green,
            style: .statusDot,
            size: .medium
        )

        // Value with Label
        BadgeView(
            icon: "thermometer",
            text: nil,
            value: "28°F",
            label: "Temperature",
            color: .cyan,
            style: .valueWithLabel,
            size: .medium
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Size Variants") {
    VStack(spacing: .spacingL) {
        BadgeView(
            icon: "snow",
            text: "Small Badge",
            value: nil,
            label: nil,
            color: .blue,
            style: .iconAndText,
            size: .small
        )

        BadgeView(
            icon: "snow",
            text: "Medium Badge",
            value: nil,
            label: nil,
            color: .blue,
            style: .iconAndText,
            size: .medium
        )

        BadgeView(
            icon: "snow",
            text: "Large Badge",
            value: nil,
            label: nil,
            color: .blue,
            style: .iconAndText,
            size: .large
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
