import SwiftUI

struct EventCreateView: View {
    @Environment(\.dismiss) private var dismiss

    var onEventCreated: ((Event) -> Void)?

    @State private var selectedMountainId = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var eventDate = Date()
    @State private var departureTime = Date()
    @State private var hasDepartureTime = false
    @State private var departureLocation = ""
    @State private var skillLevel: SkillLevel?
    @State private var carpoolAvailable = false
    @State private var carpoolSeats = 3

    @State private var isSubmitting = false
    @State private var error: String?

    // All mountains from the app config
    private let mountains: [(id: String, name: String)] = [
        ("stevens-pass", "Stevens Pass"),
        ("crystal-mountain", "Crystal Mountain"),
        ("snoqualmie-pass", "Snoqualmie Pass"),
        ("mt-baker", "Mt. Baker"),
        ("white-pass", "White Pass"),
        ("mission-ridge", "Mission Ridge"),
        ("mt-hood-meadows", "Mt. Hood Meadows"),
        ("timberline", "Timberline"),
        ("mt-hood-skibowl", "Mt. Hood Skibowl"),
        ("mt-bachelor", "Mt. Bachelor"),
        ("schweitzer", "Schweitzer"),
        ("lookout-pass", "Lookout Pass"),
        ("49-degrees-north", "49 Degrees North"),
        ("silver-mountain", "Silver Mountain"),
        ("whistler-blackcomb", "Whistler Blackcomb"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Error banner
                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                // Mountain selection
                Section("Where") {
                    Picker("Mountain", selection: $selectedMountainId) {
                        Text("Select a mountain").tag("")
                        ForEach(mountains, id: \.id) { mountain in
                            Text(mountain.name).tag(mountain.id)
                        }
                    }
                }

                // Event details
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                        .textContentType(.none)

                    DatePicker(
                        "Date",
                        selection: $eventDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                }

                // Departure info
                Section("Departure") {
                    Toggle("Set departure time", isOn: $hasDepartureTime)

                    if hasDepartureTime {
                        DatePicker(
                            "Departure Time",
                            selection: $departureTime,
                            displayedComponents: .hourAndMinute
                        )
                    }

                    TextField("Meeting Point (optional)", text: $departureLocation)
                }

                // Skill level
                Section("Group Info") {
                    Picker("Skill Level", selection: $skillLevel) {
                        Text("All levels welcome").tag(nil as SkillLevel?)
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as SkillLevel?)
                        }
                    }
                }

                // Carpool
                Section("Carpool") {
                    Toggle("I can give rides", isOn: $carpoolAvailable)

                    if carpoolAvailable {
                        Stepper("Available seats: \(carpoolSeats)", value: $carpoolSeats, in: 1...8)
                    }
                }

                // Notes
                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)

                    Text("\(notes.count)/2000")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createEvent() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSubmitting || !isFormValid)
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !selectedMountainId.isEmpty &&
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        notes.count <= 2000
    }

    // MARK: - Actions

    private func createEvent() async {
        error = nil
        isSubmitting = true

        // Format departure time if set
        var departureTimeStr: String?
        if hasDepartureTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            departureTimeStr = formatter.string(from: departureTime)
        }

        do {
            let response = try await EventService.shared.createEvent(
                mountainId: selectedMountainId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                eventDate: eventDate,
                departureTime: departureTimeStr,
                departureLocation: departureLocation.isEmpty ? nil : departureLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                skillLevel: skillLevel,
                carpoolAvailable: carpoolAvailable,
                carpoolSeats: carpoolAvailable ? carpoolSeats : nil
            )

            onEventCreated?(response.event)
            dismiss()
        } catch let err as EventServiceError {
            error = err.localizedDescription
        } catch {
            self.error = "Failed to create event"
        }

        isSubmitting = false
    }
}

#Preview {
    EventCreateView()
}
