import SwiftUI

/// Card-style empty state for inline sections
struct CardEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .symbolEffect(.pulse.byLayer, options: .repeating)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.glassmorphic)
                .padding(.top, .spacingS)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingXL)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Preview

#Preview {
    CardEmptyStateView(
        icon: "calendar",
        title: "No Forecast Data",
        message: "Add mountains to your favorites to see forecast"
    )
    .padding()
}
