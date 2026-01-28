import SwiftUI

/// Legend view for map overlays
struct MapLegendView: View {
    let overlay: MapOverlayType

    var body: some View {
        if let legend = overlay.legend {
            HStack(spacing: .spacingS) {
                Text(legend.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Color gradient bar
                HStack(spacing: 0) {
                    ForEach(Array(legend.items.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(item.color)
                                .frame(width: legendItemWidth(for: legend.items.count), height: 8)

                            Text(item.label)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.spacingS)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground).opacity(0.9))
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

    private func legendItemWidth(for count: Int) -> CGFloat {
        max(30, 180 / CGFloat(count))
    }
}

/// Expanded legend with more detail
struct ExpandedLegendView: View {
    let overlay: MapOverlayType
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(overlay.icon)
                        .font(.body)
                    Text(overlay.fullName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded, let legend = overlay.legend {
                Divider()

                VStack(alignment: .leading, spacing: .spacingXS) {
                    ForEach(Array(legend.items.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: .spacingS) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(item.color)
                                .frame(width: 20, height: 12)

                            Text(item.label)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

/// Floating legend for map overlay
struct FloatingLegend: View {
    let overlay: MapOverlayType

    var body: some View {
        if let legend = overlay.legend {
            VStack(alignment: .leading, spacing: 4) {
                Text(legend.title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                // Gradient bar with labels
                HStack(spacing: 0) {
                    ForEach(Array(legend.items.enumerated()), id: \.offset) { _, item in
                        Rectangle()
                            .fill(item.color)
                            .frame(height: 8)
                    }
                }
                .cornerRadius(.cornerRadiusTiny / 2)

                // Labels
                HStack {
                    ForEach(Array(legend.items.enumerated()), id: \.offset) { index, item in
                        if index == 0 || index == legend.items.count - 1 || index == legend.items.count / 2 {
                            Text(item.label)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        if index < legend.items.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(8)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
        }
    }
}

/// Avalanche-specific legend with danger levels
struct AvalancheLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text("Avalanche Danger")
                .font(.caption)
                .fontWeight(.bold)

            HStack(spacing: .spacingS) {
                dangerLevel(color: .green, level: "1", name: "Low")
                dangerLevel(color: .yellow, level: "2", name: "Mod")
                dangerLevel(color: .orange, level: "3", name: "Cons")
                dangerLevel(color: .red, level: "4", name: "High")
                dangerLevel(color: .black, level: "5", name: "Ext")
            }

            Text("Tap zone for details")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.spacingS)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground).opacity(0.95))
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func dangerLevel(color: Color, level: String, name: String) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 24, height: 16)
                .overlay(
                    Text(level)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color == .black || color == .red ? .white : .black)
                )

            Text(name)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        MapLegendView(overlay: .snowfall)

        MapLegendView(overlay: .snowDepth)

        FloatingLegend(overlay: .temperature)

        AvalancheLegend()

        ExpandedLegendView(overlay: .avalanche, isExpanded: .constant(true))
    }
    .padding()
    .background(Color(.systemGray6))
}
