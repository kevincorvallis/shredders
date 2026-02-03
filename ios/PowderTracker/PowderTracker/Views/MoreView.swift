import SwiftUI

struct MoreView: View {
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ChatView()
                    } label: {
                        Label("Chat", systemImage: "bubble.left.and.bubble.right")
                    }

                    NavigationLink {
                        PatrolView()
                    } label: {
                        Label("Patrol Reports", systemImage: "shield")
                    }

                    NavigationLink {
                        HistoryChartContainer()
                    } label: {
                        Label("Snow History", systemImage: "chart.xyaxis.line")
                    }

                    NavigationLink {
                        WebcamsView(mountainId: selectedMountainId)
                    } label: {
                        Label("Webcams", systemImage: "video")
                    }
                } header: {
                    Text("Features")
                }

                Section {
                    if let weatherURL = URL(string: "https://weather.gov") {
                        Link(destination: weatherURL) {
                            Label("Weather.gov", systemImage: "cloud.sun")
                        }
                    }

                    if let wsdotURL = URL(string: "https://wsdot.com/travel") {
                        Link(destination: wsdotURL) {
                            Label("WSDOT Traffic", systemImage: "car")
                        }
                    }

                    if let nwacURL = URL(string: "https://nwac.us") {
                        Link(destination: nwacURL) {
                            Label("NW Avalanche Center", systemImage: "exclamationmark.triangle")
                        }
                    }
                } header: {
                    Text("External Resources")
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                } header: {
                    Text("App")
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// AboutView moved to Views/Settings/AboutView.swift

struct SettingsView: View {
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"
    @AppStorage("temperatureUnit") private var temperatureUnit = "F"
    @AppStorage("distanceUnit") private var distanceUnit = "mi"

    var body: some View {
        Form {
            Section("Units") {
                Picker("Temperature", selection: $temperatureUnit) {
                    Text("Fahrenheit (°F)").tag("F")
                    Text("Celsius (°C)").tag("C")
                }

                Picker("Distance", selection: $distanceUnit) {
                    Text("Miles").tag("mi")
                    Text("Kilometers").tag("km")
                }
            }

            Section("Notifications") {
                NavigationLink {
                    WeatherAlertsSettingsView()
                } label: {
                    Label("Weather Alerts", systemImage: "cloud.snow.fill")
                }

                NavigationLink {
                    EventNotificationSettingsView()
                } label: {
                    Label("Event Notifications", systemImage: "calendar.badge.clock")
                }
            }

            Section("Data") {
                Button("Clear Cache") {
                    clearCache()
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Settings")
    }

    private func clearCache() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()

        // Clear image cache (Nuke uses shared URLCache by default)
        // Additional cleanup for any custom caches
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        if let cacheURL = cacheURL {
            try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.apple.nsurlsessiond"))
        }

        HapticFeedback.success.trigger()
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    MoreView()
}
