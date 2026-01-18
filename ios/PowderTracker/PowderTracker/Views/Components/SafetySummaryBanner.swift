//
//  SafetySummaryBanner.swift
//  PowderTracker
//
//  Collapsible safety summary banner showing hazard conditions
//

import SwiftUI

struct SafetySummaryBanner: View {
    let safetyData: SafetyData
    @State private var isExpanded = false

    private var safetyLevel: SafetyLevel {
        SafetyLevel(from: safetyData.assessment.level)
    }

    private var levelColor: Color {
        switch safetyLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .considerable: return .orange
        case .high, .extreme: return .red
        }
    }

    private var summaryItems: [String] {
        var items: [String] = []

        if let hazards = safetyData.hazards {
            if let avalanche = hazards.avalanche, SafetyLevel(from: avalanche.level).dotCount >= 3 {
                items.append("Avalanche risk")
            }
            if let icy = hazards.icy, SafetyLevel(from: icy.level).dotCount >= 3 {
                items.append("Icy patches")
            }
            if let wind = safetyData.weather.wind, wind.speed >= 20 {
                items.append("Wind loading")
            }
            if let treeWells = hazards.treeWells, SafetyLevel(from: treeWells.level).dotCount >= 3 {
                items.append("Tree well hazard")
            }
        }

        return items.isEmpty ? ["Good conditions"] : items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed view (always visible)
            collapsedView
                .padding(.spacingM)

            // Expanded view
            if isExpanded {
                Divider()
                expandedView
                    .padding(.spacingM)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(levelColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .stroke(levelColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - Collapsed View

    private var collapsedView: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: .spacingM) {
                // Alert icon
                Image(systemName: safetyLevel == .low ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(levelColor)

                VStack(alignment: .leading, spacing: .spacingXS) {
                    HStack(spacing: .spacingS) {
                        Text(safetyLevel.displayName.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(levelColor)

                        Text("conditions today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(summaryItems.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Expand button
                HStack(spacing: .spacingXS) {
                    Text(isExpanded ? "Hide" : "Details")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(levelColor)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(alignment: .leading, spacing: .spacingL) {
            // Hazard Matrix
            if let hazards = safetyData.hazards {
                VStack(alignment: .leading, spacing: .spacingS) {
                    Text("Hazard Matrix")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(spacing: .spacingS) {
                        if let avalanche = hazards.avalanche {
                            hazardRow("Avalanche", level: avalanche.level)
                        }
                        if let treeWells = hazards.treeWells {
                            hazardRow("Tree Wells", level: treeWells.level)
                        }
                        if let icy = hazards.icy {
                            hazardRow("Icy", level: icy.level)
                        }
                        if let crowded = hazards.crowded {
                            hazardRow("Crowds", level: crowded.level)
                        }
                    }
                }
            }

            // Tips / Recommendations
            if !safetyData.assessment.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: .spacingS) {
                    Text("Tips")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(safetyData.assessment.recommendations.prefix(3), id: \.self) { tip in
                        HStack(alignment: .top, spacing: .spacingS) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Hazard Row

    private func hazardRow(_ name: String, level: String) -> some View {
        let safetyLevel = SafetyLevel(from: level)
        let color = colorForLevel(safetyLevel)

        return HStack(spacing: .spacingS) {
            Text(name)
                .font(.caption)
                .frame(width: 80, alignment: .leading)

            // Dot indicators
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(index <= safetyLevel.dotCount ? color : Color(.tertiarySystemFill))
                        .frame(width: 8, height: 8)
                }
            }

            Text(safetyLevel.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }

    private func colorForLevel(_ level: SafetyLevel) -> Color {
        switch level {
        case .low: return .green
        case .moderate: return .yellow
        case .considerable: return .orange
        case .high, .extreme: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SafetySummaryBanner(
                safetyData: SafetyData(
                    mountain: SafetyMountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                    assessment: SafetyAssessment(
                        level: "moderate",
                        description: "Moderate conditions with some hazards",
                        recommendations: [
                            "Check avalanche forecast before backcountry",
                            "Expect variable conditions above 6000ft",
                            "Wear layers - temps vary by 15°F across elevation"
                        ]
                    ),
                    weather: SafetyWeather(
                        temperature: 28,
                        feelsLike: 22,
                        humidity: 85,
                        visibility: 8.0,
                        pressure: 29.92,
                        uvIndex: 2,
                        wind: SafetyWindData(speed: 18, gust: 25, direction: "SW")
                    ),
                    hazards: SafetyHazards(
                        avalanche: SafetyHazardLevel(level: "moderate", description: "Moderate avalanche risk"),
                        treeWells: SafetyHazardLevel(level: "low", description: nil),
                        icy: SafetyHazardLevel(level: "considerable", description: "Icy conditions on north-facing slopes"),
                        crowded: SafetyHazardLevel(level: "low", description: nil)
                    )
                )
            )

            SafetySummaryBanner(
                safetyData: SafetyData(
                    mountain: SafetyMountainInfo(id: "crystal", name: "Crystal Mountain", shortName: "Crystal"),
                    assessment: SafetyAssessment(
                        level: "low",
                        description: "Good conditions overall",
                        recommendations: ["Great day for skiing!"]
                    ),
                    weather: SafetyWeather(
                        temperature: 32,
                        feelsLike: 28,
                        humidity: 70,
                        visibility: 10.0,
                        pressure: 30.05,
                        uvIndex: 3,
                        wind: SafetyWindData(speed: 8, gust: 12, direction: "W")
                    ),
                    hazards: SafetyHazards(
                        avalanche: SafetyHazardLevel(level: "low", description: nil),
                        treeWells: SafetyHazardLevel(level: "low", description: nil),
                        icy: SafetyHazardLevel(level: "low", description: nil),
                        crowded: SafetyHazardLevel(level: "low", description: nil)
                    )
                )
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
