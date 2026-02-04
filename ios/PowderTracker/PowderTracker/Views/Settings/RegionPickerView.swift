//
//  RegionPickerView.swift
//  PowderTracker
//
//  Picker for selecting user's home region.
//

import SwiftUI

struct RegionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("homeRegion") private var homeRegion = "washington"

    var body: some View {
        NavigationStack {
            List {
                ForEach(HomeRegion.allCases) { region in
                    Button {
                        homeRegion = region.rawValue
                        HapticFeedback.selection.trigger()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: region.icon)
                                .font(.title2)
                                .foregroundStyle(region.color)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(region.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Text(region.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if homeRegion == region.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Home Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Home Region Enum

enum HomeRegion: String, CaseIterable, Identifiable {
    case washington
    case oregon
    case california
    case colorado
    case utah
    case montana
    case idaho
    case britishColumbia = "british_columbia"
    case alberta
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .washington: return "Washington"
        case .oregon: return "Oregon"
        case .california: return "California"
        case .colorado: return "Colorado"
        case .utah: return "Utah"
        case .montana: return "Montana"
        case .idaho: return "Idaho"
        case .britishColumbia: return "British Columbia"
        case .alberta: return "Alberta"
        case .other: return "Other"
        }
    }

    var description: String {
        switch self {
        case .washington: return "Crystal, Stevens, Baker & more"
        case .oregon: return "Mt. Hood, Bachelor & more"
        case .california: return "Tahoe, Mammoth & more"
        case .colorado: return "Vail, Aspen, Breck & more"
        case .utah: return "Park City, Alta, Snowbird & more"
        case .montana: return "Big Sky, Whitefish & more"
        case .idaho: return "Sun Valley, Schweitzer & more"
        case .britishColumbia: return "Whistler, Revelstoke & more"
        case .alberta: return "Banff, Lake Louise & more"
        case .other: return "Somewhere else"
        }
    }

    var icon: String {
        switch self {
        case .washington: return "w.square.fill"
        case .oregon: return "o.square.fill"
        case .california: return "c.square.fill"
        case .colorado: return "c.square.fill"
        case .utah: return "u.square.fill"
        case .montana: return "m.square.fill"
        case .idaho: return "i.square.fill"
        case .britishColumbia: return "b.square.fill"
        case .alberta: return "a.square.fill"
        case .other: return "globe"
        }
    }

    var color: Color {
        switch self {
        case .washington: return .green
        case .oregon: return .orange
        case .california: return .yellow
        case .colorado: return .blue
        case .utah: return .red
        case .montana: return .purple
        case .idaho: return .cyan
        case .britishColumbia: return .red
        case .alberta: return .red
        case .other: return .gray
        }
    }
}

#Preview {
    RegionPickerView()
}
