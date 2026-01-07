import SwiftUI

struct ArrivalTimeCard: View {
    let arrivalTime: ArrivalTimeRecommendation
    @State private var showAlternatives = false
    @State private var showTips = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            VStack(spacing: 16) {
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(confidenceColor.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
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
            HStack(spacing: 4) {
                Image(systemName: arrivalTime.confidence.icon)
                    .font(.caption)
                Text(arrivalTime.confidence.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(confidenceColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(confidenceColor.opacity(0.15))
            )
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
    }

    // MARK: - Recommended Time

    private var recommendedTimeSection: some View {
        VStack(spacing: 8) {
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
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.08))
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
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // MARK: - Factors Grid

    private var factorsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Factors")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Why This Time?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(arrivalTime.reasoning.enumerated()), id: \.offset) { index, reason in
                    HStack(alignment: .top, spacing: 8) {
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
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showAlternatives.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.subheadline)

                    Text("Alternative Times")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Image(systemName: showAlternatives ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundColor(.blue)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            if showAlternatives {
                VStack(spacing: 10) {
                    ForEach(arrivalTime.alternatives) { alt in
                        AlternativeTimeRow(alternative: alt)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Tips

    private var tipsToggle: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showTips.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.subheadline)

                    Text("Pro Tips (\(arrivalTime.tips.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Image(systemName: showTips ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundColor(.orange)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            if showTips {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(arrivalTime.tips.enumerated()), id: \.offset) { index, tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)

                            Text(tip)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Helpers

    private var confidenceColor: Color {
        switch arrivalTime.confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

// MARK: - Supporting Views

struct TimeWindowPill: View {
    let label: String
    let time: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
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
        .padding(.vertical, 8)
    }
}

struct FactorPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
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
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
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
                .padding(.leading, 24)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
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
