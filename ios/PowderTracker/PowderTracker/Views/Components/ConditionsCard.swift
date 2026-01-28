import SwiftUI

struct ConditionsCard: View {
    let conditions: Conditions

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Text("Current Conditions")
                    .sectionHeader()
                Spacer()
                Text(conditions.lastUpdatedString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: .spacingM) {
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
        .padding(.spacingM)
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
        .cardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current conditions. Snow depth \(conditions.snowDepth) inches. 24 hour snow \(conditions.snowfall24h) inches. Summit temperature \(conditions.temperature.summit) degrees. Base temperature \(conditions.temperature.base) degrees. Wind \(conditions.wind.speed) miles per hour from the \(conditions.wind.direction).")
    }
}

struct ConditionItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .metric()
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    ConditionsCard(conditions: .mock)
        .padding()
        .background(Color(.systemGroupedBackground))
}
