import SwiftUI

struct ConditionsCard: View {
    let conditions: Conditions

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Conditions")
                    .font(.headline)
                Spacer()
                Text(conditions.lastUpdatedString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ConditionItem(icon: "ruler", title: "Snow Depth", value: "\(conditions.snowDepth)\"")
                ConditionItem(icon: "snowflake", title: "24hr Snow", value: "\(conditions.snowfall24h)\"")
                ConditionItem(icon: "thermometer.snowflake", title: "Summit", value: "\(conditions.temperature.summit)°F")
                ConditionItem(icon: "thermometer", title: "Base", value: "\(conditions.temperature.base)°F")
                ConditionItem(icon: "wind", title: "Wind", value: "\(conditions.wind.speed) mph \(conditions.wind.direction)")
                ConditionItem(icon: "cloud.snow", title: "48hr Snow", value: "\(conditions.snowfall48h)\"")
                ConditionItem(icon: "arrow.up.to.line", title: "Freezing Level", value: "\(conditions.freezingLevel)'")
                ConditionItem(icon: "calendar", title: "7 Day Snow", value: "\(conditions.snowfall7d)\"")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct ConditionItem: View {
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
    ConditionsCard(conditions: .mock)
        .padding()
        .background(Color(.systemGroupedBackground))
}
