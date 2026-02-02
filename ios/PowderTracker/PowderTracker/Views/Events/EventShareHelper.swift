import SwiftUI

/// Helper for sharing events across the app
/// Ensures consistent sharing experience regardless of inviteToken availability
struct EventShareHelper {
    let event: Event

    /// The shareable URL - uses event ID for universal access
    var shareURL: URL {
        let baseURL = AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: "")
        return URL(string: "\(baseURL)/events/\(event.id)")!
    }

    /// Formatted share message with event details
    var shareMessage: String {
        """
        Join me skiing at \(event.mountainName ?? event.mountainId)! 🎿

        \(event.title)
        📅 \(event.formattedDate)
        \(event.formattedTime.map { "⏰ Departing \($0)" } ?? "")
        👥 \(event.goingCount) people going
        """
    }

    /// Full message body for iMessage including the URL
    var messageComposeBody: String {
        "\(shareMessage)\n\n\(shareURL.absoluteString)"
    }

    /// Copy link to clipboard with haptic feedback
    @MainActor
    func copyToClipboard() {
        UIPasteboard.general.url = shareURL
        HapticFeedback.success.trigger()
    }
}

/// Extension to easily create share helper from Event
extension Event {
    var shareHelper: EventShareHelper {
        EventShareHelper(event: self)
    }
}

/// A reusable share button that can be used anywhere events are displayed
struct EventShareButton: View {
    let event: Event
    var style: ShareButtonStyle = .iconOnly
    var size: ShareButtonSize = .regular

    @State private var showingShareSheet = false
    @State private var showingMessageCompose = false

    enum ShareButtonStyle {
        case iconOnly
        case iconWithLabel
        case compact
    }

    enum ShareButtonSize {
        case small
        case regular
        case large
    }

    private var shareHelper: EventShareHelper {
        event.shareHelper
    }

    var body: some View {
        Menu {
            Button {
                showingShareSheet = true
            } label: {
                Label("Share Event", systemImage: "square.and.arrow.up")
            }

            Button {
                showingMessageCompose = true
            } label: {
                Label("Send via iMessage", systemImage: "message.fill")
            }

            Button {
                shareHelper.copyToClipboard()
            } label: {
                Label("Copy Link", systemImage: "doc.on.doc")
            }
        } label: {
            shareButtonLabel
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareHelper.shareURL, shareHelper.shareMessage])
        }
        .messageComposeSheet(
            isPresented: $showingMessageCompose,
            body: shareHelper.messageComposeBody
        )
    }

    @ViewBuilder
    private var shareButtonLabel: some View {
        switch style {
        case .iconOnly:
            Image(systemName: "square.and.arrow.up")
                .font(iconFont)
                .foregroundStyle(.primary)

        case .iconWithLabel:
            Label("Share", systemImage: "square.and.arrow.up")
                .font(labelFont)

        case .compact:
            Image(systemName: "square.and.arrow.up")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())
        }
    }

    private var iconFont: Font {
        switch size {
        case .small: return .subheadline
        case .regular: return .body
        case .large: return .title3
        }
    }

    private var labelFont: Font {
        switch size {
        case .small: return .caption
        case .regular: return .subheadline
        case .large: return .body
        }
    }
}

/// Quick share button for inline use - opens iMessage directly
struct QuickShareButton: View {
    let event: Event
    @State private var showingMessageCompose = false

    var body: some View {
        Button {
            showingMessageCompose = true
        } label: {
            Image(systemName: "paperplane.fill")
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(8)
                .background(Color.blue)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share event via iMessage")
        .messageComposeSheet(
            isPresented: $showingMessageCompose,
            body: event.shareHelper.messageComposeBody
        )
    }
}
