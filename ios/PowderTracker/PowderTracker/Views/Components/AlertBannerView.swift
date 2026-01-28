import SwiftUI

/// Dismissible alert banner with severity-based gradient (orange/red)
/// Used to display weather alerts and important notifications
struct AlertBannerView: View {
    let alerts: [WeatherAlert]
    @Binding var isDismissed: Bool

    /// Severity level determines gradient colors
    enum Severity {
        case warning   // Orange gradient
        case severe    // Red gradient
        case watch     // Yellow gradient

        var gradient: LinearGradient {
            switch self {
            case .warning:
                return LinearGradient(
                    colors: [Color.orange, Color.orange.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .severe:
                return LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .watch:
                return LinearGradient(
                    colors: [Color.yellow, Color.yellow.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        var iconName: String {
            switch self {
            case .warning: return "exclamationmark.triangle.fill"
            case .severe: return "exclamationmark.octagon.fill"
            case .watch: return "eye.fill"
            }
        }

        var textColor: Color {
            switch self {
            case .warning, .severe: return .white
            case .watch: return .black
            }
        }
    }

    private var severity: Severity {
        // Check the most severe alert
        for alert in alerts {
            let severityLower = alert.severity.lowercased()
            if severityLower.contains("extreme") || severityLower.contains("severe") {
                return .severe
            }
        }
        for alert in alerts {
            let severityLower = alert.severity.lowercased()
            if severityLower.contains("moderate") || severityLower.contains("warning") {
                return .warning
            }
        }
        return .watch
    }

    private var primaryAlert: WeatherAlert? {
        // Return the most important alert (first one or most severe)
        alerts.first
    }

    var body: some View {
        if !isDismissed && !alerts.isEmpty {
            VStack(spacing: 0) {
                HStack(spacing: .spacingS) {
                    // Alert icon
                    Image(systemName: severity.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(severity.textColor)

                    // Alert content
                    VStack(alignment: .leading, spacing: 2) {
                        if let alert = primaryAlert {
                            Text(alert.event)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(severity.textColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(alert.headline)
                                .font(.caption)
                                .foregroundColor(severity.textColor.opacity(0.9))
                                .lineLimit(3)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()

                    // Alert count badge if multiple
                    if alerts.count > 1 {
                        Text("+\(alerts.count - 1)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(severity.textColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(severity.textColor.opacity(0.2))
                            )
                    }

                    // Dismiss button
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isDismissed = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(severity.textColor.opacity(0.8))
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
            }
            .background(severity.gradient)
            .cornerRadius(.cornerRadiusCard)
            .cardShadow()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(alertAccessibilityLabel)
            .accessibilityHint("Double tap to view alert details. Swipe right to dismiss.")
        }
    }

    private var alertAccessibilityLabel: String {
        guard let alert = primaryAlert else { return "Weather alert" }
        var label = "\(severity == .severe ? "Severe" : severity == .warning ? "Warning" : "Watch") alert. \(alert.event). \(alert.headline)"
        if alerts.count > 1 {
            label += " Plus \(alerts.count - 1) more alerts."
        }
        return label
    }
}

// MARK: - Compact Alert Banner (for cards)

struct CompactAlertBadge: View {
    let alertCount: Int

    var body: some View {
        if alertCount > 0 {
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                Text("\(alertCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.orange)
            )
            .accessibilityLabel("\(alertCount) active weather alert\(alertCount == 1 ? "" : "s")")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Severe alert
        AlertBannerView(
            alerts: [
                WeatherAlert(
                    id: "1",
                    event: "Winter Storm Warning",
                    headline: "Heavy snow expected. 12-18 inches possible above 4000 ft.",
                    severity: "Severe",
                    urgency: "Immediate",
                    certainty: "Likely",
                    onset: nil,
                    expires: nil,
                    description: "A winter storm will bring heavy snow to the mountains.",
                    instruction: "Be prepared for winter driving conditions.",
                    areaDesc: "Cascade Mountains"
                )
            ],
            isDismissed: .constant(false)
        )

        // Multiple alerts
        AlertBannerView(
            alerts: [
                WeatherAlert(
                    id: "1",
                    event: "Wind Advisory",
                    headline: "Gusty winds expected. 30-40 mph gusts possible.",
                    severity: "Moderate",
                    urgency: "Expected",
                    certainty: "Likely",
                    onset: nil,
                    expires: nil,
                    description: "Strong winds expected.",
                    instruction: nil,
                    areaDesc: "Cascade Mountains"
                ),
                WeatherAlert(
                    id: "2",
                    event: "Avalanche Watch",
                    headline: "Considerable avalanche danger above treeline.",
                    severity: "Moderate",
                    urgency: "Expected",
                    certainty: "Possible",
                    onset: nil,
                    expires: nil,
                    description: "Avalanche conditions.",
                    instruction: nil,
                    areaDesc: "Cascade Mountains"
                )
            ],
            isDismissed: .constant(false)
        )

        // Compact badge
        HStack {
            Text("Alert badge:")
            CompactAlertBadge(alertCount: 2)
        }

        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
