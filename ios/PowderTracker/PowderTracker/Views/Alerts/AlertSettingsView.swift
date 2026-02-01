import SwiftUI

struct AlertSettingsView: View {
    let mountainId: String
    let mountainName: String

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var subscription: AlertSubscription?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Form state
    @State private var weatherAlertsEnabled = true
    @State private var powderAlertsEnabled = true
    @State private var powderThreshold = 6
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                // Push Notifications Section
                Section {
                    NavigationLink {
                        PushNotificationSetupView()
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.blue)
                            Text("Enable Push Notifications")
                            Spacer()
                            if PushNotificationService.shared.isRegistered {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Enable push notifications to receive weather and powder alerts")
                }

                // Alert Types Section
                Section {
                    Toggle("Weather Alerts", isOn: $weatherAlertsEnabled)
                    Toggle("Powder Alerts", isOn: $powderAlertsEnabled)
                } header: {
                    Text("Alert Types")
                } footer: {
                    Text("Choose which types of alerts you want to receive for \(mountainName)")
                }

                // Powder Threshold Section
                if powderAlertsEnabled {
                    Section {
                        Stepper("Minimum: \(powderThreshold)\"", value: $powderThreshold, in: 1...24)

                        Text("You'll be notified when \(mountainName) receives at least \(powderThreshold)\" of fresh snow in 24 hours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Powder Alert Threshold")
                    }
                }

                // Error message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Alert Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveSettings()
                        }
                    }
                    .disabled(isSaving || isLoading)
                }
            }
            .task {
                await loadSubscription()
            }
        }
    }

    private func loadSubscription() async {
        guard authService.isAuthenticated else {
            errorMessage = "Please sign in to manage alert settings"
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let subscriptions = try await AlertSubscriptionService.shared.fetchSubscriptions(for: mountainId)

            if let sub = subscriptions.first {
                subscription = sub
                weatherAlertsEnabled = sub.weatherAlerts
                powderAlertsEnabled = sub.powderAlerts
                powderThreshold = sub.powderThreshold
            }
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func saveSettings() async {
        guard authService.isAuthenticated else {
            errorMessage = "Please sign in to save settings"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let updatedSub = try await AlertSubscriptionService.shared.subscribe(
                mountainId: mountainId,
                weatherAlerts: weatherAlertsEnabled,
                powderAlerts: powderAlertsEnabled,
                powderThreshold: powderThreshold
            )

            subscription = updatedSub
            dismiss()
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
        }

        isSaving = false
    }
}

#Preview {
    AlertSettingsView(mountainId: "baker", mountainName: "Mt. Baker")
        .environment(AuthService.shared)
}
