import SwiftUI

struct AlertsView: View {
    @State private var selectedMountainId: String = "baker"
    @State private var alerts: [WeatherAlert] = []
    @State private var mountainName: String = ""
    @State private var isLoading = true
    @State private var error: String?
    @State private var showMountainPicker = false
    @State private var mountainsViewModel = MountainSelectionViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading alerts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    ErrorView(message: error) {
                        Task { await loadAlerts() }
                    }
                } else if alerts.isEmpty {
                    emptyState
                } else {
                    alertsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weather Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showMountainPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(mountainName.isEmpty ? "Select Mountain" : mountainName)
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                }
            }
            .refreshable {
                await loadAlerts()
            }
            .task(id: selectedMountainId) {
                await loadAlerts()
            }
            .sheet(isPresented: $showMountainPicker) {
                mountainPickerSheet
            }
        }
    }

    private var mountainPickerSheet: some View {
        NavigationStack {
            List(mountainsViewModel.mountains) { mountain in
                Button {
                    selectedMountainId = mountain.id
                    mountainName = mountain.shortName
                    showMountainPicker = false
                } label: {
                    HStack {
                        MountainLogoView(
                            logoUrl: mountain.logo,
                            color: mountain.color,
                            size: 32
                        )

                        Text(mountain.name)
                            .foregroundColor(.primary)

                        Spacer()

                        if mountain.id == selectedMountainId {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Mountain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showMountainPicker = false
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("No Active Alerts")
                .font(.title2)
                .fontWeight(.bold)

            Text("There are no weather alerts for \(mountainName).")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("We'll notify you when weather alerts are issued.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var alertsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(alerts) { alert in
                    AlertCard(alert: alert)
                }
            }
            .padding()
        }
    }

    private func loadAlerts() async {
        isLoading = true
        error = nil

        do {
            guard let url = URL(string: "\(AppConfig.apiBaseURL)/mountains/\(selectedMountainId)/alerts") else {
                self.error = "Invalid URL"
                isLoading = false
                return
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(WeatherAlertsResponse.self, from: data)

            mountainName = response.mountain.name
            alerts = response.alerts
        } catch {
            self.error = "Unable to load weather alerts. Please try again."
        }

        isLoading = false
    }
}

struct AlertCard: View {
    let alert: WeatherAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: severityIcon)
                    .foregroundColor(severityColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.event)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(alert.severity.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(severityColor)
                }

                Spacer()
            }

            Text(alert.headline)
                .font(.subheadline)
                .foregroundColor(.primary)

            if let onset = alert.onset {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Effective: \(formatDate(onset))")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            if let expires = alert.expires {
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.caption)
                    Text("Expires: \(formatDate(expires))")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Divider()

            Text(alert.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if let instruction = alert.instruction {
                Text(instruction)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.3), lineWidth: 2)
        )
    }

    private var severityIcon: String {
        switch alert.severity.lowercased() {
        case "extreme":
            return "exclamationmark.triangle.fill"
        case "severe":
            return "exclamationmark.triangle"
        case "moderate":
            return "exclamationmark.circle"
        default:
            return "info.circle"
        }
    }

    private var severityColor: Color {
        switch alert.severity.lowercased() {
        case "extreme":
            return .red
        case "severe":
            return .orange
        case "moderate":
            return .yellow
        default:
            return .blue
        }
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: isoString) else {
            return isoString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short

        return displayFormatter.string(from: date)
    }
}

#Preview {
    AlertsView()
}
