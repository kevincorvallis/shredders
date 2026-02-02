//
//  LastMinuteEventCard.swift
//  PowderTracker
//
//  Card for same-day events with countdown timer and quick join
//

import SwiftUI

struct LastMinuteEventCard: View {
    let event: Event
    let onQuickJoin: () -> Void
    let onTap: () -> Void

    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var pulseAnimation = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Top section with countdown
                HStack {
                    // Mountain & title
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(event.mountainName ?? "Mountain")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            // Urgency badge for critical events
                            if event.urgencyLevel == .critical {
                                Text("URGENT")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.red)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(event.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Countdown badge
                    countdownBadge
                }
                .padding()

                Divider()

                // Bottom section with details and action
                HStack {
                    // Time & attendees
                    HStack(spacing: 12) {
                        if let time = event.formattedTime {
                            Label(time, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Label("\(event.goingCount) going", systemImage: "person.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if event.carpoolAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "car.fill")
                                Text("\(event.carpoolSeats ?? 0) seats")
                            }
                            .font(.caption)
                            .foregroundStyle(.green)
                        }
                    }

                    Spacer()

                    // Share button
                    QuickShareButton(event: event)

                    // Quick join button
                    if event.userRSVPStatus != .going {
                        Button(action: {
                            HapticFeedback.medium.trigger()
                            onQuickJoin()
                        }) {
                            Text("I'm In!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(event.urgencyLevel.color)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Label("Going", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(urgencyBorderColor, lineWidth: borderWidth)
                    .opacity(event.urgencyLevel == .critical ? (pulseAnimation ? 0.3 : 1.0) : 1.0)
            )
            .shadow(color: event.urgencyLevel == .critical ? .red.opacity(0.2) : .clear, radius: pulseAnimation ? 8 : 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(event.userRSVPStatus == .going ? "Double tap to view details" : "Double tap to view details or join")
        .onAppear {
            updateTimeRemaining()
            startTimer()
            if event.urgencyLevel == .critical {
                startPulseAnimation()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: event.urgencyLevel) { _, newValue in
            if newValue == .critical {
                startPulseAnimation()
            }
        }
    }

    // MARK: - Countdown Badge

    @ViewBuilder
    private var countdownBadge: some View {
        if event.urgencyLevel == .departed {
            // Departed badge
            VStack(spacing: 2) {
                Image(systemName: "car.side")
                    .font(.title3)
                Text("Departed")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
        } else if let countdown = formattedCountdown {
            VStack(spacing: 2) {
                Text("Leaving in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(countdown)
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(event.urgencyLevel.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(event.urgencyLevel.color.opacity(0.12))
            .cornerRadius(8)
        }
    }

    /// Format countdown with seconds for critical events
    private var formattedCountdown: String? {
        guard let remaining = event.timeUntilDeparture, remaining > 0 else { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            // Show seconds for critical events
            if event.urgencyLevel == .critical && minutes < 30 {
                return "\(minutes)m \(seconds)s"
            }
            return "\(minutes)m"
        } else if seconds > 0 {
            return "\(seconds)s"
        } else {
            return "Now!"
        }
    }

    // MARK: - Styling

    private var urgencyBorderColor: Color {
        switch event.urgencyLevel {
        case .critical: return .red
        case .soon: return .orange.opacity(0.5)
        default: return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch event.urgencyLevel {
        case .critical: return 2
        case .soon: return 1
        default: return 0
        }
    }

    // MARK: - Timer

    private func updateTimeRemaining() {
        timeRemaining = event.timeUntilDeparture ?? 0
    }

    private func startTimer() {
        // Update more frequently for critical events
        let interval: TimeInterval = event.urgencyLevel == .critical ? 1 : 10
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [self] _ in
            Task { @MainActor in
                updateTimeRemaining()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts = [event.title, "at \(event.mountainName ?? event.mountainId)"]

        // Add countdown or departed status
        if event.urgencyLevel == .departed {
            parts.append("Already departed")
        } else if let countdown = formattedCountdown {
            parts.append("Leaving in \(countdown)")
        }

        // Add attendee count
        parts.append("\(event.goingCount) people going")

        // Add urgency status
        if event.urgencyLevel == .critical {
            parts.append("Urgent, leaving very soon")
        }

        // Add carpool info
        if event.carpoolAvailable {
            parts.append("Carpool available with \(event.carpoolSeats ?? 0) seats")
        }

        // Add RSVP status
        if event.userRSVPStatus == .going {
            parts.append("You're going")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Last Minute Section for EventsView

struct LastMinuteCrewSection: View {
    let events: [Event]
    let onEventTap: (Event) -> Void
    let onQuickJoin: (Event) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Section header
            if !events.isEmpty {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundStyle(.orange)
                    Text("Today's Trips")
                        .font(.headline)
                    Spacer()
                    Text("\(events.count) trip\(events.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            if events.isEmpty {
                emptyState
            } else {
                ForEach(sortedEvents) { event in
                    LastMinuteEventCard(
                        event: event,
                        onQuickJoin: { onQuickJoin(event) },
                        onTap: { onEventTap(event) }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    private var sortedEvents: [Event] {
        // Sort: non-departed first (most urgent), then departed at the end
        events.sorted { event1, event2 in
            // Departed events go last
            if event1.urgencyLevel == .departed && event2.urgencyLevel != .departed {
                return false
            }
            if event1.urgencyLevel != .departed && event2.urgencyLevel == .departed {
                return true
            }
            // Otherwise sort by time remaining
            return (event1.timeUntilDeparture ?? .infinity) < (event2.timeUntilDeparture ?? .infinity)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.skiing.downhill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Last Minute Trips")
                .font(.headline)

            Text("No spontaneous ski trips today.\nBe the first to create one!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            LastMinuteCrewSection(
                events: [],
                onEventTap: { _ in },
                onQuickJoin: { _ in }
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
