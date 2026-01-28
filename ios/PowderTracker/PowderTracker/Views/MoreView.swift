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
                        HistoryChartView()
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

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(spacing: 8) {
                    Text("PowderTracker")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Your ultimate ski conditions companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(title: "Version", value: "1.0.0")
                    InfoRow(title: "Data Sources", value: "SNOTEL, NOAA, WSDOT")
                    InfoRow(title: "Coverage", value: "15 Pacific Northwest mountains")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)

                VStack(spacing: 12) {
                    Text("Data provided by:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        Text("USDA SNOTEL")
                        Text("•")
                        Text("NOAA")
                        Text("•")
                        Text("WSDOT")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

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
                Toggle("Powder Alerts", isOn: .constant(false))
                    .disabled(true)
                Toggle("Weather Alerts", isOn: .constant(false))
                    .disabled(true)
                Text("Notifications coming soon!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Data") {
                Button("Clear Cache") {
                    // TODO: Implement cache clearing
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Settings")
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
