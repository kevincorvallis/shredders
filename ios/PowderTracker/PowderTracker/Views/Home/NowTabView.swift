//
//  NowTabView.swift
//  PowderTracker
//
//  Now tab - Urgency-focused real-time information
//

import SwiftUI

struct NowTabView: View {
    var viewModel: HomeViewModel
    @StateObject private var favoritesManager = FavoritesService.shared

    var body: some View {
        LazyVStack(spacing: 20) {
            if favoritesManager.favoriteIds.isEmpty {
                emptyState
            } else {
                // Section 0: Storm Mode Banner (if active storm)
                if let stormAlert = viewModel.getMostSignificantStorm() {
                    stormModeSection(alert: stormAlert)
                }

                // Section 1: Leave Now Cards (if any)
                if !viewModel.getLeaveNowMountains().isEmpty {
                    leaveNowSection
                }

                // Section 2: Live Status Grid
                liveStatusGrid

                // Section 3: Active Weather Alerts (non-storm alerts)
                let nonStormAlerts = viewModel.getActiveAlerts().filter { !$0.isPowderBoostEvent }
                if !nonStormAlerts.isEmpty {
                    weatherAlertsSection(alerts: nonStormAlerts)
                }

                // Empty state if no urgent content
                if viewModel.getMostSignificantStorm() == nil &&
                   viewModel.getLeaveNowMountains().isEmpty &&
                   viewModel.getActiveAlerts().isEmpty {
                    noUrgentUpdates
                }
            }
        }
        .padding()
    }

    private var leaveNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leave Soon")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(viewModel.getLeaveNowMountains(), id: \.mountain.id) { item in
                LeaveNowCard(
                    mountain: item.mountain,
                    arrivalTime: item.arrivalTime
                )
            }
        }
    }

    private var liveStatusGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Status")
                .font(.headline)
                .padding(.horizontal, 4)

            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.getFavoriteMountains(), id: \.mountain.id) { item in
                    LiveStatusCard(
                        mountain: item.mountain,
                        data: item.data
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func stormModeSection(alert: WeatherAlert) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Storm Alert")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 4)

            // Find the mountain and powder score with storm info
            if let stormData = findStormDataForAlert(alert) {
                StormModeBanner(
                    stormInfo: stormData.stormInfo,
                    mountainName: stormData.mountainName
                )
            } else {
                // Fallback to basic alert row if no storm info available
                WeatherAlertRowView(alert: alert)
            }
        }
    }

    /// Find storm info from powder scores that matches this alert
    private func findStormDataForAlert(_ alert: WeatherAlert) -> (stormInfo: StormInfo, mountainName: String)? {
        for (_, data) in viewModel.mountainData {
            if let stormInfo = data.powderScore.stormInfo,
               stormInfo.isActive,
               stormInfo.eventType?.lowercased() == alert.event.lowercased() {
                return (stormInfo, data.mountain.name)
            }
        }
        // If no exact match, try to find any active storm
        for (_, data) in viewModel.mountainData {
            if let stormInfo = data.powderScore.stormInfo, stormInfo.isActive {
                return (stormInfo, data.mountain.name)
            }
        }
        return nil
    }

    private func weatherAlertsSection(alerts: [WeatherAlert]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Alerts")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(alerts) { alert in
                WeatherAlertRowView(alert: alert)
            }
        }
    }

    private var noUrgentUpdates: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("No urgent updates")
                .font(.headline)

            Text("Check the Today tab for current conditions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add mountains to see live status updates")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Weather Alert Row

struct WeatherAlertRowView: View {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(severityColor)

                Text(alert.event)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(alert.severity.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor)
                    .clipShape(Capsule())
            }

            Text(alert.headline)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let expires = alert.expires {
                Text("Until \(formatExpiry(expires))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatExpiry(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    Text("Preview temporarily disabled")
        .padding()
}
