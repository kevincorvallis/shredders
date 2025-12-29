import SwiftUI

struct MountainStatusView: View {
    let status: MountainStatus
    let variant: Variant

    enum Variant {
        case compact
        case full
    }

    var body: some View {
        if variant == .compact {
            compactView
        } else {
            fullView
        }
    }

    private var compactView: some View {
        HStack(spacing: 8) {
            // Status Badge
            Text(status.isOpen ? "OPEN" : "CLOSED")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(status.isOpen ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(status.isOpen ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(status.isOpen ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )

            // Percentage Open
            if status.isOpen, let percentOpen = status.percentOpen {
                Text("\(percentOpen)% Open")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(percentColor(for: percentOpen))
            }
        }
    }

    private var fullView: some View {
        VStack(spacing: 12) {
            // Header with Status Badge
            HStack {
                Text(status.isOpen ? "OPEN" : "CLOSED")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(status.isOpen ? .green : .red)

                Spacer()

                if let percentOpen = status.percentOpen {
                    Text("\(percentOpen)% Open")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(percentColor(for: percentOpen))
                }
            }

            // Progress Bar
            if status.isOpen, let percentOpen = status.percentOpen {
                ProgressView(value: Double(percentOpen), total: 100)
                    .tint(percentColor(for: percentOpen))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }

            // Lifts and Runs Grid
            if status.isOpen {
                HStack(spacing: 16) {
                    if let liftsOpen = status.liftsOpen {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Lifts", systemImage: "cable.car")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(liftsOpen)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let runsOpen = status.runsOpen {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Runs", systemImage: "figure.skiing.downhill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(runsOpen)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            // Message
            if let message = status.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func percentColor(for percent: Int) -> Color {
        switch percent {
        case 80...100: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}

#Preview("Compact - Open") {
    MountainStatusView(
        status: MountainStatus(
            isOpen: true,
            percentOpen: 85,
            liftsOpen: "8/10",
            runsOpen: "70/82",
            message: "Great conditions!",
            lastUpdated: nil
        ),
        variant: .compact
    )
    .padding()
}

#Preview("Full - Open") {
    MountainStatusView(
        status: MountainStatus(
            isOpen: true,
            percentOpen: 85,
            liftsOpen: "8/10",
            runsOpen: "70/82",
            message: "Great conditions!",
            lastUpdated: nil
        ),
        variant: .full
    )
    .padding()
}

#Preview("Compact - Closed") {
    MountainStatusView(
        status: MountainStatus(
            isOpen: false,
            percentOpen: 0,
            liftsOpen: "0/10",
            runsOpen: "0/82",
            message: "Closed for season",
            lastUpdated: nil
        ),
        variant: .compact
    )
    .padding()
}
