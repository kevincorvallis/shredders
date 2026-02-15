import SwiftUI

struct EventInviteView: View {
    let token: String
    var onEventJoined: ((String) -> Void)?

    @State private var invite: InviteInfo?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isRSVPing = false

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(message: error)
            } else if let invite = invite {
                inviteContent(invite: invite)
            }
        }
        .navigationTitle("You're Invited!")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInvite()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading invite...")
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Invalid Invite")
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func inviteContent(invite: InviteInfo) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Invite header
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text(invite.event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(invite.event.mountainName ?? invite.event.mountainId)
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                .padding(.top)

                // Event details
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        Text(invite.event.formattedDate)
                        Spacer()
                    }

                    if let time = invite.event.formattedTime {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text("Departing at \(time)")
                            Spacer()
                        }
                    }

                    if let location = invite.event.departureLocation {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text(location)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Organizer
                HStack(spacing: 12) {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Text(String(invite.event.creator.displayNameOrUsername.prefix(1)))
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Organized by")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(invite.event.creator.displayNameOrUsername)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Attendee count
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.secondary)
                    Text("\(invite.event.goingCount) going")
                    if invite.event.maybeCount > 0 {
                        Text("• \(invite.event.maybeCount) maybe")
                    }
                }
                .foregroundStyle(.secondary)

                // Conditions
                if let conditions = invite.conditions {
                    conditionsCard(conditions: conditions)
                }

                Spacer(minLength: 20)

                // RSVP buttons
                if invite.isValid {
                    VStack(spacing: 12) {
                        Button {
                            Task { await rsvp(status: .going) }
                        } label: {
                            Text("I'm In!")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isRSVPing)

                        Button {
                            Task { await rsvp(status: .maybe) }
                        } label: {
                            Text("Maybe")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.regularMaterial)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isRSVPing)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text(invite.isExpired ? "This event has passed" : "This invite is no longer valid")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private func conditionsCard(conditions: EventConditions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Conditions")
                .font(.headline)

            HStack(spacing: 24) {
                if let score = conditions.powderScore {
                    VStack {
                        Text(String(format: "%.1f", score))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text("Powder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let snow = conditions.snowfall24h {
                    VStack {
                        Text("\(Int(snow))\"")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("24h Snow")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let temp = conditions.temperature {
                    VStack {
                        Text("\(Int(temp))°F")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Temp")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions

    private func loadInvite() async {
        isLoading = true
        error = nil

        do {
            invite = try await EventService.shared.fetchInvite(token: token)
        } catch let err as EventServiceError {
            error = err.localizedDescription
        } catch {
            self.error = "Failed to load invite"
        }

        isLoading = false
    }

    private func rsvp(status: RSVPStatus) async {
        isRSVPing = true

        do {
            // Validate invite and get event ID
            let eventId = try await EventService.shared.useInvite(token: token)

            // RSVP to the event
            _ = try await EventService.shared.rsvp(eventId: eventId, eventDate: "", status: status)

            // Navigate to event detail
            onEventJoined?(eventId)
        } catch let err as EventServiceError {
            if case .notAuthenticated = err {
                // User needs to sign in - show auth flow
                // For now, just show error
                error = "Please sign in to RSVP"
            } else {
                error = err.localizedDescription
            }
        } catch {
            self.error = "Failed to RSVP"
        }

        isRSVPing = false
    }
}

#Preview {
    NavigationStack {
        EventInviteView(token: "preview-token")
    }
}
