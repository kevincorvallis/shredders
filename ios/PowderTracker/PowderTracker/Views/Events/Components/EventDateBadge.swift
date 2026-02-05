//
//  EventDateBadge.swift
//  PowderTracker
//
//  Compact date display badge for event cards.
//

import SwiftUI

/// Displays a compact date badge with day number and month abbreviation
struct EventDateBadge: View {
    let dateString: String // Format: yyyy-MM-dd
    var style: Style = .standard

    enum Style {
        case standard
        case compact
        case filled

        var width: CGFloat {
            switch self {
            case .standard: return 44
            case .compact: return 36
            case .filled: return 48
            }
        }

        var dayFont: Font {
            switch self {
            case .standard: return .title2
            case .compact: return .title3
            case .filled: return .title2
            }
        }

        var monthFont: Font {
            switch self {
            case .standard, .filled: return .caption2
            case .compact: return .system(size: 9)
            }
        }
    }

    private static let dateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private var parsedDate: Date? {
        Self.dateParser.date(from: dateString)
    }

    private var dayOfMonth: String {
        guard let date = parsedDate else { return "--" }
        return Self.dayFormatter.string(from: date)
    }

    private var monthAbbrev: String {
        guard let date = parsedDate else { return "---" }
        return Self.monthFormatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(dayOfMonth)
                .font(style.dayFont)
                .fontWeight(.bold)
                .foregroundStyle(textColor)

            Text(monthAbbrev)
                .font(style.monthFont)
                .fontWeight(.semibold)
                .foregroundStyle(secondaryTextColor)
                .textCase(.uppercase)
        }
        .frame(width: style.width)
        .padding(.vertical, .spacingS)
        .background(backgroundColor)
        .cornerRadius(.cornerRadiusButton)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Colors

    private var textColor: Color {
        switch style {
        case .filled:
            return .white
        default:
            return EventCardStyle.primaryText
        }
    }

    private var secondaryTextColor: Color {
        switch style {
        case .filled:
            return .white.opacity(0.8)
        default:
            return EventCardStyle.secondaryText
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return .pookieCyan
        default:
            return Color.white.opacity(0.1)
        }
    }

    private var accessibilityLabel: String {
        guard let date = parsedDate else { return dateString }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Date Badges") {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            EventDateBadge(dateString: "2026-02-04", style: .compact)
            EventDateBadge(dateString: "2026-02-04", style: .standard)
            EventDateBadge(dateString: "2026-02-04", style: .filled)
        }

        HStack(spacing: 16) {
            EventDateBadge(dateString: "2026-12-25", style: .compact)
            EventDateBadge(dateString: "2026-12-25", style: .standard)
            EventDateBadge(dateString: "2026-12-25", style: .filled)
        }
    }
    .padding()
    .background(Color(hex: "1E293B"))
}
