import SwiftUI

struct QuickStatsDashboard: View {
    let mountains: [Mountain]
    let conditionsMap: [String: MountainConditions]
    let scoresMap: [String: Int]
    let alertsMap: [String: [WeatherAlert]]

    var body: some View {
        HStack(spacing: 12) {
            // Total fresh snow today
            DashboardStat(
                icon: "snow",
                value: totalFreshSnow,
                label: "Fresh Today",
                color: .blue
            )

            Divider()
                .frame(height: 50)

            // Mountains with powder
            DashboardStat(
                icon: "mountain.2.fill",
                value: "\(powderMountainsCount)",
                label: "Powder Days",
                color: .green
            )

            Divider()
                .frame(height: 50)

            // Active alerts
            DashboardStat(
                icon: "exclamationmark.triangle.fill",
                value: "\(activeAlertsCount)",
                label: "Alerts",
                color: alertsColor
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Computed Stats

    private var totalFreshSnow: String {
        let total = mountains.compactMap { mountain in
            conditionsMap[mountain.id]?.snowfall24h
        }.reduce(0, +)

        return total > 0 ? "\(Int(total))\"" : "0\""
    }

    private var powderMountainsCount: Int {
        mountains.filter { mountain in
            guard let conditions = conditionsMap[mountain.id] else { return false }
            return conditions.snowfall24h >= 6 // 6"+ = powder day
        }.count
    }

    private var activeAlertsCount: Int {
        alertsMap.values.flatMap { $0 }.count
    }

    private var alertsColor: Color {
        activeAlertsCount > 0 ? .red : .secondary
    }
}

struct DashboardStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
