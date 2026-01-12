import SwiftUI
import UserNotifications

struct PushNotificationSetupView: View {
    @State private var pushManager = PushNotificationManager.shared
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequesting = false

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: statusIcon)
                        .font(.title)
                        .foregroundStyle(statusColor)
                        .frame(width: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusTitle)
                            .font(.headline)

                        Text(statusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                switch authStatus {
                case .notDetermined:
                    Button {
                        Task {
                            await requestPermission()
                        }
                    } label: {
                        HStack {
                            Text("Enable Push Notifications")
                            Spacer()
                            if isRequesting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRequesting)

                case .denied:
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Push notifications are disabled in Settings.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            openSettings()
                        } label: {
                            Label("Open Settings", systemImage: "gearshape")
                        }
                    }

                case .authorized, .provisional, .ephemeral:
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Push notifications are enabled", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        if pushManager.deviceToken != nil {
                            Text("Device registered")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                @unknown default:
                    EmptyView()
                }
            } header: {
                Text("Status")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(
                        icon: "cloud.bolt.fill",
                        title: "Weather Alerts",
                        description: "Get notified of severe weather warnings"
                    )

                    Divider()

                    FeatureRow(
                        icon: "snow",
                        title: "Powder Alerts",
                        description: "Know when fresh snow arrives at your favorite mountains"
                    )

                    Divider()

                    FeatureRow(
                        icon: "bell.badge.fill",
                        title: "Timely Updates",
                        description: "Receive alerts as conditions change"
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("What You'll Receive")
            }
        }
        .navigationTitle("Push Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await checkStatus()
        }
    }

    private var statusIcon: String {
        switch authStatus {
        case .notDetermined:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .authorized, .provisional, .ephemeral:
            return "bell.fill"
        @unknown default:
            return "bell.fill"
        }
    }

    private var statusColor: Color {
        switch authStatus {
        case .notDetermined:
            return .orange
        case .denied:
            return .red
        case .authorized, .provisional, .ephemeral:
            return .green
        @unknown default:
            return .gray
        }
    }

    private var statusTitle: String {
        switch authStatus {
        case .notDetermined:
            return "Not Configured"
        case .denied:
            return "Disabled"
        case .authorized, .provisional, .ephemeral:
            return "Enabled"
        @unknown default:
            return "Unknown"
        }
    }

    private var statusDescription: String {
        switch authStatus {
        case .notDetermined:
            return "Enable notifications to receive weather and powder alerts"
        case .denied:
            return "Notifications are turned off in system settings"
        case .authorized, .provisional, .ephemeral:
            return "You'll receive weather and powder alerts"
        @unknown default:
            return ""
        }
    }

    private func checkStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authStatus = settings.authorizationStatus
    }

    private func requestPermission() async {
        isRequesting = true

        do {
            try await pushManager.requestAuthorization()
            await checkStatus()
        } catch {
            print("Failed to request permission:", error)
        }

        isRequesting = false
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PushNotificationSetupView()
    }
}
