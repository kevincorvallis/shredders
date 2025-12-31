import SwiftUI

/// Dynamic, creative mountain card with gradient backgrounds and animations
struct MountainTimelineCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?
    let forecast: [ForecastDay]
    let filterMode: SnowFilter

    @State private var isAnimating = false

    // Dynamic gradient based on powder conditions
    private var dynamicGradient: LinearGradient {
        let snowfall24h = conditions?.snowfall24h ?? 0

        if snowfall24h >= 10 {
            // Epic powder - vibrant blue to purple
            return LinearGradient(
                colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if snowfall24h >= 6 {
            // Great snow - blue to cyan
            return LinearGradient(
                colors: [Color(hex: "#4facfe") ?? .blue, Color(hex: "#00f2fe") ?? .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if snowfall24h >= 3 {
            // Good snow - teal gradient
            return LinearGradient(
                colors: [Color(hex: "#43e97b") ?? .green, Color(hex: "#38f9d7") ?? .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Light/no snow - subtle gray
            return LinearGradient(
                colors: [Color(.systemGray5), Color(.systemGray6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var hasFreshPowder: Bool {
        (conditions?.snowfall24h ?? 0) >= 6
    }

    var body: some View {
        ZStack {
            // Dynamic gradient background
            RoundedRectangle(cornerRadius: 16)
                .fill(dynamicGradient)
                .opacity(0.15)

            // Glassmorphic overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)

            // Snow particles for fresh powder
            if hasFreshPowder {
                SnowParticlesView()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                glassmorphicHeader

                // Content based on filter mode with smooth transitions
                Group {
                    switch filterMode {
                    case .weather:
                        weatherContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case .snowSummary:
                        snowTimeline
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case .snowForecast:
                        forecastList
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: filterMode)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: hasFreshPowder ? .blue.opacity(0.3) : .black.opacity(0.08),
                radius: hasFreshPowder ? 12 : 8,
                x: 0,
                y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(hasFreshPowder ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .opacity(isAnimating ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }

    private var glassmorphicHeader: some View {
        HStack(spacing: 10) {
            // Animated logo with depth
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 44
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: isAnimating)

            VStack(alignment: .leading, spacing: 2) {
                Text(mountain.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("\(mountain.elevation.base) ft · \(mountain.region.capitalized)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Dynamic status badge
            if let liftStatus = conditions?.liftStatus {
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(liftStatus.isOpen ? "Open" : "Closed")
                            .font(.caption)
                            .fontWeight(.bold)

                        Circle()
                            .fill(liftStatus.isOpen ? Color.green : Color.red)
                            .frame(width: 7, height: 7)
                            .shadow(color: liftStatus.isOpen ? .green.opacity(0.6) : .red.opacity(0.6),
                                    radius: 4, x: 0, y: 0)
                    }
                    .foregroundColor(liftStatus.isOpen ? .green : .red)

                    if liftStatus.percentOpen > 0 {
                        Text("\(liftStatus.percentOpen)%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Weather Content

    private var weatherContent: some View {
        VStack(spacing: 12) {
            if let conditions = conditions {
                // Main conditions
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base Temp")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(conditions.temperature ?? 0)°F")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .primary.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    if let wind = conditions.wind {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wind")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "wind")
                                    .font(.caption)
                                Text("\(wind.speed) mph \(wind.direction)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                // Elevation temperatures
                if let tempByElevation = conditions.temperatureByElevation {
                    Divider()
                        .padding(.horizontal, 14)

                    VStack(spacing: 8) {
                        Text("Temperatures by Elevation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)

                        HStack(spacing: 12) {
                            elevationTempCard(
                                label: "Base",
                                temp: tempByElevation.base,
                                elevation: mountain.elevation.base,
                                icon: "arrow.down.to.line"
                            )

                            elevationTempCard(
                                label: "Mid",
                                temp: tempByElevation.mid,
                                elevation: (mountain.elevation.base + mountain.elevation.summit) / 2,
                                icon: "minus"
                            )

                            elevationTempCard(
                                label: "Summit",
                                temp: tempByElevation.summit,
                                elevation: mountain.elevation.summit,
                                icon: "arrow.up.to.line"
                            )
                        }
                        .padding(.horizontal, 14)
                    }
                }

                // Conditions
                if !conditions.conditions.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(conditions.conditions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    private func elevationTempCard(label: String, temp: Int, elevation: Int, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("\(temp)°")
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            Text("\(elevation) ft")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }

    // MARK: - Snow Timeline (OpenSnow-style with centered "Last 24 Hours")

    private var snowTimeline: some View {
        VStack(spacing: 0) {
            // Three-column header: Prev 1-5 Days | Last 24 Hours | Next 1-5 Days
            HStack(spacing: 0) {
                // Past summary
                VStack(spacing: 4) {
                    Text("Prev 1-5 Days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(pastFiveDaysTotal)\"")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)

                // TODAY - BIG NUMBER (focal point)
                VStack(spacing: 4) {
                    Text("Last 24 Hours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(conditions?.snowfall24h ?? 0)\"")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)

                // Future summary
                VStack(spacing: 4) {
                    Text("Next 1-5 Days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if nextFiveDaysTotal > 0 {
                        Text("\(nextFiveDaysTotal)\"")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    } else {
                        Text("-")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)

            Divider()

            // Horizontally scrollable daily timeline - starts centered on TODAY
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(-7...7, id: \.self) { dayOffset in
                            dayBarColumn(for: dayOffset)
                                .id(dayOffset)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onAppear {
                    // Auto-scroll to TODAY (offset 0) on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(0, anchor: .center)
                        }
                    }
                }
            }

            // Reported time
            if let lastUpdated = conditions?.lastUpdated {
                let date = ISO8601DateFormatter().date(from: lastUpdated) ?? Date()
                HStack(spacing: 4) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).day().hour().minute()))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text("Reported")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 6)
            }
        }
    }

    private func dayBarColumn(for offset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let snowfall = snowfallForDay(offset: offset)
        let isToday = offset == 0
        let isPast = offset < 0
        let barHeight = min(CGFloat(snowfall) * 2.5, 50)

        // Pre-compute gradient colors
        let barGradient: LinearGradient = {
            if isPast {
                return LinearGradient(
                    colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if isToday {
                return LinearGradient(
                    colors: [Color.green.opacity(0.9), Color.green.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                return LinearGradient(
                    colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }()

        let shadowColor: Color = isPast ? .orange : isToday ? .green : .blue

        return VStack(spacing: 3) {
            // Day letter
            Text(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1))
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .primary : .secondary)

            // Date number
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .primary : .secondary)

            // Animated bar chart with gradient
            VStack {
                Spacer()
                if snowfall > 0 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barGradient)
                        .frame(width: 14, height: isAnimating ? barHeight : 0)
                        .shadow(
                            color: shadowColor.opacity(0.4),
                            radius: snowfall > 6 ? 4 : 2,
                            x: 0,
                            y: 2
                        )
                        .overlay(
                            snowfall > 6
                                ? LinearGradient(
                                    colors: [.white.opacity(0), .white.opacity(0.3), .white.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : nil
                        )
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 14, height: 3)
                }
            }
            .frame(height: 50)

            // Snowfall amount with dynamic styling
            if snowfall > 0 {
                Text("\(snowfall)\"")
                    .font(.system(size: snowfall > 10 ? 11 : 9, weight: snowfall > 6 ? .bold : .semibold))
                    .foregroundColor(snowfall > 10 ? .primary : .primary.opacity(0.9))
                    .shadow(color: snowfall > 10 ? .black.opacity(0.2) : .clear, radius: 2, x: 0, y: 1)
            } else {
                Text(" ")
                    .font(.system(size: 9))
            }
        }
        .frame(width: 36)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            Group {
                if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.05))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Color.clear
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isToday
                        ? LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: 2
                )
        )
        .scaleEffect(isToday ? 1.05 : 1.0)
    }

    // MARK: - Forecast List

    private var forecastList: some View {
        VStack(spacing: 0) {
            ForEach(Array(forecast.prefix(5))) { day in
                HStack(spacing: 12) {
                    Text(String(day.date.prefix(5)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text("\(day.snowfall)\"")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 30, alignment: .trailing)

                    Text(day.conditions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(day.high)°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                if day.id != forecast.prefix(5).last?.id {
                    Divider()
                        .padding(.leading, 12)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private func snowfallForDay(offset: Int) -> Int {
        if offset == 0 {
            return conditions?.snowfall24h ?? 0
        } else if offset < 0 {
            // Past days - estimate from 48h/7d
            if offset == -1, let snow48h = conditions?.snowfall48h {
                return snow48h - (conditions?.snowfall24h ?? 0)
            }
            // Rough estimate for older days
            guard let snow7d = conditions?.snowfall7d else { return 0 }
            return max(0, (snow7d - (conditions?.snowfall48h ?? 0)) / 5)
        } else {
            // Future days from forecast
            let index = offset - 1
            guard index < forecast.count else { return 0 }
            return Int(forecast[index].snowfall)
        }
    }

    private var pastFiveDaysTotal: Int {
        conditions?.snowfall7d ?? 0
    }

    private var nextFiveDaysTotal: Int {
        Int(forecast.prefix(5).reduce(0) { $0 + $1.snowfall })
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            MountainTimelineCard(
                mountain: Mountain(
                    id: "baker",
                    name: "Mt. Baker",
                    shortName: "Baker",
                    location: MountainLocation(lat: 48.8, lng: -121.6),
                    elevation: MountainElevation(base: 3500, summit: 5089),
                    region: "washington",
                    color: "#1E40AF",
                    website: "https://www.mtbaker.us",
                    hasSnotel: true,
                    webcamCount: 3,
                    logo: "/logos/baker.svg",
                    status: nil,
                    distance: nil
                ),
                conditions: MountainConditions(
                    mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                    snowDepth: 142,
                    snowWaterEquivalent: 58.4,
                    snowfall24h: 8,
                    snowfall48h: 14,
                    snowfall7d: 32,
                    temperature: 28,
                    temperatureByElevation: nil,
                    conditions: "Snow",
                    wind: MountainConditions.WindInfo(speed: 15, direction: "NW"),
                    lastUpdated: Date().ISO8601Format(),
                    liftStatus: LiftStatus(
                        isOpen: true,
                        liftsOpen: 9,
                        liftsTotal: 10,
                        runsOpen: 45,
                        runsTotal: 52,
                        message: nil,
                        lastUpdated: Date().ISO8601Format()
                    ),
                    dataSources: MountainConditions.DataSources(
                        snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
                        noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
                        liftStatus: MountainConditions.DataSources.LiftStatusSource(available: true)
                    )
                ),
                powderScore: nil,
                forecast: [
                    ForecastDay(date: "2024-12-14", dayOfWeek: "Mon", high: 35, low: 28, snowfall: 6, precipProbability: 90, precipType: "snow", wind: .init(speed: 10, gust: 18), conditions: "Snow", icon: "snow"),
                    ForecastDay(date: "2024-12-15", dayOfWeek: "Tue", high: 33, low: 26, snowfall: 3, precipProbability: 70, precipType: "snow", wind: .init(speed: 12, gust: 20), conditions: "Light Snow", icon: "snow"),
                ],
                filterMode: .snowSummary
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Snow Particles Animation

struct SnowParticlesView: View {
    @State private var particles: [SnowParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: 1)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles()
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            SnowParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: -50...size.height)
                ),
                size: CGFloat.random(in: 2...4)
            )
        }
    }

    private func animateParticles() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            particles = particles.map { particle in
                var newParticle = particle
                newParticle.position.y += 200
                return newParticle
            }
        }
    }
}

struct SnowParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
}
