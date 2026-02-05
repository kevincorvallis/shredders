//
//  CarpoolBadge.swift
//  PowderTracker
//
//  Reusable carpool availability badge component.
//

import SwiftUI

/// Displays carpool availability with optional seat count
struct CarpoolBadge: View {
    var seats: Int? = nil
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

    private var color: Color {
        Color(hex: "10B981") ?? .green
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "car.fill")
                .font(size.font)

            if showLabel {
                if let seats = seats, seats > 0 {
                    Text("Carpool • \(seats) seats")
                        .font(size.font)
                } else {
                    Text("Carpool")
                        .font(size.font)
                }
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let seats = seats, seats > 0 {
            return "Carpool available with \(seats) seats"
        }
        return "Carpool available"
    }
}

// MARK: - Preview

#Preview("Carpool Badges") {
    VStack(spacing: 12) {
        CarpoolBadge()
        CarpoolBadge(seats: 4)
        CarpoolBadge(seats: 2, size: .compact)
        CarpoolBadge(showLabel: false)
    }
    .padding()
}
