import SwiftUI

/// Generic error state view with retry capability
struct ErrorStateView: View {
    let icon: String
    let title: String
    let message: String
    var cachedDataInfo: String? = nil
    var onRetry: (() -> Void)? = nil
    var onViewCached: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: .spacingL) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.orange)

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
            if onRetry != nil || onViewCached != nil {
                HStack(spacing: .spacingM) {
                    if let onRetry = onRetry {
                        Button(action: onRetry) {
                            Text("Retry")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if let onViewCached = onViewCached {
                        Button(action: onViewCached) {
                            Text("View Cached Data")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top, .spacingM)
            }

            // Cached data info
            if let cachedInfo = cachedDataInfo {
                Divider()
                    .padding(.horizontal, .spacingXL)

                Text(cachedInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Error States

/// Network error state
struct NetworkErrorState: View {
    var cachedDataAge: String? = nil
    var onRetry: (() -> Void)? = nil

    var body: some View {
        ErrorStateView(
            icon: "wifi.exclamationmark",
            title: "Couldn't load data",
            message: "Check your connection and try again",
            cachedDataInfo: cachedDataAge.map { "Showing cached data from \($0)" },
            onRetry: onRetry
        )
    }
}

/// Scrape failed error state
struct ScrapeFailedState: View {
    let sourceName: String
    var lastKnownAge: String? = nil
    var onRetry: (() -> Void)? = nil
    var onViewCached: (() -> Void)? = nil

    var body: some View {
        ErrorStateView(
            icon: "arrow.clockwise.circle",
            title: "Live data temporarily unavailable",
            message: "\(sourceName)'s website may be down. Showing last known conditions.",
            cachedDataInfo: lastKnownAge.map { "Last known: \($0)" },
            onRetry: onRetry,
            onViewCached: onViewCached
        )
    }
}

/// API error state
struct APIErrorState: View {
    var errorMessage: String? = nil
    var onRetry: (() -> Void)? = nil

    var body: some View {
        ErrorStateView(
            icon: "exclamationmark.triangle",
            title: "Something went wrong",
            message: errorMessage ?? "An error occurred while loading data",
            onRetry: onRetry
        )
    }
}

/// Inline error for cards
struct InlineErrorView: View {
    let message: String
    var onRetry: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: "exclamationmark.circle")
                .font(.caption)
                .foregroundColor(.red)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.spacingM)
        .background(Color.red.opacity(0.1))
        .cornerRadius(.cornerRadiusMicro)
    }
}

/// Card error state
struct CardErrorView: View {
    let title: String?
    let message: String
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: .spacingM) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: .spacingS) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if let onRetry = onRetry {
                    Button(action: onRetry) {
                        Text("Retry")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, .spacingM)
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 40) {
            NetworkErrorState(cachedDataAge: "2 hours ago", onRetry: {})
                .frame(height: 300)

            ScrapeFailedState(
                sourceName: "Mt. Baker",
                lastKnownAge: "4 hours ago",
                onRetry: {},
                onViewCached: {}
            )
            .frame(height: 300)

            InlineErrorView(message: "Failed to load", onRetry: {})

            CardErrorView(title: "Forecast", message: "Unable to load forecast data", onRetry: {})
        }
        .padding()
    }
}
