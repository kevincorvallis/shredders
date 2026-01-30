//
//  TerrainToggleButton.swift
//  PowderTracker
//
//  Terrain type toggle button for onboarding.
//

import SwiftUI

struct TerrainToggleButton: View {
    let terrain: TerrainType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacingXS) {
                Image(systemName: terrain.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(.cornerRadiusSmall)

                Text(terrain.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .blue : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingS)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusButton)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel(terrain.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        TerrainToggleButton(terrain: .groomers, isSelected: true, action: {})
        TerrainToggleButton(terrain: .moguls, isSelected: false, action: {})
        TerrainToggleButton(terrain: .trees, isSelected: true, action: {})
        TerrainToggleButton(terrain: .park, isSelected: false, action: {})
        TerrainToggleButton(terrain: .backcountry, isSelected: false, action: {})
    }
    .padding()
}
