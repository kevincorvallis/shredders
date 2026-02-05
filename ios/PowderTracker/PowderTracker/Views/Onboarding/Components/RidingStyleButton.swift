//
//  RidingStyleButton.swift
//  PowderTracker
//
//  Riding style selection button for onboarding - Skier, Snowboarder, or Both.
//

import SwiftUI

struct RidingStyleButton: View {
    let style: RidingStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacingS) {
                // Icon with animated state
                ZStack {
                    // Background circle with gradient
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [style.color.opacity(0.3), style.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color(.tertiarySystemBackground), Color(.tertiarySystemBackground)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 64, height: 64)

                    // SF Symbol icon
                    Image(systemName: style.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(isSelected ? style.color : .secondary)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? style.color : Color.clear, lineWidth: 2.5)
                        .frame(width: 64, height: 64)
                )

                // Label and description
                VStack(spacing: 2) {
                    Text(style.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? style.color : .primary)

                    Text(style.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingM)
            .padding(.horizontal, .spacingS)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .fill(isSelected ? style.color.opacity(0.08) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .stroke(isSelected ? style.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.displayName), \(style.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Compact Badge for Event Attendee Lists

struct RidingStyleBadge: View {
    let style: RidingStyle
    var showLabel: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: style.icon)
                .font(.system(size: 10, weight: .medium))

            if showLabel {
                Text(style.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(style.color)
        .padding(.horizontal, showLabel ? 6 : 4)
        .padding(.vertical, 3)
        .background(style.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Emoji Badge (super compact)

struct RidingStyleEmojiBadge: View {
    let style: RidingStyle

    var body: some View {
        Text(style.emoji)
            .font(.system(size: 14))
            .padding(2)
    }
}

#Preview("Riding Style Buttons") {
    VStack(spacing: 24) {
        Text("Riding Style Selection")
            .font(.headline)

        // Unselected state
        HStack(spacing: 12) {
            ForEach(RidingStyle.allCases) { style in
                RidingStyleButton(
                    style: style,
                    isSelected: false,
                    action: {}
                )
            }
        }

        Text("Selected States")
            .font(.subheadline)
            .foregroundStyle(.secondary)

        // Selected states
        HStack(spacing: 12) {
            ForEach(RidingStyle.allCases) { style in
                RidingStyleButton(
                    style: style,
                    isSelected: true,
                    action: {}
                )
            }
        }

        Divider()

        Text("Badge Variants")
            .font(.headline)

        HStack(spacing: 12) {
            ForEach(RidingStyle.allCases) { style in
                RidingStyleBadge(style: style)
            }
        }

        HStack(spacing: 12) {
            ForEach(RidingStyle.allCases) { style in
                RidingStyleBadge(style: style, showLabel: true)
            }
        }

        HStack(spacing: 12) {
            ForEach(RidingStyle.allCases) { style in
                RidingStyleEmojiBadge(style: style)
            }
        }
    }
    .padding()
}
