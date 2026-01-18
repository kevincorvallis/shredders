import SwiftUI

/// Horizontal scrolling overlay picker bar for map view
struct OverlayPickerBar: View {
    @ObservedObject var overlayState: MapOverlayState
    var onMoreTap: () -> Void

    // Quick access overlays (shown in bar)
    private let quickOverlays: [MapOverlayType] = [
        .snowfall, .snowDepth, .radar, .clouds, .smoke, .avalanche
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacingS) {
                    ForEach(quickOverlays) { overlay in
                        OverlayButton(
                            overlay: overlay,
                            isSelected: overlayState.activeOverlay == overlay,
                            onTap: {
                                overlayState.toggle(overlay)
                            }
                        )
                    }

                    // More button
                    Button(action: onMoreTap) {
                        VStack(spacing: 4) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18))
                            Text("More")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        .frame(width: 60, height: 56)
                    }
                }
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
            }

            Divider()
        }
        .background(Color(.systemBackground))
    }
}

/// Individual overlay button
struct OverlayButton: View {
    let overlay: MapOverlayType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(overlay.icon)
                    .font(.system(size: 20))

                Text(overlay.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)

                // Selection indicator
                if isSelected {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 2)
                        .cornerRadius(1)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 24, height: 2)
                }
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .frame(width: 60, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Compact overlay chip (for inline use)
struct OverlayChip: View {
    let overlay: MapOverlayType
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(overlay.icon)
                    .font(.caption)
                Text(overlay.displayName)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isActive ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(isActive ? .blue : .primary)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        OverlayPickerBar(
            overlayState: MapOverlayState(),
            onMoreTap: {}
        )

        Spacer()

        HStack {
            OverlayChip(overlay: .snowfall, isActive: true, onTap: {})
            OverlayChip(overlay: .radar, isActive: false, onTap: {})
            OverlayChip(overlay: .avalanche, isActive: false, onTap: {})
        }
        .padding()
    }
}
