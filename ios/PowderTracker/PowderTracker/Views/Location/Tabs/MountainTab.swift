import SwiftUI

/// Consolidated tab combining Lifts, Webcams, and Safety
struct MountainTab: View {
    @ObservedObject var viewModel: LocationViewModel
    let mountain: Mountain
    @State private var selectedSection: Section = .lifts

    enum Section: String, CaseIterable {
        case lifts = "Lifts"
        case webcams = "Webcams"
        case safety = "Safety"
    }

    var body: some View {
        VStack(spacing: .spacingL) {
            // Section picker
            sectionPicker

            // Content
            switch selectedSection {
            case .lifts:
                liftsContent
            case .webcams:
                webcamsContent
            case .safety:
                safetyContent
            }
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(Section.allCases, id: \.self) { section in
                Text(section.rawValue)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Lifts Content

    private var liftsContent: some View {
        VStack(spacing: .spacingL) {
            // Lift status summary
            if let liftStatus = viewModel.locationData?.conditions.liftStatus {
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Lift Status")
                        .sectionHeader()

                    LiftStatusCard(liftStatus: liftStatus)
                }
            }

            // Lift line predictor
            LiftLinePredictorCard(viewModel: viewModel)
        }
    }

    // MARK: - Webcams Content

    private var webcamsContent: some View {
        VStack(spacing: .spacingL) {
            if mountain.webcams.isEmpty {
                Text("No webcams available for this mountain")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .frame(alignment: .center)
            } else {
                WebcamsSection(mountain: mountain)
            }

            // Road webcams if available
            if let roadWebcams = mountain.roadWebcams, !roadWebcams.isEmpty {
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Road Webcams")
                        .sectionHeader()

                    ForEach(roadWebcams, id: \.name) { webcam in
                        WebcamCard(webcam: webcam)
                    }
                }
            }
        }
    }

    // MARK: - Safety Content

    private var safetyContent: some View {
        VStack(spacing: .spacingL) {
            // Weather alerts
            if let alerts = viewModel.locationData?.alerts, !alerts.isEmpty {
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Active Alerts")
                        .sectionHeader()

                    ForEach(alerts) { alert in
                        AlertCard(alert: alert)
                    }
                }
            } else {
                VStack(spacing: .spacingM) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("No Active Alerts")
                        .font(.headline)

                    Text("Conditions are safe")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.spacingXL)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
            }

            // Avalanche conditions (if available)
            if let conditions = viewModel.locationData?.conditions {
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Safety Information")
                        .sectionHeader()

                    VStack(spacing: .spacingM) {
                        SafetyInfoRow(
                            icon: "thermometer.snowflake",
                            title: "Temperature",
                            value: "\(Int(conditions.temperature ?? 0))°F",
                            color: temperatureColor(conditions.temperature ?? 32)
                        )

                        SafetyInfoRow(
                            icon: "wind",
                            title: "Wind Speed",
                            value: "\(Int(conditions.wind?.speed ?? 0)) mph",
                            color: windColor(conditions.wind?.speed ?? 0)
                        )

                        if let visibility = conditions.visibility {
                            SafetyInfoRow(
                                icon: "eye",
                                title: "Visibility",
                                value: visibility,
                                color: .blue
                            )
                        }
                    }
                    .padding(.spacingM)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusCard)
                }
            }
        }
    }

    // MARK: - Helpers

    private func temperatureColor(_ temp: Double) -> Color {
        if temp < 20 { return .blue }
        if temp < 32 { return .cyan }
        if temp < 40 { return .green }
        return .orange
    }

    private func windColor(_ speed: Double) -> Color {
        if speed < 10 { return .green }
        if speed < 20 { return .yellow }
        if speed < 30 { return .orange }
        return .red
    }
}

// MARK: - Supporting Views

struct SafetyInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
    }
}

struct WebcamCard: View {
    let webcam: Webcam

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text(webcam.name)
                .font(.subheadline)
                .fontWeight(.semibold)

            if let url = URL(string: webcam.url) {
                Link(destination: url) {
                    HStack {
                        Text("View Live")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

#Preview {
    ScrollView {
        MountainTab(viewModel: {
            let vm = LocationViewModel(mountain: .mock)
            return vm
        }(), mountain: .mock)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
