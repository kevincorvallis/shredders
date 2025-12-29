import SwiftUI
import Charts

struct SnowDepthSection: View {
    @ObservedObject var viewModel: LocationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "snowflake")
                    .foregroundColor(.blue)
                Text("Snow Depth")
                    .font(.headline)
            }

            // Current Depth
            if let currentDepth = viewModel.currentSnowDepth {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Base")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(Int(currentDepth))\"")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                }
            }

            // Recent Snowfall Grid
            HStack(spacing: 12) {
                if let snow24h = viewModel.snowDepth24h {
                    SnowfallCard(period: "24h", amount: snow24h)
                }
                if let snow48h = viewModel.snowDepth48h {
                    SnowfallCard(period: "48h", amount: snow48h)
                }
                if let snow72h = viewModel.snowDepth72h {
                    SnowfallCard(period: "72h", amount: snow72h)
                }
            }

            // Historical Chart
            if !viewModel.historicalSnowData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Depth Trend")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Chart(viewModel.historicalSnowData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Depth", dataPoint.depth)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Depth", dataPoint.depth)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Depth", dataPoint.depth)
                        )
                        .foregroundStyle(.blue)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    if let dataPoint = viewModel.historicalSnowData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                                        Text(dataPoint.label)
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let depth = value.as(Double.self) {
                                    Text("\(Int(depth))\"")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                }
                .padding(.top, 8)
            }

            // Last Updated
            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct SnowfallCard: View {
    let period: String
    let amount: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(period)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(Int(amount))\"")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(amount > 0 ? .blue : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
