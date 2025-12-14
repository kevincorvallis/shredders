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

            NavigationStack {
                ForecastView()
            }
            .tabItem {
                Label("Forecast", systemImage: "calendar")
            }

            NavigationStack {
                HistoryChartView()
            }
            .tabItem {
                Label("History", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }
}

#Preview {
    ContentView()
}
