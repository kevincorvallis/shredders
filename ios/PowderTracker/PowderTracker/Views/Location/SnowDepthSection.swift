import SwiftUI
import Charts

struct SnowDepthSection: View {
    @ObservedObject var viewModel: LocationViewModel
    var onNavigateToHistory: (() -> Void)?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header (Tappable)
            HStack {
                Image(systemName: "snowflake")
                    .foregroundColor(.blue)
                Text("Snow Depth")
                    .font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .foregroundColor(.secondary)
                    .imageScale(.large)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap()
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

            // Year-over-Year Comparison & Base Quality
            if let comparison = viewModel.snowComparison {
                VStack(spacing: 12) {
                    // Base Quality Rating
                    if let rating = comparison.baseDepthGuidelines.currentRating {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: rating.color) ?? .gray)
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(rating.rating) Base")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text(rating.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }

                    // Year-over-Year Comparison
                    if let lastYear = comparison.comparison.lastYear,
                       let difference = comparison.comparison.difference {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("vs. Last Year")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 6) {
                                    Text("\(Int(lastYear.snowDepth))\"")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 4) {
                                        Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                                            .font(.caption)
                                        Text("\(abs(difference))\"")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(difference >= 0 ? .green : .red)
                                }
                            }

                            Spacer()

                            if let percentChange = comparison.comparison.percentChange {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(percentChange >= 0 ? "+" : "")\(percentChange)%")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(percentChange >= 0 ? .green : .red)

                                    Text(percentChange >= 0 ? "More snow" : "Less snow")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
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

            // Historical Chart (Expanded Content)
            if isExpanded && !viewModel.historicalSnowData.isEmpty {
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
                    .frame(minWidth: 100) // Prevent 0x0 CAMetalLayer error
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))

                // Navigate to History Button
                if onNavigateToHistory != nil {
                    Button {
                        onNavigateToHistory?()
                    } label: {
                        HStack {
                            Text("View Full Snow History")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .transition(.opacity)
                }
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
        .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Tap Handler

    private func handleTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3)) {
            if isExpanded {
                // Second tap: Navigate to History tab
                onNavigateToHistory?()
            } else {
                // First tap: Expand inline
                isExpanded = true
            }
        }
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
