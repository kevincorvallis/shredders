import SwiftUI

/// Compact hero card showing the most important information at a glance
struct AtAGlanceCard: View {
    @ObservedObject var viewModel: LocationViewModel
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
            .frame(height: 120)

            // Expanded details
            if let section = expandedSection {
                Divider()
                expandedDetailsView(for: section)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }

    // MARK: - Powder Score Header
    private var powderScoreHeader: some View {
        HStack(spacing: 12) {
            // Score badge
            ZStack {
                Circle()
                    .fill(powderScoreColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text("\(viewModel.powderScore ?? 0)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(powderScoreColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(powderScoreLabel)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(powderScoreColor)

                Text("Powder Conditions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Timestamp
            if let lastUpdated = viewModel.lastUpdated {
                VStack(alignment: .trailing, spacing: 2) {
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
        .padding()
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

                ForEach(metrics, id: \.self) { metric in
                    Text(metric)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
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
                .background(color.opacity(0.15))
                .cornerRadius(8)
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
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    private var snowExpandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snow Details")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                DetailMetric(
                    label: "Base Depth",
                    value: "\(Int(viewModel.currentSnowDepth ?? 0))\"",
                    icon: "mountain.2.fill",
                    color: .blue
                )
                DetailMetric(
                    label: "24h Snow",
                    value: "\(Int(viewModel.snowDepth24h ?? 0))\"",
                    icon: "snowflake",
                    color: .blue
                )
                DetailMetric(
                    label: "48h Snow",
                    value: "\(Int(viewModel.snowDepth48h ?? 0))\"",
                    icon: "snowflake",
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
                DetailMetric(
                    label: "Temperature",
                    value: "\(Int(viewModel.temperature ?? 0))°F",
                    icon: "thermometer",
                    color: weatherColor
                )
                DetailMetric(
                    label: "Wind Speed",
                    value: "\(Int(viewModel.windSpeed ?? 0)) mph",
                    icon: "wind",
                    color: windColor
                )
                if let wind = viewModel.locationData?.conditions.wind {
                    DetailMetric(
                        label: "Direction",
                        value: wind.direction,
                        icon: "location.north.fill",
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
                    DetailMetric(
                        label: "Lifts Open",
                        value: "\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)",
                        icon: "cablecar.fill",
                        color: liftColor
                    )
                    DetailMetric(
                        label: "Runs Open",
                        value: "\(liftStatus.runsOpen)/\(liftStatus.runsTotal)",
                        icon: "figure.skiing.downhill",
                        color: liftColor
                    )
                    DetailMetric(
                        label: "Percent",
                        value: "\(liftStatus.percentOpen)%",
                        icon: "percent",
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
        }
    }

    // MARK: - Computed Properties

    private var snowMetrics: [String] {
        [
            "\(Int(viewModel.snowDepth24h ?? 0))\" 24h",
            "\(Int(viewModel.currentSnowDepth ?? 0))\" base"
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
        [
            "\(Int(viewModel.temperature ?? 0))°F",
            "\(Int(viewModel.windSpeed ?? 0)) mph"
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
        return [
            "\(liftStatus.percentOpen)% open",
            "\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)"
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
        let score = viewModel.powderScore ?? 0
        if score >= 8 { return .green }
        if score >= 6 { return .yellow }
        if score >= 4 { return .orange }
        return .red
    }

    private var powderScoreLabel: String {
        let score = viewModel.powderScore ?? 0
        if score >= 8 { return "Epic Day" }
        if score >= 6 { return "Great Conditions" }
        if score >= 4 { return "Good Day" }
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

// MARK: - Detail Metric Component
struct DetailMetric: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
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
                    roadWebcams: nil,
                    color: "#4A90E2",
                    website: "https://www.mtbaker.us",
                    logo: "/logos/baker.svg",
                    status: nil
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
