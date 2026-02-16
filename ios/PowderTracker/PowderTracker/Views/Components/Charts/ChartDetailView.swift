//
//  ChartDetailView.swift
//  PowderTracker
//
//  Clean day-by-day forecast view (OpenSnow-style)
//

import SwiftUI

/// Simplified forecast detail view — summary, alerts, day-by-day rows
struct ChartDetailView: View {
    let mountain: Mountain
    let forecast: [ForecastDay]
    @Binding var isPresented: Bool

    @State private var expandedDayIndex: Int? = nil
    @State private var rowsAppeared: Bool = false

    private let powderDayThreshold = 6
    private let epicPowderThreshold = 12

    // MARK: - Computed

    private var days: [ForecastDay] {
        Array(forecast.prefix(7))
    }

    private var totalSnowfall: Int {
        days.reduce(0) { $0 + $1.snowfall }
    }

    private var powderDayCount: Int {
        days.filter { $0.snowfall >= powderDayThreshold }.count
    }

    private var avgHigh: Int {
        guard !days.isEmpty else { return 0 }
        return days.reduce(0) { $0 + $1.high } / days.count
    }

    private var maxSnowfall: Int {
        days.map(\.snowfall).max() ?? 1
    }

    private var stormAlert: (day: ForecastDay, snowfall: Int)? {
        guard let day = days.first(where: { $0.snowfall >= 8 }) else { return nil }
        return (day, day.snowfall)
    }

    private var windAdvisory: (day: ForecastDay, gust: Int)? {
        guard let day = days.first(where: { $0.wind.gust >= 30 }) else { return nil }
        return (day, day.wind.gust)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summarySection
                    insightBanners
                    dayRows
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(mountain.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                rowsAppeared = true
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("7-Day Forecast")
                    .font(.title2)
                    .fontWeight(.bold)
                if powderDayCount > 0 {
                    Image(systemName: "snowflake")
                        .foregroundStyle(.blue)
                        .font(.subheadline)
                }
            }

            Text("\(totalSnowfall)\" total \u{00B7} \(powderDayCount) powder day\(powderDayCount == 1 ? "" : "s") \u{00B7} Avg high \(avgHigh)\u{00B0}")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Insight Banners

    @ViewBuilder
    private var insightBanners: some View {
        VStack(spacing: 8) {
            if let storm = stormAlert {
                bannerCard(
                    icon: "cloud.snow.fill",
                    title: "Storm Alert",
                    description: "\(storm.snowfall)\" expected on \(storm.day.dayOfWeek)",
                    tint: .blue
                )
            }
            if let wind = windAdvisory {
                bannerCard(
                    icon: "wind",
                    title: "Wind Advisory",
                    description: "Gusts to \(wind.gust)mph on \(wind.day.dayOfWeek)",
                    tint: .teal
                )
            }
        }
        .padding(.horizontal)
    }

    private func bannerCard(icon: String, title: String, description: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Day Rows

    private var dayRows: some View {
        VStack(spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                let isPowder = day.snowfall >= powderDayThreshold
                let isEpic = day.snowfall >= epicPowderThreshold
                let isExpanded = expandedDayIndex == index
                let isToday = index == 0

                VStack(spacing: 0) {
                    // Main row
                    HStack(spacing: 10) {
                        // Day label
                        VStack(spacing: 1) {
                            Text(isToday ? "Today" : day.dayOfWeek)
                                .font(.subheadline)
                                .fontWeight(isToday ? .bold : .medium)
                            if isPowder {
                                Image(systemName: "snowflake")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .frame(width: 44, alignment: .leading)

                        // Weather icon
                        Text(day.iconEmoji)
                            .font(.title3)

                        // Snow bar
                        GeometryReader { geo in
                            let fraction = maxSnowfall > 0 ? CGFloat(day.snowfall) / CGFloat(max(maxSnowfall, 1)) : 0
                            let barWidth = day.snowfall > 0 ? max(6, fraction * geo.size.width) : 0

                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        isEpic ? LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing) :
                                        isPowder ? LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(width: barWidth, height: 24)
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(height: 24)

                        // Snow amount
                        Text("\(day.snowfall)\"")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(width: 32, alignment: .trailing)

                        // Temps
                        Text("\(day.high)\u{00B0}/\(day.low)\u{00B0}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }

                    // Wind subtitle (only if gusty)
                    if day.wind.gust >= 20 {
                        HStack {
                            Spacer().frame(width: 44 + 10) // align under icon
                            Text("\(day.wind.gust)mph gusts")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.top, 2)
                    }

                    // Expanded detail
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 6) {
                            Divider().padding(.vertical, 4)

                            detailLine(label: "Conditions", value: day.conditions)
                            detailLine(label: "Precip", value: "\(day.precipProbability)% \(day.precipType)")
                            detailLine(label: "Wind", value: "\(day.wind.speed)mph, gusts \(day.wind.gust)mph")
                            detailLine(label: "High / Low", value: "\(day.high)\u{00B0} / \(day.low)\u{00B0}")
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    isPowder ?
                        Color.blue.opacity(0.06) :
                        Color(UIColor.secondarySystemGroupedBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        expandedDayIndex = expandedDayIndex == index ? nil : index
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .opacity(rowsAppeared ? 1 : 0)
                .offset(y: rowsAppeared ? 0 : 10)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.04),
                    value: rowsAppeared
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func detailLine(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    ChartDetailView(
        mountain: Mountain.mock,
        forecast: ForecastDay.mockWeek,
        isPresented: .constant(true)
    )
}
