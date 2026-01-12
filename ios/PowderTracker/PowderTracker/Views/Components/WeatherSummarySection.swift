import SwiftUI

/// Weather summary section showing current conditions and temperature gradient
struct WeatherSummarySection: View {
    let conditions: MountainConditions?
    var baseElevation: Int?
    var summitElevation: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weather")
                .font(.title3)
                .fontWeight(.bold)

            if let conditions = conditions {
                VStack(spacing: 16) {
                    // Current conditions row
                    HStack(spacing: 20) {
                        // Icon and description
                        VStack(alignment: .leading, spacing: 4) {
                            Image(systemName: weatherIcon)
                                .font(.system(size: 40))
                                .foregroundColor(.blue)

                            Text(conditions.conditions)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Temperature
                        if let temp = conditions.temperature {
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("\(temp)°")
                                    .font(.system(size: 48, weight: .thin))

                                Text("Feels like \(temp)°")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Temperature by elevation (UNIQUE FEATURE!)
                    if let tempByElev = conditions.temperatureByElevation {
                        MountainTemperatureProfile(
                            baseTemp: tempByElev.base,
                            midTemp: tempByElev.mid,
                            summitTemp: tempByElev.summit,
                            baseElevation: baseElevation,
                            summitElevation: summitElevation
                        )
                        .padding(.vertical, 8)
                    }

                    // Wind and snow
                    HStack(spacing: 20) {
                        if let wind = conditions.wind {
                            WeatherMetric(
                                icon: "wind",
                                label: "Wind",
                                value: "\(wind.speed) mph \(wind.direction)"
                            )
                        }

                        Spacer()

                        WeatherMetric(
                            icon: "snowflake",
                            label: "24hr Snow",
                            value: "\(conditions.snowfall24h)\""
                        )
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var weatherIcon: String {
        guard let conditions = conditions else { return "cloud" }
        let cond = conditions.conditions.lowercased()
        if cond.contains("snow") { return "cloud.snow.fill" }
        if cond.contains("rain") { return "cloud.rain.fill" }
        if cond.contains("cloud") { return "cloud.fill" }
        if cond.contains("sun") || cond.contains("clear") { return "sun.max.fill" }
        return "cloud.fill"
    }
}

// MARK: - Temperature Gradient Bar (UNIQUE!)

struct TempGradientBar: View {
    let base: Int
    let mid: Int
    let summit: Int
    var baseElevation: Int?
    var summitElevation: Int?

    private var midElevation: Int? {
        guard let base = baseElevation, let summit = summitElevation else { return nil }
        return (base + summit) / 2
    }

    var body: some View {
        HStack(spacing: 0) {
            // Base
            VStack(spacing: 4) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [tempColor(base), tempColor(mid)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 60)
                    .overlay(
                        VStack {
                            Spacer()
                            Text("\(base)°")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(.bottom, 4)
                        }
                    )

                if let elevation = baseElevation {
                    Text("Base")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("(\(elevation.formatted(.number.grouping(.never))) ft)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Base")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            // Mid
            VStack(spacing: 4) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [tempColor(mid), tempColor(summit)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            Spacer()
                            Text("\(mid)°")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(.bottom, 4)
                        }
                    )

                if let elevation = midElevation {
                    Text("Mid")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("(\(elevation.formatted(.number.grouping(.never))) ft)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Mid")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            // Summit
            VStack(spacing: 4) {
                Rectangle()
                    .fill(tempColor(summit))
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            Text("\(summit)°")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(.top, 4)
                            Spacer()
                        }
                    )

                if let elevation = summitElevation {
                    Text("Summit")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("(\(elevation.formatted(.number.grouping(.never))) ft)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Summit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .cornerRadius(8)
    }

    private func tempColor(_ temp: Int) -> Color {
        if temp <= 15 { return Color(red: 0.2, green: 0.4, blue: 0.8) } // Dark blue
        if temp <= 25 { return Color(red: 0.3, green: 0.6, blue: 0.9) } // Blue
        if temp <= 32 { return Color(red: 0.4, green: 0.8, blue: 1.0) } // Light blue
        if temp <= 40 { return Color(red: 0.5, green: 0.9, blue: 0.6) } // Green
        return Color(red: 1.0, green: 0.6, blue: 0.3) // Orange
    }
}

// MARK: - Preview

#Preview {
    let mockConditions = MountainConditions(
        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
        snowDepth: 120,
        snowWaterEquivalent: 38.5,
        snowfall24h: 8,
        snowfall48h: 14,
        snowfall7d: 22,
        temperature: 28,
        temperatureByElevation: MountainConditions.TemperatureByElevation(
            base: 32,
            mid: 28,
            summit: 24,
            referenceElevation: 4500,
            referenceTemp: 28,
            lapseRate: 3.5
        ),
        conditions: "Light Snow",
        wind: MountainConditions.WindInfo(speed: 12, direction: "NW"),
        lastUpdated: Date().ISO8601Format(),
        liftStatus: nil,
        dataSources: MountainConditions.DataSources(
            snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
            noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
            liftStatus: nil
        )
    )

    return WeatherSummarySection(conditions: mockConditions)
        .padding()
        .background(Color(.systemGroupedBackground))
}
