import SwiftUI

/// Generic empty state view with customizable icon, title, message, and actions
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var primaryAction: EmptyStateAction? = nil
    var secondaryAction: EmptyStateAction? = nil

    var body: some View {
        VStack(spacing: .spacingL) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.secondary)

            // Text
            VStack(spacing: .spacingS) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingXL)
            }

            // Actions
            if primaryAction != nil || secondaryAction != nil {
                VStack(spacing: .spacingM) {
                    if let primary = primaryAction {
                        Button(action: primary.action) {
                            Text(primary.title)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if let secondary = secondaryAction {
                        Button(action: secondary.action) {
                            Text(secondary.title)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top, .spacingM)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateAction {
    let title: String
    let action: () -> Void
}

// MARK: - Preset Empty States

/// Empty state for no favorites
struct NoFavoritesEmptyState: View {
    let onBrowse: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "star.slash",
            title: "No favorites yet",
            message: "Add mountains to see personalized forecasts and compare conditions",
            primaryAction: EmptyStateAction(title: "Browse Mountains", action: onBrowse)
        )
    }
}

/// Empty state for no search results
struct NoSearchResultsEmptyState: View {
    var onClearFilters: (() -> Void)? = nil
    var onBrowseAll: (() -> Void)? = nil

    var body: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No mountains found",
            message: "Try a different search or clear filters",
            primaryAction: onClearFilters != nil ? EmptyStateAction(title: "Clear Filters", action: onClearFilters!) : nil,
            secondaryAction: onBrowseAll != nil ? EmptyStateAction(title: "Browse All", action: onBrowseAll!) : nil
        )
    }
}

/// Empty state for no alerts
struct NoAlertsEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All clear!",
            message: "No active alerts for your mountains"
        )
    }
}

/// Empty state for no webcams
struct NoWebcamsEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "video.slash",
            title: "No webcams available",
            message: "This mountain doesn't have any webcam feeds"
        )
    }
}

/// Empty state for no forecast data
struct NoForecastEmptyState: View {
    var onRetry: (() -> Void)? = nil

    var body: some View {
        EmptyStateView(
            icon: "cloud.sun",
            title: "No forecast data",
            message: "Forecast data is temporarily unavailable",
            primaryAction: onRetry != nil ? EmptyStateAction(title: "Retry", action: onRetry!) : nil
        )
    }
}

/// Inline empty state (smaller, for cards)
struct InlineEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.spacingM)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        NoFavoritesEmptyState(onBrowse: {})
            .frame(height: 300)

        NoAlertsEmptyState()
            .frame(height: 200)

        InlineEmptyState(icon: "cloud.sun", message: "No data available")
    }
}
