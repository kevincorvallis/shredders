import SwiftUI

/// Creative circular progress indicator showing mountain open percentage
struct MountainStatusIndicator: View {
    let isOpen: Bool
    let percentOpen: Int
    let size: CGFloat

    @State private var animateProgress = false

    private var statusColor: Color {
        if !isOpen {
            return Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
        }

        switch percentOpen {
        case 80...100:
            return Color(red: 0.290, green: 0.871, blue: 0.502) // #4ADE80
        case 50...79:
            return Color(red: 0.988, green: 0.827, blue: 0.302) // #FCD34D
        case 1...49:
            return Color(red: 0.984, green: 0.573, blue: 0.235) // #FB923C
        default:
            return Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
        }
    }

    private var progressPercentage: Double {
        isOpen ? Double(percentOpen) / 100.0 : 0
    }

    var body: some View {
        ZStack {
            // Background circle (track)
            Circle()
                .stroke(
                    Color.gray.opacity(0.15),
                    style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
                )

            // Progress circle (foreground)
            Circle()
                .trim(from: 0, to: animateProgress ? progressPercentage : 0)
                .stroke(
                    statusColor,
                    style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: statusColor.opacity(0.6),
                    radius: size * 0.1,
                    x: 0,
                    y: 0
                )

            // Center icon - changes based on status
            ZStack {
                if isOpen {
                    // Ski lift icon when open
                    Image(systemName: "cablecar.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    // X mark when closed
                    Image(systemName: "xmark")
                        .font(.system(size: size * 0.35, weight: .bold))
                        .foregroundColor(statusColor)
                }
            }

            // Outer glow ring for emphasis
            if percentOpen >= 80 && isOpen {
                Circle()
                    .stroke(statusColor.opacity(0.2), lineWidth: 1)
                    .frame(width: size * 1.15, height: size * 1.15)
                    .blur(radius: 2)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

/// Compact horizontal status with circular indicator
struct CompactMountainStatus: View {
    let liftStatus: LiftStatus
    let size: CGFloat = 32

    var body: some View {
        HStack(spacing: 8) {
            // Status text
            VStack(alignment: .trailing, spacing: 2) {
                Text(liftStatus.isOpen ? "Open" : "Closed")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)

                if liftStatus.isOpen && liftStatus.percentOpen > 0 {
                    Text("\(liftStatus.percentOpen)% Open")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            // Circular progress indicator
            MountainStatusIndicator(
                isOpen: liftStatus.isOpen,
                percentOpen: liftStatus.percentOpen,
                size: size
            )
        }
    }

    private var statusColor: Color {
        if !liftStatus.isOpen {
            return Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
        }

        switch liftStatus.percentOpen {
        case 80...100:
            return Color(red: 0.290, green: 0.871, blue: 0.502) // #4ADE80
        case 50...79:
            return Color(red: 0.988, green: 0.827, blue: 0.302) // #FCD34D
        case 1...49:
            return Color(red: 0.984, green: 0.573, blue: 0.235) // #FB923C
        default:
            return Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
        }
    }
}

/// Large status card with detailed info
struct DetailedMountainStatus: View {
    let liftStatus: LiftStatus

    var body: some View {
        VStack(spacing: 16) {
            // Large circular indicator
            MountainStatusIndicator(
                isOpen: liftStatus.isOpen,
                percentOpen: liftStatus.percentOpen,
                size: 80
            )

            // Status details
            VStack(spacing: 8) {
                Text(liftStatus.isOpen ? "Currently Open" : "Currently Closed")
                    .font(.title3)
                    .fontWeight(.bold)

                if liftStatus.isOpen {
                    VStack(spacing: 4) {
                        HStack(spacing: 16) {
                            StatusDetailRow(
                                icon: "cablecar.fill",
                                label: "Lifts",
                                value: "\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)"
                            )

                            StatusDetailRow(
                                icon: "figure.skiing.downhill",
                                label: "Runs",
                                value: "\(liftStatus.runsOpen)/\(liftStatus.runsTotal)"
                            )
                        }

                        Text("\(liftStatus.percentOpen)% of mountain open")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct StatusDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Status Indicators") {
    VStack(spacing: 30) {
        Text("Mountain Status Indicators")
            .font(.title2)
            .fontWeight(.bold)

        // Different status states
        HStack(spacing: 20) {
            VStack {
                MountainStatusIndicator(isOpen: true, percentOpen: 100, size: 50)
                Text("100% Open")
                    .font(.caption)
            }

            VStack {
                MountainStatusIndicator(isOpen: true, percentOpen: 75, size: 50)
                Text("75% Open")
                    .font(.caption)
            }

            VStack {
                MountainStatusIndicator(isOpen: true, percentOpen: 45, size: 50)
                Text("45% Open")
                    .font(.caption)
            }

            VStack {
                MountainStatusIndicator(isOpen: false, percentOpen: 0, size: 50)
                Text("Closed")
                    .font(.caption)
            }
        }

        Divider()

        // Compact status examples
        VStack(spacing: 16) {
            CompactMountainStatus(
                liftStatus: LiftStatus(
                    isOpen: true,
                    liftsOpen: 9,
                    liftsTotal: 10,
                    runsOpen: 45,
                    runsTotal: 52,
                    message: nil,
                    lastUpdated: Date().ISO8601Format()
                )
            )

            CompactMountainStatus(
                liftStatus: LiftStatus(
                    isOpen: true,
                    liftsOpen: 5,
                    liftsTotal: 10,
                    runsOpen: 26,
                    runsTotal: 52,
                    message: nil,
                    lastUpdated: Date().ISO8601Format()
                )
            )

            CompactMountainStatus(
                liftStatus: LiftStatus(
                    isOpen: false,
                    liftsOpen: 0,
                    liftsTotal: 10,
                    runsOpen: 0,
                    runsTotal: 52,
                    message: nil,
                    lastUpdated: Date().ISO8601Format()
                )
            )
        }

        Divider()

        // Detailed status card
        DetailedMountainStatus(
            liftStatus: LiftStatus(
                isOpen: true,
                liftsOpen: 9,
                liftsTotal: 10,
                runsOpen: 45,
                runsTotal: 52,
                message: nil,
                lastUpdated: Date().ISO8601Format()
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
