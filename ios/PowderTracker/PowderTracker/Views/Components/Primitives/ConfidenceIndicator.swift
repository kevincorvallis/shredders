import SwiftUI

/// A reusable confidence indicator component
/// Consolidates confidence display from: ArrivalTimeCard, ParkingCard, LeaveNowCard, QuickArrivalTimeBanner
struct ConfidenceIndicator: View {
    enum Style {
        case badge      // Pill with colored background
        case dot        // Small colored circle
        case bar        // Progress bar style
    }

    let confidence: String // "high", "medium", "low"
    var style: Style = .badge
    var showIcon: Bool = true
    var showText: Bool = true

    var body: some View {
        Group {
            switch style {
            case .badge:
                badgeStyle
            case .dot:
                dotStyle
            case .bar:
                barStyle
            }
        }
    }

    // MARK: - Style Variants

    private var badgeStyle: some View {
        HStack(spacing: .spacingXS) {
            if showIcon {
                Image(systemName: confidenceIcon)
                    .font(.caption)
            }
            if showText {
                Text(confidenceText)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(confidenceColor)
        .padding(.horizontal, .spacingS)
        .padding(.vertical, .spacingXS)
        .background(
            Capsule()
                .fill(confidenceColor.opacity(.opacityMedium))
        )
    }

    private var dotStyle: some View {
        HStack(spacing: .spacingXS) {
            Circle()
                .fill(confidenceColor)
                .frame(width: .statusDotSize, height: .statusDotSize)

            if showText {
                Text(confidenceText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceColor)
            }
        }
    }

    private var barStyle: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            if showText {
                Text(confidenceText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: .cornerRadiusMicro)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)

                    // Filled portion
                    RoundedRectangle(cornerRadius: .cornerRadiusMicro)
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * confidencePercentage, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Helpers

    private var confidenceColor: Color {
        Color.forConfidenceLevel(confidence)
    }

    private var confidenceIcon: String {
        switch confidence.lowercased() {
        case "high":
            return "checkmark.circle.fill"
        case "medium":
            return "exclamationmark.circle.fill"
        case "low":
            return "questionmark.circle.fill"
        default:
            return "circle.fill"
        }
    }

    private var confidenceText: String {
        confidence.capitalized
    }

    private var confidencePercentage: CGFloat {
        switch confidence.lowercased() {
        case "high":
            return 1.0
        case "medium":
            return 0.65
        case "low":
            return 0.33
        default:
            return 0.5
        }
    }
}

// MARK: - Preview

#Preview("Confidence Styles") {
    VStack(spacing: .spacingXL) {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Badge Style")
                .font(.headline)

            HStack(spacing: .spacingM) {
                ConfidenceIndicator(
                    confidence: "high",
                    style: .badge
                )

                ConfidenceIndicator(
                    confidence: "medium",
                    style: .badge
                )

                ConfidenceIndicator(
                    confidence: "low",
                    style: .badge
                )
            }
        }

        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Dot Style")
                .font(.headline)

            VStack(alignment: .leading, spacing: .spacingS) {
                ConfidenceIndicator(
                    confidence: "high",
                    style: .dot
                )

                ConfidenceIndicator(
                    confidence: "medium",
                    style: .dot
                )

                ConfidenceIndicator(
                    confidence: "low",
                    style: .dot
                )
            }
        }

        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Bar Style")
                .font(.headline)

            VStack(spacing: .spacingM) {
                ConfidenceIndicator(
                    confidence: "high",
                    style: .bar
                )
                .frame(height: 30)

                ConfidenceIndicator(
                    confidence: "medium",
                    style: .bar
                )
                .frame(height: 30)

                ConfidenceIndicator(
                    confidence: "low",
                    style: .bar
                )
                .frame(height: 30)
            }
        }

        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Icon Only")
                .font(.headline)

            HStack(spacing: .spacingM) {
                ConfidenceIndicator(
                    confidence: "high",
                    style: .badge,
                    showIcon: true,
                    showText: false
                )

                ConfidenceIndicator(
                    confidence: "medium",
                    style: .badge,
                    showIcon: true,
                    showText: false
                )

                ConfidenceIndicator(
                    confidence: "low",
                    style: .badge,
                    showIcon: true,
                    showText: false
                )
            }
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
