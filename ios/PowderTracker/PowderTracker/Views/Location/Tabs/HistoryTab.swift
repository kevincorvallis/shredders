import SwiftUI

struct HistoryTab: View {
    var viewModel: LocationViewModel
    let mountain: Mountain

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                // Season Summary Card
                seasonSummaryCard

                // Monthly Snowfall Chart Placeholder
                monthlySnowfallCard

                // Historical Comparison
                historicalComparisonCard
            }
            .padding(.spacingM)
        }
    }

    // MARK: - Season Summary

    private var seasonSummaryCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("2024-25 Season")
                    .font(.headline)
                Spacer()
            }

            Divider()

            HStack(spacing: .spacingXL) {
                statColumn(value: "127\"", label: "Total Snow", icon: "snowflake")
                statColumn(value: "42", label: "Powder Days", icon: "cloud.snow.fill")
                statColumn(value: "89\"", label: "Base Depth", icon: "ruler")
            }

            Text("Data from SNOTEL sensors")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func statColumn(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Monthly Snowfall

    private var monthlySnowfallCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.cyan)
                Text("Monthly Snowfall")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Simple bar chart placeholder
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(monthlyData, id: \.month) { data in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 28, height: CGFloat(data.inches) * 2)

                        Text(data.month)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120, alignment: .bottom)
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private var monthlyData: [(month: String, inches: Int)] {
        [
            ("Nov", 18),
            ("Dec", 42),
            ("Jan", 38),
            ("Feb", 29),
            ("Mar", 0),
            ("Apr", 0)
        ]
    }

    // MARK: - Historical Comparison

    private var historicalComparisonCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("vs. Historical Average")
                    .font(.headline)
                Spacer()
            }

            Divider()

            VStack(spacing: .spacingS) {
                comparisonRow(label: "Season to Date", current: "127\"", average: "142\"", percentDiff: -11)
                comparisonRow(label: "Peak Base", current: "89\"", average: "102\"", percentDiff: -13)
                comparisonRow(label: "Powder Days", current: "42", average: "38", percentDiff: 11)
            }

            Text("Compared to 10-year average")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func comparisonRow(label: String, current: String, average: String, percentDiff: Int) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(current)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("(\(percentDiff > 0 ? "+" : "")\(percentDiff)%)")
                .font(.caption)
                .foregroundStyle(percentDiff >= 0 ? .green : .red)
        }
    }
}
