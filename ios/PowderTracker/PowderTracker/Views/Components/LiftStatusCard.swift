import SwiftUI

// MARK: - Lift Status Card

/// Creative lift status card showing live data from DynamoDB
struct LiftStatusCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let liftStatus: LiftStatus
    @State private var animateProgress = false

    var body: some View {
        VStack(spacing: 16) {
            // Header with animated status badge
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor.gradient)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(statusColor, lineWidth: 1)
                                .scaleEffect(animateProgress ? 1.5 : 1)
                                .opacity(animateProgress ? 0 : 1)
                        )

                    Text(liftStatus.isOpen ? "OPEN" : "CLOSED")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(statusColor.opacity(0.3), lineWidth: 1)
                        )
                )

                Spacer()

                // Overall percentage
                Text("\(liftStatus.percentOpen)%")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(percentColor)
            }

            // Circular progress rings for lifts and runs
            HStack(spacing: 24) {
                CircularProgressView(
                    value: liftStatus.liftsOpen,
                    total: liftStatus.liftsTotal,
                    label: "Lifts",
                    icon: "cablecar.fill",
                    color: percentColor,
                    animate: animateProgress
                )

                if liftStatus.runsTotal > 0 {
                    CircularProgressView(
                        value: liftStatus.runsOpen,
                        total: liftStatus.runsTotal,
                        label: "Runs",
                        icon: "figure.skiing.downhill",
                        color: percentColor,
                        animate: animateProgress
                    )
                }
            }
            .padding(.vertical, 8)

            // Message if available
            if let message = liftStatus.message, !message.isEmpty {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.blue)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }

            // Last updated timestamp
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
                Text("Updated \(timeAgo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusHero))
        .adaptiveShadow(colorScheme: colorScheme, radius: 8, y: 2)
        .accessibleCard(
            label: "\(liftStatus.isOpen ? "Open" : "Closed"). \(liftStatus.liftsOpen) of \(liftStatus.liftsTotal) lifts operating. \(liftStatus.runsOpen) of \(liftStatus.runsTotal) runs open. Updated \(timeAgo).",
            hint: nil
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateProgress = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                if liftStatus.isOpen {
                    animateProgress = true
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        liftStatus.isOpen ? .green : .red
    }

    private var percentColor: Color {
        switch liftStatus.percentOpen {
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    private var timeAgo: String {
        guard let date = ISO8601DateFormatter().date(from: liftStatus.lastUpdated) else {
            return "recently"
        }

        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "just now"
        }
    }
}

// MARK: - Circular Progress View

/// Circular progress ring with count display
struct CircularProgressView: View {
    let value: Int
    let total: Int
    let label: String
    let icon: String
    let color: Color
    let animate: Bool

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animate ? percentage : 0)
                    .stroke(
                        color.gradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)

                // Center content
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(color)

                    Text("\(value)")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)

                    Text("of \(total)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Lift Status Badge

/// Compact lift status badge for list views
struct LiftStatusBadge: View {
    let liftStatus: LiftStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(liftStatus.isOpen ? "OPEN" : "CLOSED")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)

            if liftStatus.isOpen {
                Text("•")
                    .foregroundColor(.secondary)
                    .font(.caption2)

                Text("\(liftStatus.percentOpen)%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(percentColor)

                Text("•")
                    .foregroundColor(.secondary)
                    .font(.caption2)

                Text("\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if liftStatus.isOpen {
            return "Open, \(liftStatus.percentOpen) percent capacity, \(liftStatus.liftsOpen) of \(liftStatus.liftsTotal) lifts"
        } else {
            return "Closed"
        }
    }

    private var statusColor: Color {
        liftStatus.isOpen ? .green : .red
    }

    private var percentColor: Color {
        switch liftStatus.percentOpen {
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}

// MARK: - Mini Lift Map

/// A visual grid map showing lift status with a simplified mountain layout
struct MiniLiftMap: View {
    let liftStatus: LiftStatus
    @State private var animateIn = false

    /// Simulated lift positions for visual layout (normalized 0-1 coordinates)
    private var liftPositions: [(x: CGFloat, y: CGFloat, isOpen: Bool)] {
        guard liftStatus.liftsTotal > 0 else { return [] }

        // Generate lift positions in a mountain-like pattern
        // Lifts are spread across the mountain with more at the base
        var positions: [(x: CGFloat, y: CGFloat, isOpen: Bool)] = []

        for i in 0..<liftStatus.liftsTotal {
            let isOpen = i < liftStatus.liftsOpen
            let progress = CGFloat(i) / CGFloat(max(1, liftStatus.liftsTotal - 1))

            // Create a mountain-like distribution
            // Base lifts (lower y values), peak lifts (higher y values)
            let tier = i / 3 // Group lifts into tiers
            let tierOffset = CGFloat(i % 3) / 3.0

            // X position: spread across with slight randomization per tier
            let baseX: CGFloat = 0.2 + tierOffset * 0.6 + (progress * 0.1)
            let x = min(max(baseX, 0.1), 0.9)

            // Y position: tiers go up the mountain (inverted - 0 is top)
            let y = 0.8 - CGFloat(tier) * 0.15

            positions.append((x: x, y: max(0.2, y), isOpen: isOpen))
        }

        return positions
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Mountain silhouette background
                MountainSilhouette()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.blue.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Lift markers
                ForEach(Array(liftPositions.enumerated()), id: \.offset) { index, position in
                    LiftMarker(isOpen: position.isOpen, index: index, animate: animateIn)
                        .position(
                            x: geo.size.width * position.x,
                            y: geo.size.height * position.y
                        )
                }

                // Legend
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Open")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text("Closed")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding(.bottom, 8)
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusCard))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateIn = true
            }
        }
    }
}

/// Mountain silhouette shape for the background
struct MountainSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: rect.maxY))

        // Left slope
        path.addLine(to: CGPoint(x: rect.width * 0.15, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.6))

        // Main peak
        path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.1)) // Summit

        // Secondary peak
        path.addLine(to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.15))

        // Right slope
        path.addLine(to: CGPoint(x: rect.width * 0.85, y: rect.height * 0.45))
        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))

        // Close path
        path.closeSubpath()

        return path
    }
}

/// Individual lift marker on the map
struct LiftMarker: View {
    let isOpen: Bool
    let index: Int
    let animate: Bool

    var body: some View {
        ZStack {
            // Outer glow for open lifts
            if isOpen && animate {
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 20, height: 20)
            }

            // Main marker
            Circle()
                .fill(isOpen ? Color.green : Color.red.opacity(0.5))
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                .scaleEffect(animate ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.6)
                        .delay(Double(index) * 0.05),
                    value: animate
                )
        }
    }
}

// MARK: - Previews
#Preview("Lift Status Card - High %") {
    LiftStatusCard(
        liftStatus: LiftStatus(
            isOpen: true,
            liftsOpen: 9,
            liftsTotal: 10,
            runsOpen: 45,
            runsTotal: 52,
            message: "All major lifts operating",
            lastUpdated: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
        )
    )
    .padding()
}

#Preview("Lift Status Card - Medium %") {
    LiftStatusCard(
        liftStatus: LiftStatus(
            isOpen: true,
            liftsOpen: 6,
            liftsTotal: 10,
            runsOpen: 30,
            runsTotal: 52,
            message: nil,
            lastUpdated: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800))
        )
    )
    .padding()
}

#Preview("Lift Status Card - Closed") {
    LiftStatusCard(
        liftStatus: LiftStatus(
            isOpen: false,
            liftsOpen: 0,
            liftsTotal: 10,
            runsOpen: 0,
            runsTotal: 52,
            message: "Closed for the season",
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
    )
    .padding()
}

#Preview("Lift Status Badge") {
    VStack(spacing: 12) {
        LiftStatusBadge(
            liftStatus: LiftStatus(
                isOpen: true,
                liftsOpen: 9,
                liftsTotal: 10,
                runsOpen: 45,
                runsTotal: 52,
                message: nil,
                lastUpdated: ISO8601DateFormatter().string(from: Date())
            )
        )

        LiftStatusBadge(
            liftStatus: LiftStatus(
                isOpen: false,
                liftsOpen: 0,
                liftsTotal: 10,
                runsOpen: 0,
                runsTotal: 52,
                message: nil,
                lastUpdated: ISO8601DateFormatter().string(from: Date())
            )
        )
    }
    .padding()
}
