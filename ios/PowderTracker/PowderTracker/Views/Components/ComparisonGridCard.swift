import SwiftUI

/// Compact card for comparison grid showing key mountain metrics
/// Redesigned for density - more info in less space
/// Uses design system tokens for consistent styling with the main app
struct ComparisonGridCard: View {
    @Environment(\.colorScheme) private var colorScheme

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
        return Color.forPowderScore(score)
    }

    private var hasFreshSnow: Bool {
        (conditions?.snowfall24h ?? 0) >= 6
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with mountain name and score
            headerSection

            // Main stats area
            statsSection
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .stroke(
                    isBest ? scoreColor.opacity(0.8) : Color.clear,
                    lineWidth: 2
                )
        )
        .cardShadow()
        .overlay(alignment: .topTrailing) {
            // Best pick indicator
            if isBest {
                bestPickBadge
            }
        }
        .accessibleCard(
            label: accessibilityLabel,
            hint: "Double tap to view mountain details"
        )
        .limitDynamicType()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: .spacingXS) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: .iconMedium
            )

            Text(mountain.shortName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(.primary)
                .layoutPriority(1)

            Spacer(minLength: .spacingXS)

            // Compact badges row
            HStack(spacing: .spacingXS) {
                // Alert count badge (if alerts > 0)
                if alertCount > 0 {
                    CompactAlertBadge(alertCount: alertCount)
                }

                // Webcam quick-view button
                if webcamCount > 0 {
                    webcamButton
                }

                // Powder Score Badge
                if let score = powderScore?.score {
                    powderScoreBadge(score: score)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, .spacingS)
        .padding(.vertical, .spacingS)
        .background(
            Color(.tertiarySystemBackground)
                .opacity(colorScheme == .dark ? 0.5 : 1)
        )
    }

    private var webcamButton: some View {
        Button {
            HapticFeedback.light.trigger()
            onWebcamTap?()
        } label: {
            Image(systemName: "video.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View \(mountain.shortName) webcams")
        .accessibilityHint("Opens webcam viewer")
    }

    private func powderScoreBadge(score: Double) -> some View {
        Text(String(format: "%.1f", score))
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(scoreColor)
                    .shadow(color: scoreColor.opacity(0.4), radius: 3, y: 1)
            )
            .contentTransition(.numericText())
    }

    private var bestPickBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
            Text("BEST")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [scoreColor, scoreColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .offset(x: -8, y: -8)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: .spacingS) {
            // Snow stats row
            HStack(spacing: 0) {
                // 24h Snow
                statColumn(
                    value: "\(Int(conditions?.snowfall24h ?? 0))\"",
                    label: "24h",
                    highlight: (conditions?.snowfall24h ?? 0) >= 6,
                    icon: hasFreshSnow ? "snowflake" : nil
                )

                verticalDivider

                // 48h Snow
                statColumn(
                    value: "\(Int(conditions?.snowfall48h ?? 0))\"",
                    label: "48h",
                    highlight: (conditions?.snowfall48h ?? 0) >= 12,
                    icon: nil
                )

                verticalDivider

                // Base Depth
                statColumn(
                    value: "\(Int(conditions?.snowDepth ?? 0))\"",
                    label: "Base",
                    highlight: false,
                    icon: nil
                )
            }

            // Secondary stats row
            secondaryStatsRow
        }
        .padding(.spacingM)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1, height: 32)
    }

    private var secondaryStatsRow: some View {
        ViewThatFits(in: .horizontal) {
            // Tier 1: compact single row
            HStack(spacing: .spacingXS) {
                temperatureStat
                liftsStat
                if let crowd = crowdLevel {
                    CrowdIndicatorPill(level: crowd, compact: true)
                }
                Spacer(minLength: 0)
                trendIndicator
            }

            // Tier 2: two-line fallback
            VStack(spacing: .spacingXS) {
                HStack(spacing: .spacingXS) {
                    temperatureStat
                    liftsStat
                    if let crowd = crowdLevel {
                        CrowdIndicatorPill(level: crowd, compact: true)
                    }
                    Spacer(minLength: 0)
                }
                HStack {
                    Spacer(minLength: 0)
                    trendIndicator
                }
            }
        }
    }

    @ViewBuilder
    private var temperatureStat: some View {
        if let temp = conditions?.temperature {
            HStack(spacing: .spacingXS) {
                Image(systemName: SkiIcon.temperature.systemName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.forTemperature(Int(temp)))
                Text("\(Int(temp))°")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var liftsStat: some View {
        if let liftStatus = conditions?.liftStatus {
            HStack(spacing: .spacingXS) {
                Image(systemName: SkiIcon.chairlift.systemName)
                    .font(.system(size: 10, weight: .medium))
                Text("\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .foregroundColor(liftStatus.liftsOpen > 0 ? Color(UIColor.systemGreen) : .secondary)
        }
    }

    private var trendIndicator: some View {
        HStack(spacing: .spacingXS) {
            Image(systemName: trend.iconName)
                .font(.system(size: 10, weight: .semibold))
            Text(trend.shortLabel)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, 6)
        .padding(.vertical, .spacingXS)
        .background(
            Capsule()
                .fill(trend.color.opacity(0.12))
        )
        .fixedSize()
    }

    private func statColumn(value: String, label: String, highlight: Bool, icon: String?) -> some View {
        VStack(spacing: .spacingXS) {
            HStack(spacing: 2) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                        .symbolEffect(.variableColor, isActive: highlight)
                }
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(highlight ? .cyan : .primary)
                    .contentTransition(.numericText())
            }
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts: [String] = [mountain.shortName]

        if let score = powderScore?.score {
            parts.append("Powder score \(String(format: "%.1f", score))")
        }

        if isBest {
            parts.append("Best pick")
        }

        if let conditions = conditions {
            if conditions.snowfall24h > 0 {
                parts.append("\(Int(conditions.snowfall24h)) inches in 24 hours")
            }
            if let liftStatus = conditions.liftStatus {
                parts.append("\(liftStatus.liftsOpen) of \(liftStatus.liftsTotal) lifts open")
            }
        }

        parts.append("Trend \(trend.label)")

        return parts.joined(separator: ", ")
    }
}

// MARK: - Equatable

extension ComparisonGridCard: Equatable {
    nonisolated static func == (lhs: ComparisonGridCard, rhs: ComparisonGridCard) -> Bool {
        lhs.mountain.id == rhs.mountain.id
            && lhs.conditions?.snowfall24h == rhs.conditions?.snowfall24h
            && lhs.conditions?.snowfall48h == rhs.conditions?.snowfall48h
            && lhs.conditions?.snowDepth == rhs.conditions?.snowDepth
            && lhs.conditions?.temperature == rhs.conditions?.temperature
            && lhs.powderScore?.score == rhs.powderScore?.score
            && lhs.trend == rhs.trend
            && lhs.isBest == rhs.isBest
            && lhs.webcamCount == rhs.webcamCount
            && lhs.alertCount == rhs.alertCount
            && lhs.crowdLevel == rhs.crowdLevel
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
        case .improving: return Color(UIColor.systemGreen)
        case .stable: return Color(UIColor.systemGray)
        case .declining: return Color(UIColor.systemOrange)
        }
    }
}

// MARK: - Crowd Indicator Pill

struct CrowdIndicatorPill: View {
    let level: RiskLevel
    var compact: Bool = false

    private var displayText: String {
        switch level {
        case .low: return "Quiet"
        case .medium: return "Mod"
        case .high: return "Busy"
        }
    }

    private var backgroundColor: Color {
        switch level {
        case .low: return Color(UIColor.systemGreen)
        case .medium: return Color(UIColor.systemYellow)
        case .high: return Color(UIColor.systemRed)
        }
    }

    private var textColor: Color {
        switch level {
        case .medium: return .black
        case .low, .high: return .white
        }
    }

    private var iconName: String {
        switch level {
        case .low: return "person.fill"
        case .medium: return "person.2.fill"
        case .high: return "person.3.fill"
        }
    }

    var body: some View {
        HStack(spacing: compact ? 0 : .spacingXS) {
            Image(systemName: iconName)
                .font(.system(size: 9, weight: .medium))
            if !compact {
                Text(displayText)
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundColor(textColor)
        .padding(.horizontal, compact ? 5 : .spacingS)
        .padding(.vertical, .spacingXS)
        .background(
            Capsule()
                .fill(backgroundColor.opacity(0.9))
                .shadow(color: backgroundColor.opacity(0.3), radius: 2, y: 1)
        )
        .accessibilityLabel("Crowd level: \(displayText)")
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

#Preview("Comparison Grid") {
    ScrollView {
        VStack(alignment: .leading, spacing: .spacingL) {
            Text("Quick Comparison")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: .spacingM), GridItem(.flexible(), spacing: .spacingM)], spacing: .spacingM) {
                // Best pick with full data
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
                    conditions: MountainConditions(
                        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                        snowDepth: 142,
                        snowWaterEquivalent: 58.4,
                        snowfall24h: 12,
                        snowfall48h: 18,
                        snowfall7d: 32,
                        temperature: 26,
                        temperatureByElevation: nil,
                        conditions: "Snow",
                        wind: MountainConditions.WindInfo(speed: 15, direction: "SW"),
                        lastUpdated: ISO8601DateFormatter().string(from: Date()),
                        liftStatus: LiftStatus(
                            isOpen: true,
                            liftsOpen: 8,
                            liftsTotal: 10,
                            runsOpen: 45,
                            runsTotal: 52,
                            message: nil,
                            lastUpdated: ISO8601DateFormatter().string(from: Date())
                        ),
                        dataSources: MountainConditions.DataSources(
                            snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
                            noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
                            liftStatus: MountainConditions.DataSources.LiftStatusSource(available: true)
                        )
                    ),
                    powderScore: MountainPowderScore(
                        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                        score: 8.5,
                        factors: [],
                        verdict: "Excellent powder",
                        conditions: nil,
                        stormInfo: nil,
                        dataAvailable: nil
                    ),
                    trend: .improving,
                    isBest: true,
                    webcamCount: 3,
                    alertCount: 1,
                    crowdLevel: .low
                )

                // Second place
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
                    conditions: MountainConditions(
                        mountain: MountainInfo(id: "crystal", name: "Crystal Mountain", shortName: "Crystal"),
                        snowDepth: 98,
                        snowWaterEquivalent: 42.1,
                        snowfall24h: 6,
                        snowfall48h: 10,
                        snowfall7d: 24,
                        temperature: 28,
                        temperatureByElevation: nil,
                        conditions: "Partly Cloudy",
                        wind: MountainConditions.WindInfo(speed: 10, direction: "W"),
                        lastUpdated: ISO8601DateFormatter().string(from: Date()),
                        liftStatus: LiftStatus(
                            isOpen: true,
                            liftsOpen: 9,
                            liftsTotal: 11,
                            runsOpen: 50,
                            runsTotal: 57,
                            message: nil,
                            lastUpdated: ISO8601DateFormatter().string(from: Date())
                        ),
                        dataSources: MountainConditions.DataSources(
                            snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Crystal"),
                            noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
                            liftStatus: MountainConditions.DataSources.LiftStatusSource(available: true)
                        )
                    ),
                    powderScore: MountainPowderScore(
                        mountain: MountainInfo(id: "crystal", name: "Crystal Mountain", shortName: "Crystal"),
                        score: 7.2,
                        factors: [],
                        verdict: "Good conditions",
                        conditions: nil,
                        stormInfo: nil,
                        dataAvailable: nil
                    ),
                    trend: .stable,
                    isBest: false,
                    webcamCount: 4,
                    crowdLevel: .medium
                )

                // Declining conditions
                ComparisonGridCard(
                    mountain: Mountain(
                        id: "stevens",
                        name: "Stevens Pass",
                        shortName: "Stevens",
                        location: MountainLocation(lat: 47.7448, lng: -121.0890),
                        elevation: MountainElevation(base: 4000, summit: 5845),
                        region: "WA",
                        color: "#2ECC71",
                        website: "https://www.stevenspass.com",
                        hasSnotel: true,
                        webcamCount: 2,
                        logo: "/logos/stevens.svg",
                        status: nil,
                        passType: .epic
                    ),
                    conditions: MountainConditions(
                        mountain: MountainInfo(id: "stevens", name: "Stevens Pass", shortName: "Stevens"),
                        snowDepth: 76,
                        snowWaterEquivalent: 32.0,
                        snowfall24h: 0,
                        snowfall48h: 2,
                        snowfall7d: 8,
                        temperature: 34,
                        temperatureByElevation: nil,
                        conditions: "Cloudy",
                        wind: MountainConditions.WindInfo(speed: 5, direction: "S"),
                        lastUpdated: ISO8601DateFormatter().string(from: Date()),
                        liftStatus: LiftStatus(
                            isOpen: true,
                            liftsOpen: 6,
                            liftsTotal: 10,
                            runsOpen: 35,
                            runsTotal: 52,
                            message: nil,
                            lastUpdated: ISO8601DateFormatter().string(from: Date())
                        ),
                        dataSources: MountainConditions.DataSources(
                            snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Stevens"),
                            noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
                            liftStatus: MountainConditions.DataSources.LiftStatusSource(available: true)
                        )
                    ),
                    powderScore: MountainPowderScore(
                        mountain: MountainInfo(id: "stevens", name: "Stevens Pass", shortName: "Stevens"),
                        score: 5.4,
                        factors: [],
                        verdict: "Fair conditions",
                        conditions: nil,
                        stormInfo: nil,
                        dataAvailable: nil
                    ),
                    trend: .declining,
                    isBest: false,
                    webcamCount: 2,
                    crowdLevel: .high
                )

                // No conditions data
                ComparisonGridCard(
                    mountain: Mountain(
                        id: "snoqualmie",
                        name: "Snoqualmie",
                        shortName: "Snoqualmie",
                        location: MountainLocation(lat: 47.4231, lng: -121.4140),
                        elevation: MountainElevation(base: 3000, summit: 5400),
                        region: "WA",
                        color: "#E74C3C",
                        website: "https://www.summitatsnoqualmie.com",
                        hasSnotel: false,
                        webcamCount: 1,
                        logo: "/logos/snoqualmie.svg",
                        status: nil,
                        passType: .epic
                    ),
                    conditions: nil,
                    powderScore: nil,
                    trend: .stable,
                    isBest: false,
                    webcamCount: 1
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    LazyVGrid(columns: [GridItem(.flexible(), spacing: .spacingM), GridItem(.flexible(), spacing: .spacingM)], spacing: .spacingM) {
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
            conditions: MountainConditions(
                mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                snowDepth: 142,
                snowWaterEquivalent: 58.4,
                snowfall24h: 12,
                snowfall48h: 18,
                snowfall7d: 32,
                temperature: 26,
                temperatureByElevation: nil,
                conditions: "Snow",
                wind: nil,
                lastUpdated: ISO8601DateFormatter().string(from: Date()),
                liftStatus: LiftStatus(
                    isOpen: true,
                    liftsOpen: 8,
                    liftsTotal: 10,
                    runsOpen: 45,
                    runsTotal: 52,
                    message: nil,
                    lastUpdated: ISO8601DateFormatter().string(from: Date())
                ),
                dataSources: MountainConditions.DataSources(
                    snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
                    noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
                    liftStatus: MountainConditions.DataSources.LiftStatusSource(available: true)
                )
            ),
            powderScore: MountainPowderScore(
                mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                score: 8.5,
                factors: [],
                verdict: "Excellent powder",
                conditions: nil,
                stormInfo: nil,
                dataAvailable: nil
            ),
            trend: .improving,
            isBest: true,
            webcamCount: 3,
            alertCount: 2,
            crowdLevel: .low
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
