import SwiftUI

/// A reusable metric display component that consolidates multiple metric variants
/// Used in: AtAGlanceCard, MountainConditionsCard, MountainStatusIndicator
struct MetricView: View {
    enum Layout {
        case vertical   // Icon on top, centered (default)
        case horizontal // Icon on left, left-aligned
    }

    let icon: String
    let label: String?
    let value: String
    let color: Color
    var layout: Layout = .vertical

    var body: some View {
        Group {
            if layout == .vertical {
                verticalLayout
            } else {
                horizontalLayout
            }
        }
    }

    // MARK: - Layouts

    private var verticalLayout: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if let label = label {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingM)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private var horizontalLayout: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: .iconMedium, height: .iconMedium)

            VStack(alignment: .leading, spacing: .spacingXS) {
                if let label = label {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.spacingM)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Preview

#Preview("Vertical Layout") {
    VStack(spacing: .spacingL) {
        MetricView(
            icon: "snowflake",
            label: "24h Snow",
            value: "12\"",
            color: .blue,
            layout: .vertical
        )

        MetricView(
            icon: "thermometer",
            label: "Temperature",
            value: "28°F",
            color: .cyan,
            layout: .vertical
        )

        MetricView(
            icon: "wind",
            label: "Wind Speed",
            value: "15 mph",
            color: .orange,
            layout: .vertical
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Horizontal Layout") {
    VStack(spacing: .spacingM) {
        MetricView(
            icon: "mountain.2.fill",
            label: "Base Depth",
            value: "120\"",
            color: .blue,
            layout: .horizontal
        )

        MetricView(
            icon: "cablecar.fill",
            label: "Lifts Open",
            value: "12/15",
            color: .green,
            layout: .horizontal
        )

        MetricView(
            icon: "figure.skiing.downhill",
            label: "Runs Open",
            value: "85%",
            color: .green,
            layout: .horizontal
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
