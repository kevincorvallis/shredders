import SwiftUI

/// Creative lift status card showing live data from DynamoDB
struct LiftStatusCard: View {
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
                    .foregroundColor(.secondary)
                Text("Updated \(timeAgo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
