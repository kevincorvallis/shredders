import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @Binding var deepLinkMountainId: String?
    @State private var selectedMountain: Mountain? = nil
    @State private var mountainsViewModel = MountainSelectionViewModel()

    var body: some View {
        TabView {
            // OpenSnow-style Home with horizontal forecast timeline
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Redesigned Mountains grid view
            MountainsView()
                .tabItem {
                    Label("Mountains", systemImage: "mountain.2.fill")
                }

            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "exclamationmark.triangle.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
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
        .sheet(item: $selectedMountain) { mountain in
            NavigationStack {
                LocationView(mountain: mountain)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedMountain = nil
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView(deepLinkMountainId: .constant(nil))
}
