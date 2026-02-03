//
//  EventNotificationSettingsView.swift
//  PowderTracker
//
//  Settings for event-related push notifications.
//

import SwiftUI

struct EventNotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Event notification preferences stored in AppStorage
    @AppStorage("notifyEventUpdates") private var eventUpdates = true
    @AppStorage("notifyEventCancellations") private var eventCancellations = true
    @AppStorage("notifyNewRSVPs") private var newRSVPs = true
    @AppStorage("notifyRSVPChanges") private var rsvpChanges = true
    @AppStorage("notifyEventComments") private var eventComments = true
    @AppStorage("notifyCommentReplies") private var commentReplies = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $eventUpdates) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Event Updates")
                                Text("Changes to date, time, or location")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }

                    Toggle(isOn: $eventCancellations) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Event Cancellations")
                                Text("When events you're attending are cancelled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Events You're Attending")
                }

                Section {
                    Toggle(isOn: $newRSVPs) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("New RSVPs")
                                Text("When someone joins your event")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "person.badge.plus.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    Toggle(isOn: $rsvpChanges) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RSVP Changes")
                                Text("When attendees change their status")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Events You're Hosting")
                }

                Section {
                    Toggle(isOn: $eventComments) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("New Comments")
                                Text("When someone comments on your event")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bubble.left.fill")
                                .foregroundStyle(.purple)
                        }
                    }

                    Toggle(isOn: $commentReplies) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Comment Replies")
                                Text("When someone replies to your comment")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .foregroundStyle(.cyan)
                        }
                    }
                } header: {
                    Text("Comments")
                }

                Section {
                    Text("Event notifications keep you updated on ski trips you're planning or attending. Disable specific types above if you prefer fewer notifications.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Event Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EventNotificationSettingsView()
}
