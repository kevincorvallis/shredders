import SwiftUI

/// OpenSnow-style mountain card with snow timeline
struct MountainTimelineCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?
    let forecast: [ForecastDay]

    var body: some View {
        VStack(spacing: 0) {
            // Header: Logo + Name + Status
            header

            // Snow timeline
            snowTimeline
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var header: some View {
        HStack(spacing: 12) {
            // Logo
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 50
            )

            // Name and location
            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(mountain.elevation.base) ft · \(mountain.region.capitalized) · United States")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Open status
            if let liftStatus = conditions?.liftStatus {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(liftStatus.isOpen ? "Open" : "Closed")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(liftStatus.isOpen ? .green : .red)

                    if liftStatus.percentOpen > 0 {
                        HStack(spacing: 2) {
                            Text("(\(liftStatus.percentOpen)%)")
                                .font(.subheadline)
                                .foregroundColor(.green)

                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
    }

    private var snowTimeline: some View {
        VStack(spacing: 8) {
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

                Text("Next 6+")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 60)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Main timeline row
            HStack(spacing: 0) {
                // Prev 1-5 days bar chart
                HStack(spacing: 2) {
                    Spacer()
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: 8, height: CGFloat.random(in: 10...30))
                    }
                }
                .frame(maxWidth: .infinity)

                // Last 24 hours - BIG NUMBER
                Text("\(conditions?.snowfall24h ?? 0)\"")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)

                // Next 1-5 days preview
                HStack(spacing: 4) {
                    ForEach(forecast.prefix(5)) { day in
                        if day.snowfall > 0 {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Next 6+ placeholder
                Text("")
                    .frame(width: 60)
            }
            .frame(height: 80)

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

                Text("")
                    .frame(width: 60)
            }
            .padding(.horizontal)

            // Daily breakdown calendar
            dailyBreakdown
        }
        .padding(.bottom, 12)
    }

    private var dailyBreakdown: some View {
        VStack(spacing: 4) {
            Divider()
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Day labels
            HStack(spacing: 2) {
                ForEach(["S", "S", "M", "T", "W", "T", "F"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Dates
            HStack(spacing: 2) {
                ForEach(0..<7) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset - 3, to: Date())!
                    Text(date.formatted(.dateTime.day()))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Snow bars (simplified)
            HStack(spacing: 2) {
                ForEach(0..<7) { _ in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.orange.opacity(0.5))
                            .frame(height: CGFloat.random(in: 4...20))
                    }
                    .frame(maxWidth: .infinity, maxHeight: 24)
                }
            }
            .padding(.horizontal)

            // Reported time
            Text("Wed 31 12:00a")
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text("Reported")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: "plus.circle")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 8)
        }
    }

    private var pastFiveDaysTotal: Int {
        // Mock calculation - would use real historical data
        Int.random(in: 10...30)
    }

    private var nextFiveDaysTotal: Int {
        Int(forecast.prefix(5).reduce(0) { $0 + $1.snowfall })
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
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
                    wind: nil,
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
                forecast: []
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
