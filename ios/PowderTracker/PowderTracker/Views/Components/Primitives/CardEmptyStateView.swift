import SwiftUI

/// Card-style empty state for inline sections
struct CardEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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
