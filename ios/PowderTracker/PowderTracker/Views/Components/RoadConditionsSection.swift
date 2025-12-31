import SwiftUI

/// Road conditions and access info - UNIQUE FEATURE not in OpenSnow!
struct RoadConditionsSection: View {
    let roads: [RoadCondition]?
    let mountainId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "car.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Road & Access")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                NavigationLink {
                    // Link to full road webcams view
                    WebcamsView(mountainId: mountainId)
                } label: {
                    Text("Webcams")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            if let roads = roads, !roads.isEmpty {
                VStack(spacing: 12) {
                    ForEach(roads.prefix(2)) { road in
                        RoadConditionRow(road: road)
                    }

                    if roads.count > 2 {
                        Text("+ \(roads.count - 2) more routes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Check local conditions before traveling")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Road Condition Row

struct RoadConditionRow: View {
    let road: RoadCondition

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(road.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let conditions = road.conditions {
                    Text(conditions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if road.chainsRequired {
                HStack(spacing: 4) {
                    Image(systemName: "link.circle.fill")
                        .font(.caption)
                    Text("Chains")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        switch road.status.lowercased() {
        case "open": return .green
        case "closed": return .red
        case "restricted": return .orange
        default: return .gray
        }
    }
}

// MARK: - Road Condition Model

struct RoadCondition: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let conditions: String?
    let chainsRequired: Bool
}

// MARK: - Preview

#Preview {
    let mockRoads = [
        RoadCondition(
            name: "SR 542 to Mt. Baker",
            status: "Open",
            conditions: "Snow and ice, drive carefully",
            chainsRequired: true
        ),
        RoadCondition(
            name: "I-5 North",
            status: "Open",
            conditions: "Clear, normal conditions",
            chainsRequired: false
        ),
        RoadCondition(
            name: "SR 20 Mountain Loop",
            status: "Closed",
            conditions: "Avalanche control work",
            chainsRequired: false
        )
    ]

    return RoadConditionsSection(roads: mockRoads, mountainId: "baker")
        .padding()
        .background(Color(.systemGroupedBackground))
}
