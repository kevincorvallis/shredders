import SwiftUI

struct MountainPickerView: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @Binding var selectedMountainId: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRegion: Region = .all

    enum Region: String, CaseIterable {
        case all = "All"
        case washington = "WA"
        case oregon = "OR"
        case idaho = "ID"
    }

    private var filteredMountains: [Mountain] {
        switch selectedRegion {
        case .all:
            return viewModel.mountains
        case .washington:
            return viewModel.washingtonMountains
        case .oregon:
            return viewModel.oregonMountains
        case .idaho:
            return viewModel.idahoMountains
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Region filter
                Picker("Region", selection: $selectedRegion) {
                    ForEach(Region.allCases, id: \.self) { region in
                        Text(region.rawValue).tag(region)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if viewModel.isLoading {
                    ProgressView("Loading mountains...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredMountains) { mountain in
                            MountainPickerRow(
                                mountain: mountain,
                                score: viewModel.getScore(for: mountain),
                                distance: viewModel.getDistance(to: mountain),
                                isSelected: mountain.id == selectedMountainId
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMountainId = mountain.id
                                dismiss()
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select Mountain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadMountains()
            }
        }
    }
}

struct MountainPickerRow: View {
    let mountain: Mountain
    let score: Double?
    let distance: Double?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Powder score badge
            ZStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 44, height: 44)

                Text(score != nil ? String(format: "%.0f", score!) : "?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(mountain.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("\(mountain.elevation.summit.formatted())'")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let distance = distance {
                        Text("\(Int(distance)) mi")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(regionName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .cornerRadius(4)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }

    private var scoreColor: Color {
        guard let score = score else { return .gray }
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .red
    }

    private var regionName: String {
        switch mountain.region {
        case "washington": return "WA"
        case "oregon": return "OR"
        case "idaho": return "ID"
        default: return mountain.region.uppercased()
        }
    }
}

#Preview {
    MountainPickerView(selectedMountainId: .constant("baker"))
}
