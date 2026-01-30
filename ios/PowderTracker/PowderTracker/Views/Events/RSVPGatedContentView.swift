//
//  RSVPGatedContentView.swift
//  PowderTracker
//
//  A wrapper view that shows blurred preview content with RSVP CTA
//  for non-RSVP'd users, and full content for attendees.
//

import SwiftUI

struct RSVPGatedContentView<Content: View>: View {
    let isGated: Bool
    let previewCount: Int
    let contentType: GatedContentType
    let onRSVPTap: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            if isGated {
                gatedPreview
            } else {
                content()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isGated)
    }

    // MARK: - Gated Preview

    private var gatedPreview: some View {
        VStack(spacing: .spacingL) {
            // Blurred content placeholder
            ZStack {
                // Background blur effect
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .fill(.ultraThinMaterial)
                    .frame(height: 200)

                // Overlay content
                VStack(spacing: .spacingM) {
                    contentTypeIcon
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .symbolEffect(.pulse, options: .repeating, value: isAnimating)

                    VStack(spacing: .spacingS) {
                        Text(previewTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(previewSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // RSVP CTA Button
                    Button {
                        HapticFeedback.medium.trigger()
                        onRSVPTap()
                    } label: {
                        HStack(spacing: .spacingS) {
                            Image(systemName: "hand.raised.fill")
                            Text("RSVP to Unlock")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, .spacingL)
                        .padding(.vertical, .spacingM)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.spacingL)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }

    // MARK: - Content Type Helpers

    private var contentTypeIcon: Image {
        switch contentType {
        case .discussion:
            return Image(systemName: "bubble.left.and.bubble.right.fill")
        case .photos:
            return Image(systemName: "photo.stack.fill")
        case .activity:
            return Image(systemName: "chart.line.uptrend.xyaxis")
        }
    }

    private var previewTitle: String {
        switch contentType {
        case .discussion:
            return previewCount > 0 ? "\(previewCount) comments" : "Discussion"
        case .photos:
            return previewCount > 0 ? "\(previewCount) photos" : "Photos"
        case .activity:
            return "Activity Timeline"
        }
    }

    private var previewSubtitle: String {
        switch contentType {
        case .discussion:
            return "RSVP to join the conversation"
        case .photos:
            return "RSVP to see and share photos"
        case .activity:
            return "RSVP to see who's going"
        }
    }
}

// MARK: - Content Types

enum GatedContentType {
    case discussion
    case photos
    case activity
}

// MARK: - Convenience Extensions

extension View {
    /// Wrap content in RSVP gating if user hasn't RSVP'd
    func rsvpGated(
        isGated: Bool,
        previewCount: Int = 0,
        contentType: GatedContentType,
        onRSVPTap: @escaping () -> Void
    ) -> some View {
        RSVPGatedContentView(
            isGated: isGated,
            previewCount: previewCount,
            contentType: contentType,
            onRSVPTap: onRSVPTap
        ) {
            self
        }
    }
}

// MARK: - Preview

#Preview("Gated - Discussion") {
    RSVPGatedContentView(
        isGated: true,
        previewCount: 12,
        contentType: .discussion,
        onRSVPTap: { print("RSVP tapped") }
    ) {
        Text("Full discussion content here")
    }
    .padding()
}

#Preview("Gated - Photos") {
    RSVPGatedContentView(
        isGated: true,
        previewCount: 5,
        contentType: .photos,
        onRSVPTap: { print("RSVP tapped") }
    ) {
        Text("Full photos content here")
    }
    .padding()
}

#Preview("Unlocked") {
    RSVPGatedContentView(
        isGated: false,
        previewCount: 0,
        contentType: .discussion,
        onRSVPTap: {}
    ) {
        VStack {
            Text("Full content visible!")
                .font(.headline)
            Text("User has RSVP'd to this event")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    .padding()
}
