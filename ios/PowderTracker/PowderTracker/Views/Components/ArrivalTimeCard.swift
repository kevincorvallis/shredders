import SwiftUI

struct ArrivalTimeCard: View {
    let arrivalTime: ArrivalTimeRecommendation
    @State private var showAlternatives = false
    @State private var showTips = false

    private var confidenceColor: Color {
        Color.forConfidenceLevel(arrivalTime.confidence.displayName)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            VStack(spacing: .spacingL) {
                // Main recommendation
                recommendedTimeSection

                // Arrival window
                arrivalWindowSection

                // Factors grid
                factorsGrid

                // Reasoning
                reasoningSection

                // Alternatives toggle
                if !arrivalTime.alternatives.isEmpty {
                    alternativesToggle
                }

                // Tips toggle
                if !arrivalTime.tips.isEmpty {
                    tipsToggle
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusHero)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusHero)
                .strokeBorder(confidenceColor.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Best Arrival Time")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("AI-powered recommendation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Confidence badge
            ConfidenceIndicator(
                confidence: arrivalTime.confidence.displayName,
                style: .badge,
                showIcon: true,
                showText: true
            )
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
    }

    // MARK: - Recommended Time

    private var recommendedTimeSection: some View {
        VStack(spacing: .spacingS) {
            Text("Arrive By")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(arrivalTime.recommendedArrivalTime)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(arrivalTime.arrivalWindow.optimal)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingM)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(Color.blue.opacity(.opacitySubtle))
        )
    }

    // MARK: - Arrival Window

    private var arrivalWindowSection: some View {
        HStack(spacing: 0) {
            TimeWindowPill(
                label: "Earliest",
                time: arrivalTime.arrivalWindow.earliest,
                color: .orange
            )

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 40)

            TimeWindowPill(
                label: "Optimal",
                time: arrivalTime.arrivalWindow.optimal,
                color: .green
            )

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 40)

            TimeWindowPill(
                label: "Latest",
                time: arrivalTime.arrivalWindow.latest,
                color: .red
            )
        }
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // MARK: - Factors Grid

    private var factorsGrid: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Factors")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: .spacingM) {
                FactorPill(
                    icon: arrivalTime.factors.expectedCrowdLevel.icon,
                    label: "Crowds",
                    value: arrivalTime.factors.expectedCrowdLevel.displayName,
                    color: Color(arrivalTime.factors.expectedCrowdLevel.color)
                )

                FactorPill(
                    icon: arrivalTime.factors.roadConditions.icon,
                    label: "Roads",
                    value: arrivalTime.factors.roadConditions.displayName,
                    color: Color(arrivalTime.factors.roadConditions.color)
                )

                FactorPill(
                    icon: arrivalTime.factors.weatherQuality.icon,
                    label: "Weather",
                    value: arrivalTime.factors.weatherQuality.displayName,
                    color: Color(arrivalTime.factors.weatherQuality.color)
                )

                FactorPill(
                    icon: arrivalTime.factors.powderFreshness.icon,
                    label: "Powder",
                    value: arrivalTime.factors.powderFreshness.displayName,
                    color: Color(arrivalTime.factors.powderFreshness.color)
                )

                FactorPill(
                    icon: arrivalTime.factors.parkingDifficulty.icon,
                    label: "Parking",
                    value: arrivalTime.factors.parkingDifficulty.displayName,
                    color: Color(arrivalTime.factors.parkingDifficulty.color)
                )
            }
        }
    }

    // MARK: - Reasoning

    private var reasoningSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Why This Time?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: .spacingS) {
                ForEach(Array(arrivalTime.reasoning.enumerated()), id: \.offset) { index, reason in
                    HStack(alignment: .top, spacing: .spacingS) {
                        Image(systemName: "\(index + 1).circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)

                        Text(reason)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Alternatives

    private var alternativesToggle: some View {
        ExpandableSection(
            title: "Alternative Times",
            icon: "arrow.triangle.2.circlepath",
            count: nil,
            color: .blue,
            isExpanded: $showAlternatives
        ) {
            ForEach(arrivalTime.alternatives) { alt in
                AlternativeTimeRow(alternative: alt)
            }
        }
    }

    // MARK: - Tips

    private var tipsToggle: some View {
        ExpandableSection(
            title: "Pro Tips",
            icon: "lightbulb.fill",
            count: arrivalTime.tips.count,
            color: .orange,
            isExpanded: $showTips
        ) {
            ForEach(Array(arrivalTime.tips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: .spacingS) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text(tip)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

}

// MARK: - Supporting Views

struct TimeWindowPill: View {
    let label: String
    let time: String
    let color: Color

    var body: some View {
        VStack(spacing: .spacingXS) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(time)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingS)
    }
}

struct FactorPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: .spacingXS) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingS)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct AlternativeTimeRow: View {
    let alternative: ArrivalTimeRecommendation.AlternativeTime

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "clock")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                Text(alternative.time)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(alternative.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(alternative.tradeoff)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, .spacingXXL)
        }
        .padding(.spacingM)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        ArrivalTimeCard(arrivalTime: .mock)
            .padding()
    }
}
