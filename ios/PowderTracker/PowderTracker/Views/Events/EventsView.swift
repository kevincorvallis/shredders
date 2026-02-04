import SwiftUI

struct EventsView: View {
    @Environment(AuthService.self) private var authService
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

    enum EventFilter: String, CaseIterable, RawRepresentable {
        case all = "All"
        case lastMinute = "Last Minute"
        case mine = "My Events"
        case attending = "Attending"
    }

    enum EventViewMode: String, CaseIterable {
        case list = "list"
        case map = "map"

        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .map: return "map"
            }
        }
    }

    var body: some View {
        // Show sample events view for non-authenticated users
        if !authService.isAuthenticated {
            unauthenticatedEventsView
        } else {
            authenticatedEventsView
        }
    }

    // MARK: - Unauthenticated View (Sample Events)

    private var unauthenticatedEventsView: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [hexColor("0F172A"), hexColor("1E293B")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        LinearGradient(
                                            colors: [hexColor("0EA5E9").opacity(0.3), hexColor("A855F7").opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(hexColor("0EA5E9").opacity(0.5), lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: .spacingXS) {
                                    Text("Plan ski trips with friends")
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Text("Create events, coordinate carpools")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [hexColor("0EA5E9").opacity(0.2), hexColor("A855F7").opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(hexColor("0EA5E9").opacity(0.3), lineWidth: 1)
                            )

                            Text("Sign in to join upcoming trips or create your own")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            // CTA Buttons with haptic feedback
                            VStack(spacing: 12) {
                                NavigationLink(destination: UnifiedAuthView()) {
                                    HStack {
                                        Text("Sign in to join events")
                                            .fontWeight(.semibold)
                                        Image(systemName: "arrow.right")
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(hexColor("0EA5E9"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .simultaneousGesture(TapGesture().onEnded { _ in
                                    HapticFeedback.light.trigger()
                                })

                                NavigationLink(destination: UnifiedAuthView()) {
                                    Text("Create an account")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(hexColor("334155"))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .simultaneousGesture(TapGesture().onEnded { _ in
                                    HapticFeedback.light.trigger()
                                })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Sample Events Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Text("Example Events")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white.opacity(0.6))

                                Text("Preview")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(hexColor("1E293B"))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Spacer()
                            }
                            .padding(.horizontal)

                            ForEach(SampleEventData.samples) { event in
                                SampleEventRow(event: event)
                                    .padding(.horizontal)
                            }
                        }

                        // Bottom CTA with haptic
                        VStack(spacing: 12) {
                            Text("Ready to hit the slopes with friends?")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))

                            NavigationLink(destination: UnifiedAuthView()) {
                                HStack {
                                    Text("Get started free")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                        .symbolRenderingMode(.hierarchical)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [hexColor("0EA5E9"), hexColor("0284C7")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: hexColor("0EA5E9").opacity(0.3), radius: 12, y: 4)
                            }
                            .simultaneousGesture(TapGesture().onEnded { _ in
                                HapticFeedback.medium.trigger()
                            })
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 24)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Ski Events")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Authenticated View

    private var authenticatedEventsView: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(message: error)
                } else if events.isEmpty {
                    emptyView
                } else {
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
            }
            .navigationTitle("Ski Events")
            .toolbar {
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
                    .accessibilityLabel(viewMode == .list ? "Show map view" : "Show list view")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityIdentifier("events_create_button")
                }
            }
            .refreshable {
                await loadEvents()
            }
            .sheet(isPresented: $showingCreateSheet) {
                EventCreateView(
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
            // Load mountains for map view
            if mountains.isEmpty {
                mountains = MountainService.shared.allMountains
            }
            await loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EventCancelled"))) { _ in
            // Refresh events when an event is cancelled
            Task { await loadEvents(bustCache: true) }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        // Use skeleton loading for better perceived performance
        EventsTabSkeleton()
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
    
    /// Banner suggesting users find the best powder day to create an event
    private var powderDayFinderBanner: some View {
        Button {
            HapticFeedback.medium.trigger()
            showingCreateSheet = true
        } label: {
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
                    
                    Text("AI picks the best day & mountain for your trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Arrow
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

    private var eventsList: some View {
        AdaptiveContentView(maxWidth: .maxContentWidthRegular) {
            List {
                // Powder Day Finder suggestion banner
                Section {
                    powderDayFinderBanner
                }
                .listRowInsets(EdgeInsets(top: .spacingS, leading: .spacingL, bottom: .spacingS, trailing: .spacingL))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Filter picker
                Picker("Filter", selection: $filter) {
                    ForEach(EventFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: .spacingS, leading: .spacingL, bottom: .spacingS, trailing: .spacingL))
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("events_filter_picker")
                .onChange(of: filter) { _, _ in
                    Task { await loadEvents() }
                }

                // Show Last Minute section or regular events
                if filter == .lastMinute {
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
                } else {
                    // Regular events list (filtered by search)
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
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
        }
    }

    /// Events happening today with departure times
    private var todayEvents: [Event] {
        events.filter { $0.isToday && $0.departureTime != nil }
    }

    /// Filtered events based on search text
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

    /// Quick RSVP to join an event
    private func quickJoinEvent(_ event: Event) async {
        do {
            _ = try await EventService.shared.rsvp(eventId: event.id, status: .going)
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

    // MARK: - Data Loading

    private func loadEvents(bustCache: Bool = false) async {
        isLoading = events.isEmpty
        error = nil

        do {
            let response = try await EventService.shared.fetchEvents(
                upcoming: true,
                createdByMe: filter == .mine,
                attendingOnly: filter == .attending,
                bustCache: bustCache
            )
            events = response.events
        } catch let err as EventServiceError {
            error = err.localizedDescription
        } catch {
            self.error = "Failed to load events"
        }

        isLoading = false
    }

    // MARK: - Helper

    private func hexColor(_ hex: String) -> Color {
        Color(hex: hex) ?? .gray
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: Event
    @State private var showingShareSheet = false
    @State private var showingMessageCompose = false

    var body: some View {
        HStack(alignment: .top, spacing: .spacingM) {
            // MARK: - Date Badge (Visual Anchor)
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(EventCardStyle.primaryText)
                Text(monthAbbrev)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(EventCardStyle.secondaryText)
                    .textCase(.uppercase)
            }
            .frame(width: 44)
            .padding(.vertical, .spacingS)
            .background(Color.white.opacity(0.1))
            .cornerRadius(.cornerRadiusButton)

            // MARK: - Event Details
            VStack(alignment: .leading, spacing: EventCardStyle.innerSpacing) {
                // Title row with badges
                HStack(alignment: .top) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(EventCardStyle.primaryText)
                        .lineLimit(2)

                    Spacer(minLength: .spacingS)

                    // Badges
                    HStack(spacing: .spacingXS) {
                        if event.isCreator == true {
                            Text("HOST")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(EventCardStyle.hostBadgeColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(EventCardStyle.hostBadgeColor.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        if let level = event.skillLevel {
                            skillLevelBadge(for: level)
                        }
                    }
                }

                // Mountain + Time row
                HStack(spacing: .spacingS) {
                    // Mountain
                    Label(event.mountainName ?? event.mountainId, systemImage: "mountain.2")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(EventCardStyle.mountainIconColor)

                    if let time = event.formattedTime {
                        Text("•")
                            .foregroundStyle(EventCardStyle.tertiaryText)
                        Label(time, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(EventCardStyle.secondaryText)
                    }
                }

                // Departure location (if available)
                if let location = event.departureLocation, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(EventCardStyle.secondaryText)
                        .lineLimit(1)
                }

                // Bottom row: Attendees + Carpool + RSVP Status
                HStack(spacing: .spacingM) {
                    // Attendees
                    HStack(spacing: .spacingXS) {
                        Label("\(event.goingCount) going", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(EventCardStyle.secondaryText)

                        if event.maybeCount > 0 {
                            Text("+\(event.maybeCount) maybe")
                                .font(.caption)
                                .foregroundStyle(EventCardStyle.tertiaryText)
                        }
                    }

                    // Carpool badge
                    if event.carpoolAvailable {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                                .font(.caption2)
                            if let seats = event.carpoolSeats, seats > 0 {
                                Text("Carpool \u{2022} \(seats) seats")
                                    .font(.caption)
                            } else {
                                Text("Carpool")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(EventCardStyle.carpoolColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(EventCardStyle.carpoolColor.opacity(0.2))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // RSVP Status
                    if let status = event.userRSVPStatus {
                        HStack(spacing: .spacingXS) {
                            Image(systemName: rsvpIcon(for: status))
                            Text(status.displayName)
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(rsvpColor(for: status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(rsvpColor(for: status).opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .eventCardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(eventRowAccessibilityLabel)
        .accessibilityHint("Double tap to view details. Long press for options.")
        .contextMenu {
            Button {
                showingShareSheet = true
            } label: {
                Label("Share Event", systemImage: "square.and.arrow.up")
            }

            Button {
                copyEventLink()
            } label: {
                Label("Copy Link", systemImage: "doc.on.doc")
            }

            Button {
                showingMessageCompose = true
            } label: {
                Label("Send via iMessage", systemImage: "message.fill")
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url, shareMessage])
            }
        }
        .messageComposeSheet(
            isPresented: $showingMessageCompose,
            body: messageComposeBody
        )
    }

    // MARK: - Share Helpers

    private var shareURL: URL? {
        URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))/events/\(event.id)")
    }

    private var shareMessage: String {
        """
        Join me skiing at \(event.mountainName ?? event.mountainId)! 🎿

        \(event.title)
        📅 \(event.formattedDate)
        \(event.formattedTime.map { "⏰ Departing \($0)" } ?? "")
        👥 \(event.goingCount) people going
        """
    }

    private var messageComposeBody: String {
        guard let url = shareURL else { return shareMessage }
        return "\(shareMessage)\n\n\(url.absoluteString)"
    }

    // MARK: - Skill Level Badge

    @ViewBuilder
    private func skillLevelBadge(for level: SkillLevel) -> some View {
        HStack(spacing: 6) {
            skillLevelIcon(for: level)
            Text(skillLevelLabel(for: level))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(skillLevelColor(for: level))
        .padding(.horizontal, EventCardStyle.badgeHorizontalPadding)
        .padding(.vertical, EventCardStyle.badgeVerticalPadding)
        .background(skillLevelColor(for: level).opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func skillLevelIcon(for level: SkillLevel) -> some View {
        switch level {
        case .beginner:
            Circle()
                .fill(EventCardStyle.beginnerColor)
                .frame(width: 12, height: 12)
        case .intermediate:
            Rectangle()
                .fill(EventCardStyle.intermediateColor)
                .frame(width: 12, height: 12)
        case .advanced:
            Image(systemName: "diamond.fill")
                .font(.system(size: 12))
                .foregroundStyle(.black)
        case .expert:
            HStack(spacing: 1) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 10))
                Image(systemName: "diamond.fill")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.black)
        case .all:
            HStack(spacing: 2) {
                Circle()
                    .fill(EventCardStyle.beginnerColor)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(EventCardStyle.intermediateColor)
                    .frame(width: 8, height: 8)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.black)
            }
        }
    }

    private func skillLevelLabel(for level: SkillLevel) -> String {
        switch level {
        case .beginner: return "Green"
        case .intermediate: return "Blue"
        case .advanced: return "Black"
        case .expert: return "2x Black"
        case .all: return "All Levels"
        }
    }

    private func skillLevelColor(for level: SkillLevel) -> Color {
        switch level {
        case .beginner: return EventCardStyle.beginnerColor
        case .intermediate: return EventCardStyle.intermediateColor
        case .advanced, .expert: return EventCardStyle.primaryText
        case .all: return EventCardStyle.allLevelsColor
        }
    }

    // MARK: - Date Formatting

    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: event.eventDate) else {
            return "--"
        }
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: event.eventDate) else {
            return "---"
        }
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    // MARK: - RSVP Helpers

    private func rsvpIcon(for status: RSVPStatus) -> String {
        switch status {
        case .going: return "checkmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        case .invited: return "envelope.fill"
        case .declined: return "xmark.circle.fill"
        case .waitlist: return "hourglass"
        }
    }

    private func rsvpColor(for status: RSVPStatus) -> Color {
        switch status {
        case .going: return .green
        case .maybe: return .orange
        case .invited: return .blue
        case .declined: return .secondary
        case .waitlist: return .purple
        }
    }

    // MARK: - Accessibility

    private var eventRowAccessibilityLabel: String {
        var parts = [event.title, "at \(event.mountainName ?? event.mountainId)", event.formattedDate]

        if let time = event.formattedTime {
            parts.append("departing at \(time)")
        }

        parts.append("\(event.goingCount) people going")

        if event.maybeCount > 0 {
            parts.append("\(event.maybeCount) maybe")
        }

        if let level = event.skillLevel {
            parts.append("Skill level \(level.displayName)")
        }

        if event.carpoolAvailable {
            parts.append("Carpool available")
        }

        if event.isCreator == true {
            parts.append("You're the organizer")
        }

        if let status = event.userRSVPStatus {
            parts.append(status == .going ? "You're going" : "You said maybe")
        }

        return parts.joined(separator: ", ")
    }

    // MARK: - Sharing

    private func copyEventLink() {
        let url = URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))/events/\(event.id)")!
        UIPasteboard.general.url = url
        HapticFeedback.success.trigger()
    }
}

// MARK: - Sample Event Data

struct SampleEventData: Identifiable {
    let id: String
    let title: String
    let mountainName: String
    let eventDate: String
    let departureTime: String?
    let departureLocation: String?
    let goingCount: Int
    let maybeCount: Int
    let skillLevel: SkillLevel
    let carpoolAvailable: Bool
    let carpoolSeats: Int?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: eventDate) else { return eventDate }
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    var formattedTime: String? {
        guard let time = departureTime else { return nil }
        let components = time.split(separator: ":")
        guard components.count >= 2, let hour = Int(components[0]) else { return time }
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour >= 12 ? "PM" : "AM"
        return "\(h12):\(components[1]) \(ampm)"
    }

    static let samples: [SampleEventData] = [
        SampleEventData(
            id: "sample-1",
            title: "First Tracks Friday",
            mountainName: "Summit at Snoqualmie",
            eventDate: getUpcomingDate(2),
            departureTime: "06:00:00",
            departureLocation: "Seattle - Capitol Hill",
            goingCount: 8,
            maybeCount: 3,
            skillLevel: .beginner,
            carpoolAvailable: true,
            carpoolSeats: 4
        ),
        SampleEventData(
            id: "sample-2",
            title: "Powder Day at Baker!",
            mountainName: "Mt. Baker",
            eventDate: getUpcomingDate(3),
            departureTime: "05:30:00",
            departureLocation: "Bellingham",
            goingCount: 6,
            maybeCount: 2,
            skillLevel: .intermediate,
            carpoolAvailable: true,
            carpoolSeats: 3
        ),
        SampleEventData(
            id: "sample-3",
            title: "Backside Bowls Session",
            mountainName: "Stevens Pass",
            eventDate: getUpcomingDate(5),
            departureTime: "06:30:00",
            departureLocation: "Bellevue - Downtown",
            goingCount: 4,
            maybeCount: 1,
            skillLevel: .advanced,
            carpoolAvailable: true,
            carpoolSeats: 2
        ),
        SampleEventData(
            id: "sample-4",
            title: "Steep Chutes & Cliffs",
            mountainName: "Crystal Mountain",
            eventDate: getUpcomingDate(7),
            departureTime: "05:00:00",
            departureLocation: "Tacoma",
            goingCount: 3,
            maybeCount: 0,
            skillLevel: .expert,
            carpoolAvailable: false,
            carpoolSeats: nil
        ),
        SampleEventData(
            id: "sample-5",
            title: "Group Day - All Welcome!",
            mountainName: "Whistler Blackcomb",
            eventDate: getUpcomingDate(10),
            departureTime: "04:00:00",
            departureLocation: "Seattle - University District",
            goingCount: 12,
            maybeCount: 5,
            skillLevel: .all,
            carpoolAvailable: true,
            carpoolSeats: 6
        )
    ]

    private static func getUpcomingDate(_ daysFromNow: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Sample Event Row

struct SampleEventRow: View {
    let event: SampleEventData
    @State private var showSignInPrompt = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(hexColor("1E293B").opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(hexColor("334155").opacity(0.5), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            Label(event.mountainName, systemImage: "mountain.2")
                                .font(.subheadline)
                                .foregroundStyle(hexColor("0EA5E9"))

                            Text("•")
                                .foregroundStyle(.white.opacity(0.3))

                            Text(event.formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    Spacer()

                    skillLevelBadge(for: event.skillLevel)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if let time = event.formattedTime {
                        Label("Departing \(time)", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    if let location = event.departureLocation {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                HStack(spacing: 16) {
                    Label("\(event.goingCount) going", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    if event.maybeCount > 0 {
                        Text("+\(event.maybeCount) maybe")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    if event.carpoolAvailable, let seats = event.carpoolSeats {
                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                                .font(.caption2)
                            Text("Carpool • \(seats) seats")
                                .font(.caption)
                        }
                        .foregroundStyle(hexColor("10B981"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hexColor("10B981").opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(16)

            if showSignInPrompt {
                RoundedRectangle(cornerRadius: 16)
                    .fill(hexColor("0F172A").opacity(0.9))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundStyle(hexColor("0EA5E9"))

                            Text("Sign in to view & join")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                    )
                    .transition(.opacity)
            }
        }
        .frame(height: 180)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.light.trigger()
            withAnimation(.bouncy) {
                showSignInPrompt = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.smooth) {
                    showSignInPrompt = false
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(eventAccessibilityLabel)
        .accessibilityHint("Double tap to sign in and view event details")
    }

    private var eventAccessibilityLabel: String {
        var parts = [event.title, "at \(event.mountainName)", event.formattedDate]
        if let time = event.formattedTime {
            parts.append("departing at \(time)")
        }
        parts.append("\(event.goingCount) people going")
        parts.append(skillLevelAccessibilityLabel(for: event.skillLevel))
        if event.carpoolAvailable {
            parts.append("Carpool available")
        }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private func skillLevelBadge(for level: SkillLevel) -> some View {
        HStack(spacing: 6) {
            // Ski trail difficulty icon
            skillLevelIcon(for: level)

            Text(skillLevelLabel(for: level))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(skillLevelColor(for: level))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(skillLevelColor(for: level).opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("Skill level: \(skillLevelAccessibilityLabel(for: level))")
    }

    private func skillLevelAccessibilityLabel(for level: SkillLevel) -> String {
        switch level {
        case .beginner: return "Beginner, green circle runs"
        case .intermediate: return "Intermediate, blue square runs"
        case .advanced: return "Advanced, black diamond runs"
        case .expert: return "Expert, double black diamond runs"
        case .all: return "All skill levels welcome"
        }
    }

    @ViewBuilder
    private func skillLevelIcon(for level: SkillLevel) -> some View {
        switch level {
        case .beginner:
            // Green circle
            Circle()
                .fill(hexColor("22C55E"))
                .frame(width: 12, height: 12)
        case .intermediate:
            // Blue square
            Rectangle()
                .fill(hexColor("3B82F6"))
                .frame(width: 12, height: 12)
        case .advanced:
            // Black diamond
            Image(systemName: "diamond.fill")
                .font(.system(size: 12))
                .foregroundStyle(.black)
        case .expert:
            // Double black diamond
            HStack(spacing: 1) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 10))
                Image(systemName: "diamond.fill")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.black)
        case .all:
            // Multi-level icon (stacked shapes)
            HStack(spacing: 2) {
                Circle()
                    .fill(hexColor("22C55E"))
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(hexColor("3B82F6"))
                    .frame(width: 8, height: 8)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.black)
            }
        }
    }

    private func skillLevelLabel(for level: SkillLevel) -> String {
        switch level {
        case .beginner: return "Green"
        case .intermediate: return "Blue"
        case .advanced: return "Black"
        case .expert: return "Double Black"
        case .all: return "All Levels"
        }
    }

    private func skillLevelColor(for level: SkillLevel) -> Color {
        switch level {
        case .beginner: return hexColor("22C55E")
        case .intermediate: return hexColor("3B82F6")
        case .advanced: return .primary
        case .expert: return .primary
        case .all: return hexColor("A855F7")
        }
    }

    private func hexColor(_ hex: String) -> Color {
        Color(hex: hex) ?? .gray
    }
}

#Preview("Events") {
    EventsView()
        .environment(AuthService.shared)
}
