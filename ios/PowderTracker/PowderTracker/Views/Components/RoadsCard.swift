import SwiftUI

struct RoadsCard: View {
    let roads: RoadsResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(.orange)
                Text("Road & Pass Conditions")
                    .font(.headline)
                Spacer()
                if let provider = roads?.provider {
                    Text(provider)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let roads = roads {
                if !roads.supported {
                    Text("Road data not available for this region")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if !roads.configured {
                    Text("Road conditions service not configured")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if roads.passes.isEmpty {
                    Text("No relevant pass data found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(roads.passes.prefix(2)) { pass in
                        PassConditionRow(pass: pass)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(roadsAccessibilityLabel)
    }

    private var roadsAccessibilityLabel: String {
        guard let roads = roads else { return "Road conditions loading" }
        if !roads.supported || !roads.configured || roads.passes.isEmpty {
            return "Road and pass conditions. No data available."
        }
        var label = "Road and pass conditions."
        for pass in roads.passes.prefix(2) {
            label += " \(pass.name): \(pass.roadCondition)."
            if pass.travelAdvisory {
                label += " Travel advisory in effect."
            }
        }
        return label
    }
}

struct PassConditionRow: View {
    let pass: PassCondition

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pass.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if let temp = pass.temperatureInFahrenheit {
                    Text("\(temp)°F")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                Label(pass.roadCondition, systemImage: "road.lanes")
                    .font(.caption)
                    .foregroundStyle(roadConditionColor(pass.roadCondition))

                Label(pass.weatherCondition, systemImage: "cloud.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if pass.travelAdvisory {
                Label("Travel Advisory", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if !pass.restrictions.isEmpty {
                ForEach(pass.restrictions.prefix(2), id: \.direction) { restriction in
                    HStack(spacing: 4) {
                        Text(restriction.direction)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(restriction.text)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func roadConditionColor(_ condition: String) -> Color {
        let lower = condition.lowercased()
        if lower.contains("closed") {
            return .red
        } else if lower.contains("chain") || lower.contains("traction") {
            return .orange
        } else if lower.contains("compact") || lower.contains("ice") || lower.contains("snow") {
            return .yellow
        } else {
            return .green
        }
    }
}

#Preview {
    VStack {
        RoadsCard(roads: .mock)
        RoadsCard(roads: nil)
    }
    .padding()
}
