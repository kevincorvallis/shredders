//
//  TemperatureElevationMapView.swift
//  PowderTracker
//
//  Interactive temperature map showing temperature variation by elevation.
//  Color-coded visualization of mountain temperature zones.
//

import SwiftUI

struct TemperatureElevationMapView: View {
    let mountain: MountainDetail
    let temperatureData: MountainConditions.TemperatureByElevation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header info
                VStack(spacing: 8) {
                    Text("Temperature by Elevation")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(mountain.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Visual mountain temperature map
                TemperatureMountainVisualization(
                    baseTemp: temperatureData.base,
                    midTemp: temperatureData.mid,
                    summitTemp: temperatureData.summit,
                    baseElevation: mountain.elevation.base,
                    midElevation: (mountain.elevation.base + mountain.elevation.summit) / 2,
                    summitElevation: mountain.elevation.summit
                )
                .frame(height: 400)
                .padding(.horizontal)

                // Temperature gradient legend
                TemperatureGradientLegend()
                    .padding(.horizontal)

                // Detailed temperature table
                TemperatureDataTable(
                    baseTemp: temperatureData.base,
                    midTemp: temperatureData.mid,
                    summitTemp: temperatureData.summit,
                    baseElevation: mountain.elevation.base,
                    midElevation: (mountain.elevation.base + mountain.elevation.summit) / 2,
                    summitElevation: mountain.elevation.summit,
                    referenceTemp: temperatureData.referenceTemp,
                    referenceElevation: temperatureData.referenceElevation,
                    lapseRate: temperatureData.lapseRate
                )
                .padding(.horizontal)

                // Explanation
                VStack(alignment: .leading, spacing: 12) {
                    Text("About Temperature Lapse Rate")
                        .font(.headline)

                    Text("Temperature typically decreases by \(String(format: "%.1f", abs(temperatureData.lapseRate)))°F per 1,000 ft of elevation gain. This visualization shows estimated temperatures at different elevations based on current conditions.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Temperature Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Mountain Visualization with Temperature Colors

struct TemperatureMountainVisualization: View {
    let baseTemp: Int
    let midTemp: Int
    let summitTemp: Int
    let baseElevation: Int
    let midElevation: Int
    let summitElevation: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Mountain shape with gradient
                TemperatureMountainShape()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: tempColor(baseTemp), location: 0.0),
                                .init(color: tempColor(midTemp), location: 0.5),
                                .init(color: tempColor(summitTemp), location: 1.0)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                // Temperature labels at each zone
                VStack(spacing: 0) {
                    // Summit label
                    HStack {
                        Spacer()
                        TemperatureLabel(
                            temp: summitTemp,
                            elevation: summitElevation,
                            label: "Summit"
                        )
                        .offset(x: -20)
                        Spacer()
                    }
                    .frame(height: geometry.size.height * 0.33)

                    // Mid label
                    HStack {
                        TemperatureLabel(
                            temp: midTemp,
                            elevation: midElevation,
                            label: "Mid"
                        )
                        .offset(x: 40)
                        Spacer()
                    }
                    .frame(height: geometry.size.height * 0.33)

                    // Base label
                    HStack {
                        Spacer()
                        TemperatureLabel(
                            temp: baseTemp,
                            elevation: baseElevation,
                            label: "Base"
                        )
                        .offset(x: -40)
                        Spacer()
                    }
                    .frame(height: geometry.size.height * 0.34)
                }
            }
        }
    }

    private func tempColor(_ temp: Int) -> Color {
        switch temp {
        case ...10:
            return Color(red: 0.2, green: 0.4, blue: 0.9) // Deep blue - very cold
        case 11...20:
            return Color(red: 0.3, green: 0.6, blue: 1.0) // Light blue - cold
        case 21...28:
            return Color(red: 0.4, green: 0.8, blue: 0.9) // Cyan - optimal snow
        case 29...32:
            return Color(red: 0.9, green: 0.9, blue: 0.5) // Yellow - freezing
        case 33...40:
            return Color(red: 1.0, green: 0.7, blue: 0.3) // Orange - warm
        default:
            return Color(red: 1.0, green: 0.4, blue: 0.3) // Red - too warm
        }
    }
}

// MARK: - Mountain Shape

struct TemperatureMountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Start at bottom left
        path.move(to: CGPoint(x: 0, y: height))

        // Left slope
        path.addQuadCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.2),
            control: CGPoint(x: width * 0.2, y: height * 0.4)
        )

        // Peak
        path.addLine(to: CGPoint(x: width * 0.5, y: 0))

        // Right slope
        path.addQuadCurve(
            to: CGPoint(x: width, y: height),
            control: CGPoint(x: width * 0.7, y: height * 0.3)
        )

        // Close path
        path.closeSubpath()

        return path
    }
}

// MARK: - Temperature Label

struct TemperatureLabel: View {
    let temp: Int
    let elevation: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(temp)°F")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

            Text("\(elevation) ft")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Temperature Gradient Legend

struct TemperatureGradientLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Temperature Scale")
                .font(.headline)

            VStack(spacing: 8) {
                LegendRow(color: Color(red: 0.2, green: 0.4, blue: 0.9), label: "≤ 10°F", description: "Very Cold")
                LegendRow(color: Color(red: 0.3, green: 0.6, blue: 1.0), label: "11-20°F", description: "Cold")
                LegendRow(color: Color(red: 0.4, green: 0.8, blue: 0.9), label: "21-28°F", description: "Optimal Snow")
                LegendRow(color: Color(red: 0.9, green: 0.9, blue: 0.5), label: "29-32°F", description: "Freezing")
                LegendRow(color: Color(red: 1.0, green: 0.7, blue: 0.3), label: "33-40°F", description: "Warm")
                LegendRow(color: Color(red: 1.0, green: 0.4, blue: 0.3), label: "> 40°F", description: "Too Warm")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct LegendRow: View {
    let color: Color
    let label: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 40, height: 24)

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Temperature Data Table

struct TemperatureDataTable: View {
    let baseTemp: Int
    let midTemp: Int
    let summitTemp: Int
    let baseElevation: Int
    let midElevation: Int
    let summitElevation: Int
    let referenceTemp: Int
    let referenceElevation: Int
    let lapseRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Elevation Data")
                .font(.headline)

            VStack(spacing: 12) {
                TemperatureRow(
                    zone: "Summit",
                    elevation: summitElevation,
                    temp: summitTemp,
                    icon: "arrow.up.to.line"
                )

                Divider()

                TemperatureRow(
                    zone: "Mid Mountain",
                    elevation: midElevation,
                    temp: midTemp,
                    icon: "minus"
                )

                Divider()

                TemperatureRow(
                    zone: "Base",
                    elevation: baseElevation,
                    temp: baseTemp,
                    icon: "arrow.down.to.line"
                )
            }

            Divider()
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Temperature Drop:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(baseTemp - summitTemp)°F")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Vertical Drop:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(summitElevation - baseElevation) ft")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Lapse Rate:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.1f", abs(lapseRate)))°F per 1,000 ft")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct TemperatureRow: View {
    let zone: String
    let elevation: Int
    let temp: Int
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(zone)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(elevation) ft")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(temp)°F")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(tempColor(temp))
        }
    }

    private func tempColor(_ temp: Int) -> Color {
        switch temp {
        case ...20: return .blue
        case 21...28: return .cyan
        case 29...32: return .yellow
        case 33...40: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

struct TemperatureElevationMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TemperatureElevationMapView(
                mountain: MountainDetail(
                    id: "crystal",
                    name: "Crystal Mountain",
                    shortName: "Crystal",
                    location: MountainLocation(lat: 46.935, lng: -121.474),
                    elevation: MountainElevation(base: 4400, summit: 7012),
                    region: "washington",
                    snotel: nil,
                    noaa: nil,
                    webcams: [],
                    roadWebcams: nil,
                    color: "#8b5cf6",
                    website: "https://www.crystalmountainresort.com",
                    logo: "/logos/crystal.png",
                    status: nil,
                    passType: .ikon
                ),
                temperatureData: MountainConditions.TemperatureByElevation(
                    base: 32,
                    mid: 26,
                    summit: 20,
                    referenceElevation: 5000,
                    referenceTemp: 28,
                    lapseRate: -3.5
                )
            )
        }
    }
}
