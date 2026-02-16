//
//  EventsView.swift
//  PowderTracker
//
//  Main events list view with filtering and map toggle.
//

import SwiftUI

// MARK: - Event Filter

enum EventFilter: String, CaseIterable {
    case all = "All"
    case lastMinute = "Last Minute"
    case mine = "My Events"
    case attending = "Attending"
}

// MARK: - Event View Mode

enum EventViewMode: String, CaseIterable {
    case list
    case map

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .map: return "map"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .list: return "Show map view"
        case .map: return "Show list view"
        }
    }
}

// MARK: - Events View

struct EventsView: View {
    @Environment(AuthService.self) private var authService

    var prefetchedEvents: [Event]?

    @State private var events: [Event] = []
    @State private var mountains: [Mountain] = []
    @State private var isLoading = true
    @State private var error: String?

    @AppStorage("eventsFilter") private var filter: EventFilter = .all
    @AppStorage("eventsViewMode") private var viewMode: EventViewMode = .list

    @State private var showingCreateSheet = false
    @State private var navigationPath = NavigationPath()
    @State private var toast: ToastMessage?
    @State private var searchText = ""

    // Pagination
    @State private var hasMore = false
    @State private var isLoadingMore = false
    private let pageSize = 20

    // Powder day suggestion state
    @State private var powderDayMountain: (mountain: Mountain, score: Int)?
    @State private var showPowderDayHint = false
    @State private var suggestedMountainForEvent: String?

    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedView
            } else {
                UnauthenticatedEventsView()
            }
        }
    }

    // MARK: - Authenticated View

    private var authenticatedView: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if isLoading {
                    EventsTabSkeleton()
                } else if let error = error {
                    errorView(message: error)
                } else if events.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Ski Events")
            .toolbar { toolbarContent }
            .enhancedRefreshable { await loadEvents() }
            .sheet(isPresented: $showingCreateSheet) {
                EventCreateView(
                    suggestedMountainId: suggestedMountainForEvent,
                    onEventCreated: { _ in
                        Task { await loadEvents(bustCache: true) }
                    }
                )
            }
            .navigationDestination(for: String.self) { eventId in
                EventDetailView(eventId: eventId)
            }
            .toast($toast)
            .searchable(text: $searchText, prompt: "Search events...")
        }
        .task {
            if mountains.isEmpty {
                mountains = MountainService.shared.allMountains
            }
            if let prefetchedEvents, !prefetchedEvents.isEmpty, events.isEmpty {
                events = prefetchedEvents
                isLoading = false
            } else {
                await loadEvents()
            }
            await checkForPowderDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EventCancelled"))) { _ in
            Task { await loadEvents(bustCache: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RSVPUpdated"))) { _ in
            Task { await loadEvents(bustCache: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EventUpdated"))) { _ in
            Task { await loadEvents(bustCache: true) }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .list:
            eventsList
        case .map:
            EventsMapView(
                events: events,
                mountains: mountains,
                onEventSelected: { event in
                    navigationPath.append(event.id)
                }
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Events List

    private var eventsList: some View {
        AdaptiveContentView(maxWidth: .maxContentWidthRegular) {
            List {
                // Powder Day Finder Banner
                Section {
                    PowderDayFinderBanner(
                        suggestedMountainName: powderDayMountain?.mountain.name
                    ) {
                        showingCreateSheet = true
                    }
                }
                .listRowInsets(EdgeInsets(top: .spacingS, leading: .spacingL, bottom: .spacingS, trailing: .spacingL))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Filter Picker
                filterPicker
                    .listRowInsets(EdgeInsets(top: .spacingS, leading: .spacingL, bottom: .spacingS, trailing: .spacingL))
                    .listRowBackground(Color.clear)

                // Content based on filter
                if filter == .lastMinute {
                    lastMinuteSection
                } else {
                    regularEventsSection
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filter) {
            ForEach(EventFilter.allCases, id: \.self) { f in
                Text(f.rawValue).tag(f)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("events_filter_picker")
        .onChange(of: filter) { _, _ in
            events = []
            Task { await loadEvents() }
        }
    }

    @ViewBuilder
    private var lastMinuteSection: some View {
        Section {
            LastMinuteCrewSection(
                events: todayEvents,
                onEventTap: { event in
                    navigationPath.append(event.id)
                },
                onQuickJoin: { event in
                    Task { await quickJoinEvent(event) }
                }
            )
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var regularEventsSection: some View {
        if filteredEvents.isEmpty && !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        } else {
            ForEach(filteredEvents) { event in
                NavigationLink(destination: EventDetailView(eventId: event.id)) {
                    EventRowView(event: event)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: .spacingS, leading: .spacingL, bottom: .spacingS, trailing: .spacingL))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onAppear {
                    // Trigger pagination when nearing the end of the list
                    if event.id == filteredEvents.last?.id && hasMore {
                        Task { await loadMoreEvents() }
                    }
                }
            }

            // Loading indicator at bottom
            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 8)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewMode = viewMode == .list ? .map : .list
                }
                HapticFeedback.selection.trigger()
            } label: {
                Image(systemName: viewMode == .list ? "map" : "list.bullet")
                    .font(.body)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(viewMode.accessibilityLabel)
        }

        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 12) {
                // Powder day micro-button (appears when score >= 7)
                if let powderDay = powderDayMountain {
                    Button {
                        HapticFeedback.medium.trigger()
                        showPowderDayHint.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.caption)
                            Text("\(powderDay.score)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(powderDay.score >= 9 ? Color.green : Color.mint)
                        )
                    }
                    .popover(isPresented: $showPowderDayHint) {
                        PowderDayHintPopover(
                            mountain: powderDay.mountain,
                            score: powderDay.score,
                            onCreateEvent: {
                                showPowderDayHint = false
                                showingCreateSheet = true
                            }
                        )
                        .presentationCompactAdaptation(.popover)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Powder day alert: \(powderDay.mountain.name) has a score of \(powderDay.score)")
                }

                // Create event button
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .accessibilityIdentifier("events_create_button")
            }
        }
    }

    // MARK: - State Views

    private func errorView(message: String) -> some View {
        BrockEmptyState(
            title: "Ruh Roh!",
            message: "Brock couldn't fetch the events. \(message)",
            expression: .chilly,
            actionTitle: "Try Again",
            action: {
                Task { await loadEvents() }
            }
        )
    }

    private var emptyStateView: some View {
        BrockEmptyState(
            title: "No Upcoming Events",
            message: "Brock is ready to shred! Create an event to rally your crew for a powder day.",
            expression: .excited,
            actionTitle: "Create Event",
            action: {
                showingCreateSheet = true
            }
        )
    }

    // MARK: - Computed Properties

    private var todayEvents: [Event] {
        events.filter { $0.isToday && $0.departureTime != nil }
    }

    private var filteredEvents: [Event] {
        guard !searchText.isEmpty else { return events }
        let query = searchText.lowercased()
        return events.filter { event in
            event.title.lowercased().contains(query) ||
            (event.mountainName ?? "").lowercased().contains(query) ||
            (event.notes ?? "").lowercased().contains(query) ||
            (event.departureLocation ?? "").lowercased().contains(query)
        }
    }

    // MARK: - Data Loading

    private func loadEvents(bustCache: Bool = false) async {
        isLoading = events.isEmpty
        error = nil

        do {
            let response = try await EventService.shared.fetchEvents(
                upcoming: true,
                createdByMe: filter == .mine,
                attendingOnly: filter == .attending,
                limit: pageSize,
                offset: 0,
                bustCache: bustCache
            )
            events = response.events
            hasMore = response.pagination.hasMore
        } catch let err as EventServiceError {
            error = err.localizedDescription
        } catch {
            self.error = "Failed to load events"
        }

        isLoading = false
    }

    private func loadMoreEvents() async {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true

        do {
            let response = try await EventService.shared.fetchEvents(
                upcoming: true,
                createdByMe: filter == .mine,
                attendingOnly: filter == .attending,
                limit: pageSize,
                offset: events.count
            )
            events.append(contentsOf: response.events)
            hasMore = response.pagination.hasMore
        } catch {
            // Silently fail for pagination — user can scroll up and try again
        }

        isLoadingMore = false
    }

    private func quickJoinEvent(_ event: Event) async {
        do {
            _ = try await EventService.shared.rsvp(eventId: event.id, eventDate: event.eventDate, status: .going)
            HapticFeedback.success.trigger()
            await loadEvents()
            toast = ToastMessage(
                type: .success,
                title: "You're in!",
                message: "You've joined \(event.title)"
            )
        } catch let err as EventServiceError {
            HapticFeedback.error.trigger()
            toast = ToastMessage(
                type: .error,
                title: "Couldn't join event",
                message: err.localizedDescription
            )
        } catch {
            HapticFeedback.error.trigger()
            toast = ToastMessage(
                type: .error,
                title: "Couldn't join event",
                message: "Please try again later"
            )
        }
    }

    // MARK: - Powder Day Check

    /// Check favorite mountains for powder day conditions (score >= 7)
    private func checkForPowderDay() async {
        let favoriteIds = FavoritesService.shared.favoriteIds
        guard !favoriteIds.isEmpty else { return }

        // Check up to 3 favorites for powder conditions
        let mountainsToCheck = Array(favoriteIds.prefix(3))
        let apiClient = APIClient.shared

        await withTaskGroup(of: (String, Double?).self) { group in
            for mountainId in mountainsToCheck {
                group.addTask {
                    do {
                        let response = try await apiClient.fetchMountainData(for: mountainId)
                        return (mountainId, response.powderScore.score)
                    } catch {
                        return (mountainId, nil)
                    }
                }
            }

            var bestScore: (mountainId: String, score: Double)?

            for await (mountainId, score) in group {
                guard let score = score, score >= 7.0 else { continue }
                if bestScore == nil || score > bestScore!.score {
                    bestScore = (mountainId, score)
                }
            }

            if let best = bestScore,
               let mountain = mountains.first(where: { $0.id == best.mountainId }) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    powderDayMountain = (mountain, Int(best.score))
                    suggestedMountainForEvent = best.mountainId
                }
            }
        }
    }
}

// MARK: - Powder Day Hint Popover

private struct PowderDayHintPopover: View {
    let mountain: Mountain
    let score: Int
    let onCreateEvent: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Header
            HStack(spacing: .spacingS) {
                Image(systemName: "snowflake")
                    .font(.title2)
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Powder Day!")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(mountain.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Score badge
                Text("\(score)/10")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(score >= 9 ? Color.green : Color.mint)
                    )
            }

            Text("Great conditions for a ski trip! Create an event to rally your crew.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onCreateEvent()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Event")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.spacingL)
        .frame(width: 280)
    }
}

// MARK: - Powder Day Finder Banner

private struct PowderDayFinderBanner: View {
    var suggestedMountainName: String?
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.medium.trigger()
            action()
        }) {
            HStack(spacing: .spacingM) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: .cyan.opacity(0.3), radius: 6, y: 2)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Find Best Powder Day")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if let mountainName = suggestedMountainName {
                        Text("Best conditions at \(mountainName)")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                            .lineLimit(1)
                    } else {
                        Text("AI picks the best day & mountain for your trip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.spacingM)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: .cornerRadiusCard)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.3), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .cardShadow()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("powder_day_finder_banner")
    }
}

// MARK: - Preview

#Preview("Events View") {
    EventsView()
        .environment(AuthService.shared)
}
