//
//  LiveStatusCard.swift
//  PowderTracker
//
//  Compact live status card for Now tab grid
//

import SwiftUI

struct LiveStatusCard: View {
    let mountain: Mountain
    let data: MountainBatchedResponse

    private var liftStatusColor: Color {
        guard let liftStatus = data.conditions.liftStatus else { return .gray }
        let percentage = Double(liftStatus.liftsOpen) / Double(liftStatus.liftsTotal)

        if percentage > 0.75 { return .green }
        if percentage > 0.5 { return .yellow }
        if percentage > 0 { return .orange }
        return .gray
    }

    private var liftStatusPercentage: Int {
        guard let liftStatus = data.conditions.liftStatus else { return 0 }
        return Int((Double(liftStatus.liftsOpen) / Double(liftStatus.liftsTotal)) * 100)
    }

    var body: some View {
        NavigationLink {
            LocationView(mountain: mountain)
        } label: {
            VStack(spacing: .spacingM) {
                // Mountain logo
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 40
                )

                // Mountain name
                Text(mountain.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Lift status badge
                HStack(spacing: .spacingXS) {
                    Circle()
                        .fill(liftStatusColor)
                        .frame(width: 8, height: 8)

                    Text("\(liftStatusPercentage)%")
                        .badge()
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, .spacingS)
                .padding(.vertical, .spacingXS)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())

                // Fresh snow badge
                if data.conditions.snowfall24h > 0 {
                    HStack(spacing: .spacingXS) {
                        Image(systemName: "snowflake")
                            .font(.caption2)

                        Text("\(Int(data.conditions.snowfall24h))\"")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                }

                // Last updated
                Text(formatLastUpdated(data.cachedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, .spacingM)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
        .buttonStyle(.plain)
    }

    private func formatLastUpdated(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "Recently" }

        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - Preview

#Preview {
    Text("Preview temporarily disabled")
        .padding()
}
