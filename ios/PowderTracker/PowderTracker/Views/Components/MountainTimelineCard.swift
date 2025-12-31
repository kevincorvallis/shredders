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

            // Content based on filter mode with smooth transitions
            Group {
                switch filterMode {
                case .weather:
                    weatherContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .snowSummary:
                    snowTimeline
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .snowForecast:
                    forecastList
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: filterMode)
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
        VStack(spacing: 8) {
            // Summary header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("24h")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(conditions?.snowfall24h ?? 0)\"")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .frame(width: 60)

                VStack(alignment: .leading, spacing: 2) {
                    Text("48h")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(conditions?.snowfall48h ?? 0)\"")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(width: 60)

                VStack(alignment: .leading, spacing: 2) {
                    Text("7d")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(conditions?.snowfall7d ?? 0)\"")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(width: 60)

                Spacer()

                if nextFiveDaysTotal > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next 5d")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(nextFiveDaysTotal)\"")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider()
                .padding(.horizontal, 12)

            // Horizontally scrollable daily timeline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(-7...7, id: \.self) { dayOffset in
                        dailySnowCard(for: dayOffset)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 8)

            // Scroll hint
            Text("← Swipe to see daily forecast →")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .padding(.bottom, 6)
        }
    }

    private func dailySnowCard(for offset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let snowfall = snowfallForDay(offset: offset)
        let isToday = offset == 0
        let isPast = offset < 0
        let isFuture = offset > 0

        return VStack(spacing: 6) {
            // Day label
            Text(isToday ? "TODAY" : date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.system(size: 10, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .primary : .secondary)

            // Date
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            // Snow bar
            VStack {
                Spacer()
                if snowfall > 0 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isPast ? Color.orange : isFuture ? Color.blue : Color.green)
                        .frame(width: 20, height: min(CGFloat(snowfall) * 3, 60))
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 20, height: 4)
                }
            }
            .frame(height: 60)

            // Snowfall amount
            if snowfall > 0 {
                Text("\(snowfall)\"")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
            } else {
                Text("0\"")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Forecast info for future days
            if isFuture && offset - 1 < forecast.count {
                let day = forecast[offset - 1]
                HStack(spacing: 2) {
                    Text("\(day.high)°")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(day.icon.prefix(1))
                        .font(.system(size: 10))
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.blue.opacity(0.1) : Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isToday ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
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
