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
            if let mountainDetail = viewModel.locationData?.mountain {
                if mountainDetail.webcams.isEmpty {
                    Text("No webcams available for this mountain")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .frame(alignment: .center)
                } else {
                    VStack(alignment: .leading, spacing: .spacingM) {
                        Text("Mountain Webcams")
                            .sectionHeader()

                        ForEach(mountainDetail.webcams) { webcam in
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
                }

                // Road webcams if available
                if let roadWebcams = mountainDetail.roadWebcams, !roadWebcams.isEmpty {
                    VStack(alignment: .leading, spacing: .spacingM) {
                        Text("Road Webcams")
                            .sectionHeader()

                        ForEach(roadWebcams) { webcam in
                            VStack(alignment: .leading, spacing: .spacingS) {
                                Text(webcam.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text("\(webcam.highway) - \(webcam.agency)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

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
                }
            } else {
                Text("Loading webcam data...")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
    }

    // MARK: - Safety Content

    private var safetyContent: some View {
        VStack(spacing: .spacingL) {
            // Weather alerts - using embedded AlertsView for full alert functionality
            VStack(alignment: .leading, spacing: .spacingM) {
                Text("Weather Alerts")
                    .sectionHeader()

                AlertsView(mountainId: mountain.id, mountainName: mountain.name)
            }

            // Safety conditions from current data
            if let conditions = viewModel.locationData?.conditions {
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Current Conditions")
                        .sectionHeader()

                    VStack(spacing: .spacingM) {
                        SafetyInfoRow(
                            icon: "thermometer.snowflake",
                            title: "Temperature",
                            value: "\(conditions.temperature ?? 0)°F",
                            color: temperatureColor(Double(conditions.temperature ?? 32))
                        )

                        SafetyInfoRow(
                            icon: "wind",
                            title: "Wind Speed",
                            value: "\(conditions.wind?.speed ?? 0) mph",
                            color: windColor(Double(conditions.wind?.speed ?? 0))
                        )
                    }
                    .padding(.spacingM)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusCard)
                }
            }

            // Link to Patrol View for detailed safety info
            NavigationLink {
                PatrolView()
            } label: {
                HStack {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.title3)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ski Patrol Information")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("View detailed safety information")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
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
