import SwiftUI

struct EventDetailView: View {
    let eventId: String

    @State private var event: EventWithDetails?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isRSVPing = false
    @State private var showingShareSheet = false
    @State private var currentUserRSVPStatus: RSVPStatus?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error = error {
                errorView(message: error)
            } else if let event = event {
                eventContent(event: event)
            }
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let event = event, event.isCreator == true || event.inviteToken != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .refreshable {
            await loadEvent()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let token = event?.inviteToken {
                let url = URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))/events/invite/\(token)")!
                ShareSheet(items: [url])
            }
        }
        .task {
            await loadEvent()
        }
    }

    // MARK: - Subviews

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task { await loadEvent() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func eventContent(event: EventWithDetails) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Event Info Card
                eventInfoCard(event: event)

                // Conditions Card
                if let conditions = event.conditions {
                    conditionsCard(conditions: conditions)
                }

                // Attendees Card
                attendeesCard(event: event)

                // RSVP Buttons
                if event.isCreator != true {
                    rsvpButtons(event: event)
                }
            }
            .padding()
        }
    }

    private func eventInfoCard(event: EventWithDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(event.title)
                .font(.title2)
                .fontWeight(.bold)

            Label(event.mountainName ?? event.mountainId, systemImage: "mountain.2.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Label(event.formattedDate, systemImage: "calendar")

                if let time = event.formattedTime {
                    Label("Departing at \(time)", systemImage: "clock")
                }

                if let location = event.departureLocation {
                    Label(location, systemImage: "mappin.and.ellipse")
                }

                if let level = event.skillLevel {
                    Label(level.displayName, systemImage: "speedometer")
                }

                if event.carpoolAvailable {
                    Label("Carpool available (\(event.carpoolSeats ?? 0) seats)", systemImage: "car.fill")
                        .foregroundStyle(.green)
                }
            }
            .foregroundStyle(.secondary)

            if let notes = event.notes {
                Divider()
                Text(notes)
                    .font(.body)
            }

            Divider()

            // Organizer
            HStack(spacing: 12) {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(event.creator.displayNameOrUsername.prefix(1)))
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Organized by")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(event.creator.displayNameOrUsername)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func conditionsCard(conditions: EventConditions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Conditions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let score = conditions.powderScore {
                    conditionItem(
                        label: "Powder Score",
                        value: String(format: "%.1f", score),
                        color: .blue
                    )
                }
                if let snow = conditions.snowfall24h {
                    conditionItem(
                        label: "24h Snowfall",
                        value: "\(Int(snow))\"",
                        color: .white
                    )
                }
                if let temp = conditions.temperature {
                    conditionItem(
                        label: "Temperature",
                        value: "\(Int(temp))°F",
                        color: .white
                    )
                }
                if let depth = conditions.snowDepth {
                    conditionItem(
                        label: "Snow Depth",
                        value: "\(Int(depth))\"",
                        color: .white
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func conditionItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }

    private func attendeesCard(event: EventWithDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Who's Going")
                    .font(.headline)

                Spacer()

                Text("\(event.goingCount) going, \(event.maybeCount) maybe")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if event.attendees.isEmpty {
                Text("No attendees yet")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(event.attendees) { attendee in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(String(attendee.user.displayNameOrUsername.prefix(1)))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }

                        Text(attendee.user.displayNameOrUsername)
                            .font(.subheadline)

                        Spacer()

                        HStack(spacing: 8) {
                            if attendee.isDriver {
                                Text("Driver")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.1))
                                    .clipShape(Capsule())
                            }

                            Text(attendee.status.displayName)
                                .font(.caption2)
                                .foregroundStyle(attendee.status == .going ? .blue : .orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(attendee.status == .going ? .blue.opacity(0.1) : .orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func rsvpButtons(event: EventWithDetails) -> some View {
        HStack(spacing: 16) {
            Button {
                Task { await rsvp(status: .going) }
            } label: {
                Text("I'm In!")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentUserRSVPStatus == .going ? .green : .green.opacity(0.2))
                    .foregroundStyle(currentUserRSVPStatus == .going ? .white : .green)
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
                    .background(currentUserRSVPStatus == .maybe ? .orange : .orange.opacity(0.2))
                    .foregroundStyle(currentUserRSVPStatus == .maybe ? .white : .orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isRSVPing)
        }
    }

    // MARK: - Actions

    private func loadEvent() async {
        isLoading = event == nil
        error = nil

        do {
            let loadedEvent = try await EventService.shared.fetchEvent(id: eventId)
            event = loadedEvent
            currentUserRSVPStatus = loadedEvent.userRSVPStatus
        } catch let err as EventServiceError {
            error = err.localizedDescription
        } catch {
            self.error = "Failed to load event"
        }

        isLoading = false
    }

    private func rsvp(status: RSVPStatus) async {
        isRSVPing = true

        do {
            let response = try await EventService.shared.rsvp(eventId: eventId, status: status)
            // Update local state
            currentUserRSVPStatus = response.attendee.status
        } catch {
            // Show error
        }

        isRSVPing = false

        // Reload to get updated attendees
        await loadEvent()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        EventDetailView(eventId: "preview-id")
    }
}
