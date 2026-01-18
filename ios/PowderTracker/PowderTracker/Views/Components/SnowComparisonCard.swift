//
//  SnowComparisonCard.swift
//  PowderTracker
//
//  Year-over-year snow comparison card showing current vs last year snowpack
//

import SwiftUI

struct SnowComparisonCard: View {
    let comparison: SnowComparisonResponse
    @State private var isExpanded = false

    private var percentChange: Int {
        comparison.comparison.percentChange ?? 0
    }

    private var changeDirection: String {
        if percentChange > 0 { return "+" }
        return ""
    }

    private var changeColor: Color {
        if percentChange > 10 { return .green }
        if percentChange < -10 { return .red }
        return .orange
    }

    private var ratingColor: Color {
        guard let rating = comparison.baseDepthGuidelines.currentRating?.rating.lowercased() else {
            return .gray
        }
        switch rating {
        case "excellent": return .green
        case "good": return .blue
        case "fair": return .orange
        case "poor": return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.spacingM)

            // Comparison bars
            comparisonBarsView
                .padding(.horizontal, .spacingM)
                .padding(.bottom, .spacingM)

            // Rating badge
            if let rating = comparison.baseDepthGuidelines.currentRating {
                ratingBadge(rating)
                    .padding(.horizontal, .spacingM)
                    .padding(.bottom, .spacingM)
            }

            // Expanded elevation breakdown
            if isExpanded {
                Divider()
                expandedView
                    .padding(.spacingM)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text("vs Last Year")
                    .font(.headline)
                    .fontWeight(.semibold)

                if let current = comparison.comparison.current,
                   let lastYear = comparison.comparison.lastYear {
                    let diff = current.snowDepth - lastYear.snowDepth
                    HStack(spacing: .spacingXS) {
                        Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                            .foregroundColor(changeColor)
                        Text("\(changeDirection)\(percentChange)%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(changeColor)
                    }
                }
            }

            Spacer()

            // Expand button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: .spacingXS) {
                    Text(isExpanded ? "Hide" : "Details")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
    }

    // MARK: - Comparison Bars

    private var comparisonBarsView: some View {
        HStack(spacing: .spacingL) {
            // This Year
            yearColumn(
                label: "This Year",
                depth: comparison.comparison.current?.snowDepth ?? 0,
                maxDepth: maxDepth,
                color: .blue
            )

            // Last Year
            yearColumn(
                label: "Last Year",
                depth: comparison.comparison.lastYear?.snowDepth ?? 0,
                maxDepth: maxDepth,
                color: .gray.opacity(0.6)
            )

            // Change indicator
            changeColumn
        }
    }

    private var maxDepth: Int {
        max(
            comparison.comparison.current?.snowDepth ?? 0,
            comparison.comparison.lastYear?.snowDepth ?? 0,
            1
        )
    }

    private func yearColumn(label: String, depth: Int, maxDepth: Int, color: Color) -> some View {
        VStack(spacing: .spacingS) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Bar
            GeometryReader { geo in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(height: geo.size.height * CGFloat(depth) / CGFloat(maxDepth))
                }
            }
            .frame(height: 60)

            Text("\(depth)\"")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color == .blue ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var changeColumn: some View {
        VStack(spacing: .spacingS) {
            Text("Change")
                .font(.caption2)
                .foregroundColor(.secondary)

            VStack(spacing: .spacingXS) {
                Image(systemName: percentChange >= 0 ? "arrow.up" : "arrow.down")
                    .font(.title2)
                    .foregroundColor(changeColor)

                Text("\(changeDirection)\(percentChange)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(changeColor)
            }
            .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Rating Badge

    private func ratingBadge(_ rating: BaseDepthRating) -> some View {
        HStack(spacing: .spacingS) {
            Circle()
                .fill(ratingColor)
                .frame(width: 8, height: 8)

            Text(rating.rating.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(ratingColor)

            Text("•")
                .foregroundColor(.secondary)

            Text(rating.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .background(ratingColor.opacity(0.1))
        .cornerRadius(.cornerRadiusButton)
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Elevation Info")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Elevation category
            HStack {
                Image(systemName: "mountain.2.fill")
                    .foregroundColor(.blue)
                Text(comparison.mountain.elevationCategory.capitalized)
                    .font(.subheadline)

                Spacer()

                Text("\(comparison.mountain.elevation.base)' - \(comparison.mountain.elevation.summit)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Thresholds guide
            VStack(alignment: .leading, spacing: .spacingS) {
                Text("Season Guidelines")
                    .font(.caption)
                    .foregroundColor(.secondary)

                let thresholds = comparison.baseDepthGuidelines.thresholds
                HStack(spacing: .spacingS) {
                    thresholdPill("Poor", thresholds.poor, .red)
                    thresholdPill("Fair", thresholds.fair, .orange)
                    thresholdPill("Good", thresholds.good, .blue)
                    thresholdPill("Excellent", thresholds.excellent, .green)
                }
            }
        }
    }

    private func thresholdPill(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)\"")
                .font(.caption2)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, .spacingS)
        .padding(.vertical, .spacingXS)
        .background(color.opacity(0.1))
        .cornerRadius(.cornerRadiusMicro)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SnowComparisonCard(
                comparison: SnowComparisonResponse(
                    mountain: MountainElevationInfo(
                        id: "baker",
                        name: "Mt. Baker",
                        elevation: MountainElevation(base: 3500, summit: 5089),
                        elevationCategory: "mid-elevation"
                    ),
                    comparison: YearOverYearComparison(
                        current: SnowDepthDataPoint(date: "2025-01-15", snowDepth: 142),
                        lastYear: SnowDepthDataPoint(date: "2024-01-15", snowDepth: 98),
                        difference: 44,
                        percentChange: 45
                    ),
                    baseDepthGuidelines: BaseDepthGuidelines(
                        elevationCategory: "mid-elevation",
                        thresholds: DepthThresholds(minimal: 30, poor: 60, fair: 90, good: 120, excellent: 150),
                        currentRating: BaseDepthRating(rating: "Good", description: "Above average for mid-January", color: "blue")
                    )
                )
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
