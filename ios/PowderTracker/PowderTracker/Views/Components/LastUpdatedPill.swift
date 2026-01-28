import SwiftUI

/// Compact pill showing last updated time
struct LastUpdatedPill: View {
    let date: Date
    let source: String?
    var showIcon: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: "clock")
                    .font(.caption2)
            }

            Text(timeAgoString)
                .font(.caption)

            if let source = source {
                Text("·")
                    .font(.caption)
                Text(source)
                    .font(.caption)
            }
        }
        .foregroundColor(.secondary)
    }

    private var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Last updated pill with freshness indicator dot
struct FreshnessUpdatedPill: View {
    let provenance: DataProvenance

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(provenance.status.color)
                .frame(width: 6, height: 6)

            Text(provenance.timeAgoString)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("·")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(provenance.source)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Timestamp pill with full date/time
struct TimestampPill: View {
    let date: Date
    var format: DateFormat = .relative

    enum DateFormat {
        case relative
        case time
        case dateTime
    }

    var body: some View {
        Text(formattedDate)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(.cornerRadiusButton)
    }

    private var formattedDate: String {
        switch format {
        case .relative:
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        case .time:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        case .dateTime:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        LastUpdatedPill(date: Date().addingTimeInterval(-300), source: "NWS")

        LastUpdatedPill(date: Date().addingTimeInterval(-3600), source: "Baker API", showIcon: true)

        FreshnessUpdatedPill(provenance: .freshMock)

        FreshnessUpdatedPill(provenance: .staleMock)

        HStack {
            TimestampPill(date: Date(), format: .relative)
            TimestampPill(date: Date(), format: .time)
            TimestampPill(date: Date(), format: .dateTime)
        }
    }
    .padding()
}
