import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "snowflake")
                }

            MountainMapView()
                .tabItem {
                    Label("Mountains", systemImage: "map")
                }

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            PatrolView()
                .tabItem {
                    Label("Patrol", systemImage: "shield")
                }

            NavigationStack {
                ForecastView()
            }
            .tabItem {
                Label("Forecast", systemImage: "calendar")
            }
        }
    }
}

#Preview {
    ContentView()
}
