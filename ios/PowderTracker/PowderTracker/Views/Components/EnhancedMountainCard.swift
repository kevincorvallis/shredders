import SwiftUI

struct EnhancedMountainCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: MountainPowderScore?
    let arrivalTime: ArrivalTimeRecommendation?
    let alerts: [WeatherAlert]?
    let roads: RoadsResponse?
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header with logo, badges, and favorite
            headerSection

            // Live stats section
            statsSection

            // Quick info pills
            infoPillsSection
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusHero))
        .adaptiveShadow(colorScheme: colorScheme, radius: 8, y: 4)
        .accessibleCard(
            label: accessibilityLabel,
            hint: "Double tap to view mountain details"
        )
    }

    private var accessibilityLabel: String {
        var components: [String] = [mountain.shortName]

        if let score = powderScore?.score {
            components.append("Powder score \(Int(score)) out of 10")
        }

        if let snowfall = conditions?.snowfall24h, snowfall > 0 {
            components.append("\(Int(snowfall)) inches fresh snow")
        }

        if let temp = conditions?.temperature {
            components.append("\(Int(temp)) degrees")
        }

        return components.joined(separator: ", ")
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .topTrailing) {
            // Logo background
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 80
            )
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: mountain.color)?.opacity(0.2) ?? .blue.opacity(0.2),
                        Color(hex: mountain.color)?.opacity(0.05) ?? .blue.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            VStack(alignment: .trailing, spacing: 8) {
                // Favorite button with haptic feedback and bounce animation
                Button {
                    HapticFeedback.medium.trigger()
                    onFavoriteToggle()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(isFavorite ? .yellow : .white)
                        .symbolEffect(.bounce, value: isFavorite)
                        .shadow(radius: 2)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibleButton(
                    label: isFavorite ? "Remove from favorites" : "Add to favorites",
                    hint: "Double tap to toggle favorite status"
                )

                // Live status badges
                statusBadges
            }
        }
    }

    // MARK: - Status Badges

    @ViewBuilder
    private var statusBadges: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Fresh powder badge
            if let snowfall = conditions?.snowfall24h, snowfall >= 6 {
                Badge(
                    icon: "snow",
                    text: "\(Int(snowfall))\" fresh",
                    color: .green
                )
            }

            // Chains required badge
            if let passes = roads?.passes,
               passes.contains(where: { pass in
                   pass.restrictions.contains(where: { $0.text.lowercased().contains("chain") })
               }) {
                Badge(
                    icon: "link",
                    text: "Chains",
                    color: .orange
                )
            }

            // Alert active badge
            if let alerts = alerts, !alerts.isEmpty {
                Badge(
                    icon: "exclamationmark.triangle.fill",
                    text: "\(alerts.count)",
                    color: .red
                )
            }

            // Leave now badge
            if shouldShowLeaveNowBadge {
                Badge(
                    icon: "clock.fill",
                    text: "Leave Now",
                    color: .blue,
                    animated: true
                )
            }
        }
        .padding(8)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name and region
            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.shortName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(mountain.region.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(.cornerRadiusTiny)
            }

            Divider()
                .padding(.vertical, 4)

            // Key stats grid
            HStack(spacing: 16) {
                // Powder score
                if let score = powderScore?.score {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("POWDER")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(scoreColor(Double(score)))
                                .frame(width: 8, height: 8)

                            Text("\(score)/10")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(Double(score)))
                        }
                    }
                }

                Spacer()

                // Arrival time
                if let arrivalTime = arrivalTime {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ARRIVE BY")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(arrivalTime.recommendedArrivalTime)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(12)
    }

    // MARK: - Info Pills

    private var infoPillsSection: some View {
        HStack(spacing: 8) {
            // Fresh snow amount
            if let snowfall = conditions?.snowfall24h, snowfall > 0 {
                InfoPill(
                    icon: "snow",
                    text: "\(Int(snowfall))\" 24h"
                )
            }

            // Temperature
            if let temp = conditions?.temperature {
                InfoPill(
                    icon: "thermometer.medium",
                    text: "\(Int(temp))°F"
                )
            }

            // Base depth
            if let base = conditions?.snowDepth {
                InfoPill(
                    icon: "mountain.2.fill",
                    text: "\(Int(base))\" base"
                )
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Helpers

    private var shouldShowLeaveNowBadge: Bool {
        guard let arrivalTime = arrivalTime else { return false }

        // Parse arrival time and check if we're in the "leave now" window
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        guard let targetTime = formatter.date(from: arrivalTime.recommendedArrivalTime) else {
            return false
        }

        let now = Date()
        let calendar = Calendar.current

        // Compare just the time components
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetTime)

        guard let nowHour = nowComponents.hour, let nowMinute = nowComponents.minute,
              let targetHour = targetComponents.hour, let targetMinute = targetComponents.minute else {
            return false
        }

        let nowMinutes = nowHour * 60 + nowMinute
        let targetMinutes = targetHour * 60 + targetMinute

        // Show "Leave Now" if we're within 60 minutes of optimal arrival time
        return targetMinutes - nowMinutes <= 60 && targetMinutes - nowMinutes >= 0
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        if score >= 3 { return .orange }
        return .red
    }
}

// MARK: - Supporting Views

struct Badge: View {
    let icon: String
    let text: String
    let color: Color
    var animated: Bool = false

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color)
                .shadow(color: color.opacity(0.5), radius: 4)
        )
        .scaleEffect(animated && pulse ? 1.05 : 1.0)
        .animation(
            animated ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
            value: pulse
        )
        .onAppear {
            if animated {
                pulse = true
            }
        }
    }
}

struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}
