import SwiftUI

struct MountainCardRow: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?

    var body: some View {
        HStack(spacing: 12) {
            // Logo
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 40
            )

            // Info column
            VStack(alignment: .leading, spacing: 6) {
                // Name + Region
                HStack(spacing: 8) {
                    Text(mountain.shortName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(mountain.region.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }

                // Lift Status Badge or Static Badge
                if let liftStatus = conditions?.liftStatus {
                    LiftStatusBadge(liftStatus: liftStatus)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("STATIC")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Snowfall
                if let conditions = conditions {
                    if conditions.snowfall24h > 0 || conditions.snowfall48h > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Text("\(conditions.snowfall24h)\" / \(conditions.snowfall48h)\"")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("24h / 48h")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("No new snow")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // Loading state
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Powder score circle
            if let score = powderScore {
                ZStack {
                    Circle()
                        .fill(scoreColor(score.score))
                        .frame(width: 44, height: 44)

                    Text("\(Int(score.score))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            } else if conditions == nil {
                // Loading state
                ProgressView()
                    .frame(width: 44, height: 44)
            } else {
                // No score available
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)

                    Text("—")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 7...10:
            return .green
        case 5..<7:
            return .yellow
        default:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Full data card
        MountainCardRow(
            mountain: Mountain(
                id: "baker",
                name: "Mt. Baker",
                shortName: "Baker",
                location: MountainLocation(lat: 48.8587, lng: -121.6714),
                elevation: MountainElevation(base: 3500, summit: 5089),
                region: "WA",
                color: "#4A90E2",
                website: "https://www.mtbaker.us",
                hasSnotel: true,
                webcamCount: 3,
                logo: "/logos/baker.svg",
                status: nil
            ),
            conditions: MountainConditions(
                mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                snowDepth: 142,
                snowWaterEquivalent: 58.4,
                snowfall24h: 8,
                snowfall48h: 14,
                snowfall7d: 32,
                temperature: 28,
                temperatureByElevation: MountainConditions.TemperatureByElevation(
                    base: 32,
                    mid: 28,
                    summit: 25,
                    referenceElevation: 4500,
                    referenceTemp: 28,
                    lapseRate: 3.5
                ),
                conditions: "Snow",
                wind: MountainConditions.WindInfo(speed: 15, direction: "SW"),
                lastUpdated: ISO8601DateFormatter().string(from: Date()),
                liftStatus: LiftStatus(
                    isOpen: true,
                    liftsOpen: 9,
                    liftsTotal: 10,
                    runsOpen: 45,
                    runsTotal: 52,
                    message: "All major lifts operating",
                    lastUpdated: ISO8601DateFormatter().string(from: Date())
                ),
                dataSources: MountainConditions.DataSources(
                    snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
                    noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
                    liftStatus: MountainConditions.DataSources.LiftStatusSource(available: true)
                )
            ),
            powderScore: MountainPowderScore.mock
        )

        // Static data (no lift status)
        MountainCardRow(
            mountain: Mountain(
                id: "meadows",
                name: "Mt. Hood Meadows",
                shortName: "Meadows",
                location: MountainLocation(lat: 45.3318, lng: -121.6654),
                elevation: MountainElevation(base: 4523, summit: 7300),
                region: "OR",
                color: "#E74C3C",
                website: "https://www.skihood.com",
                hasSnotel: true,
                webcamCount: 2,
                logo: "/logos/meadows.svg",
                status: nil
            ),
            conditions: MountainConditions(
                mountain: MountainInfo(id: "meadows", name: "Mt. Hood Meadows", shortName: "Meadows"),
                snowDepth: 98,
                snowWaterEquivalent: 42.1,
                snowfall24h: 0,
                snowfall48h: 2,
                snowfall7d: 12,
                temperature: 32,
                temperatureByElevation: nil,
                conditions: "Partly Cloudy",
                wind: MountainConditions.WindInfo(speed: 10, direction: "W"),
                lastUpdated: ISO8601DateFormatter().string(from: Date()),
                liftStatus: nil,
                dataSources: MountainConditions.DataSources(
                    snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Mt Hood Meadows"),
                    noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "PDX"),
                    liftStatus: MountainConditions.DataSources.LiftStatusSource(available: false)
                )
            ),
            powderScore: MountainPowderScore(
                mountain: MountainInfo(id: "meadows", name: "Mt. Hood Meadows", shortName: "Meadows"),
                score: 5.2,
                factors: [
                    MountainPowderScore.ScoreFactor(
                        name: "Fresh Snow",
                        value: 0,
                        weight: 0.35,
                        contribution: 0,
                        description: "No new snow"
                    )
                ],
                verdict: "Fair conditions",
                conditions: MountainPowderScore.ScoreConditions(
                    snowfall24h: 0,
                    snowfall48h: 2,
                    temperature: 32,
                    windSpeed: 10,
                    upcomingSnow: 0
                ),
                dataAvailable: MountainPowderScore.DataAvailability(snotel: true, noaa: true)
            )
        )

        // Loading state
        MountainCardRow(
            mountain: Mountain(
                id: "crystal",
                name: "Crystal Mountain",
                shortName: "Crystal",
                location: MountainLocation(lat: 46.9356, lng: -121.4747),
                elevation: MountainElevation(base: 4400, summit: 7012),
                region: "WA",
                color: "#9B59B6",
                website: "https://www.crystalmountainresort.com",
                hasSnotel: true,
                webcamCount: 4,
                logo: "/logos/crystal.svg",
                status: nil
            ),
            conditions: nil,
            powderScore: nil
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
