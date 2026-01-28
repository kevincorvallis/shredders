import SwiftUI

/// Compact card for comparison grid showing key mountain metrics
/// Redesigned for density - more info in less space
struct ComparisonGridCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?
    let trend: TrendIndicator
    let isBest: Bool

    // Enhanced properties (Phase 2.1)
    var webcamCount: Int = 0
    var alertCount: Int = 0
    var crowdLevel: RiskLevel? = nil
    var onWebcamTap: (() -> Void)? = nil

    private var scoreColor: Color {
        guard let score = powderScore?.score else { return .gray }
        if score >= 7.0 { return .green }
        else if score >= 5.0 { return .yellow }
        else { return .red }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with mountain name and score
            HStack(spacing: 6) {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 24
                )

                Text(mountain.shortName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                // Alert count badge (if alerts > 0)
                if alertCount > 0 {
                    CompactAlertBadge(alertCount: alertCount)
                }

                // Webcam quick-view button
                if webcamCount > 0 {
                    Button {
                        onWebcamTap?()
                    } label: {
                        Image(systemName: "video.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color(.tertiarySystemFill))
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Powder Score Badge
                if let score = powderScore?.score {
                    Text(String(format: "%.1f", score))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(scoreColor)
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground))

            // Main stats area
            VStack(spacing: 8) {
                // Snow stats row
                HStack(spacing: 0) {
                    // 24h Snow
                    statColumn(
                        value: "\(Int(conditions?.snowfall24h ?? 0))\"",
                        label: "24h",
                        highlight: (conditions?.snowfall24h ?? 0) >= 6
                    )

                    Divider().frame(height: 30)

                    // 48h Snow
                    statColumn(
                        value: "\(Int(conditions?.snowfall48h ?? 0))\"",
                        label: "48h",
                        highlight: (conditions?.snowfall48h ?? 0) >= 12
                    )

                    Divider().frame(height: 30)

                    // Base Depth
                    statColumn(
                        value: "\(Int(conditions?.snowDepth ?? 0))\"",
                        label: "Base",
                        highlight: false
                    )
                }

                // Secondary stats row
                HStack(spacing: 12) {
                    // Temperature
                    if let temp = conditions?.temperature {
                        HStack(spacing: 3) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 10))
                            Text("\(temp)°F")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Lifts
                    if let liftStatus = conditions?.liftStatus {
                        HStack(spacing: 3) {
                            Image(systemName: "cablecar.fill")
                                .font(.system(size: 10))
                            Text("\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)")
                                .font(.caption2)
                        }
                        .foregroundColor(liftStatus.liftsOpen > 0 ? .green : .secondary)
                    }

                    // Crowd indicator pill
                    if let crowd = crowdLevel {
                        CrowdIndicatorPill(level: crowd)
                    }

                    Spacer()

                    // Trend
                    HStack(spacing: 2) {
                        Image(systemName: trend.iconName)
                            .font(.system(size: 9))
                        Text(trend.shortLabel)
                            .font(.caption2)
                    }
                    .foregroundColor(trend.color)
                }
                .padding(.horizontal, 4)
            }
            .padding(10)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isBest ? scoreColor : Color.clear, lineWidth: 2)
        )
    }

    private func statColumn(value: String, label: String, highlight: Bool) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(highlight ? .blue : .primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
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

    var shortLabel: String {
        switch self {
        case .improving: return "Up"
        case .stable: return "Flat"
        case .declining: return "Down"
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

// MARK: - Crowd Indicator Pill

struct CrowdIndicatorPill: View {
    let level: RiskLevel

    private var displayText: String {
        switch level {
        case .low: return "Quiet"
        case .medium: return "Mod"
        case .high: return "Busy"
        }
    }

    private var backgroundColor: Color {
        switch level {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }

    private var textColor: Color {
        switch level {
        case .medium: return .black
        case .low, .high: return .white
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 9))
            Text(displayText)
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
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
        snotel != nil || liftStatus != nil
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                score: 6.2,
                factors: [],
                verdict: "Good conditions",
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
