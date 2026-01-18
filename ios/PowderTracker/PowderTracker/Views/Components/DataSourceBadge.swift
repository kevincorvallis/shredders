import SwiftUI

/// Full data source badge showing freshness status, time ago, and source
/// Use for detailed data provenance display
struct DataSourceBadge: View {
    let provenance: DataProvenance
    var onRefresh: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: .spacingS) {
            // Status indicator
            HStack(spacing: 4) {
                Image(systemName: provenance.status.icon)
                    .font(.caption2)
                Text(provenance.status.label)
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .foregroundColor(provenance.status.color)

            Divider()
                .frame(height: 12)

            // Time ago
            Text("Updated \(provenance.timeAgoString)")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .frame(height: 12)

            // Source
            Text("Source: \(provenance.source)")
                .font(.caption)
                .foregroundColor(.secondary)

            // Refresh button for stale data
            if provenance.status == .stale || provenance.status == .error, let onRefresh = onRefresh {
                Spacer()

                Button(action: onRefresh) {
                    Text(provenance.status == .error ? "Retry" : "Tap to refresh")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.spacingS)
        .background(provenance.status.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusMicro)
                .stroke(provenance.status.borderColor, lineWidth: 1)
        )
        .cornerRadius(.cornerRadiusMicro)
    }
}

/// Compact inline data source badge
struct InlineDataSourceBadge: View {
    let provenance: DataProvenance

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(provenance.status.color)
                .frame(width: 6, height: 6)

            Text("\(provenance.timeAgoString) · \(provenance.source)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

/// Error state data source badge
struct ErrorDataSourceBadge: View {
    let lastKnownDate: Date?
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: .spacingS) {
            HStack(spacing: .spacingS) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)

                Text("ERROR")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)

                Divider()
                    .frame(height: 12)

                Text("Failed to load")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let lastKnown = lastKnownDate {
                    Divider()
                        .frame(height: 12)

                    Text("Last known: \(timeAgo(from: lastKnown))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let onRetry = onRetry {
                    Button(action: onRetry) {
                        Text("Retry")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.spacingS)
        .background(Color.red.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusMicro)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(.cornerRadiusMicro)
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DataSourceBadge(provenance: .freshMock)

        DataSourceBadge(provenance: .recentMock)

        DataSourceBadge(provenance: .staleMock, onRefresh: {})

        ErrorDataSourceBadge(lastKnownDate: Date().addingTimeInterval(-21600), onRetry: {})

        InlineDataSourceBadge(provenance: .freshMock)
    }
    .padding()
}
