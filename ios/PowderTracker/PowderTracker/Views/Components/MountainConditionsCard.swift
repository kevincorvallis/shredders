import SwiftUI

struct MountainConditionsCard: View {
    let conditions: MountainConditions

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Conditions")
                    .font(.headline)
                Spacer()
                Text(lastUpdatedString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let snowDepth = conditions.snowDepth {
                    ConditionMetric(icon: "ruler", title: "Snow Depth", value: "\(snowDepth)\"")
                }
                ConditionMetric(icon: "snowflake", title: "24hr Snow", value: "\(conditions.snowfall24h)\"")
                if let temp = conditions.temperature {
                    ConditionMetric(icon: "thermometer.snowflake", title: "Temperature", value: "\(temp)°F")
                }
                if let wind = conditions.wind {
                    ConditionMetric(icon: "wind", title: "Wind", value: "\(wind.speed) mph \(wind.direction)")
                }
                ConditionMetric(icon: "cloud.snow", title: "48hr Snow", value: "\(conditions.snowfall48h)\"")
                ConditionMetric(icon: "calendar", title: "7 Day Snow", value: "\(conditions.snowfall7d)\"")
            }

            HStack {
                Image(systemName: weatherIcon)
                    .foregroundColor(.blue)
                Text(conditions.conditions)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var lastUpdatedString: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: conditions.lastUpdated) else { return "Unknown" }
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private var weatherIcon: String {
        let cond = conditions.conditions.lowercased()
        if cond.contains("snow") { return "cloud.snow.fill" }
        if cond.contains("rain") { return "cloud.rain.fill" }
        if cond.contains("cloud") { return "cloud.fill" }
        if cond.contains("sun") || cond.contains("clear") { return "sun.max.fill" }
        return "cloud.fill"
    }
}

struct ConditionMetric: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
    }
}

#Preview {
    MountainConditionsCard(conditions: .mock)
        .padding()
        .background(Color(.systemGroupedBackground))
}
