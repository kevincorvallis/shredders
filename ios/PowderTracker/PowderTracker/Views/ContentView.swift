import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @Binding var deepLinkMountainId: String?
    @Binding var deepLinkEventId: String?
    @Binding var deepLinkInviteToken: String?
    @State private var selectedMountain: Mountain? = nil
    @State private var selectedEventId: String? = nil
    @State private var selectedInviteToken: String? = nil
    @State private var selectedTab: Int = 0
    @StateObject private var mountainsViewModel = MountainSelectionViewModel()
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            // New Today view - primary landing screen
            TodayView(viewModel: homeViewModel)
                .tabItem {
                    Label("Today", systemImage: "sun.snow.fill")
                }
                .tag(0)

            // Redesigned Mountains grid view
            MountainsView()
                .tabItem {
                    Label("Mountains", systemImage: "mountain.2.fill")
                }
                .tag(1)

            // Events tab
            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(2)

            MountainMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(3)

            // Profile tab - re-enabled
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(4)
        }
        .onChange(of: deepLinkMountainId) { oldValue, newValue in
            if let mountainId = newValue {
                // Look up the mountain
                if let mountain = mountainsViewModel.mountains.first(where: { $0.id == mountainId }) {
                    selectedMountain = mountain
                }
                // Clear the deep link after handling
                deepLinkMountainId = nil
            }
        }
        .onChange(of: deepLinkEventId) { oldValue, newValue in
            if let eventId = newValue {
                selectedEventId = eventId
                selectedTab = 2 // Switch to Events tab
                deepLinkEventId = nil
            }
        }
        .onChange(of: deepLinkInviteToken) { oldValue, newValue in
            if let token = newValue {
                selectedInviteToken = token
                selectedTab = 2 // Switch to Events tab
                deepLinkInviteToken = nil
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
