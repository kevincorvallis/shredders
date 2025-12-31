import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // OpenSnow-style Home with horizontal forecast timeline
            NewHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Redesigned Mountains grid view
            NewMountainsView()
                .tabItem {
                    Label("Mountains", systemImage: "mountain.2.fill")
                }

            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "exclamationmark.triangle.fill")
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
