import SwiftUI

/// Full-screen empty state view with icon, title, message, and optional action button
struct TabEmptyStateView<Action: View>: View {
    let icon: String
    let title: String
    let message: String
    @ViewBuilder let action: () -> Action

    init(
        icon: String,
        title: String,
        message: String,
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
    }

    var body: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingXL)

            action()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingXXL * 2.5)
    }
}

// MARK: - Preview

#Preview {
    TabEmptyStateView(
        icon: "star.slash",
        title: "No Favorites Yet",
        message: "Add mountains to track conditions and snowfall"
    )
}
