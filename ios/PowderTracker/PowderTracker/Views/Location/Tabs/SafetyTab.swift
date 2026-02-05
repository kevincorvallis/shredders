import SwiftUI

struct SafetyTab: View {
    var viewModel: LocationViewModel
    let mountain: Mountain

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                // Current Alerts
                currentAlertsCard

                // Avalanche Conditions
                avalancheCard

                // Road Conditions
                roadConditionsCard

                // Ski Patrol Info
                patrolInfoCard
            }
            .padding(.spacingM)
        }
    }

    // MARK: - Current Alerts

    private var currentAlertsCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("Active Alerts")
                    .font(.headline)
                Spacer()
                Text("1")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange)
                    .clipShape(Capsule())
            }

            Divider()

            HStack(alignment: .top, spacing: .spacingS) {
                Image(systemName: "wind")
                    .font(.title3)
                    .foregroundStyle(.cyan)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text("High Wind Advisory")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Gusts up to 45 mph expected. Upper lifts may experience delays.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Expires: 4:00 PM today")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - Avalanche Conditions

    private var avalancheCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "mountain.2.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("Avalanche Conditions")
                    .font(.headline)
                Spacer()
            }

            Divider()

            HStack(spacing: .spacingL) {
                // Danger Level
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 50, height: 50)
                        Text("2")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                    }
                    Text("Moderate")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Problem: Wind Slabs")
                        .font(.subheadline)
                    Text("Aspects: N, NE, E")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Elevation: Above 6,000'")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Button {
                if let url = URL(string: "https://nwac.us") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("View Full NWAC Forecast")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - Road Conditions

    private var roadConditionsCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Road Conditions")
                    .font(.headline)
                Spacer()
            }

            Divider()

            VStack(spacing: .spacingS) {
                roadRow(road: "SR 20", status: "Open", condition: "Bare/Wet", chains: false)
                roadRow(road: "SR 542", status: "Open", condition: "Compact Snow", chains: true)
            }

            Button {
                if let url = URL(string: "https://wsdot.wa.gov/travel/real-time/mountainpasses") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("View WSDOT Pass Report")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func roadRow(road: String, status: String, condition: String, chains: Bool) -> some View {
        HStack {
            Text(road)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text(condition)
                .font(.caption)
                .foregroundStyle(.secondary)
            if chains {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.green)
        }
    }

    // MARK: - Patrol Info

    private var patrolInfoCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Image(systemName: "cross.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("Ski Patrol")
                    .font(.headline)
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: .spacingS) {
                infoRow(label: "Emergency", value: "911")
                infoRow(label: "Patrol Direct", value: "(360) 555-0123")
                infoRow(label: "First Aid", value: "Base Lodge, Level 2")
            }

            Text("For non-emergencies, contact any lift operator or patrol member.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
