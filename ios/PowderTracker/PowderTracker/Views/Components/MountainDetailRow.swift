//
//  MountainDetailRow.swift
//  PowderTracker
//
//  Progressive disclosure row showing mountain summary and expandable details
//

import SwiftUI
import Charts

struct MountainDetailRow: View {
    let mountain: Mountain
    let data: MountainBatchedResponse
    let powderScore: MountainPowderScore?
    let trend: TrendIndicator
    @ObservedObject var viewModel: HomeViewModel

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed State - Always visible
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Mountain logo
                    MountainLogoView(
                        logoUrl: mountain.logo,
                        color: mountain.color,
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mountain.shortName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        // Snowfall 24h/48h
                        HStack(spacing: 4) {
                            Image(systemName: "snow")
                                .font(.caption2)
                                .foregroundStyle(.blue)

                            let snow24h = data.conditions.snowfall24h
                            let snow48h = data.conditions.snowfall48h

                            Text("\(snow24h)\"/\(snow48h)\"")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Trend indicator
                            Image(systemName: trend.iconName)
                                .font(.caption2)
                                .foregroundStyle(trend.color)
                        }
                    }

                    Spacer()

                    // Powder score
                    if let score = powderScore?.score {
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", score))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(scoreColor(score))

                            Text("/10")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Expand chevron
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded State - Detailed information
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 16)

                    // 7-Day simplified timeline
                    sevenDayTimeline

                    // Weather summary
                    weatherSummary

                    // Actions
                    HStack(spacing: 12) {
                        // Get Directions button
                        Button {
                            openMapsDirections()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                Text("Directions")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // View Full Details button
                        NavigationLink {
                            LocationView(mountain: mountain)
                        } label: {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("Details")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.tertiarySystemBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 7-Day Timeline

    private var sevenDayTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Forecast")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.forecast.prefix(7)) { day in
                        VStack(spacing: 6) {
                            // Day label
                            Text(dayLabel(for: day))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            // Snowfall icon + amount
                            VStack(spacing: 2) {
                                Image(systemName: day.snowfall > 0 ? "snow" : "cloud")
                                    .font(.caption)
                                    .foregroundStyle(day.snowfall >= 6 ? .blue : .secondary)

                                Text("\(day.snowfall)\"")
                                    .font(.caption)
                                    .fontWeight(day.snowfall >= 6 ? .semibold : .regular)
                                    .foregroundStyle(day.snowfall >= 6 ? .blue : .primary)
                            }

                            // Temperature range
                            Text("\(day.high)°")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 50)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Weather Summary

    private var weatherSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Conditions")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let temp = data.conditions.temperature {
                    WeatherStatCard(
                        icon: "thermometer.medium",
                        label: "Temperature",
                        value: "\(Int(temp))°"
                    )
                }

                if let wind = data.conditions.wind {
                    WeatherStatCard(
                        icon: "wind",
                        label: "Wind",
                        value: "\(wind.speed) mph"
                    )
                }

                if let snowDepth = data.conditions.snowDepth {
                    WeatherStatCard(
                        icon: "mountain.2.fill",
                        label: "Base Depth",
                        value: "\(Int(snowDepth))\""
                    )
                }

                if let liftStatus = data.conditions.liftStatus {
                    WeatherStatCard(
                        icon: "cablecar.fill",
                        label: "Lifts Open",
                        value: "\(liftStatus.percentOpen)%"
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7.0 { return .green }
        else if score >= 5.0 { return .yellow }
        else { return .red }
    }

    private func dayLabel(for forecastDay: ForecastDay) -> String {
        guard let date = forecastDay.formattedDate else {
            return forecastDay.dayOfWeek
        }

        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isTomorrow = calendar.isDateInTomorrow(date)

        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tom"
        }

        return String(forecastDay.dayOfWeek.prefix(3))
    }

    private func openMapsDirections() {
        let lat = mountain.location.lat
        let lng = mountain.location.lng
        if let url = URL(string: "maps://?daddr=\(lat),\(lng)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Weather Stat Card

struct WeatherStatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    Text("Preview temporarily disabled")
        .padding()
}
