import SwiftUI

/// Compact card for comparison grid showing key mountain metrics
/// Designed for 2-column grid layout with visual hierarchy emphasizing powder score
struct ComparisonGridCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?
    let trend: TrendIndicator
    let isBest: Bool // Highlight the best powder mountain

    // Color coding based on powder score
    private var scoreColor: Color {
        guard let score = powderScore?.score else { return .gray }

        if score >= 7.0 {
            return .green
        } else if score >= 5.0 {
            return .yellow
        } else {
            return .red
        }
    }

    // Background gradient based on powder score
    private var backgroundGradient: LinearGradient {
        guard let score = powderScore?.score else {
            return LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if score >= 7.0 {
            // Green gradient for excellent powder
            return LinearGradient(
                colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if score >= 5.0 {
            // Yellow gradient for good powder
            return LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.yellow.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Red/gray gradient for fair powder
            return LinearGradient(
                colors: [Color.red.opacity(0.08), Color(.systemGray6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(backgroundGradient)

            // Glassmorphic overlay
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(.ultraThinMaterial)

            // Best powder glow
            if isBest {
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .stroke(scoreColor, lineWidth: 2)
                    .shadow(color: scoreColor.opacity(0.5), radius: 8)
            }

            // Card content
            VStack(spacing: .spacingS) {
                // Header: Mountain name + badge
                HStack(spacing: .spacingXS) {
                    Text(mountain.shortName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    // Live/Static badge
                    if let conditions = conditions {
                        HStack(spacing: .spacingXS / 2) {
                            if conditions.dataSources.isLive {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 5)
                            }
                            Text(conditions.dataSources.isLive ? "LIVE" : "STATIC")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, .spacingXS / 2)
                        .background(
                            Capsule()
                                .fill(conditions.dataSources.isLive ? Color.green : Color.orange)
                                .shadow(color: conditions.dataSources.isLive ? Color.green.opacity(0.4) : Color.orange.opacity(0.4), radius: 4)
                        )
                    }
                }
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingM)

                // Powder Score (Hero metric)
                VStack(spacing: .spacingXS) {
                    if let score = powderScore?.score {
                        Text(String(format: "%.1f", score))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)

                        Text("/10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("--")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)

                        Text("No Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, .spacingXS)

                // Snowfall 24h/48h
                HStack(spacing: .spacingXS) {
                    let snow24h = conditions?.snowfall24h ?? 0
                    let snow48h = conditions?.snowfall48h ?? 0

                    Text("\(snow24h)\"")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(snow24h >= 6 ? .blue : .primary)

                    Text("/")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("\(snow48h)\"")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(snow48h >= 12 ? .blue : .primary)
                }

                // Trend indicator
                HStack(spacing: .spacingXS) {
                    Image(systemName: trend.iconName)
                        .font(.caption)
                        .foregroundColor(trend.color)

                    Text(trend.label)
                        .font(.caption)
                        .foregroundColor(trend.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                // Bottom row: Lift status + Temperature
                HStack(spacing: .spacingM) {
                    // Lift status
                    if let liftStatus = conditions?.liftStatus {
                        HStack(spacing: .spacingXS) {
                            Image(systemName: "cablecar.fill")
                                .font(.caption)

                            Text("\(liftStatus.percentOpen)%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.primary)
                    }

                    Spacer()

                    // Temperature
                    if let temp = conditions?.temperature {
                        HStack(spacing: .spacingXS) {
                            Image(systemName: "thermometer.medium")
                                .font(.caption)

                            Text("\(temp)°")
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, .spacingM)
                .padding(.bottom, .spacingM)
            }
        }
        .frame(width: 165, height: 220)
        .cornerRadius(.cornerRadiusHero)
        .shadow(color: .black.opacity(isBest ? 0.15 : 0.08), radius: isBest ? 12 : 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let scoreText = powderScore.map { String(format: "%.1f out of 10", $0.score) } ?? "No score"
        let snow24h = conditions?.snowfall24h ?? 0
        let snow48h = conditions?.snowfall48h ?? 0
        let trendText = "\(trend.label) conditions"
        let bestText = isBest ? "Best powder today" : ""

        return "\(mountain.shortName). Powder score: \(scoreText). \(snow24h) inches in 24 hours, \(snow48h) inches in 48 hours. \(trendText). \(bestText)"
    }
}

// MARK: - Supporting Types

enum TrendIndicator {
    case improving
    case stable
    case declining

    var iconName: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .gray
        case .declining: return .orange
        }
    }
}

// MARK: - Data Source Helper

extension MountainConditions {
    var isLive: Bool {
        dataSources.isLive
    }
}

extension MountainConditions.DataSources {
    var isLive: Bool {
        // Consider it live if it has real-time lift status
        snotel != nil || liftStatus != nil
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        ComparisonGridCard(
            mountain: Mountain(
                id: "baker",
                name: "Mt. Baker",
                shortName: "Baker",
                location: MountainLocation(lat: 48.8563, lng: -121.6644),
                elevation: MountainElevation(base: 3500, summit: 5089),
                region: "WA",
                color: "#4A90E2",
                website: "https://www.mtbaker.us",
                hasSnotel: true,
                webcamCount: 3,
                logo: "/logos/baker.svg",
                status: nil,
                passType: .ikon
            ),
            conditions: nil,
            powderScore: MountainPowderScore(
                mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                score: 8.5,
                factors: [],
                verdict: "Excellent powder",
                conditions: nil,
                dataAvailable: nil
            ),
            trend: .improving,
            isBest: true
        )

        ComparisonGridCard(
            mountain: Mountain(
                id: "crystal",
                name: "Crystal Mountain",
                shortName: "Crystal",
                location: MountainLocation(lat: 46.9356, lng: -121.4747),
                elevation: MountainElevation(base: 4400, summit: 7012),
                region: "WA",
                color: "#9C27B0",
                website: "https://www.crystalmountainresort.com",
                hasSnotel: true,
                webcamCount: 4,
                logo: "/logos/crystal.svg",
                status: nil,
                passType: .ikon
            ),
            conditions: nil,
            powderScore: MountainPowderScore(
                mountain: MountainInfo(id: "crystal", name: "Crystal Mountain", shortName: "Crystal"),
                score: 7.2,
                factors: [],
                verdict: "Great conditions",
                conditions: nil,
                dataAvailable: nil
            ),
            trend: .stable,
            isBest: false
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
