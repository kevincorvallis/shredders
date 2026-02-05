//
//  RSVPStatusBadge.swift
//  PowderTracker
//
//  Reusable RSVP status badge component.
//

import SwiftUI

/// Displays the user's RSVP status with icon and label
struct RSVPStatusBadge: View {
    let status: RSVPStatus
    var showLabel: Bool = true
    var size: Size = .standard

    enum Size {
        case compact
        case standard

        var font: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            }
        }

        var iconFont: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return 6
            case .standard: return 8
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact: return 3
            case .standard: return 4
            }
        }
    }

    var body: some View {
        HStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(size.iconFont)

            if showLabel {
                Text(status.displayName)
                    .font(size.font)
                    .fontWeight(.semibold)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("RSVP status: \(status.displayName)")
    }

    // MARK: - Styling

    private var icon: String {
        switch status {
        case .going: return "checkmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        case .invited: return "envelope.fill"
        case .declined: return "xmark.circle.fill"
        case .waitlist: return "hourglass"
        }
    }

    private var color: Color {
        switch status {
        case .going: return .green
        case .maybe: return .orange
        case .invited: return .blue
        case .declined: return .secondary
        case .waitlist: return .purple
        }
    }
}

// MARK: - Preview

#Preview("All Statuses") {
    VStack(spacing: 12) {
        ForEach([RSVPStatus.going, .maybe, .invited, .declined, .waitlist], id: \.self) { status in
            HStack(spacing: 16) {
                RSVPStatusBadge(status: status, size: .compact)
                RSVPStatusBadge(status: status, size: .standard)
                RSVPStatusBadge(status: status, showLabel: false)
            }
        }
    }
    .padding()
}
