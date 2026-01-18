import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @Binding var deepLinkMountainId: String?
    @State private var selectedMountain: Mountain? = nil
    @StateObject private var mountainsViewModel = MountainSelectionViewModel()
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        TabView {
            // New Today view - primary landing screen
            TodayView(viewModel: homeViewModel)
                .tabItem {
                    Label("Today", systemImage: "sun.snow.fill")
                }

            // Redesigned Mountains grid view
            MountainsView()
                .tabItem {
                    Label("Mountains", systemImage: "mountain.2.fill")
                }

            MountainMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            // Profile tab - re-enabled
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
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
        .task {
            await mountainsViewModel.loadMountains()
        }
    }
}

#Preview {
    ContentView(deepLinkMountainId: .constant(nil))
}
