//
//  SkiIconicElements.swift
//  PowderTracker
//
//  Iconic ski and snowboard UI elements inspired by real resort signage,
//  lift tickets, and trail maps.
//
//  Sources:
//  - Trail signs: https://signsofthemountains.com/blogs/news/what-do-the-symbols-on-ski-trail-signs-mean
//  - Lift icons: https://www.flaticon.com/free-icons/ski-lift
//  - Ski app patterns: OpenSnow, Slopes, OnTheSnow
//

import SwiftUI

// MARK: - Lift Ticket Card Style

/// A card modifier that makes views look like authentic ski lift tickets
struct LiftTicketStyle: ViewModifier {
    var showPerforation: Bool = true
    var showBarcode: Bool = false

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // Perforated tear line at top
            if showPerforation {
                PerforationLine()
                    .padding(.horizontal, 8)
            }

            content

            // Optional barcode at bottom
            if showBarcode {
                TicketBarcode()
                    .padding(.top, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

/// Perforated tear line like on real lift tickets
struct PerforationLine: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { _ in
                Circle()
                    .fill(Color(.separator).opacity(0.4))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

/// Barcode visual element for lift ticket aesthetic
struct TicketBarcode: View {
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<30, id: \.self) { i in
                Rectangle()
                    .fill(Color.primary.opacity(0.7))
                    .frame(width: CGFloat.random(in: 1...3), height: 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

extension View {
    /// Apply lift ticket styling to any card
    func liftTicketStyle(showPerforation: Bool = true, showBarcode: Bool = false) -> some View {
        modifier(LiftTicketStyle(showPerforation: showPerforation, showBarcode: showBarcode))
    }
}

// MARK: - Snow Quality Badge

/// Badge showing snow quality (uses SnowQuality enum from CheckIn.swift)
struct SnowQualityBadge: View {
    let quality: SnowQuality
    var size: BadgeSize = .standard

    enum BadgeSize {
        case compact, standard, large

        var iconSize: CGFloat {
            switch self {
            case .compact: return 12
            case .standard: return 14
            case .large: return 18
            }
        }

        var font: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            case .large: return .subheadline
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: quality.icon)
                .font(.system(size: size.iconSize))

            Text(quality.displayName)
                .font(size.font)
                .fontWeight(.medium)
        }
        .foregroundStyle(quality.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(quality.color.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("Snow quality: \(quality.displayName), \(quality.conditionDescription)")
    }
}

// MARK: - Chairlift Type Icons

/// Types of ski lifts with authentic icons
enum LiftType: String, CaseIterable {
    case chairlift = "Chairlift"
    case highSpeedQuad = "High-Speed Quad"
    case sixPack = "6-Pack Express"
    case gondola = "Gondola"
    case bubbleChair = "Bubble Chair"
    case tram = "Tram"
    case surfaceLift = "Surface Lift"
    case magicCarpet = "Magic Carpet"
    case tBar = "T-Bar"
    case ropeTow = "Rope Tow"

    var icon: String {
        switch self {
        case .chairlift, .highSpeedQuad, .sixPack: return "cablecar"
        case .gondola, .bubbleChair, .tram: return "cablecar.fill"
        case .surfaceLift, .tBar: return "arrow.up.forward"
        case .magicCarpet: return "arrow.right"
        case .ropeTow: return "line.diagonal"
        }
    }

    var capacity: String? {
        switch self {
        case .highSpeedQuad: return "4"
        case .sixPack: return "6"
        case .gondola: return "8+"
        case .tram: return "100+"
        default: return nil
        }
    }

    var isHighSpeed: Bool {
        switch self {
        case .highSpeedQuad, .sixPack, .gondola, .tram: return true
        default: return false
        }
    }
}

/// Icon showing lift type with optional capacity badge
struct LiftTypeIcon: View {
    let type: LiftType
    var status: LiftStatus = .open
    var size: CGFloat = 24

    enum LiftStatus {
        case open, closed, hold, scheduled

        var color: Color {
            switch self {
            case .open: return .green
            case .closed: return .red
            case .hold: return .orange
            case .scheduled: return .blue
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main lift icon
            Image(systemName: type.icon)
                .font(.system(size: size))
                .foregroundStyle(status.color)

            // High-speed indicator
            if type.isHighSpeed {
                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(.yellow)
                    .offset(x: 2, y: 2)
            }

            // Capacity badge
            if let capacity = type.capacity {
                Text(capacity)
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(2)
                    .background(Circle().fill(status.color))
                    .offset(x: 4, y: 4)
            }
        }
        .accessibilityLabel("\(type.rawValue), \(status == .open ? "Open" : status == .closed ? "Closed" : "On hold")")
    }
}

// MARK: - Trail Feature Icons

/// Trail features and terrain types
enum TrailFeature: String, CaseIterable {
    case moguls = "Moguls"
    case groomed = "Groomed"
    case glades = "Glades"
    case bowls = "Bowls"
    case steeps = "Steeps"
    case terrainPark = "Terrain Park"
    case halfPipe = "Half Pipe"
    case rails = "Rails & Boxes"
    case catTrack = "Cat Track"
    case traverse = "Traverse"

    var icon: String {
        switch self {
        case .moguls: return "circle.grid.3x3.fill"
        case .groomed: return "line.3.horizontal"
        case .glades: return "tree.fill"
        case .bowls: return "circle.bottomhalf.filled"
        case .steeps: return "arrow.down.right"
        case .terrainPark: return "figure.skiing.downhill"
        case .halfPipe: return "trapezoid.and.line.horizontal"
        case .rails: return "rectangle.and.hand.point.up.left.filled"
        case .catTrack: return "road.lanes"
        case .traverse: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .moguls: return .orange
        case .groomed: return .blue
        case .glades: return .green
        case .bowls: return .cyan
        case .steeps: return .red
        case .terrainPark, .halfPipe, .rails: return .purple
        case .catTrack, .traverse: return .gray
        }
    }
}

/// Badge showing trail feature
struct TrailFeatureBadge: View {
    let feature: TrailFeature
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: feature.icon)
                .font(.caption)

            if showLabel {
                Text(feature.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(feature.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(feature.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Elevation Badge

/// Badge showing mountain elevation
struct ElevationBadge: View {
    let elevation: Int // in feet
    var type: ElevationType = .summit

    enum ElevationType {
        case summit, base, verticalDrop

        var label: String {
            switch self {
            case .summit: return "Summit"
            case .base: return "Base"
            case .verticalDrop: return "Vert"
            }
        }

        var icon: String {
            switch self {
            case .summit: return "triangle.fill"
            case .base: return "triangle"
            case .verticalDrop: return "arrow.up.and.down"
            }
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.caption2)
                Text(formattedElevation)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }

            Text(type.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("\(type.label) elevation: \(elevation) feet")
    }

    private var formattedElevation: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: elevation)) ?? "\(elevation)") + "'"
    }
}

// MARK: - Chairlift Loading Animation

/// Animated chairlift loading indicator
struct ChairliftLoadingView: View {
    @State private var offset: CGFloat = 0
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Cable line
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 2)

                // Towers
                HStack {
                    LiftTower()
                    Spacer()
                    LiftTower()
                    Spacer()
                    LiftTower()
                }

                // Moving chair
                Image(systemName: "cablecar.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .offset(x: offset)
            }
            .frame(height: 40)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                    offset = 80
                }
            }

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(width: 200)
    }
}

/// Single lift tower shape
private struct LiftTower: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 4, height: 20)

            Rectangle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 12, height: 4)
        }
    }
}

// MARK: - Goggle View Toggle

/// Toggle styled like ski goggles lens
struct GoggleViewToggle: View {
    @Binding var isCompact: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isCompact.toggle()
            }
            HapticFeedback.selection.trigger()
        } label: {
            HStack(spacing: 2) {
                // Left lens
                Capsule()
                    .fill(isCompact ? Color.blue : Color.secondary.opacity(0.3))
                    .frame(width: 20, height: 14)
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )

                // Bridge
                Rectangle()
                    .fill(Color.primary.opacity(0.5))
                    .frame(width: 4, height: 6)

                // Right lens
                Capsule()
                    .fill(isCompact ? Color.secondary.opacity(0.3) : Color.blue)
                    .frame(width: 20, height: 14)
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(4)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompact ? "Switch to expanded view" : "Switch to compact view")
    }
}

// MARK: - Ski Pass Style Badge

/// Badge styled like a season pass
struct SkiPassBadge: View {
    let passName: String
    let resortCount: Int

    var body: some View {
        HStack(spacing: 8) {
            // Pass icon
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 20)

                Image(systemName: "person.text.rectangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(passName)
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("\(resortCount) resorts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview("Lift Ticket Style") {
    VStack(spacing: 20) {
        VStack {
            Text("Mountain Card")
                .font(.headline)
            Text("With lift ticket styling")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .liftTicketStyle(showBarcode: true)

        VStack {
            Text("Simple Ticket")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .liftTicketStyle()
    }
    .padding()
}

#Preview("Snow Quality") {
    VStack(spacing: 12) {
        Text("Snow Conditions").font(.headline)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(SnowQuality.allCases, id: \.self) { quality in
                SnowQualityBadge(quality: quality)
            }
        }
    }
    .padding()
}

#Preview("Lift Types") {
    VStack(spacing: 16) {
        Text("Lift Types").font(.headline)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
            ForEach(LiftType.allCases, id: \.self) { type in
                VStack {
                    LiftTypeIcon(type: type)
                    Text(type.rawValue)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    .padding()
}

#Preview("Trail Features") {
    VStack(spacing: 12) {
        Text("Trail Features").font(.headline)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(TrailFeature.allCases, id: \.self) { feature in
                TrailFeatureBadge(feature: feature)
            }
        }
    }
    .padding()
}

#Preview("Elevation Badges") {
    HStack(spacing: 16) {
        ElevationBadge(elevation: 11053, type: .summit)
        ElevationBadge(elevation: 6200, type: .base)
        ElevationBadge(elevation: 4853, type: .verticalDrop)
    }
    .padding()
}

#Preview("Loading & Toggle") {
    VStack(spacing: 32) {
        ChairliftLoadingView("Loading conditions...")

        HStack {
            Text("View Mode:")
            GoggleViewToggle(isCompact: .constant(false))
        }

        SkiPassBadge(passName: "Ikon Pass", resortCount: 50)
    }
    .padding()
}
