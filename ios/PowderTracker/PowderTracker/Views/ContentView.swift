import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService

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
    }
}

#Preview {
    ContentView()
}
