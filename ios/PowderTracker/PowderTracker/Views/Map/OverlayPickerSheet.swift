import SwiftUI

/// Full overlay picker sheet with all options organized by category
struct OverlayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var overlayState: MapOverlayState

    var body: some View {
        NavigationStack {
            List {
                ForEach(OverlayCategory.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(category.overlays) { overlay in
                            OverlayRow(
                                overlay: overlay,
                                isEnabled: overlayState.activeOverlay == overlay,
                                onToggle: {
                                    overlayState.toggle(overlay)
                                }
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Map Overlays")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Individual overlay row in the picker sheet
struct OverlayRow: View {
    let overlay: MapOverlayType
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: .spacingM) {
                // Icon
                Text(overlay.icon)
                    .font(.title2)
                    .frame(width: 32)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(overlay.fullName)
                            .font(.body)
                            .foregroundColor(.primary)

                        if overlay.isComingSoon {
                            Text("COMING SOON")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(.cornerRadiusTiny)
                        }
                    }

                    Text(overlay.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Toggle indicator
                if overlay.isComingSoon {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Toggle("", isOn: .constant(isEnabled))
                        .labelsHidden()
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(overlay.isComingSoon)
        .opacity(overlay.isComingSoon ? 0.6 : 1)
    }
}

/// Compact overlay toggle for settings
struct OverlayToggle: View {
    let overlay: MapOverlayType
    @Binding var isEnabled: Bool

    var body: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: .spacingS) {
                Text(overlay.icon)
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text(overlay.displayName)
                        .font(.subheadline)
                    Text(overlay.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OverlayPickerSheet(overlayState: MapOverlayState())
}
