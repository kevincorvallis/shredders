import SwiftUI

// MARK: - Data Freshness Status

enum DataFreshnessStatus: String, CaseIterable {
    case fresh      // < 15 minutes
    case recent     // 15 min - 1 hour
    case stale      // > 1 hour
    case error      // Failed to load

    var label: String {
        switch self {
        case .fresh: return "FRESH"
        case .recent: return "RECENT"
        case .stale: return "STALE"
        case .error: return "ERROR"
        }
    }

    var color: Color {
        switch self {
        case .fresh: return .green
        case .recent: return .yellow
        case .stale: return .orange
        case .error: return .red
        }
    }

    var backgroundColor: Color {
        switch self {
        case .fresh: return Color.green.opacity(0.15)
        case .recent: return Color.yellow.opacity(0.15)
        case .stale: return Color.orange.opacity(0.15)
        case .error: return Color.red.opacity(0.15)
        }
    }

    var borderColor: Color {
        switch self {
        case .fresh: return Color.green.opacity(0.3)
        case .recent: return Color.yellow.opacity(0.3)
        case .stale: return Color.orange.opacity(0.3)
        case .error: return Color.red.opacity(0.3)
        }
    }

    var icon: String {
        switch self {
        case .fresh: return "checkmark.circle.fill"
        case .recent: return "clock.fill"
        case .stale: return "exclamationmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

// MARK: - Data Provenance

struct DataProvenance {
    let lastUpdated: Date
    let source: String
    let sourceUrl: URL?

    init(lastUpdated: Date, source: String, sourceUrl: URL? = nil) {
        self.lastUpdated = lastUpdated
        self.source = source
        self.sourceUrl = sourceUrl
    }

    init(lastUpdated: Date, source: String, sourceUrlString: String?) {
        self.lastUpdated = lastUpdated
        self.source = source
        self.sourceUrl = sourceUrlString.flatMap { URL(string: $0) }
    }

    var status: DataFreshnessStatus {
        let minutes = Date().timeIntervalSince(lastUpdated) / 60
        if minutes < 15 { return .fresh }
        if minutes < 60 { return .recent }
        return .stale
    }

    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    var fullTimeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    var minutesAgo: Int {
        Int(Date().timeIntervalSince(lastUpdated) / 60)
    }
}

// MARK: - Data Source

enum DataSourceType: String, CaseIterable {
    case snotel = "SNOTEL"
    case noaa = "NOAA"
    case nws = "NWS"
    case liftStatus = "Lift Status"
    case wsdot = "WSDOT"
    case scraped = "Scraped"
    case resortApi = "Resort API"
    case nwac = "NWAC"
    case cached = "Cached"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .snotel: return "snowflake"
        case .noaa, .nws: return "cloud.sun.fill"
        case .liftStatus: return "cablecar.fill"
        case .wsdot: return "car.fill"
        case .scraped: return "globe"
        case .resortApi: return "building.2.fill"
        case .nwac: return "mountain.2.fill"
        case .cached: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Mock Data

extension DataProvenance {
    static let freshMock = DataProvenance(
        lastUpdated: Date().addingTimeInterval(-300), // 5 min ago
        source: "Baker API"
    )

    static let recentMock = DataProvenance(
        lastUpdated: Date().addingTimeInterval(-2700), // 45 min ago
        source: "NWS"
    )

    static let staleMock = DataProvenance(
        lastUpdated: Date().addingTimeInterval(-10800), // 3 hours ago
        source: "Scraped"
    )
}
