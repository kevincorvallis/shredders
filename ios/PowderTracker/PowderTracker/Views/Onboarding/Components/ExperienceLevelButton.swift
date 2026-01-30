//
//  ExperienceLevelButton.swift
//  PowderTracker
//
//  Experience level selection button for onboarding.
//

import SwiftUI

struct ExperienceLevelButton: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacingS) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : level.color)
                    .frame(width: 56, height: 56)
                    .background(isSelected ? level.color : level.color.opacity(0.1))
                    .cornerRadius(.cornerRadiusCard)

                VStack(spacing: 2) {
                    Text(level.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? level.color : .primary)

                    Text(level.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 90)
            .padding(.spacingS)
            .background(isSelected ? level.color.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel("\(level.displayName), \(level.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: 12) {
        ExperienceLevelButton(
            level: .beginner,
            isSelected: false,
            action: {}
        )
        ExperienceLevelButton(
            level: .intermediate,
            isSelected: true,
            action: {}
        )
        ExperienceLevelButton(
            level: .advanced,
            isSelected: false,
            action: {}
        )
        ExperienceLevelButton(
            level: .expert,
            isSelected: false,
            action: {}
        )
    }
    .padding()
}
