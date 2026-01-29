//
//  ChartDetailCard.swift
//  PowderTracker
//
//  Detail card shown when user taps a data point on a chart
//

import SwiftUI

/// Detail card for showing expanded information about a selected data point
struct ChartDetailCard: View {
    let date: Date
    let snowfall: Int
    let snowDepth: Int
    let temperature: Int?
    let conditions: String?
    var isPowderDay: Bool = false
    var onDismiss: (() -> Void)? = nil
    var onNavigateToDetail: (() -> Void)? = nil

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle for drag
            dragHandle

            // Content
            VStack(alignment: .leading, spacing: .spacingM) {
                // Header with date
                headerSection

                Divider()

                // Main stats
                statsSection

                // Conditions if available
                if let conditions = conditions {
                    conditionsSection(conditions)
                }

                // Action buttons
                actionButtons
            }
            .padding(.spacingL)
        }
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: -8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Components

    private var dragHandle: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.vertical, .spacingS)
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(formatDate(date))
                    .font(.title3)
                    .fontWeight(.bold)

                Text(formatDayOfWeek(date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Powder day badge
            if isPowderDay {
                HStack(spacing: 4) {
                    Image(systemName: snowfall >= 12 ? "star.fill" : "snowflake")
                        .foregroundStyle(snowfall >= 12 ? .yellow : .cyan)
                    Text(snowfall >= 12 ? "Epic!" : "Powder!")
                        .font(.subheadline.bold())
                        .foregroundStyle(snowfall >= 12 ? .orange : .cyan)
                }
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
                .background(
                    Capsule()
                        .fill((snowfall >= 12 ? Color.orange : Color.cyan).opacity(0.15))
                )
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: .spacingL) {
            // Snowfall
            StatItem(
                icon: "snowflake",
                iconColor: .cyan,
                value: "\(snowfall)\"",
                label: "Fresh Snow"
            )

            Divider()
                .frame(height: 50)

            // Snow Depth
            StatItem(
                icon: "ruler",
                iconColor: Color.chartPrimary(for: .snowDepth),
                value: "\(snowDepth)\"",
                label: "Total Depth"
            )

            if let temp = temperature {
                Divider()
                    .frame(height: 50)

                // Temperature
                StatItem(
                    icon: "thermometer.medium",
                    iconColor: .orange,
                    value: "\(temp)°F",
                    label: "Temperature"
                )
            }
        }
    }

    private func conditionsSection(_ conditions: String) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text("Conditions")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(conditions)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private var actionButtons: some View {
        HStack(spacing: .spacingM) {
            // View Details button
            if let onNavigate = onNavigateToDetail {
                Button {
                    HapticFeedback.light.trigger()
                    onNavigate()
                } label: {
                    HStack(spacing: .spacingXS) {
                        Image(systemName: "arrow.right.circle")
                        Text("View Details")
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.spacingM)
                    .background(Color.chartPrimary(for: .snowDepth))
                    .foregroundStyle(.white)
                    .cornerRadius(.cornerRadiusCard)
                }
            }

            // Dismiss button
            if let onDismiss = onDismiss {
                Button {
                    HapticFeedback.light.trigger()
                    onDismiss()
                } label: {
                    HStack(spacing: .spacingXS) {
                        Image(systemName: "xmark.circle")
                        Text("Close")
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: onNavigateToDetail == nil ? .infinity : nil)
                    .padding(.spacingM)
                    .background(Color(.secondarySystemBackground))
                    .foregroundStyle(.primary)
                    .cornerRadius(.cornerRadiusCard)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Chart Detail Card Container

/// Container view that manages the detail card presentation
struct ChartDetailCardContainer<Content: View>: View {
    @Binding var selectedDataPoint: HistoryDataPoint?
    let content: () -> Content
    var onNavigateToDetail: ((HistoryDataPoint) -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            content()

            if let point = selectedDataPoint {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.chartTooltip) {
                            selectedDataPoint = nil
                        }
                    }

                ChartDetailCard(
                    date: point.formattedDate ?? Date(),
                    snowfall: point.snowfall,
                    snowDepth: point.snowDepth,
                    temperature: point.temperature,
                    conditions: nil,
                    isPowderDay: point.snowfall >= 6,
                    onDismiss: {
                        withAnimation(.chartTooltip) {
                            selectedDataPoint = nil
                        }
                    },
                    onNavigateToDetail: onNavigateToDetail != nil ? {
                        onNavigateToDetail?(point)
                    } : nil
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Detail Card") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack {
            Spacer()

            ChartDetailCard(
                date: Date(),
                snowfall: 8,
                snowDepth: 145,
                temperature: 28,
                conditions: "Heavy snow expected throughout the day with occasional wind gusts.",
                isPowderDay: true,
                onDismiss: { },
                onNavigateToDetail: { }
            )
        }
    }
}

#Preview("Epic Powder Day") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack {
            Spacer()

            ChartDetailCard(
                date: Date(),
                snowfall: 14,
                snowDepth: 162,
                temperature: 22,
                conditions: "Exceptional powder conditions. 14 inches of fresh snow overnight!",
                isPowderDay: true,
                onDismiss: { }
            )
        }
    }
}

#Preview("Minimal") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack {
            Spacer()

            ChartDetailCard(
                date: Date(),
                snowfall: 2,
                snowDepth: 120,
                temperature: nil,
                conditions: nil,
                isPowderDay: false,
                onDismiss: { }
            )
        }
    }
}
