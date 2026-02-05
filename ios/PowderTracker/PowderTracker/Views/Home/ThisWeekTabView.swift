//
//  ThisWeekTabView.swift
//  PowderTracker
//
//  This Week tab - Multi-day planning outlook
//

import SwiftUI

struct ThisWeekTabView: View {
    var viewModel: HomeViewModel
    @ObservedObject private var favoritesManager = FavoritesService.shared

    var body: some View {
        LazyVStack(spacing: 20) {
            if favoritesManager.favoriteIds.isEmpty {
                emptyState
            } else {
                // Section 1: Powder Day Outlook (3-Day)
                powderDayOutlookSection

                // Section 2: Week Forecast Summary
                weekForecastSection
            }
        }
        .padding()
    }

    private var powderDayOutlookSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3-Day Powder Outlook")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(favoritesManager.favoriteIds, id: \.self) { mountainId in
                if let mountain = viewModel.mountainsById[mountainId],
                   let data = viewModel.mountainData[mountainId] {
                    PowderDayOutlookCard(
                        mountain: mountain,
                        plan: data.powderDay
                    )
                }
            }
        }
    }

    private var weekForecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Forecast")
                .font(.headline)
                .padding(.horizontal, 4)

            // Aggregate forecast across all favorites
            let maxSnowByDay = calculateMaxSnowByDay()

            if !maxSnowByDay.isEmpty {
                WeekForecastChart(snowByDay: maxSnowByDay)
            } else {
                Text("Forecast data loading...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
    }

    private func calculateMaxSnowByDay() -> [DaySnowfall] {
        var daySnowMap: [String: Double] = [:]

        // Aggregate max snowfall per day across all favorites
        for (_, data) in viewModel.mountainData {
            for (index, day) in data.forecast.prefix(7).enumerated() {
                let dayKey = "Day \(index + 1)"
                daySnowMap[dayKey] = max(daySnowMap[dayKey] ?? 0, Double(day.snowfall))
            }
        }

        // Convert to sorted array
        return daySnowMap.sorted { $0.key < $1.key }
            .map { DaySnowfall(day: $0.key, snowfall: $0.value) }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add mountains to see weekly powder outlook")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Week Forecast Chart

struct DaySnowfall: Identifiable {
    let day: String
    var id: String { day }
    let snowfall: Double
}

struct WeekForecastChart: View {
    let snowByDay: [DaySnowfall]

    private var maxSnow: Double {
        snowByDay.map { $0.snowfall }.max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(snowByDay) { day in
                VStack(spacing: 4) {
                    // Snowfall amount
                    Text("\(Int(day.snowfall))\"")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: day.snowfall))
                        .frame(height: barHeight(for: day.snowfall))

                    // Day label
                    Text(day.day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 120)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func barHeight(for snow: Double) -> CGFloat {
        let minHeight: CGFloat = 10
        let maxHeight: CGFloat = 80
        guard maxSnow > 0 else { return minHeight }

        let ratio = snow / maxSnow
        return minHeight + (maxHeight - minHeight) * CGFloat(ratio)
    }

    private func barColor(for snow: Double) -> Color {
        if snow >= 8 { return .blue }
        if snow >= 4 { return .cyan }
        if snow >= 2 { return .teal }
        return .gray
    }
}

// MARK: - Preview

#Preview {
    Text("Preview temporarily disabled")
        .padding()
}
