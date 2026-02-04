//
//  SeasonPassPickerView.swift
//  PowderTracker
//
//  Picker for selecting user's season pass type.
//

import SwiftUI

struct SeasonPassPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("seasonPass") private var seasonPass = "none"

    var body: some View {
        NavigationStack {
            List {
                ForEach(SeasonPassType.allCases) { passType in
                    Button {
                        seasonPass = passType.rawValue
                        HapticFeedback.selection.trigger()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: passType.icon)
                                .font(.title2)
                                .foregroundStyle(passType.color)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(passType.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Text(passType.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if seasonPass == passType.rawValue {
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
            .navigationTitle("Season Pass")
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

#Preview {
    SeasonPassPickerView()
}
