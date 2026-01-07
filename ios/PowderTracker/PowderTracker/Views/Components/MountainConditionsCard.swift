import SwiftUI

struct MountainConditionsCard: View {
    let conditions: MountainConditions
    var baseElevation: Int?
    var summitElevation: Int?
    var mountainDetail: MountainDetail? // Optional for temperature map navigation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Conditions")
                    .font(.headline)
                Spacer()
                Text(lastUpdatedString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let snowDepth = conditions.snowDepth {
                    ConditionMetric(icon: "ruler", title: "Snow Depth", value: "\(snowDepth)\"")
                }
                ConditionMetric(icon: "snowflake", title: "24hr Snow", value: "\(conditions.snowfall24h)\"")
                if let wind = conditions.wind {
                    ConditionMetric(icon: "wind", title: "Wind", value: "\(wind.speed) mph \(wind.direction)")
                }
                ConditionMetric(icon: "cloud.snow", title: "48hr Snow", value: "\(conditions.snowfall48h)\"")
                ConditionMetric(icon: "calendar", title: "7 Day Snow", value: "\(conditions.snowfall7d)\"")
            }

            // Temperature by elevation section (tappable when mountain detail available)
            if let tempByElevation = conditions.temperatureByElevation {
                Group {
                    if let mountain = mountainDetail {
                        NavigationLink(destination: TemperatureElevationMapView(
                            mountain: mountain,
                            temperatureData: tempByElevation
                        )) {
                            temperatureSection(tempByElevation)
                        }
                        .buttonStyle(.plain)
                    } else {
                        temperatureSection(tempByElevation)
                    }
                }
                .padding(.top, 8)
            } else if let temp = conditions.temperature {
                // Fallback to single temperature if elevation data not available
                ConditionMetric(icon: "thermometer.snowflake", title: "Temperature", value: "\(temp)°F")
            }

            HStack {
                Image(systemName: weatherIcon)
                    .foregroundColor(.blue)
                Text(conditions.conditions)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var lastUpdatedString: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: conditions.lastUpdated) else { return "Unknown" }
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private var weatherIcon: String {
        let cond = conditions.conditions.lowercased()
        if cond.contains("snow") { return "cloud.snow.fill" }
        if cond.contains("rain") { return "cloud.rain.fill" }
        if cond.contains("cloud") { return "cloud.fill" }
        if cond.contains("sun") || cond.contains("clear") { return "sun.max.fill" }
        return "cloud.fill"
    }

    private var midElevation: Int? {
        guard let base = baseElevation, let summit = summitElevation else { return nil }
        return (base + summit) / 2
    }

    @ViewBuilder
    private func temperatureSection(_ tempByElevation: MountainConditions.TemperatureByElevation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Temperature by Elevation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                if mountainDetail != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 16) {
                ElevationTempView(
                    label: "Base",
                    temp: tempByElevation.base,
                    icon: "arrow.down.to.line",
                    elevation: baseElevation
                )
                Spacer()
                ElevationTempView(
                    label: "Mid",
                    temp: tempByElevation.mid,
                    icon: "minus",
                    elevation: midElevation
                )
                Spacer()
                ElevationTempView(
                    label: "Summit",
                    temp: tempByElevation.summit,
                    icon: "arrow.up.to.line",
                    elevation: summitElevation
                )
            }

            if mountainDetail != nil {
                Text("Tap to see temperature map")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
    }
}

struct ConditionMetric: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
    }
}

struct ElevationTempView: View {
    let label: String
    let temp: Int
    let icon: String
    var elevation: Int?

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("\(temp)°F")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(tempColor)

            if let elevation = elevation {
                Text("\(label)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text("(\(elevation.formatted(.number.grouping(.never))) ft)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    private var tempColor: Color {
        if temp <= 20 { return .blue }
        if temp <= 32 { return .cyan }
        if temp <= 40 { return .green }
        return .orange
    }
}

#Preview {
    MountainConditionsCard(conditions: .mock)
        .padding()
        .background(Color(.systemGroupedBackground))
}
