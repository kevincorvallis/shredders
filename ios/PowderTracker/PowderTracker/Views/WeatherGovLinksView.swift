import SwiftUI

struct WeatherGovLinksView: View {
    let mountainId: String
    @State private var links: WeatherGovLinks?
    @State private var alerts: [WeatherAlert] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            // Weather Alerts Section
            if !alerts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(alerts) { alert in
                        WeatherAlertCard(alert: alert)
                    }
                }
            }

            // Weather.gov Quick Links
            if let links = links {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.blue)
                        Text("NOAA Weather.gov")
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))

                    Divider()

                    VStack(spacing: 0) {
                        WeatherGovLinkRow(
                            title: "Detailed Forecast",
                            icon: "list.bullet.rectangle",
                            url: links.forecast
                        )

                        Divider().padding(.leading, 50)

                        WeatherGovLinkRow(
                            title: "Hourly Graph",
                            icon: "chart.xyaxis.line",
                            url: links.hourly
                        )

                        Divider().padding(.leading, 50)

                        WeatherGovLinkRow(
                            title: "Active Alerts",
                            icon: "exclamationmark.triangle",
                            url: links.alerts
                        )

                        Divider().padding(.leading, 50)

                        WeatherGovLinkRow(
                            title: "Forecast Discussion",
                            icon: "doc.text",
                            url: links.discussion
                        )
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        async let linksTask: () = loadLinks()
        async let alertsTask: () = loadAlerts()

        await linksTask
        await alertsTask
    }

    private func loadLinks() async {
        do {
            let response = try await APIClient.shared.fetchWeatherGovLinks(for: mountainId)

            // Check if task was cancelled before updating state
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.links = response.weatherGov
            }
        } catch {
            // Only log non-cancellation errors
            if !Task.isCancelled && (error as NSError).code != NSURLErrorCancelled {
                print("Failed to load weather.gov links: \(error)")
            }
        }
    }

    private func loadAlerts() async {
        do {
            let response = try await APIClient.shared.fetchAlerts(for: mountainId)

            // Check if task was cancelled before updating state
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.alerts = response.alerts
            }
        } catch {
            // Only log non-cancellation errors
            if !Task.isCancelled && (error as NSError).code != NSURLErrorCancelled {
                print("Failed to load alerts: \(error)")
            }
        }
    }
}

struct WeatherAlertCard: View {
    let alert: WeatherAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(severityColor)
                Text(alert.event)
                    .font(.headline)
                    .foregroundColor(severityColor)
                Spacer()
            }

            Text(alert.headline)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(alert.description)
                .font(.caption)
                .lineLimit(4)
                .foregroundColor(.secondary)

            if let instruction = alert.instruction {
                Text(instruction)
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(6)
                    .lineLimit(3)
            }

            if let expires = alert.expires {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Expires: \(formatDate(expires))")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(severityColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.3), lineWidth: 2)
        )
    }

    private var severityColor: Color {
        switch alert.severity.lowercased() {
        case "extreme":
            return .red
        case "severe":
            return .orange
        case "moderate":
            return .yellow
        case "minor":
            return .blue
        default:
            return .gray
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

struct WeatherGovLinkRow: View {
    let title: String
    let icon: String
    let url: String

    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
