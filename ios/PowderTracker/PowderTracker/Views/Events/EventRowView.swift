//
//  EventRowView.swift
//  PowderTracker
//
//  A clean, modern event row card for the events list.
//

import SwiftUI

/// Event row card displaying key information in a compact format
struct EventRowView: View {
    let event: Event

    @State private var showingShareSheet = false
    @State private var showingMessageCompose = false

    var body: some View {
        HStack(alignment: .top, spacing: .spacingM) {
            // Date Badge
            EventDateBadge(dateString: event.eventDate)

            // Event Details
            VStack(alignment: .leading, spacing: .spacingS) {
                // Title row with badges
                titleRow

                // Mountain & Time
                mountainTimeRow

                // Departure location
                if let location = event.departureLocation, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(EventCardStyle.secondaryText)
                        .lineLimit(1)
                }

                // Bottom row: Attendees, Carpool, RSVP
                bottomRow
            }
        }
        .eventCardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details")
        .contextMenu { contextMenuItems }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url, shareMessage])
            }
        }
        .messageComposeSheet(
            isPresented: $showingMessageCompose,
            body: messageComposeBody
        )
    }

    // MARK: - Subviews

    private var titleRow: some View {
        HStack(alignment: .top) {
            Text(event.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(EventCardStyle.primaryText)
                .lineLimit(2)

            Spacer(minLength: .spacingS)

            // Badges
            HStack(spacing: .spacingXS) {
                if event.isCreator == true {
                    HostBadge()
                }

                if let level = event.skillLevel {
                    SkillLevelBadge(level: level, size: .compact)
                }
            }
        }
    }

    private var mountainTimeRow: some View {
        HStack(spacing: .spacingS) {
            Label(event.mountainName ?? event.mountainId, systemImage: "mountain.2")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(EventCardStyle.mountainIconColor)

            if let time = event.formattedTime {
                Text("•")
                    .foregroundStyle(EventCardStyle.tertiaryText)
                Label(time, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(EventCardStyle.secondaryText)
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: .spacingM) {
            // Attendees
            attendeeInfo

            // Carpool badge
            if event.carpoolAvailable {
                CarpoolBadge(seats: event.carpoolSeats, size: .compact)
            }

            Spacer()

            // RSVP Status
            if let status = event.userRSVPStatus {
                RSVPStatusBadge(status: status, size: .compact)
            }
        }
    }

    private var attendeeInfo: some View {
        HStack(spacing: .spacingXS) {
            Label("\(event.goingCount) going", systemImage: "person.2.fill")
                .font(.caption)
                .foregroundStyle(EventCardStyle.secondaryText)

            if event.maybeCount > 0 {
                Text("+\(event.maybeCount) maybe")
                    .font(.caption)
                    .foregroundStyle(EventCardStyle.tertiaryText)
            }
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            showingShareSheet = true
        } label: {
            Label("Share Event", systemImage: "square.and.arrow.up")
        }

        Button {
            copyEventLink()
        } label: {
            Label("Copy Link", systemImage: "doc.on.doc")
        }

        Button {
            showingMessageCompose = true
        } label: {
            Label("Send via iMessage", systemImage: "message.fill")
        }
    }

    // MARK: - Sharing

    private var shareURL: URL? {
        URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))/events/\(event.id)")
    }

    private var shareMessage: String {
        """
        Join me skiing at \(event.mountainName ?? event.mountainId)!

        \(event.title)
        \(event.formattedDate)
        \(event.formattedTime.map { "Departing \($0)" } ?? "")
        \(event.goingCount) people going
        """
    }

    private var messageComposeBody: String {
        guard let url = shareURL else { return shareMessage }
        return "\(shareMessage)\n\n\(url.absoluteString)"
    }

    private func copyEventLink() {
        if let url = shareURL {
            UIPasteboard.general.url = url
            HapticFeedback.success.trigger()
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts = [
            event.title,
            "at \(event.mountainName ?? event.mountainId)",
            event.formattedDate
        ]

        if let time = event.formattedTime {
            parts.append("departing at \(time)")
        }

        parts.append("\(event.goingCount) people going")

        if event.maybeCount > 0 {
            parts.append("\(event.maybeCount) maybe")
        }

        if let level = event.skillLevel {
            parts.append("Skill level \(level.displayName)")
        }

        if event.carpoolAvailable {
            parts.append("Carpool available")
        }

        if event.isCreator == true {
            parts.append("You're the organizer")
        }

        if let status = event.userRSVPStatus {
            parts.append(status == .going ? "You're going" : "You said maybe")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("Event Row") {
    ScrollView {
        VStack(spacing: 16) {
            // These would use mock data in a real preview
            Text("Event rows would appear here")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
