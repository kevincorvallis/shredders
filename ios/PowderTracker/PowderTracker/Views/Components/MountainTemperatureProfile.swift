import SwiftUI

/// Creative mountain profile showing temperature by elevation
struct MountainTemperatureProfile: View {
    let baseTemp: Int
    let midTemp: Int
    let summitTemp: Int
    let baseElevation: Int?
    let summitElevation: Int?

    private var midElevation: Int? {
        guard let base = baseElevation, let summit = summitElevation else { return nil }
        return (base + summit) / 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mountain.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Temperature by Elevation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Mountain profile illustration
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Background gradient (sky)
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.1),
                            Color.blue.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(.cornerRadiusCard)

                    // Mountain silhouette with temperature gradient
                    MountainProfileShape()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: tempColor(summitTemp), location: 0.0),
                                    .init(color: tempColor(midTemp), location: 0.5),
                                    .init(color: tempColor(baseTemp), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            MountainProfileShape()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                        )

                    // Temperature markers
                    ZStack {
                        // Summit marker
                        TemperatureMarker(
                            temp: summitTemp,
                            elevation: summitElevation,
                            label: "Summit",
                            icon: "arrow.up.to.line"
                        )
                        .position(
                            x: geometry.size.width * 0.5,
                            y: geometry.size.height * 0.15
                        )

                        // Mid marker
                        TemperatureMarker(
                            temp: midTemp,
                            elevation: midElevation,
                            label: "Mid",
                            icon: "minus"
                        )
                        .position(
                            x: geometry.size.width * 0.35,
                            y: geometry.size.height * 0.5
                        )

                        // Base marker
                        TemperatureMarker(
                            temp: baseTemp,
                            elevation: baseElevation,
                            label: "Base",
                            icon: "arrow.down.to.line"
                        )
                        .position(
                            x: geometry.size.width * 0.25,
                            y: geometry.size.height * 0.85
                        )
                    }
                }
            }
            .frame(height: 200)
            .cornerRadius(.cornerRadiusCard)

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: tempColor(summitTemp), label: "Coldest")
                LegendItem(color: tempColor(midTemp), label: "Mid-Mountain")
                LegendItem(color: tempColor(baseTemp), label: "Warmest")
            }
            .font(.caption2)
        }
        .padding(.vertical, 8)
    }

    private func tempColor(_ temp: Int) -> Color {
        if temp <= 15 { return Color(red: 0.2, green: 0.4, blue: 0.9) } // Deep blue
        if temp <= 25 { return Color(red: 0.4, green: 0.6, blue: 0.95) } // Blue
        if temp <= 32 { return Color(red: 0.6, green: 0.8, blue: 1.0) } // Light blue
        if temp <= 40 { return Color(red: 0.7, green: 0.9, blue: 0.7) } // Green
        return Color(red: 1.0, green: 0.7, blue: 0.4) // Orange
    }
}

// MARK: - Mountain Profile Shape

struct MountainProfileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Create a realistic mountain profile
        path.move(to: CGPoint(x: 0, y: height))

        // Left slope (gradual)
        path.addQuadCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.4),
            control: CGPoint(x: width * 0.2, y: height * 0.6)
        )

        // Summit peak
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.1),
            control: CGPoint(x: width * 0.45, y: height * 0.2)
        )

        // Right slope (steeper)
        path.addQuadCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.6),
            control: CGPoint(x: width * 0.6, y: height * 0.25)
        )

        // Base right
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Temperature Marker

struct TemperatureMarker: View {
    let temp: Int
    let elevation: Int?
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            // Temperature in a badge
            HStack(spacing: 4) {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 10))
                Text("\(temp)°F")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.75))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            )

            // Connector line
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 2, height: 12)

            // Elevation label
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                if let elev = elevation {
                    Text("\(elev.formatted(.number.grouping(.never))) ft")
                        .font(.system(size: 8))
                        .opacity(0.9)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.6))
            )
        }
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MountainTemperatureProfile(
            baseTemp: 34,
            midTemp: 28,
            summitTemp: 22,
            baseElevation: 4400,
            summitElevation: 7012
        )
        .padding()
        .background(Color(.systemBackground))

        MountainTemperatureProfile(
            baseTemp: 42,
            midTemp: 35,
            summitTemp: 28,
            baseElevation: 3500,
            summitElevation: 5089
        )
        .padding()
        .background(Color(.systemBackground))
    }
    .background(Color(.systemGroupedBackground))
}
