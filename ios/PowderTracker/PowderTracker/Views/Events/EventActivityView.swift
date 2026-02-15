//
//  EventActivityView.swift
//  PowderTracker
//
//  Activity timeline view for events showing RSVPs, comments, and milestones.
//

import SwiftUI
import NukeUI

struct EventActivityView: View {
    let eventId: String
    @State private var viewModel: EventActivityViewModel

    init(eventId: String) {
        self.eventId = eventId
        self._viewModel = State(initialValue: EventActivityViewModel(eventId: eventId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.activities.isEmpty {
                loadingView
            } else if viewModel.isGated {
                gatedView
            } else if viewModel.isEmpty {
                emptyView
            } else {
                activityList
            }
        }
        .task {
            await viewModel.loadActivity()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: .spacingM) {
            ProgressView()
            Text("Loading activity...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Gated View

    private var gatedView: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: .spacingS) {
                Text("\(viewModel.activityCount) activities")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(viewModel.gatedMessage ?? "RSVP to see activity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: .spacingS) {
                Text("No activity yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Activity will appear here as people RSVP and comment")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Activity List

    private var activityList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.activities) { activity in
                    ActivityRowView(activity: activity)
                        .task {
                            await viewModel.loadMoreIfNeeded(currentItem: activity)
                        }
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .padding(.spacingM)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Activity Row View

struct ActivityRowView: View {
    let activity: EventActivity

    var body: some View {
        HStack(alignment: .top, spacing: .spacingM) {
            // Timeline line and icon
            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(activity.isMilestone ? Color.yellow.opacity(0.2) : Color(.tertiarySystemBackground))
                        .frame(width: 36, height: 36)

                    Image(systemName: activity.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(activity.iconColor)
                }

                // Connecting line
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 36)

            // Content
            VStack(alignment: .leading, spacing: .spacingXS) {
                // Activity text
                if activity.isMilestone {
                    // Milestone special styling
                    HStack(spacing: .spacingXS) {
                        Text("🎉")
                        Text(activity.displayText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, .spacingM)
                    .padding(.vertical, .spacingS)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.15))
                    )
                } else {
                    HStack(spacing: .spacingS) {
                        // Avatar (if user exists)
                        if let user = activity.user {
                            LazyImage(url: URL(string: user.avatarUrl ?? "")) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Circle()
                                        .fill(avatarGradient)
                                        .overlay(
                                            Text(user.displayNameOrUsername.prefix(1).uppercased())
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                        )
                                }
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                        }

                        Text(activity.displayText)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }

                    // Comment preview (if comment activity)
                    if activity.activityType == .commentPosted,
                       let preview = activity.metadata.preview {
                        Text(preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.leading, activity.user != nil ? 32 : 0)
                    }
                }

                // Time
                Text(activity.relativeTime)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, .spacingS)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var description = activity.displayText
        if let preview = activity.metadata.preview {
            description += ". \(preview)"
        }
        description += ". \(activity.relativeTime)"
        return description
    }

    private var avatarGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventActivityView(eventId: "preview-event-id")
            .navigationTitle("Activity")
    }
}
