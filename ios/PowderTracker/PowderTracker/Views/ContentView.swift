import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "mountain.2.circle.fill")
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
