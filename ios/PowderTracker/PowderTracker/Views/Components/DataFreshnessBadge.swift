import SwiftUI

/// Shows data source + last updated time
/// Used to indicate how fresh the displayed data is
struct DataFreshnessBadge: View {
    let lastUpdated: Date?
    let sources: [DataSource]

    enum DataSource: String {
        case snotel = "SNOTEL"
        case noaa = "NOAA"
        case liftStatus = "Resort"
        case wsdot = "WSDOT"

        var icon: String {
            switch self {
            case .snotel: return "antenna.radiowaves.left.and.right"
            case .noaa: return "cloud.sun.fill"
            case .liftStatus: return "cablecar.fill"
            case .wsdot: return "car.fill"
            }
        }

        var color: Color {
            switch self {
            case .snotel: return .blue
            case .noaa: return .orange
            case .liftStatus: return .green
            case .wsdot: return .purple
            }
        }
    }

    private var freshnessText: String {
        guard let lastUpdated = lastUpdated else {
            return "Unknown"
        }

        let now = Date()
        let interval = now.timeIntervalSince(lastUpdated)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    private var freshnessColor: Color {
        guard let lastUpdated = lastUpdated else {
            return .secondary
        }

        let interval = Date().timeIntervalSince(lastUpdated)

        if interval < 1800 { // Less than 30 minutes
            return .green
        } else if interval < 3600 { // Less than 1 hour
            return .yellow
        } else if interval < 7200 { // Less than 2 hours
            return .orange
        } else {
            return .secondary
        }
    }

    var body: some View {
        HStack(spacing: .spacingXS) {
            // Status dot
            Circle()
                .fill(freshnessColor)
                .frame(width: .statusDotSize, height: .statusDotSize)

            // Last updated time
            Text(freshnessText)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Data sources
            if !sources.isEmpty {
                Text("•")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))

                HStack(spacing: 4) {
                    ForEach(sources.prefix(3), id: \.rawValue) { source in
                        Image(systemName: source.icon)
                            .font(.system(size: 10))
                            .foregroundColor(source.color)
                    }
                }
            }
        }
    }
}

// MARK: - Inline Data Freshness (for cards)

struct InlineDataFreshness: View {
    let lastUpdated: Date?
    let isLive: Bool

    private var freshnessText: String {
        guard let lastUpdated = lastUpdated else {
            return "Unknown"
        }

        let now = Date()
        let interval = now.timeIntervalSince(lastUpdated)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if isLive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(freshnessText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Data Source Pills

struct DataSourcePill: View {
    let source: DataFreshnessBadge.DataSource

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: source.icon)
                .font(.system(size: 10))
            Text(source.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(source.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(source.color.opacity(0.12))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Standard badge
        DataFreshnessBadge(
            lastUpdated: Date().addingTimeInterval(-300),
            sources: [.snotel, .noaa]
        )

        // Stale data
        DataFreshnessBadge(
            lastUpdated: Date().addingTimeInterval(-7200),
            sources: [.noaa]
        )

        // Unknown
        DataFreshnessBadge(
            lastUpdated: nil,
            sources: []
        )

        Divider()

        // Inline freshness
        HStack {
            InlineDataFreshness(lastUpdated: Date(), isLive: true)
            Spacer()
            InlineDataFreshness(lastUpdated: Date().addingTimeInterval(-1800), isLive: false)
        }
        .padding()

        Divider()

        // Data source pills
        HStack {
            DataSourcePill(source: .snotel)
            DataSourcePill(source: .noaa)
            DataSourcePill(source: .liftStatus)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
