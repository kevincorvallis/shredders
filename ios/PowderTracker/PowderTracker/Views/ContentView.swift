import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @Binding var deepLinkMountainId: String?
    @State private var selectedMountain: Mountain? = nil
    @StateObject private var mountainsViewModel = MountainSelectionViewModel()

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

            MountainMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            // MARK: - Profile tab temporarily disabled for App Store release
            // TODO: Re-enable once Sign in with Apple is configured in Supabase
            // ProfileView()
            //     .tabItem {
            //         Label("Profile", systemImage: "person.circle.fill")
            //     }

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
        .task {
            await mountainsViewModel.loadMountains()
        }
    }
}

#Preview {
    ContentView(deepLinkMountainId: .constant(nil))
}
