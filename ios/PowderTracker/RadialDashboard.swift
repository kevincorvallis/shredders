import SwiftUI

/// Radial dashboard showing mountain conditions in Apple Watch activity rings style
struct RadialDashboard: View {
    @ObservedObject var viewModel: LocationViewModel
    @State private var animationProgress: Double = 0
    @State private var selectedRing: RingType? = nil

    enum RingType {
        case snow, weather, status
    }

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)

            VStack(spacing: 20) {
                Text("Conditions Overview")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Radial rings
                ZStack {
                    // Outer ring: Status indicators (lifts, roads)
                    StatusRing(viewModel: viewModel, progress: animationProgress)
                        .frame(width: 280, height: 280)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedRing = selectedRing == .status ? nil : .status
                            }
                        }

                    // Middle ring: Weather conditions
                    WeatherRing(viewModel: viewModel, progress: animationProgress)
                        .frame(width: 220, height: 220)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedRing = selectedRing == .weather ? nil : .weather
                            }
                        }

                    // Inner ring: Snow accumulation
                    SnowRing(viewModel: viewModel, progress: animationProgress)
                        .frame(width: 160, height: 160)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedRing = selectedRing == .snow ? nil : .snow
                            }
                        }

                    // Center: Powder score
                    PowderScoreCenter(score: viewModel.powderScore ?? 0)
                        .scaleEffect(animationProgress)
                }
                .frame(height: 300)

                // Selected ring details
                if let selected = selectedRing {
                    RingDetailsView(ringType: selected, viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Powder Score Center
struct PowderScoreCenter: View {
    let score: Int
    @State private var pulse = false

    var scoreColor: Color {
        if score >= 8 { return .green }
        if score >= 6 { return .yellow }
        if score >= 4 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            // Pulsing background
            Circle()
                .fill(scoreColor.opacity(0.2))
                .frame(width: 100, height: 100)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .opacity(pulse ? 0.3 : 0.6)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)

                Text("POWDER")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - Snow Ring (Inner)
struct SnowRing: View {
    @ObservedObject var viewModel: LocationViewModel
    let progress: Double

    private var snow24h: Double { viewModel.snowDepth24h ?? 0 }
    private var snow48h: Double { viewModel.snowDepth48h ?? 0 }
    private var snow72h: Double { viewModel.snowDepth72h ?? 0 }

    // Normalize to 0-1 scale (max expected: 24" in period)
    private var normalized24h: Double { min(snow24h / 24.0, 1.0) }
    private var normalized48h: Double { min(snow48h / 36.0, 1.0) }
    private var normalized72h: Double { min(snow72h / 48.0, 1.0) }

    var body: some View {
        ZStack {
            // 72h segment (bottom third)
            RingSegment(
                startAngle: .degrees(-90),
                endAngle: .degrees(30),
                progress: normalized72h * progress,
                color: .blue.opacity(0.4),
                lineWidth: 25
            )

            // 48h segment (right third)
            RingSegment(
                startAngle: .degrees(30),
                endAngle: .degrees(150),
                progress: normalized48h * progress,
                color: .blue.opacity(0.6),
                lineWidth: 25
            )

            // 24h segment (left third)
            RingSegment(
                startAngle: .degrees(150),
                endAngle: .degrees(270),
                progress: normalized24h * progress,
                color: .blue,
                lineWidth: 25
            )

            // Labels
            if progress > 0.8 {
                VStack {
                    Spacer()
                    Text("❄️ \(Int(snow24h))\" / \(Int(snow48h))\" / \(Int(snow72h))\"")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .offset(y: 95)
                }
            }
        }
    }
}

// MARK: - Weather Ring (Middle)
struct WeatherRing: View {
    @ObservedObject var viewModel: LocationViewModel
    let progress: Double

    private var temp: Double { viewModel.temperature ?? 32 }
    private var wind: Double { viewModel.windSpeed ?? 0 }

    // Normalize temp to 0-1 (0°F = 0, 40°F = 1)
    private var normalizedTemp: Double { min(max((temp - 0) / 40.0, 0), 1.0) }

    // Normalize wind to 0-1 (0mph = 1, 40mph+ = 0)
    private var normalizedWind: Double { max(1.0 - (wind / 40.0), 0) }

    private var tempColor: Color {
        if temp < 20 { return .blue }
        if temp < 32 { return .cyan }
        if temp < 40 { return .green }
        return .orange
    }

    private var windColor: Color {
        if wind < 10 { return .green }
        if wind < 20 { return .yellow }
        if wind < 30 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            // Temperature segment (left half)
            RingSegment(
                startAngle: .degrees(90),
                endAngle: .degrees(270),
                progress: normalizedTemp * progress,
                color: tempColor,
                lineWidth: 25
            )

            // Wind segment (right half)
            RingSegment(
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                progress: normalizedWind * progress,
                color: windColor,
                lineWidth: 25
            )

            // Labels
            if progress > 0.8 {
                HStack(spacing: 60) {
                    Text("💨\(Int(wind))")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(windColor)
                        .offset(x: 85)

                    Text("🌡️\(Int(temp))°")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(tempColor)
                        .offset(x: -85)
                }
            }
        }
    }
}

// MARK: - Status Ring (Outer)
struct StatusRing: View {
    @ObservedObject var viewModel: LocationViewModel
    let progress: Double

    private var liftPercent: Double {
        guard let liftStatus = viewModel.locationData?.conditions.liftStatus else { return 0 }
        return Double(liftStatus.percentOpen) / 100.0
    }

    private var hasRoadData: Bool { viewModel.hasRoadData }

    private var liftColor: Color {
        liftPercent >= 0.8 ? .green : liftPercent >= 0.5 ? .yellow : .orange
    }

    var body: some View {
        ZStack {
            // Lifts segment (top half)
            RingSegment(
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                progress: liftPercent * progress,
                color: liftColor,
                lineWidth: 25
            )

            // Road conditions segment (bottom half) - green if good, gray if unavailable
            RingSegment(
                startAngle: .degrees(90),
                endAngle: .degrees(270),
                progress: hasRoadData ? progress : 0.3,
                color: hasRoadData ? .green : .gray.opacity(0.3),
                lineWidth: 25
            )

            // Labels
            if progress > 0.8 {
                VStack {
                    Text("🎿 \(Int(liftPercent * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(liftColor)
                        .offset(y: -115)

                    Spacer()

                    Text(hasRoadData ? "🚗 Open" : "🚗 N/A")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(hasRoadData ? .green : .gray)
                        .offset(y: 115)
                }
            }
        }
    }
}

// MARK: - Ring Segment (Reusable component for arc drawing)
struct RingSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(startAngle)
    }
}

// MARK: - Ring Details View
struct RingDetailsView: View {
    let ringType: RadialDashboard.RingType
    @ObservedObject var viewModel: LocationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch ringType {
            case .snow:
                Label("Snow Accumulation", systemImage: "snowflake")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 16) {
                    MetricBadge(label: "24h", value: "\(Int(viewModel.snowDepth24h ?? 0))\"", color: .blue)
                    MetricBadge(label: "48h", value: "\(Int(viewModel.snowDepth48h ?? 0))\"", color: .blue.opacity(0.6))
                    MetricBadge(label: "72h", value: "\(Int(viewModel.snowDepth72h ?? 0))\"", color: .blue.opacity(0.4))
                }

            case .weather:
                Label("Weather Conditions", systemImage: "cloud.sun.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 16) {
                    MetricBadge(
                        label: "Temp",
                        value: "\(Int(viewModel.temperature ?? 0))°F",
                        color: viewModel.temperature ?? 0 < 32 ? .cyan : .orange
                    )
                    MetricBadge(
                        label: "Wind",
                        value: "\(Int(viewModel.windSpeed ?? 0)) mph",
                        color: (viewModel.windSpeed ?? 0) < 15 ? .green : .orange
                    )
                }

            case .status:
                Label("Mountain Status", systemImage: "mountain.2.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if let liftStatus = viewModel.locationData?.conditions.liftStatus {
                    HStack(spacing: 16) {
                        MetricBadge(
                            label: "Lifts",
                            value: "\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)",
                            color: .green
                        )
                        MetricBadge(
                            label: "Runs",
                            value: "\(liftStatus.runsOpen)/\(liftStatus.runsTotal)",
                            color: .green
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MetricBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        RadialDashboard(viewModel: {
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
