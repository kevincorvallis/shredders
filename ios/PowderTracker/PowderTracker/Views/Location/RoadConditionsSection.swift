import SwiftUI

struct RoadConditionsSection: View {
    @ObservedObject var viewModel: LocationViewModel

    var body: some View {
        if let roadData = viewModel.locationData?.roads,
           roadData.supported && !roadData.passes.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Section Header
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.purple)
                    Text("Mountain Pass Conditions")
                        .font(.headline)
                }

                // Pass Conditions
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(roadData.passes) { pass in
                        PassConditionCard(pass: pass)
                    }
                }

                // Provider Info
                if let provider = roadData.provider {
                    Text("Data from \(provider)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Message
                if let message = roadData.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

struct PassConditionCard: View {
    let pass: PassCondition

    var severityColor: Color {
        let roadCondition = pass.roadCondition.lowercased()
        if roadCondition.contains("closed") {
            return .red
        } else if roadCondition.contains("difficult") || roadCondition.contains("snow") || roadCondition.contains("ice") {
            return .orange
        } else if roadCondition.contains("wet") || roadCondition.contains("caution") {
            return .yellow
        }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: pass.travelAdvisory ? "exclamationmark.triangle.fill" : "road.lanes")
                    .foregroundColor(pass.travelAdvisory ? .red : severityColor)
                Text(pass.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Road")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(pass.roadCondition)
                        .font(.caption)
                        .foregroundColor(severityColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Weather")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(pass.weatherCondition)
                        .font(.caption)
                }

                if let temp = pass.temperatureInFahrenheit {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temp")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(temp)°F")
                            .font(.caption)
                    }
                }
            }

            if !pass.restrictions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Restrictions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    ForEach(pass.restrictions, id: \.direction) { restriction in
                        HStack {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                            Text("\(restriction.direction): \(restriction.text)")
                                .font(.caption)
                        }
                    }
                }
            }

            if pass.travelAdvisory {
                Label("Travel Advisory", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(pass.travelAdvisory ? Color.red.opacity(0.3) : severityColor.opacity(0.3), lineWidth: 1)
        )
    }
}
