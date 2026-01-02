import SwiftUI

/// Dynamic, creative mountain card with gradient backgrounds and animations
struct MountainTimelineCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?
    let forecast: [ForecastDay]
    let filterMode: SnowFilter
    @ObservedObject var scrollSync: TimelineScrollSync // Synchronized horizontal scrolling

    @State private var isAnimating = false
    @State private var scrollPosition: Int? = 0 // Track snapped day (which day is centered)

    // Dynamic gradient based on powder conditions
    private var dynamicGradient: LinearGradient {
        let snowfall24h = conditions?.snowfall24h ?? 0

        if snowfall24h >= 10 {
            // Epic powder - vibrant blue to purple
            let color1: Color = Color(hex: "#667eea") ?? .blue
            let color2: Color = Color(hex: "#764ba2") ?? .purple
            return LinearGradient(
                colors: [color1, color2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if snowfall24h >= 6 {
            // Great snow - blue to cyan
            let color1: Color = Color(hex: "#4facfe") ?? .blue
            let color2: Color = Color(hex: "#00f2fe") ?? .cyan
            return LinearGradient(
                colors: [color1, color2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if snowfall24h >= 3 {
            // Good snow - teal gradient
            let color1: Color = Color(hex: "#43e97b") ?? .green
            let color2: Color = Color(hex: "#38f9d7") ?? .cyan
            return LinearGradient(
                colors: [color1, color2],
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
        HStack(spacing: 8) {
            // Animated logo with depth
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 38
            )
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: isAnimating)

            VStack(alignment: .leading, spacing: 1) {
                Text(mountain.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("\(mountain.elevation.base) ft · \(mountain.region.capitalized)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Creative circular progress status indicator
            if let liftStatus = conditions?.liftStatus {
                CompactMountainStatus(liftStatus: liftStatus)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    // MARK: - Weather Content

    private var weatherContent: some View {
        VStack(spacing: 8) {
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
                .padding(.horizontal, 10)
                .padding(.top, 8)

                // Elevation temperatures
                if let tempByElevation = conditions.temperatureByElevation {
                    Divider()
                        .padding(.horizontal, 10)

                    VStack(spacing: 8) {
                        Text("Temperatures by Elevation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)

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
                        .padding(.horizontal, 10)
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
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
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
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }

    // MARK: - Snow Timeline (Dynamically scrollable timeline)

    private var snowTimeline: some View {
        VStack(spacing: 0) {
            // Dynamic three-column header (updates as you scroll)
            HStack(spacing: 0) {
                // Prev 5d (dynamic - relative to centered day)
                VStack(spacing: 2) {
                    Text("Prev 5d")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(dynamicPrevFiveDaysTotal)\"")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.984, green: 0.573, blue: 0.235))
                }
                .frame(maxWidth: .infinity)

                // Centered day (dynamic - updates with scroll)
                VStack(spacing: 1) {
                    Text(centeredDayLabel)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(snowfallForDay(offset: centerDayOffset))\"")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .id("header-\(centerDayOffset)")

                // Next 5d (dynamic - relative to centered day)
                VStack(spacing: 2) {
                    Text("Next 5d")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    if dynamicNextFiveDaysTotal > 0 {
                        Text("\(dynamicNextFiveDaysTotal)\"")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                    } else {
                        Text("-")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .animation(.easeOut(duration: 0.2), value: centerDayOffset)

            // Continuous horizontally scrollable bar graph
            ScrollViewReader { proxy in
                GeometryReader { outerGeo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(-7...7, id: \.self) { dayOffset in
                                fullDayColumn(for: dayOffset)
                                    .id(dayOffset)
                                    .containerRelativeFrame(.horizontal, count: 5, spacing: 2)
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.horizontal, outerGeo.size.width / 2 - 20) // Center padding
                        .padding(.vertical, 6)
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $scrollPosition)
                    .onChange(of: scrollPosition) { oldValue, newValue in
                        if oldValue != newValue, newValue != nil {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .onAppear {
                        // Scroll to today initially
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                scrollPosition = 0
                            }
                        }
                    }
                }
                .frame(height: 65)
            }

            // Reported timestamp
            if let lastUpdated = conditions?.lastUpdated {
                let date = ISO8601DateFormatter().date(from: lastUpdated) ?? Date()
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                    Text(date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Dynamic Header Calculations

    /// Centered day offset (which day is in center of viewport)
    private var centerDayOffset: Int {
        scrollPosition ?? 0
    }

    /// Dynamic totals for prev 5 days (relative to centered day)
    private var dynamicPrevFiveDaysTotal: Int {
        (centerDayOffset - 5..<centerDayOffset).reduce(0) { total, offset in
            total + snowfallForDay(offset: offset)
        }
    }

    /// Dynamic totals for next 5 days (relative to centered day)
    private var dynamicNextFiveDaysTotal: Int {
        (centerDayOffset + 1...centerDayOffset + 5).reduce(0) { total, offset in
            total + snowfallForDay(offset: offset)
        }
    }

    /// Dynamic label for centered day
    private var centeredDayLabel: String {
        if centerDayOffset == 0 {
            return "Last 24h"
        } else if centerDayOffset < 0 {
            return "\(abs(centerDayOffset))d Ago"
        } else {
            return "In \(centerDayOffset)d"
        }
    }

    // MARK: - Bar Color Coding

    /// Get bar color based on snowfall amount and whether it's past/future
    private func barColor(for snowfall: Int, isPast: Bool) -> Color {
        // Color intensity based on snowfall amount
        if snowfall == 0 {
            return Color.gray.opacity(0.3)
        } else if snowfall >= 10 {
            // Epic snow - very bright, saturated
            return isPast ? Color(red: 1.0, green: 0.6, blue: 0.2) : Color(red: 0.2, green: 0.6, blue: 1.0)
        } else if snowfall >= 7 {
            // Heavy snow - bright
            return isPast ? Color(red: 0.984, green: 0.573, blue: 0.235) : Color(red: 0.3, green: 0.65, blue: 1.0)
        } else if snowfall >= 4 {
            // Moderate snow - medium
            return isPast ? Color(red: 0.9, green: 0.5, blue: 0.25) : Color(red: 0.4, green: 0.7, blue: 0.95)
        } else {
            // Light snow - subtle
            return isPast ? Color(red: 0.8, green: 0.45, blue: 0.25) : Color(red: 0.5, green: 0.75, blue: 0.9)
        }
    }

    // MARK: - Animation Helpers

    /// Calculate scale based on distance from center
    private func barAnimationScale(for dayOffset: Int, geometry: GeometryProxy) -> CGFloat {
        let barCenter = geometry.frame(in: .named("scroll")).midX
        let viewportCenter = geometry.size.width / 2
        let distance = abs(barCenter - viewportCenter)
        let maxDistance: CGFloat = 200
        let normalizedDistance = min(distance / maxDistance, 1.0)
        return 1.0 - (normalizedDistance * 0.3)  // 1.0 at center, 0.7 at edges
    }

    /// Calculate opacity based on distance from center
    private func barAnimationOpacity(for dayOffset: Int, geometry: GeometryProxy) -> CGFloat {
        let barCenter = geometry.frame(in: .named("scroll")).midX
        let viewportCenter = geometry.size.width / 2
        let distance = abs(barCenter - viewportCenter)
        let maxDistance: CGFloat = 200
        let normalizedDistance = min(distance / maxDistance, 1.0)
        return 1.0 - (normalizedDistance * 0.6)  // 1.0 at center, 0.4 at edges
    }

    // Full-size day column for continuous scrolling
    private func fullDayColumn(for offset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let snowfall = snowfallForDay(offset: offset)
        let isToday = offset == 0
        let isPast = offset < 0
        let barHeight = min(CGFloat(snowfall) * 3.0, 40)

        let color = barColor(for: snowfall, isPast: isPast)

        return GeometryReader { geometry in
            VStack(spacing: 1) {
                // Date display
                VStack(spacing: 0) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1))
                        .font(.system(size: 8, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? .primary : .secondary)
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 9, weight: isToday ? .bold : .regular))
                        .foregroundColor(isToday ? .primary : .secondary)
                }

                // Bar chart
                ZStack(alignment: .bottom) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 16, height: 40)

                    // Bar with dynamic color coding
                    if snowfall > 0 {
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 16, height: barHeight)
                            .shadow(
                                color: color.opacity(0.3),
                                radius: snowfall > 6 ? 3 : 1,
                                x: 0,
                                y: 1
                            )
                    }
                }
                .frame(height: 40)

                // Snowfall amount
                Text(snowfall > 0 ? "\(snowfall)\"" : "-")
                    .font(.system(size: 8, weight: snowfall > 6 ? .bold : .medium))
                    .foregroundColor(snowfall > 0 ? .primary : .secondary.opacity(0.6))
            }
            .frame(width: 26)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? Color.blue.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isToday ? Color.blue.opacity(0.5) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(barAnimationScale(for: offset, geometry: geometry))
            .opacity(barAnimationOpacity(for: offset, geometry: geometry))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scrollPosition)
        }
        .frame(width: 26)  // Fixed width for GeometryReader
    }

    // Compact day column for 5-day sections
    private func compactDayColumn(for offset: Int, color: Color) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let snowfall = snowfallForDay(offset: offset)
        let barHeight = min(CGFloat(snowfall) * 3.0, 40)

        return VStack(spacing: 2) {
            // Bar
            VStack {
                Spacer()
                if snowfall > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.8))
                        .frame(width: 8, height: barHeight)
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 8, height: 3)
                }
            }
            .frame(height: 40)

            // Day letter
            Text(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1))
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            // Date number
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var prevFiveDaysTotal: Int {
        (-5..<0).reduce(0) { total, offset in
            total + snowfallForDay(offset: offset)
        }
    }

    private var nextFiveDaysTotal: Int {
        (1...5).reduce(0) { total, offset in
            total + snowfallForDay(offset: offset)
        }
    }

    // Redesigned day bar - clean, balanced proportions
    private func redesignedDayBar(for offset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let snowfall = snowfallForDay(offset: offset)
        let isToday = offset == 0
        let isPast = offset < 0
        let barHeight = min(CGFloat(snowfall) * 3.5, 55)

        let barColor: Color = isPast ? .orange : isToday ? .green : .blue

        return VStack(spacing: 2) {
            // Date display
            VStack(spacing: 0) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1))
                    .font(.system(size: 9, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? .primary : .secondary)
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 10, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .primary : .secondary)
            }

            // Bar chart
            ZStack(alignment: .bottom) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 16, height: 55)

                // Animated bar
                if snowfall > 0 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [barColor, barColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 16, height: barHeight)
                        .shadow(
                            color: barColor.opacity(0.4),
                            radius: snowfall > 6 ? 4 : 2,
                            x: 0,
                            y: 2
                        )
                }
            }
            .frame(height: 55)

            // Snowfall amount
            Text(snowfall > 0 ? "\(snowfall)\"" : "-")
                .font(.system(size: 9, weight: snowfall > 6 ? .bold : .medium))
                .foregroundColor(snowfall > 0 ? .primary : .secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.blue.opacity(0.08) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isToday ? Color.blue.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
    }

    // Compact day bar column - ultra condensed for synchronized scrolling
    private func compactDayBarColumn(for offset: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let snowfall = snowfallForDay(offset: offset)
        let isToday = offset == 0
        let isPast = offset < 0
        let barHeight = min(CGFloat(snowfall) * 2.0, 35)

        let barColor: Color = isPast ? .orange : isToday ? .green : .blue

        return VStack(spacing: 1) {
            // Day letter (single char)
            Text(date.formatted(.dateTime.weekday(.abbreviated)).prefix(1))
                .font(.system(size: 8, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .primary : .secondary)

            // Animated bar chart
            VStack {
                Spacer()
                if snowfall > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor.opacity(0.8))
                        .frame(width: 10, height: isAnimating ? barHeight : 0)
                        .shadow(
                            color: barColor.opacity(0.3),
                            radius: snowfall > 6 ? 3 : 1,
                            x: 0,
                            y: 1
                        )
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 10, height: 2)
                }
            }
            .frame(height: 35)

            // Snowfall amount
            if snowfall > 0 {
                Text("\(snowfall)\"")
                    .font(.system(size: 7, weight: snowfall > 6 ? .bold : .regular))
                    .foregroundColor(.primary.opacity(0.9))
            } else {
                Text(" ")
                    .font(.system(size: 7))
            }
        }
        .frame(width: 20)
        .padding(.vertical, 2)
        .padding(.horizontal, 1)
        .background(
            Group {
                if isToday {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                } else {
                    Color.clear
                }
            }
        )
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
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
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
                HStack(spacing: 10) {
                    // Formatted date
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatForecastDate(day.date))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text(day.dayOfWeek)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 35, alignment: .leading)

                    // Powder quality indicator
                    powderQualityBadge(for: Int(day.snowfall))

                    // Snowfall amount
                    Text("\(day.snowfall)\"")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(snowfallColor(for: Int(day.snowfall)))
                        .frame(width: 28, alignment: .trailing)

                    // Conditions
                    Text(day.conditions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    // Temperature range
                    HStack(spacing: 2) {
                        Text("\(day.high)°")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("/")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(day.low)°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)

                if day.id != forecast.prefix(5).last?.id {
                    Divider()
                        .padding(.leading, 10)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // Format forecast date (e.g., "Jan 15")
    private func formatForecastDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: dateString) else {
            return String(dateString.suffix(5)) // Fallback to "MM-DD"
        }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d"
        return outputFormatter.string(from: date)
    }

    // Color code snowfall amounts
    private func snowfallColor(for snowfall: Int) -> Color {
        switch snowfall {
        case 10...:
            return Color(red: 0.290, green: 0.871, blue: 0.502) // Green - epic
        case 6...9:
            return .blue // Good
        case 3...5:
            return .cyan // Moderate
        default:
            return .secondary // Light/none
        }
    }

    // Powder quality badge
    @ViewBuilder
    private func powderQualityBadge(for snowfall: Int) -> some View {
        let (emoji, _) = powderQuality(for: snowfall)
        Text(emoji)
            .font(.caption)
    }

    private func powderQuality(for snowfall: Int) -> (emoji: String, label: String) {
        switch snowfall {
        case 12...:
            return ("🔥", "Epic")
        case 8...11:
            return ("⭐️", "Great")
        case 4...7:
            return ("👍", "Good")
        case 1...3:
            return ("❄️", "Light")
        default:
            return ("", "None")
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
                filterMode: .snowSummary,
                scrollSync: TimelineScrollSync()
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
