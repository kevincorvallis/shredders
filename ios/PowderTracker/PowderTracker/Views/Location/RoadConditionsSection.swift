import SwiftUI

struct RoadConditionsSection: View {
    @ObservedObject var viewModel: LocationViewModel
    var onNavigateToTravel: (() -> Void)?
    @State private var isExpanded = false

    var body: some View {
        if let roadData = viewModel.locationData?.roads,
           roadData.supported && !roadData.passes.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Section Header (Tappable)
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.purple)
                    Text("Mountain Pass Conditions")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.secondary)
                        .imageScale(.large)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    handleTap()
                }

                // Pass Conditions
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(roadData.passes) { pass in
                        PassConditionCard(pass: pass, isExpanded: isExpanded)
                    }
                }

                // Expanded Content: Navigate to Travel Button
                if isExpanded && onNavigateToTravel != nil {
                    Button {
                        onNavigateToTravel?()
                    } label: {
                        HStack {
                            Text("View Trip Planning")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(.cornerRadiusButton)
                    }
                    .transition(.opacity)
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
            .cornerRadius(.cornerRadiusCard)
            .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Tap Handler

    private func handleTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3)) {
            if isExpanded {
                // Second tap: Navigate to Travel tab
                onNavigateToTravel?()
            } else {
                // First tap: Expand inline
                isExpanded = true
            }
        }
    }
}

struct PassConditionCard: View {
    let pass: PassCondition
    let isExpanded: Bool

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

            // Summary (always visible)
            Text(pass.roadCondition)
                .font(.caption)
                .foregroundColor(severityColor)
                .fontWeight(.semibold)

            // Expanded Details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
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
                            .cornerRadius(.cornerRadiusTiny)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusButton)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(pass.travelAdvisory ? Color.red.opacity(0.3) : severityColor.opacity(0.3), lineWidth: 1)
        )
    }
}
