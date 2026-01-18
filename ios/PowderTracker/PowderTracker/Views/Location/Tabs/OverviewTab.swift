import SwiftUI

struct OverviewTab: View {
    @ObservedObject var viewModel: LocationViewModel
    let mountain: Mountain
    @Binding var selectedTab: TabbedLocationView.Tab

    var body: some View {
        VStack(spacing: 16) {
            // Powder Score Card
            if let score = viewModel.powderScore {
                PowderScoreCard(score: score)
            }

            // Safety Summary Banner
            if let safetyData = viewModel.safetyData {
                SafetySummaryBanner(safetyData: safetyData)
            }

            // Quick Arrival Time Banner
            QuickArrivalTimeBanner(mountain: mountain, selectedTab: $selectedTab)

            // At-a-Glance Metrics
            AtAGlanceCard(viewModel: viewModel)

            // Snow Comparison Card (Year-over-Year)
            if let snowComparison = viewModel.snowComparison {
                SnowComparisonCard(comparison: snowComparison)
            }

            // Quick Stats Grid
            QuickStatsGrid(viewModel: viewModel)

            // Current Conditions Detail
            CurrentConditionsCard(viewModel: viewModel)
        }
    }
}

// MARK: - Powder Score Card

struct PowderScoreCard: View {
    let score: Int

    private var scoreColor: Color {
        switch score {
        case 9...10: return .green
        case 7...8: return .blue
        case 5...6: return .orange
        case 3...4: return .yellow
        default: return .red
        }
    }

    private var scoreLabel: String {
        switch score {
        case 9...10: return "Epic"
        case 7...8: return "Great"
        case 5...6: return "Good"
        case 3...4: return "Fair"
        default: return "Poor"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Score circle
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.2))
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(scoreColor, lineWidth: 8)
                    .frame(width: 110, height: 110)

                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)

                    Text("/ 10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Score label
            Text(scoreLabel)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)

            Text("Powder Score")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    @ObservedObject var viewModel: LocationViewModel

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            OverviewStatCard(
                icon: "snow",
                title: "Snow Depth",
                value: viewModel.currentSnowDepth.map { "\(Int($0))\"" } ?? "N/A",
                color: .blue
            )

            OverviewStatCard(
                icon: "thermometer.medium",
                title: "Temperature",
                value: viewModel.temperature.map { "\(Int($0))°F" } ?? "N/A",
                color: .orange
            )

            OverviewStatCard(
                icon: "wind",
                title: "Wind Speed",
                value: viewModel.windSpeed.map { "\(Int($0)) mph" } ?? "N/A",
                color: .cyan
            )

            OverviewStatCard(
                icon: "cloud.sun.fill",
                title: "Conditions",
                value: viewModel.weatherDescription ?? "N/A",
                color: .purple
            )
        }
    }
}

struct OverviewStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Current Conditions Card

struct CurrentConditionsCard: View {
    @ObservedObject var viewModel: LocationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Snowfall")
                .font(.headline)

            VStack(spacing: 8) {
                SnowfallRow(period: "24 hours", inches: viewModel.snowDepth24h ?? 0)
                SnowfallRow(period: "48 hours", inches: viewModel.snowDepth48h ?? 0)
                SnowfallRow(period: "7 days", inches: viewModel.snowDepth72h ?? 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct SnowfallRow: View {
    let period: String
    let inches: Double

    var body: some View {
        HStack {
            Text(period)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(inches))\"")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(inches > 0 ? .blue : .secondary)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab: TabbedLocationView.Tab = .overview

        var body: some View {
            ScrollView {
                OverviewTab(
                    viewModel: LocationViewModel(mountain: .mock),
                    mountain: .mock,
                    selectedTab: $selectedTab
                )
                .padding()
            }
        }
    }

    return PreviewWrapper()
}
