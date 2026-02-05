import SwiftUI

/// Compact hero card showing the most important information at a glance
struct AtAGlanceCard: View {
    var viewModel: LocationViewModel
    var onNavigateToLifts: (() -> Void)?
    @State private var expandedSection: ExpandableSection? = nil

    enum ExpandableSection {
        case snow, weather, lifts
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with powder score
            powderScoreHeader

            Divider()

            // Three-column grid
            HStack(spacing: 0) {
                // Snow section
                glanceSection(
                    icon: "snowflake",
                    title: "SNOW",
                    metrics: snowMetrics,
                    status: snowStatus,
                    color: .blue,
                    section: .snow
                )

                Divider()

                // Weather section
                glanceSection(
                    icon: "cloud.sun.fill",
                    title: "WEATHER",
                    metrics: weatherMetrics,
                    status: weatherStatus,
                    color: weatherColor,
                    section: .weather
                )

                Divider()

                // Lifts section
                glanceSection(
                    icon: "cablecar.fill",
                    title: "LIFTS",
                    metrics: liftMetrics,
                    status: liftStatus,
                    color: liftColor,
                    section: .lifts
                )
            }
            .frame(minHeight: 120)

            // Expanded details
            if let section = expandedSection {
                Divider()
                expandedDetailsView(for: section)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
        .heroShadow()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("At a glance conditions")
    }

    // MARK: - Powder Score Header
    private var powderScoreHeader: some View {
        HStack(spacing: .spacingM) {
            // Score badge
            ZStack {
                Circle()
                    .fill(powderScoreColor.opacity(.opacityMedium))
                    .frame(width: 50, height: 50)

                Text(String(format: "%.1f", viewModel.powderScore ?? 0))
                    .heroNumber()
                    .foregroundColor(powderScoreColor)
            }

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(powderScoreLabel)
                    .cardTitle()
                    .foregroundColor(powderScoreColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text("Powder Conditions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Timestamp
            if let lastUpdated = viewModel.lastUpdated {
                VStack(alignment: .trailing, spacing: .spacingXS) {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(lastUpdated, style: .relative)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.spacingM)
    }

    // MARK: - Glance Section
    @ViewBuilder
    private func glanceSection(
        icon: String,
        title: String,
        metrics: [String],
        status: String,
        color: Color,
        section: ExpandableSection
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                expandedSection = expandedSection == section ? nil : section
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                    Text(metric)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    Text(status)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Color(.tertiarySystemFill)
                        .overlay(color.opacity(.opacitySubtle))
                )
                .cornerRadius(.cornerRadiusButton)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Details
    @ViewBuilder
    private func expandedDetailsView(for section: ExpandableSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            switch section {
            case .snow:
                snowExpandedDetails
            case .weather:
                weatherExpandedDetails
            case .lifts:
                liftsExpandedDetails
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
    }

    private var snowExpandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snow Details")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                MetricView(
                    icon: "mountain.2.fill",
                    label: "Base Depth",
                    value: "\(Int(viewModel.currentSnowDepth ?? 0))\"",
                    color: .blue
                )
                MetricView(
                    icon: "snowflake",
                    label: "24h Snow",
                    value: "\(Int(viewModel.snowDepth24h ?? 0))\"",
                    color: .blue
                )
                MetricView(
                    icon: "snowflake",
                    label: "48h Snow",
                    value: "\(Int(viewModel.snowDepth48h ?? 0))\"",
                    color: .blue.opacity(0.7)
                )
            }

            if let description = viewModel.weatherDescription {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var weatherExpandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Details")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                MetricView(
                    icon: "thermometer",
                    label: "Temperature",
                    value: "\(Int(viewModel.temperature ?? 0))°F",
                    color: weatherColor
                )
                MetricView(
                    icon: "wind",
                    label: "Wind Speed",
                    value: "\(Int(viewModel.windSpeed ?? 0)) mph",
                    color: windColor
                )
                if let wind = viewModel.locationData?.conditions.wind {
                    MetricView(
                        icon: "location.north.fill",
                        label: "Direction",
                        value: wind.direction,
                        color: .gray
                    )
                }
            }

            if let description = viewModel.weatherDescription {
                HStack {
                    Image(systemName: weatherIconFor(description))
                        .foregroundColor(weatherColor)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var liftsExpandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lift & Run Status")
                .font(.headline)
                .foregroundColor(.primary)

            if let liftStatus = viewModel.locationData?.conditions.liftStatus {
                HStack(spacing: 16) {
                    MetricView(
                        icon: "cablecar.fill",
                        label: "Lifts Open",
                        value: "\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)",
                        color: liftColor
                    )
                    MetricView(
                        icon: "figure.skiing.downhill",
                        label: "Runs Open",
                        value: "\(liftStatus.runsOpen)/\(liftStatus.runsTotal)",
                        color: liftColor
                    )
                    MetricView(
                        icon: "percent",
                        label: "Percent",
                        value: "\(liftStatus.percentOpen)%",
                        color: liftColor
                    )
                }

                if let message = liftStatus.message {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(liftColor)
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Navigate to Lifts Tab Button
            if onNavigateToLifts != nil {
                Button {
                    onNavigateToLifts?()
                } label: {
                    HStack {
                        Text("View Lift Map & Details")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(.opacityLight))
                    .cornerRadius(.cornerRadiusButton)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Computed Properties

    private var snowMetrics: [String] {
        let snow24h = Int(viewModel.snowDepth24h ?? 0)
        let baseDepth = Int(viewModel.currentSnowDepth ?? 0)
        return [
            "\(snow24h)\" 24h",
            "\(baseDepth)\" base"
        ]
    }

    private var snowStatus: String {
        let snow24h = viewModel.snowDepth24h ?? 0
        if snow24h >= 12 { return "Epic" }
        if snow24h >= 6 { return "Fresh" }
        if snow24h >= 2 { return "Light" }
        return "None"
    }

    private var weatherMetrics: [String] {
        let temp = Int(viewModel.temperature ?? 0)
        let windSpeed = Int(viewModel.windSpeed ?? 0)
        return [
            "\(temp)°F",
            "\(windSpeed) mph"
        ]
    }

    private var weatherStatus: String {
        let wind = viewModel.windSpeed ?? 0
        if wind >= 30 { return "Windy" }
        if wind >= 20 { return "Breezy" }
        return "Calm"
    }

    private var weatherColor: Color {
        let temp = viewModel.temperature ?? 32
        if temp < 20 { return .blue }
        if temp < 32 { return .cyan }
        if temp < 40 { return .green }
        return .orange
    }

    private var windColor: Color {
        let wind = viewModel.windSpeed ?? 0
        if wind < 10 { return .green }
        if wind < 20 { return .yellow }
        if wind < 30 { return .orange }
        return .red
    }

    private var liftMetrics: [String] {
        guard let liftStatus = viewModel.locationData?.conditions.liftStatus else {
            return ["N/A", "N/A"]
        }
        let percent = liftStatus.percentOpen
        let liftsInfo = "\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)"
        return [
            "\(percent)%",
            liftsInfo
        ]
    }

    private var liftStatus: String {
        guard let status = viewModel.locationData?.conditions.liftStatus else {
            return "Unknown"
        }
        return status.isOpen ? "Open" : "Closed"
    }

    private var liftColor: Color {
        guard let status = viewModel.locationData?.conditions.liftStatus else {
            return .gray
        }
        let percent = status.percentOpen
        if percent >= 80 { return .green }
        if percent >= 50 { return .yellow }
        if percent >= 20 { return .orange }
        return .red
    }

    private var powderScoreColor: Color {
        let score = viewModel.powderScore ?? 0.0
        if score >= 8.0 { return .green }
        if score >= 6.0 { return .yellow }
        if score >= 4.0 { return .orange }
        return .red
    }

    private var powderScoreLabel: String {
        let score = viewModel.powderScore ?? 0.0
        if score >= 8.0 { return "Epic Day" }
        if score >= 6.0 { return "Great Conditions" }
        if score >= 4.0 { return "Good Day" }
        return "Fair Conditions"
    }

    private func weatherIconFor(_ description: String) -> String {
        let lower = description.lowercased()
        if lower.contains("clear") || lower.contains("sunny") {
            return "sun.max.fill"
        } else if lower.contains("cloud") {
            return "cloud.fill"
        } else if lower.contains("snow") {
            return "cloud.snow.fill"
        } else if lower.contains("rain") {
            return "cloud.rain.fill"
        }
        return "cloud.sun.fill"
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        AtAGlanceCard(viewModel: {
            let vm = LocationViewModel(mountain: .mock)
            vm.locationData = MountainBatchedResponse(
                mountain: MountainDetail(
                    id: "baker",
                    name: "Mt. Baker",
                    shortName: "Baker",
                    location: MountainLocation(lat: 48.8587, lng: -121.6714),
                    elevation: MountainElevation(base: 3500, summit: 5089),
                    region: "WA",
                    snotel: MountainDetail.SnotelInfo(stationId: "909", stationName: "Wells Creek"),
                    noaa: MountainDetail.NOAAInfo(gridOffice: "SEW", gridX: 120, gridY: 110),
                    webcams: [],
                    webcamPageUrl: nil,
                    roadWebcams: nil,
                    color: "#4A90E2",
                    website: "https://www.mtbaker.us",
                    logo: "/logos/baker.svg",
                    status: nil,
                    passType: .independent
                ),
                conditions: MountainConditions.mock,
                powderScore: MountainPowderScore.mock,
                forecast: [],
                sunData: nil,
                roads: nil,
                tripAdvice: nil,
                powderDay: nil,
                alerts: [],
                weatherGovLinks: nil,
                status: nil,
                cachedAt: ISO8601DateFormatter().string(from: Date())
            )
            return vm
        }())
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
