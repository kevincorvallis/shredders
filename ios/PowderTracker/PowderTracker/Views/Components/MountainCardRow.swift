import SwiftUI

struct MountainCardRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?
    var isFavorite: Bool? = nil
    var onFavoriteToggle: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: .spacingM) {
            // Logo
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 40
            )

            // Info column
            VStack(alignment: .leading, spacing: .spacingS) {
                // Name + Region + Pass Badge
                HStack(spacing: .spacingS) {
                    Text(mountain.shortName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    // Cute pass badge
                    if let passType = mountain.passType, passType != .independent {
                        PassBadge(passType: passType, compact: true)
                    }

                    Text(mountain.region.uppercased())
                        .badge()
                        .foregroundColor(.secondary)
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, .spacingXS)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(.cornerRadiusMicro)
                }

                // Lift Status Badge or Static Badge
                if let liftStatus = conditions?.liftStatus {
                    LiftStatusBadge(liftStatus: liftStatus)
                } else {
                    HStack(spacing: .spacingXS) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("STATIC")
                            .badge()
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, .spacingS)
                    .padding(.vertical, .spacingXS)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(.cornerRadiusButton)
                }

                // Snowfall
                if let conditions = conditions {
                    if conditions.snowfall24h > 0 || conditions.snowfall48h > 0 {
                        HStack(spacing: .spacingXS) {
                            Image(systemName: "snowflake")
                                .font(.caption)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.blue)

                            Text("\(conditions.snowfall24h)\" / \(conditions.snowfall48h)\"")
                                .metric()
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())

                            Text("24h / 48h")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: .spacingXS) {
                            Image(systemName: "snowflake")
                                .font(.caption)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.secondary)
                            Text("No new snow")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // Loading state
                    HStack(spacing: .spacingXS) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Favorite button with haptic feedback and bounce animation
            if let isFavorite = isFavorite, let toggle = onFavoriteToggle {
                Button {
                    HapticFeedback.medium.trigger()
                    toggle()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(isFavorite ? .yellow : .gray)
                        .symbolEffect(.bounce, value: isFavorite)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibleButton(
                    label: isFavorite ? "Remove from favorites" : "Add to favorites"
                )
            }

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
        .standardCard()
        .cardMaxWidth()
        .contextMenu {
            // Favorite action
            if let isFavorite = isFavorite, let toggle = onFavoriteToggle {
                Button {
                    HapticFeedback.light.trigger()
                    toggle()
                } label: {
                    Label(
                        isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: isFavorite ? "star.slash" : "star.fill"
                    )
                }
            }

            // Share action
            Button {
                // Share sheet will be presented by parent view
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            // Navigate action
            if let url = URL(string: mountain.website) {
                Link(destination: url) {
                    Label("Visit Website", systemImage: "safari")
                }
            }

            Divider()

            // Info section
            if let conditions = conditions {
                Text("\(conditions.snowfall24h)\" fresh / \(conditions.snowfall48h)\" 48h")
                if let temp = conditions.temperature {
                    Text("\(Int(temp))°F")
                }
            }
        } preview: {
            // Preview card for context menu
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    MountainLogoView(
                        logoUrl: mountain.logo,
                        color: mountain.color,
                        size: 60
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mountain.name)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text(mountain.region)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let score = powderScore?.score {
                        ZStack {
                            Circle()
                                .fill(Color.forPowderScore(score))
                                .frame(width: 50, height: 50)

                            Text("\(Int(score))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }

                if let conditions = conditions {
                    Divider()

                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("24h Snow")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(conditions.snowfall24h)\"")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading) {
                            Text("Base")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(conditions.snowDepth ?? 0)\"")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        if let temp = conditions.temperature {
                            VStack(alignment: .leading) {
                                Text("Temp")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(temp))°F")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(width: 300)
        }
        .accessibleCard(
            label: accessibilityLabel,
            hint: "Double tap to view mountain details"
        )
        .limitDynamicType()
    }

    private var accessibilityLabel: String {
        var parts: [String] = [mountain.shortName]

        if let conditions = conditions {
            if conditions.snowfall24h > 0 || conditions.snowfall48h > 0 {
                parts.append("\(conditions.snowfall24h) inches in 24 hours, \(conditions.snowfall48h) inches in 48 hours")
            } else {
                parts.append("No new snow")
            }

            if let liftStatus = conditions.liftStatus {
                parts.append("\(liftStatus.liftsOpen) of \(liftStatus.liftsTotal) lifts open")
            }
        }

        if let score = powderScore {
            parts.append("Powder score \(Int(score.score)) out of 10")
        }

        if let isFav = isFavorite, isFav {
            parts.append("Favorited")
        }

        return parts.joined(separator: ". ")
    }

    private func scoreColor(_ score: Double) -> Color {
        Color.forPowderScore(score)
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
                status: nil,
                passType: .independent
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
                status: nil,
                passType: .independent
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
                stormInfo: nil,
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
                status: nil,
                passType: .ikon
            ),
            conditions: nil,
            powderScore: nil
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
