import SwiftUI

/// OpenSnow-style mountain card with snow timeline
struct MountainTimelineCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?
    let forecast: [ForecastDay]
    let filterMode: SnowFilter

    var body: some View {
        VStack(spacing: 0) {
            header

            // Content based on filter mode
            switch filterMode {
            case .weather:
                weatherContent
            case .snowSummary:
                snowTimeline
            case .snowForecast:
                forecastList
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var header: some View {
        HStack(spacing: 10) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(mountain.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(mountain.elevation.base) ft · \(mountain.region.capitalized)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let liftStatus = conditions?.liftStatus {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(liftStatus.isOpen ? "Open" : "Closed")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Circle()
                            .fill(liftStatus.isOpen ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                    }
                    .foregroundColor(liftStatus.isOpen ? .green : .red)

                    if liftStatus.percentOpen > 0 {
                        Text("(\(liftStatus.percentOpen)%)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground))
    }

    // MARK: - Weather Content

    private var weatherContent: some View {
        VStack(spacing: 8) {
            if let conditions = conditions {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temperature")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(conditions.temperature ?? 0)°F")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    if let wind = conditions.wind {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wind")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(wind.speed) mph \(wind.direction)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Snow Timeline

    private var snowTimeline: some View {
        VStack(spacing: 4) {
            // Timeline headers
            HStack(spacing: 0) {
                Text("Prev 1-5 Days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                Text("Last 24 Hours")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)

                Text("Next 1-5 Days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Main timeline row
            HStack(spacing: 0) {
                // Prev 5 days bars (use 7d total as approximation)
                HStack(spacing: 1) {
                    Spacer()
                    ForEach(0..<5, id: \.self) { index in
                        let height = pastDayHeight(for: index)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: 6, height: height)
                    }
                }
                .frame(maxWidth: .infinity)

                // Last 24 hours - BIG NUMBER
                Text("\(conditions?.snowfall24h ?? 0)\"")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)

                // Next 5 days bars (from forecast)
                HStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { index in
                        let snowfall = index < forecast.count ? forecast[index].snowfall : 0
                        let height = forecastBarHeight(Double(snowfall))
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 6, height: height)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 60)

            // Summary numbers
            HStack(spacing: 0) {
                Text("\(pastFiveDaysTotal)\"")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)

                Spacer()
                    .frame(maxWidth: .infinity)

                Text(nextFiveDaysTotal > 0 ? "\(nextFiveDaysTotal)\"" : "")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)

            // Daily breakdown
            dailyBreakdown
        }
        .padding(.bottom, 8)
    }

    private var dailyBreakdown: some View {
        VStack(spacing: 2) {
            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            // Day labels (centered on today)
            HStack(spacing: 1) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                    let dayLetter = date.formatted(.dateTime.weekday(.abbreviated)).prefix(1)
                    Text(String(dayLetter))
                        .font(.system(size: 9))
                        .foregroundColor(offset == 0 ? .primary : .secondary)
                        .fontWeight(offset == 0 ? .bold : .regular)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Dates
            HStack(spacing: 1) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 10))
                        .fontWeight(offset == 0 ? .bold : .regular)
                        .foregroundColor(offset == 0 ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Snow bars
            HStack(spacing: 1) {
                ForEach(-3...3, id: \.self) { offset in
                    VStack {
                        Spacer()
                        let snowfall = snowfallForDay(offset: offset)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(offset <= 0 ? Color.orange.opacity(0.6) : Color.blue.opacity(0.6))
                            .frame(height: dailyBarHeight(snowfall))
                    }
                    .frame(maxWidth: .infinity, maxHeight: 20)
                }
            }
            .padding(.horizontal, 12)

            // Reported time
            if let lastUpdated = conditions?.lastUpdated {
                let date = ISO8601DateFormatter().date(from: lastUpdated) ?? Date()
                HStack(spacing: 4) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).day().hour().minute()))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }

            HStack(spacing: 3) {
                Text("Reported")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Image(systemName: "plus.circle")
                    .font(.system(size: 9))
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 6)
        }
    }

    // MARK: - Forecast List

    private var forecastList: some View {
        VStack(spacing: 0) {
            ForEach(Array(forecast.prefix(5))) { day in
                HStack(spacing: 12) {
                    Text(String(day.date.prefix(5)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text("\(day.snowfall)\"")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 30, alignment: .trailing)

                    Text(day.conditions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(day.high)°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                if day.id != forecast.prefix(5).last?.id {
                    Divider()
                        .padding(.leading, 12)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private func pastDayHeight(for index: Int) -> CGFloat {
        // Use 7d snowfall distributed over past days
        guard let snow7d = conditions?.snowfall7d, snow7d > 0 else { return 4 }
        let avgPerDay = Double(snow7d) / 7.0
        // Vary heights slightly for visual interest
        let variation = Double.random(in: 0.8...1.2)
        let snowfall = avgPerDay * variation
        return min(CGFloat(snowfall * 2), 30)
    }

    private func forecastBarHeight(_ snowfall: Double) -> CGFloat {
        if snowfall == 0 { return 4 }
        return min(CGFloat(snowfall * 2), 30)
    }

    private func dailyBarHeight(_ snowfall: Int) -> CGFloat {
        if snowfall == 0 { return 2 }
        return min(CGFloat(Double(snowfall) * 0.8), 16)
    }

    private func snowfallForDay(offset: Int) -> Int {
        if offset == 0 {
            return conditions?.snowfall24h ?? 0
        } else if offset < 0 {
            // Past days - estimate from 48h/7d
            if offset == -1, let snow48h = conditions?.snowfall48h {
                return snow48h - (conditions?.snowfall24h ?? 0)
            }
            // Rough estimate for older days
            guard let snow7d = conditions?.snowfall7d else { return 0 }
            return max(0, (snow7d - (conditions?.snowfall48h ?? 0)) / 5)
        } else {
            // Future days from forecast
            let index = offset - 1
            guard index < forecast.count else { return 0 }
            return Int(forecast[index].snowfall)
        }
    }

    private var pastFiveDaysTotal: Int {
        conditions?.snowfall7d ?? 0
    }

    private var nextFiveDaysTotal: Int {
        Int(forecast.prefix(5).reduce(0) { $0 + $1.snowfall })
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            MountainTimelineCard(
                mountain: Mountain(
                    id: "baker",
                    name: "Mt. Baker",
                    shortName: "Baker",
                    location: MountainLocation(lat: 48.8, lng: -121.6),
                    elevation: MountainElevation(base: 3500, summit: 5089),
                    region: "washington",
                    color: "#1E40AF",
                    website: "https://www.mtbaker.us",
                    hasSnotel: true,
                    webcamCount: 3,
                    logo: "/logos/baker.svg",
                    status: nil,
                    distance: nil
                ),
                conditions: MountainConditions(
                    mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                    snowDepth: 142,
                    snowWaterEquivalent: 58.4,
                    snowfall24h: 8,
                    snowfall48h: 14,
                    snowfall7d: 32,
                    temperature: 28,
                    temperatureByElevation: nil,
                    conditions: "Snow",
                    wind: MountainConditions.WindInfo(speed: 15, direction: "NW"),
                    lastUpdated: Date().ISO8601Format(),
                    liftStatus: LiftStatus(
                        isOpen: true,
                        liftsOpen: 9,
                        liftsTotal: 10,
                        runsOpen: 45,
                        runsTotal: 52,
                        message: nil,
                        lastUpdated: Date().ISO8601Format()
                    ),
                    dataSources: MountainConditions.DataSources(
                        snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
                        noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
                        liftStatus: MountainConditions.DataSources.LiftStatusSource(available: true)
                    )
                ),
                powderScore: nil,
                forecast: [
                    ForecastDay(date: "2024-12-14", dayOfWeek: "Mon", high: 35, low: 28, snowfall: 6, precipProbability: 90, precipType: "snow", wind: .init(speed: 10, gust: 18), conditions: "Snow", icon: "snow"),
                    ForecastDay(date: "2024-12-15", dayOfWeek: "Tue", high: 33, low: 26, snowfall: 3, precipProbability: 70, precipType: "snow", wind: .init(speed: 12, gust: 20), conditions: "Light Snow", icon: "snow"),
                ],
                filterMode: .snowSummary
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
