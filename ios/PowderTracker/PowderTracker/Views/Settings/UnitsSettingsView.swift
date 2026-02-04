//
//  UnitsSettingsView.swift
//  PowderTracker
//
//  Settings for measurement units (temperature, distance, snowfall).
//

import SwiftUI

struct UnitsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("temperatureUnit") private var temperatureUnit = "F"
    @AppStorage("distanceUnit") private var distanceUnit = "mi"
    @AppStorage("snowfallUnit") private var snowfallUnit = "in"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Temperature", selection: $temperatureUnit) {
                        Label("Fahrenheit (°F)", systemImage: "thermometer.high")
                            .tag("F")
                        Label("Celsius (°C)", systemImage: "thermometer.low")
                            .tag("C")
                    }
                    .onChange(of: temperatureUnit) { _, _ in
                        HapticFeedback.selection.trigger()
                    }

                    Picker("Distance", selection: $distanceUnit) {
                        Label("Miles", systemImage: "car")
                            .tag("mi")
                        Label("Kilometers", systemImage: "car")
                            .tag("km")
                    }
                    .onChange(of: distanceUnit) { _, _ in
                        HapticFeedback.selection.trigger()
                    }

                    Picker("Snowfall", selection: $snowfallUnit) {
                        Label("Inches", systemImage: "snowflake")
                            .tag("in")
                        Label("Centimeters", systemImage: "snowflake")
                            .tag("cm")
                    }
                    .onChange(of: snowfallUnit) { _, _ in
                        HapticFeedback.selection.trigger()
                    }
                } header: {
                    Text("Measurement Units")
                } footer: {
                    Text("These settings affect how measurements are displayed throughout the app.")
                }

                Section {
                    Button("Reset to Defaults") {
                        withAnimation {
                            temperatureUnit = "F"
                            distanceUnit = "mi"
                            snowfallUnit = "in"
                        }
                        HapticFeedback.success.trigger()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Units")
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

// MARK: - Unit Helpers

extension String {
    /// Format temperature based on user's unit preference
    static func formatTemperature(_ fahrenheit: Double, unit: String) -> String {
        if unit == "C" {
            let celsius = (fahrenheit - 32) * 5 / 9
            return String(format: "%.0f°C", celsius)
        }
        return String(format: "%.0f°F", fahrenheit)
    }

    /// Format distance based on user's unit preference
    static func formatDistance(_ miles: Double, unit: String) -> String {
        if unit == "km" {
            let km = miles * 1.60934
            return String(format: "%.1f km", km)
        }
        return String(format: "%.1f mi", miles)
    }

    /// Format snowfall based on user's unit preference
    static func formatSnowfall(_ inches: Double, unit: String) -> String {
        if unit == "cm" {
            let cm = inches * 2.54
            return String(format: "%.0f cm", cm)
        }
        return String(format: "%.0f\"", inches)
    }
}

#Preview {
    UnitsSettingsView()
}
