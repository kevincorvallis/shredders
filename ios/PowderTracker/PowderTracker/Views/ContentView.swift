import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var deepLinkMountainId: String?
    @Binding var deepLinkEventId: String?
    @Binding var deepLinkInviteToken: String?
    @State private var selectedMountain: Mountain? = nil
    @State private var selectedEventId: String? = nil
    @State private var selectedInviteToken: String? = nil
    @State private var selectedTab: Int = 0
    @State private var selectedSection: NavigationSection? = .today
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var mountainsViewModel = MountainSelectionViewModel()
    @State private var homeViewModel = HomeViewModel()

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadNavigation
            } else {
                iPhoneNavigation
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Haptic feedback on tab change
            HapticFeedback.selection.trigger()
        }
        .onChange(of: selectedSection) { oldValue, newValue in
            // Sync tab selection with section for deep links
            if let section = newValue {
                switch section {
                case .today: selectedTab = 0
                case .mountains: selectedTab = 1
                case .events: selectedTab = 2
                case .map: selectedTab = 3
                case .profile: selectedTab = 4
                }
                HapticFeedback.selection.trigger()
            }
        }
        .onChange(of: deepLinkMountainId) { oldValue, newValue in
            if let mountainId = newValue {
                if let mountain = mountainsViewModel.mountains.first(where: { $0.id == mountainId }) {
                    selectedMountain = mountain
                }
                deepLinkMountainId = nil
            }
        }
        .onChange(of: deepLinkEventId) { oldValue, newValue in
            if let eventId = newValue {
                selectedEventId = eventId
                selectedTab = 2
                selectedSection = .events
                deepLinkEventId = nil
            }
        }
        .onChange(of: deepLinkInviteToken) { oldValue, newValue in
            if let token = newValue {
                selectedInviteToken = token
                selectedTab = 2
                selectedSection = .events
                deepLinkInviteToken = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTab"))) { notification in
            if let tabIndex = notification.userInfo?["tabIndex"] as? Int {
                withAnimation(.smooth) {
                    selectedTab = tabIndex
                    // Sync section selection for iPad
                    switch tabIndex {
                    case 0: selectedSection = .today
                    case 1: selectedSection = .mountains
                    case 2: selectedSection = .events
                    case 3: selectedSection = .map
                    case 4: selectedSection = .profile
                    default: break
                    }
                }
            }
        }
        .sheet(item: $selectedMountain) { mountain in
            NavigationStack {
                MountainDetailView(mountain: mountain)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedMountain = nil
                            }
                        }
                    }
            }
        }
        .sheet(item: Binding(
            get: { selectedEventId.map { EventSheetId(id: $0) } },
            set: { selectedEventId = $0?.id }
        )) { eventSheet in
            NavigationStack {
                EventDetailView(eventId: eventSheet.id)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedEventId = nil
                            }
                        }
                    }
            }
        }
        .sheet(item: Binding(
            get: { selectedInviteToken.map { InviteSheetToken(token: $0) } },
            set: { selectedInviteToken = $0?.token }
        )) { inviteSheet in
            NavigationStack {
                EventInviteView(token: inviteSheet.token) { eventId in
                    selectedInviteToken = nil
                    selectedEventId = eventId
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            selectedInviteToken = nil
                        }
                    }
                }
            }
        }
        .task {
            await mountainsViewModel.loadMountains()
        }
    }

    // MARK: - iPad Navigation (Sidebar + Detail)
    @ViewBuilder
    private var iPadNavigation: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(NavigationSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("PowderTracker")
            .listStyle(.sidebar)
        } detail: {
            NavigationStack {
                switch selectedSection {
                case .today:
                    TodayView(viewModel: homeViewModel)
                case .mountains:
                    MountainsTabView()
                case .events:
                    EventsView()
                case .map:
                    MountainMapView()
                case .profile:
                    ProfileView()
                case nil:
                    ContentUnavailableView(
                        "Select a Section",
                        systemImage: "mountain.2.fill",
                        description: Text("Choose a section from the sidebar")
                    )
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - iPhone Navigation (TabView)
    @ViewBuilder
    private var iPhoneNavigation: some View {
        TabView(selection: $selectedTab) {
            TodayView(viewModel: homeViewModel)
                .tabItem {
                    Label("Today", systemImage: "sun.snow.fill")
                }
                .tag(0)
                .accessibilityIdentifier("tab_today")

            MountainsTabView()
                .tabItem {
                    Label("Mountains", systemImage: "mountain.2.fill")
                }
                .tag(1)
                .accessibilityIdentifier("tab_mountains")

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(2)
                .accessibilityIdentifier("tab_events")

            MountainMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(3)
                .accessibilityIdentifier("tab_map")

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(4)
                .accessibilityIdentifier("tab_profile")
        }
    }
}

// Helper structs for sheet presentation
struct EventSheetId: Identifiable {
    let id: String
}

struct InviteSheetToken: Identifiable {
    let token: String
    var id: String { token }
}

#Preview {
    ContentView(
        deepLinkMountainId: .constant(nil),
        deepLinkEventId: .constant(nil),
        deepLinkInviteToken: .constant(nil)
    )
}
