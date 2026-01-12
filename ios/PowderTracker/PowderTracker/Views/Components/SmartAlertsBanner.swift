//
//  SmartAlertsBanner.swift
//  PowderTracker
//
//  Smart alerts banner showing urgent notifications
//

import SwiftUI

// MARK: - Smart Alerts Banner

struct SmartAlertsBanner: View {
    let leaveNowMountains: [(mountain: Mountain, arrivalTime: ArrivalTimeRecommendation)]
    let weatherAlerts: [WeatherAlert]

    private var hasAlerts: Bool {
        !leaveNowMountains.isEmpty || !weatherAlerts.isEmpty
    }

    var body: some View {
        if hasAlerts {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacingM) {
                    // Leave Now alerts (red/urgent)
                    ForEach(Array(leaveNowMountains.prefix(2)), id: \.mountain.id) { item in
                        LeaveNowAlertCard(
                            mountain: item.mountain,
                            arrivalTime: item.arrivalTime
                        )
                    }

                    // Weather alerts (orange/warning)
                    ForEach(Array(weatherAlerts.prefix(2)), id: \.id) { alert in
                        WeatherAlertBannerCard(alert: alert)
                    }
                }
                .padding(.horizontal, .spacingL)
            }
            .frame(height: 100)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Leave Now Alert Card

struct LeaveNowAlertCard: View {
    let mountain: Mountain
    let arrivalTime: ArrivalTimeRecommendation

    var body: some View {
        HStack(spacing: .spacingM) {
            // Clock icon with pulse animation
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .symbolEffect(.pulse)

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text("Leave Now")
                    .badge()
                    .foregroundStyle(.white.opacity(0.9))

                Text(mountain.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("Arrive \(arrivalTime.arrivalWindow.optimal)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            // Get Directions button
            Button {
                openMapsDirections(to: mountain)
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(.spacingM)
        .frame(width: 280)
        .background(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(.cornerRadiusCard)
        .cardShadow()
    }

    private func openMapsDirections(to mountain: Mountain) {
        // Open Apple Maps with directions
        let lat = mountain.location.lat
        let lng = mountain.location.lng
        if let url = URL(string: "maps://?daddr=\(lat),\(lng)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Weather Alert Banner Card

struct WeatherAlertBannerCard: View {
    let alert: WeatherAlert

    private var severityColor: Color {
        switch alert.severity.lowercased() {
        case "extreme": return .red
        case "severe": return .orange
        case "moderate": return .yellow
        default: return .blue
        }
    }

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack(spacing: .spacingS) {
                    Text(alert.severity.uppercased())
                        .badge()
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.3))
                        .clipShape(Capsule())

                    Spacer()
                }

                Text(alert.event)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let expires = alert.expires {
                    Text("Until \(formatExpiry(expires))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Spacer()
        }
        .padding(.spacingM)
        .frame(width: 280)
        .background(severityColor.gradient)
        .cornerRadius(.cornerRadiusCard)
        .cardShadow()
    }

    private func formatExpiry(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h a"
        return displayFormatter.string(from: date)
    }
}

// MARK: - Smart Suggestion Card

struct SmartSuggestionCard: View {
    let suggestion: String

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text("Smart Tip")
                    .badge()
                    .foregroundStyle(.white.opacity(0.9))

                Text(suggestion)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.spacingM)
        .frame(width: 280)
        .background(
            LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(.cornerRadiusCard)
        .cardShadow()
    }
}

// MARK: - Previews

#Preview {
    Text("Previews temporarily disabled")
        .padding()
}
