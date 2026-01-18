import SwiftUI

struct AlertsView: View {
    // Optional mountainId for embedding in mountain detail views
    // When provided, shows alerts for that mountain only without picker
    let mountainId: String?
    let mountainName: String?

    @State private var selectedMountainId: String = "baker"
    @State private var alerts: [WeatherAlert] = []
    @State private var displayMountainName: String = ""
    @State private var isLoading = true
    @State private var error: String?
    @State private var showMountainPicker = false
    @State private var mountainsViewModel = MountainSelectionViewModel()

    // Computed property to determine if we're in embedded mode (single mountain)
    private var isEmbedded: Bool {
        mountainId != nil
    }

    // Convenience initializer for standalone use (no mountainId filter)
    init() {
        self.mountainId = nil
        self.mountainName = nil
    }

    // Initializer for embedded use within a mountain detail view
    init(mountainId: String, mountainName: String) {
        self.mountainId = mountainId
        self.mountainName = mountainName
    }

    var body: some View {
        // When embedded, show content directly without NavigationStack
        if isEmbedded {
            embeddedContent
        } else {
            standaloneContent
        }
    }

    // Content for embedded use (within mountain detail view)
    private var embeddedContent: some View {
        Group {
            if isLoading {
                ProgressView("Loading alerts...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if let error = error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Unable to load alerts")
                        .font(.subheadline)
                    Button("Retry") {
                        Task { await loadAlerts() }
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if alerts.isEmpty {
                embeddedEmptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(alerts) { alert in
                        AlertCard(alert: alert)
                    }
                }
            }
        }
        .task {
            // Initialize with provided mountainId
            if let id = mountainId {
                selectedMountainId = id
            }
            if let name = mountainName {
                displayMountainName = name
            }
            await loadAlerts()
        }
    }

    // Content for standalone use (as a full screen view)
    private var standaloneContent: some View {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showMountainPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(displayMountainName.isEmpty ? "Select Mountain" : displayMountainName)
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

    // Compact empty state for embedded mode
    private var embeddedEmptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("No Active Alerts")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Conditions are safe")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var mountainPickerSheet: some View {
        NavigationStack {
            List(mountainsViewModel.mountains) { mountain in
                Button {
                    selectedMountainId = mountain.id
                    displayMountainName = mountain.shortName
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

            Text("There are no weather alerts for \(displayMountainName).")
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

            displayMountainName = response.mountain.name
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
