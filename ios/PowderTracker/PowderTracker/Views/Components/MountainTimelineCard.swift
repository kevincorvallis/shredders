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

    // MARK: - Snow Timeline (OpenSnow-style with centered "Last 24 Hours")

    private var snowTimeline: some View {
        VStack(spacing: 0) {
            // Three-column header: Prev 1-5 Days | Last 24 Hours | Next 1-5 Days
            HStack(spacing: 0) {
                // Past summary
                VStack(spacing: 4) {
                    Text("Prev 1-5 Days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(pastFiveDaysTotal)\"")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)

                // TODAY - BIG NUMBER (focal point)
                VStack(spacing: 4) {
                    Text("Last 24 Hours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(conditions?.snowfall24h ?? 0)\"")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)

                // Future summary
                VStack(spacing: 4) {
                    Text("Next 1-5 Days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if nextFiveDaysTotal > 0 {
                        Text("\(nextFiveDaysTotal)\"")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    } else {
                        Text("-")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)

            Divider()

            // Horizontally scrollable daily timeline - starts centered on TODAY
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(-7...7, id: \.self) { dayOffset in
                            dayBarColumn(for: dayOffset)
                                .id(dayOffset)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onAppear {
                    // Auto-scroll to TODAY (offset 0) on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(0, anchor: .center)
                        }
                    }
                }
            }

            // Reported time
            if let lastUpdated = conditions?.lastUpdated {
                let date = ISO8601DateFormatter().date(from: lastUpdated) ?? Date()
                HStack(spacing: 4) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).day().hour().minute()))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text("Reported")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 6)
            }
        }
    }

    private func dayBarColumn(for offset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let snowfall = snowfallForDay(offset: offset)
        let isToday = offset == 0
        let isPast = offset < 0

        return VStack(spacing: 3) {
            // Day letter
            Text(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1))
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .primary : .secondary)

            // Date number
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .primary : .secondary)

            // Bar chart
            VStack {
                Spacer()
                if snowfall > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isPast ? Color.orange.opacity(0.8) : isToday ? Color.green : Color.blue.opacity(0.8))
                        .frame(width: 12, height: min(CGFloat(snowfall) * 2.5, 50))
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 12, height: 3)
                }
            }
            .frame(height: 50)

            // Snowfall amount (only if > 0)
            if snowfall > 0 {
                Text("\(snowfall)\"")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.primary)
            } else {
                Text(" ")
                    .font(.system(size: 9))
            }
        }
        .frame(width: 32)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isToday ? Color.blue.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isToday ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1.5)
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
