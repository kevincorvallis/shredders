//
//  WeatherAlertsSettingsView.swift
//  PowderTracker
//
//  Settings for weather and storm alerts.
//

import SwiftUI

struct WeatherAlertsSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Alert preferences stored in AppStorage
    @AppStorage("alertStormWarnings") private var stormWarnings = true
    @AppStorage("alertRoadClosures") private var roadClosures = true
    @AppStorage("alertHighWinds") private var highWinds = false
    @AppStorage("alertAvalanche") private var avalancheAlerts = true
    @AppStorage("alertChainRequirements") private var chainRequirements = true
    @AppStorage("alertTemperatureDrops") private var temperatureDrops = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $stormWarnings) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Storm Warnings")
                                Text("Major winter storms approaching")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "cloud.snow.fill")
                                .foregroundStyle(.blue)
                        }
                    }

                    Toggle(isOn: $roadClosures) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Road Closures")
                                Text("Pass closures and restrictions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "road.lanes.curved.right")
                                .foregroundStyle(.orange)
                        }
                    }

                    Toggle(isOn: $chainRequirements) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Chain Requirements")
                                Text("Traction advisories")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "link")
                                .foregroundStyle(.gray)
                        }
                    }
                } header: {
                    Text("Road & Travel")
                }

                Section {
                    Toggle(isOn: $avalancheAlerts) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Avalanche Warnings")
                                Text("High danger ratings from NWAC")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                    }

                    Toggle(isOn: $highWinds) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("High Winds")
                                Text("Lift closures due to wind")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "wind")
                                .foregroundStyle(.cyan)
                        }
                    }

                    Toggle(isOn: $temperatureDrops) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Extreme Cold")
                                Text("Temperatures below 0°F")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "thermometer.snowflake")
                                .foregroundStyle(.purple)
                        }
                    }
                } header: {
                    Text("Safety")
                }

                Section {
                    Text("Weather alerts are checked every 30 minutes. You'll receive push notifications when conditions change.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("Data from NOAA, NWAC, and WSDOT")
                }
            }
            .navigationTitle("Weather Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WeatherAlertsSettingsView()
}
