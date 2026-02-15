import SwiftUI

struct DatePollView: View {
    let eventId: String
    let isCreator: Bool

    @State private var poll: DatePoll?
    @State private var isLoading = true
    @State private var error: String?
    @State private var votingOptionId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Label("Date Poll", systemImage: "calendar.badge.checkmark")
                    .font(.headline)

                Spacer()

                if let poll, poll.isOpen {
                    Text("Open")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .cornerRadius(.cornerRadiusTiny)
                } else if poll != nil {
                    Text("Closed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(.cornerRadiusTiny)
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let poll {
                ForEach(poll.options) { option in
                    dateOptionCard(option: option, pollOpen: poll.isOpen)
                }
            }
        }
        .task {
            await loadPoll()
        }
    }

    // MARK: - Date Option Card

    private func dateOptionCard(option: DateOption, pollOpen: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                Text(option.displayDate)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Vote count summary
                HStack(spacing: .spacingS) {
                    if option.availableCount > 0 {
                        Label("\(option.availableCount)", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    if option.maybeCount > 0 {
                        Label("\(option.maybeCount)", systemImage: "questionmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if option.unavailableCount > 0 {
                        Label("\(option.unavailableCount)", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            // Vote buttons (only if poll is open)
            if pollOpen {
                HStack(spacing: .spacingS) {
                    voteButton(
                        optionId: option.id,
                        vote: .available,
                        icon: "checkmark",
                        label: "Available",
                        color: .green,
                        currentVote: currentVote(for: option)
                    )
                    voteButton(
                        optionId: option.id,
                        vote: .maybe,
                        icon: "questionmark",
                        label: "Maybe",
                        color: .orange,
                        currentVote: currentVote(for: option)
                    )
                    voteButton(
                        optionId: option.id,
                        vote: .unavailable,
                        icon: "xmark",
                        label: "Can't",
                        color: .red,
                        currentVote: currentVote(for: option)
                    )

                    Spacer()

                    // Organizer "Pick this date" button
                    if isCreator {
                        Button {
                            Task { await resolveWithOption(option.id) }
                        } label: {
                            Text("Pick")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue)
                                .cornerRadius(.cornerRadiusButton)
                        }
                    }
                }
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - Vote Button

    private func voteButton(
        optionId: String,
        vote: DateVoteChoice,
        icon: String,
        label: String,
        color: Color,
        currentVote: DateVoteChoice?
    ) -> some View {
        let isSelected = currentVote == vote
        let isVoting = votingOptionId == optionId

        return Button {
            Task { await castVote(optionId: optionId, vote: vote) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .foregroundStyle(isSelected ? color : .secondary)
            .cornerRadius(.cornerRadiusButton)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .stroke(isSelected ? color : .clear, lineWidth: 1.5)
            )
        }
        .disabled(isVoting)
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func currentVote(for option: DateOption) -> DateVoteChoice? {
        guard let userId = AuthService.shared.getCurrentUserId() else { return nil }
        return option.votes.first(where: { $0.userId == userId })?.vote
    }

    // MARK: - Data Loading

    private func loadPoll() async {
        isLoading = true
        error = nil

        do {
            let response = try await EventService.shared.fetchPoll(eventId: eventId)
            poll = response.poll
        } catch {
            // 404 means no poll exists — that's fine, not an error
            if case EventServiceError.notFound = error {
                self.poll = nil
            } else {
                self.error = "Could not load poll"
            }
        }

        isLoading = false
    }

    private func castVote(optionId: String, vote: DateVoteChoice) async {
        votingOptionId = optionId

        do {
            _ = try await EventService.shared.castVote(
                eventId: eventId,
                optionId: optionId,
                vote: vote.rawValue
            )
            HapticFeedback.selection.trigger()
            // Reload to get updated counts
            await loadPoll()
        } catch {
            #if DEBUG
            print("Failed to cast vote: \(error)")
            #endif
        }

        votingOptionId = nil
    }

    private func resolveWithOption(_ optionId: String) async {
        do {
            try await EventService.shared.resolvePoll(eventId: eventId, optionId: optionId)
            HapticFeedback.success.trigger()
            await loadPoll()
        } catch {
            #if DEBUG
            print("Failed to resolve poll: \(error)")
            #endif
        }
    }
}

#Preview {
    DatePollView(eventId: "test-event", isCreator: true)
        .padding()
        .environment(AuthService.shared)
}
