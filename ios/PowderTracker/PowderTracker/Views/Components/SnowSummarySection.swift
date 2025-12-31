import SwiftUI

/// Snow summary section with key metrics
struct SnowSummarySection: View {
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Snow Summary")
                .font(.title3)
                .fontWeight(.bold)

            if let conditions = conditions {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    // Snow depth
                    if let snowDepth = conditions.snowDepth {
                        SnowMetricCard(
                            icon: "ruler.fill",
                            label: "Base Depth",
                            value: "\(snowDepth)\"",
                            color: .blue,
                            subtitle: depthQuality(snowDepth)
                        )
                    }

                    // 24hr snowfall
                    SnowMetricCard(
                        icon: "snowflake",
                        label: "24hr Snow",
                        value: "\(conditions.snowfall24h)\"",
                        color: .cyan,
                        subtitle: snowfall24h > 6 ? "Powder day!" : "Light"
                    )

                    // 48hr snowfall
                    SnowMetricCard(
                        icon: "cloud.snow.fill",
                        label: "48hr Snow",
                        value: "\(conditions.snowfall48h)\"",
                        color: .indigo,
                        subtitle: "\(conditions.snowfall48h - conditions.snowfall24h)\" yesterday"
                    )

                    // 7-day total
                    SnowMetricCard(
                        icon: "calendar",
                        label: "7-Day Total",
                        value: "\(conditions.snowfall7d)\"",
                        color: .purple,
                        subtitle: weekTrend
                    )
                }

                // Powder score if available
                if let score = powderScore {
                    Divider()
                        .padding(.vertical, 8)

                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Powder Score")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            Text(score.verdict ?? "Check conditions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Score circle
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                            Circle()
                                .trim(from: 0, to: score.score / 10)
                                .stroke(
                                    scoreColor(score.score),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 0) {
                                Text(String(format: "%.1f", score.score))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(scoreColor(score.score))

                                Text("/ 10")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 70, height: 70)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var snowfall24h: Int {
        conditions?.snowfall24h ?? 0
    }

    private func depthQuality(_ depth: Int) -> String {
        if depth >= 100 { return "Excellent" }
        if depth >= 60 { return "Good" }
        if depth >= 30 { return "Fair" }
        return "Limited"
    }

    private var weekTrend: String {
        guard let conditions = conditions else { return "" }
        if conditions.snowfall7d > conditions.snowfall48h * 2 {
            return "Active week"
        } else if conditions.snowfall7d < conditions.snowfall48h {
            return "Dry spell"
        }
        return "Steady"
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        if score >= 3 { return .orange }
        return .red
    }
}

// MARK: - Snow Metric Card

struct SnowMetricCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    let mockConditions = MountainConditions(
        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
        snowDepth: 120,
        snowWaterEquivalent: 38.5,
        snowfall24h: 8,
        snowfall48h: 14,
        snowfall7d: 22,
        temperature: 28,
        temperatureByElevation: nil,
        conditions: "Light Snow",
        wind: nil,
        lastUpdated: Date().ISO8601Format(),
        liftStatus: nil,
        dataSources: MountainConditions.DataSources(
            snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
            noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
            liftStatus: nil
        )
    )

    let mockScore = MountainPowderScore(
        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
        score: 8.2,
        factors: [],
        verdict: "SEND IT! Epic powder conditions!",
        conditions: nil,
        dataAvailable: nil
    )

    SnowSummarySection(conditions: mockConditions, powderScore: mockScore)
        .padding()
        .background(Color(.systemGroupedBackground))
}
