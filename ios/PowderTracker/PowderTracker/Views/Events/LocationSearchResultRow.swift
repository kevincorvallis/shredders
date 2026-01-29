//
//  LocationSearchResultRow.swift
//  PowderTracker
//
//  A row component for displaying location search results
//

import SwiftUI
import MapKit

struct LocationSearchResultRow: View {
    let completion: MKLocalSearchCompletion

    var body: some View {
        HStack(spacing: 12) {
            // Location icon
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.12))
                )

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(completion.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Icon Helpers

    private var iconName: String {
        // Try to determine icon based on result type
        let title = completion.title.lowercased()
        let subtitle = completion.subtitle.lowercased()

        if title.contains("park") || subtitle.contains("park") {
            return "leaf.fill"
        } else if title.contains("coffee") || title.contains("cafe") || title.contains("starbucks") {
            return "cup.and.saucer.fill"
        } else if title.contains("gas") || title.contains("shell") || title.contains("chevron") {
            return "fuelpump.fill"
        } else if title.contains("parking") {
            return "p.circle.fill"
        } else if title.contains("transit") || title.contains("station") || title.contains("metro") {
            return "tram.fill"
        } else if subtitle.contains("search nearby") {
            return "magnifyingglass"
        } else {
            return "mappin.circle.fill"
        }
    }

    private var iconColor: Color {
        let title = completion.title.lowercased()

        if title.contains("park") {
            return .green
        } else if title.contains("coffee") || title.contains("cafe") {
            return .brown
        } else if title.contains("gas") {
            return .orange
        } else if title.contains("parking") {
            return .blue
        } else if title.contains("transit") || title.contains("station") {
            return .purple
        } else {
            return .red
        }
    }
}

#Preview {
    List {
        LocationSearchResultRow(
            completion: PreviewMKLocalSearchCompletion(
                title: "Starbucks",
                subtitle: "123 Main St, Seattle, WA"
            )
        )
        LocationSearchResultRow(
            completion: PreviewMKLocalSearchCompletion(
                title: "REI Seattle Flagship",
                subtitle: "222 Yale Ave N, Seattle, WA"
            )
        )
        LocationSearchResultRow(
            completion: PreviewMKLocalSearchCompletion(
                title: "Gas Works Park",
                subtitle: "2101 N Northlake Way, Seattle, WA"
            )
        )
    }
}

// Preview helper
private class PreviewMKLocalSearchCompletion: MKLocalSearchCompletion {
    private let _title: String
    private let _subtitle: String

    init(title: String, subtitle: String) {
        self._title = title
        self._subtitle = subtitle
        super.init()
    }

    override var title: String { _title }
    override var subtitle: String { _subtitle }
}
