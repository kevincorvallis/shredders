import SwiftUI

struct CheckInFormView: View {
    let mountainId: String
    let onCheckInCreated: ((CheckIn) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var tripReport = ""
    @State private var rating: Int? = nil
    @State private var selectedSnowQuality: SnowQuality? = nil
    @State private var selectedCrowdLevel: CrowdLevel? = nil
    @State private var isPublic = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Rating Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overall Rating")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    rating = value
                                } label: {
                                    Text("\(value)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .frame(width: 50, height: 50)
                                        .background(rating == value ? Color.blue : Color(.systemGray6))
                                        .foregroundStyle(rating == value ? .white : .primary)
                                        .cornerRadius(.cornerRadiusButton)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Rating")
                }

                // Conditions Section
                Section {
                    Picker("Snow Quality", selection: $selectedSnowQuality) {
                        Text("Select...").tag(nil as SnowQuality?)
                        ForEach(SnowQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality as SnowQuality?)
                        }
                    }

                    Picker("Crowd Level", selection: $selectedCrowdLevel) {
                        Text("Select...").tag(nil as CrowdLevel?)
                        ForEach(CrowdLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as CrowdLevel?)
                        }
                    }
                } header: {
                    Text("Conditions")
                }

                // Trip Report Section
                Section {
                    ZStack(alignment: .topLeading) {
                        if tripReport.isEmpty {
                            Text("Share your experience...")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }

                        TextEditor(text: $tripReport)
                            .frame(minHeight: 120)
                            .opacity(tripReport.isEmpty ? 0.5 : 1)
                    }

                    HStack {
                        Spacer()
                        Text("\(tripReport.count)/5000")
                            .font(.caption)
                            .foregroundStyle(tripReport.count > 5000 ? .red : .secondary)
                    }
                } header: {
                    Text("Trip Report")
                } footer: {
                    Text("Optional - Share details about your experience")
                }

                // Visibility Section
                Section {
                    Toggle("Make this check-in public", isOn: $isPublic)
                } footer: {
                    Text("Public check-ins are visible to all users")
                }

                // Error message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Check In") {
                        Task {
                            await submitCheckIn()
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }

    private func submitCheckIn() async {
        guard authService.isAuthenticated else {
            errorMessage = "Please sign in to check in"
            return
        }

        if tripReport.count > 5000 {
            errorMessage = "Trip report must be less than 5000 characters"
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let checkIn = try await CheckInService.shared.createCheckIn(
                mountainId: mountainId,
                tripReport: tripReport.isEmpty ? nil : tripReport,
                rating: rating,
                snowQuality: selectedSnowQuality?.rawValue,
                crowdLevel: selectedCrowdLevel?.rawValue,
                isPublic: isPublic
            )

            onCheckInCreated?(checkIn)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

#Preview {
    CheckInFormView(mountainId: "baker", onCheckInCreated: nil)
        .environment(AuthService.shared)
}
