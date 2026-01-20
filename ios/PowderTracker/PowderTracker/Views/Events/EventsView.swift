import SwiftUI

struct EventsView: View {
    @State private var events: [Event] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var filter: EventFilter = .all
    @State private var showingCreateSheet = false

    enum EventFilter: String, CaseIterable {
        case all = "All Events"
        case mine = "My Events"
        case attending = "Attending"
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(message: error)
                } else if events.isEmpty {
                    emptyView
                } else {
                    eventsList
                }
            }
            .navigationTitle("Ski Events")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .refreshable {
                await loadEvents()
            }
            .sheet(isPresented: $showingCreateSheet) {
                EventCreateView(onEventCreated: { _ in
                    Task { await loadEvents() }
                })
            }
        }
        .task {
            await loadEvents()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading events...")
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadEvents() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No upcoming events")
                .font(.headline)
            Text("Create an event to invite friends skiing!")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showingCreateSheet = true
            } label: {
                Label("Create Event", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var eventsList: some View {
        List {
            // Filter picker
            Picker("Filter", selection: $filter) {
                ForEach(EventFilter.allCases, id: \.self) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .onChange(of: filter) { _, _ in
                Task { await loadEvents() }
            }

            // Events
            ForEach(events) { event in
                NavigationLink(destination: EventDetailView(eventId: event.id)) {
                    EventRowView(event: event)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Data Loading

    private func loadEvents() async {
        isLoading = events.isEmpty
        error = nil

        do {
            let response = try await EventService.shared.fetchEvents(
                upcoming: true,
                createdByMe: filter == .mine,
                attendingOnly: filter == .attending
            )
            events = response.events
        } catch let err as EventServiceError {
            error = err.localizedDescription
        } catch {
            self.error = "Failed to load events"
        }

        isLoading = false
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.headline)

                Spacer()

                if event.isCreator == true {
                    Text("Organizer")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 8) {
                Label(event.mountainName ?? event.mountainId, systemImage: "mountain.2")
                    .font(.subheadline)
                    .foregroundStyle(.blue)

                Text("•")
                    .foregroundStyle(.secondary)

                Text(event.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let time = event.formattedTime {
                Label("Departing \(time)", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("\(event.goingCount)", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if event.carpoolAvailable {
                    Label("Carpool", systemImage: "car.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Spacer()

                if let status = event.userRSVPStatus {
                    Text(status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(status == .going ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(status == .going ? .green.opacity(0.1) : .orange.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EventsView()
}
