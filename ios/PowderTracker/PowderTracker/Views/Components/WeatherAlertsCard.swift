import SwiftUI

/// Displays weather alerts from WeatherKit
struct WeatherAlertsCard: View {
    let alerts: [WeatherKitAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Weather Alerts")
                    .font(.headline)
                Spacer()
                WeatherAttributionInline()
            }
            
            ForEach(alerts) { alert in
                WeatherAlertRow(alert: alert)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct WeatherAlertRow: View {
    let alert: WeatherKitAlert
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            severityBadge
                            Text(alert.region)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(alert.summary)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("Source: \(alert.source)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: alert.detailsURL) {
                        HStack {
                            Text("View Full Details")
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                        .foregroundStyle(.blue)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(severityBackgroundColor.opacity(0.1))
        .cornerRadius(.cornerRadiusButton)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .stroke(severityBackgroundColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var severityBadge: some View {
        Text(alert.severity.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severityColor)
            .cornerRadius(4)
    }
    
    private var severityColor: Color {
        switch alert.severity.lowercased() {
        case "extreme":
            return .purple
        case "severe":
            return .red
        case "moderate":
            return .orange
        case "minor":
            return .yellow
        default:
            return .gray
        }
    }
    
    private var severityBackgroundColor: Color {
        switch alert.severity.lowercased() {
        case "extreme":
            return .purple
        case "severe":
            return .red
        case "moderate":
            return .orange
        case "minor":
            return .yellow
        default:
            return .gray
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            WeatherAlertsCard(alerts: [
                WeatherKitAlert(
                    id: "1",
                    source: "National Weather Service",
                    severity: "severe",
                    summary: "Winter Storm Warning until 6:00 PM PST",
                    detailsURL: URL(string: "https://weather.gov")!,
                    region: "Cascade Mountains"
                ),
                WeatherKitAlert(
                    id: "2",
                    source: "National Weather Service",
                    severity: "moderate",
                    summary: "High Wind Watch from 3:00 AM to 9:00 PM PST",
                    detailsURL: URL(string: "https://weather.gov")!,
                    region: "Sierra Nevada"
                )
            ])
        }
        .padding()
    }
}
