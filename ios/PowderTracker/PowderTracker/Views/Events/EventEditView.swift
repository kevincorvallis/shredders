import SwiftUI

struct EventEditView: View {
    @Environment(\.dismiss) private var dismiss

    let event: EventWithDetails
    var onEventUpdated: (() -> Void)?

    @State private var title: String
    @State private var notes: String
    @State private var eventDate: Date
    @State private var departureTime: Date
    @State private var hasDepartureTime: Bool
    @State private var departureLocation: String
    @State private var skillLevel: SkillLevel?
    @State private var carpoolAvailable: Bool
    @State private var carpoolSeats: Int
    @State private var hasMaxAttendees: Bool
    @State private var maxAttendees: Int

    @State private var isSubmitting = false
    @State private var error: String?
    @State private var showingLocationPicker = false

    init(event: EventWithDetails, onEventUpdated: (() -> Void)? = nil) {
        self.event = event
        self.onEventUpdated = onEventUpdated

        // Initialize state from event
        _title = State(initialValue: event.title)
        _notes = State(initialValue: event.notes ?? "")
        _departureLocation = State(initialValue: event.departureLocation ?? "")
        _skillLevel = State(initialValue: event.skillLevel)
        _carpoolAvailable = State(initialValue: event.carpoolAvailable)
        _carpoolSeats = State(initialValue: event.carpoolSeats ?? 3)
        _hasMaxAttendees = State(initialValue: event.maxAttendees != nil)
        _maxAttendees = State(initialValue: event.maxAttendees ?? 20)
        _hasDepartureTime = State(initialValue: event.departureTime != nil)

        // Parse event date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let parsedDate = dateFormatter.date(from: event.eventDate) ?? Date()
        _eventDate = State(initialValue: parsedDate)

        // Parse departure time
        if let timeStr = event.departureTime {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let parsedTime = timeFormatter.date(from: timeStr) ?? Date()
            _departureTime = State(initialValue: parsedTime)
        } else {
            _departureTime = State(initialValue: Date())
        }
    }

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

                // Mountain (read-only)
                Section("Where") {
                    HStack {
                        Label(event.mountainName ?? event.mountainId, systemImage: "mountain.2.fill")
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("Can't change mountain")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Event details
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                        .textContentType(.none)
                        .accessibilityIdentifier("edit_event_title_field")

                    DatePicker(
                        "Date",
                        selection: $eventDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .accessibilityIdentifier("edit_event_date_picker")
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

                    // Meeting point with location picker
                    Button {
                        showingLocationPicker = true
                    } label: {
                        HStack {
                            Label("Meeting Point", systemImage: "mappin.and.ellipse")
                                .foregroundStyle(.primary)

                            Spacer()

                            if departureLocation.isEmpty {
                                Text("Optional")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(departureLocation)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Skill level and capacity
                Section("Group Info") {
                    Picker("Skill Level", selection: $skillLevel) {
                        Text("All levels welcome").tag(nil as SkillLevel?)
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as SkillLevel?)
                        }
                    }

                    Toggle("Limit group size", isOn: $hasMaxAttendees)
                        .accessibilityIdentifier("edit_event_max_attendees_toggle")

                    if hasMaxAttendees {
                        Stepper("Max attendees: \(maxAttendees)", value: $maxAttendees, in: 2...200)
                            .accessibilityIdentifier("edit_event_max_attendees_stepper")
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
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("edit_event_cancel_button")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await updateEvent() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSubmitting || !isFormValid)
                    .accessibilityIdentifier("edit_event_save_button")
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
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $departureLocation)
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        notes.count <= 2000
    }

    // MARK: - Actions

    private func updateEvent() async {
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
            _ = try await EventService.shared.updateEvent(
                id: event.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                eventDate: eventDate,
                departureTime: departureTimeStr,
                departureLocation: departureLocation.isEmpty ? nil : departureLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                skillLevel: skillLevel,
                carpoolAvailable: carpoolAvailable,
                carpoolSeats: carpoolAvailable ? carpoolSeats : nil,
                maxAttendees: hasMaxAttendees ? maxAttendees : nil,
                clearMaxAttendees: !hasMaxAttendees && event.maxAttendees != nil
            )

            HapticFeedback.success.trigger()
            // Notify EventsView so it can refresh the list
            NotificationCenter.default.post(
                name: NSNotification.Name("EventUpdated"),
                object: nil,
                userInfo: ["eventId": event.id]
            )
            onEventUpdated?()
            dismiss()
        } catch let err as EventServiceError {
            HapticFeedback.error.trigger()
            error = err.localizedDescription
        } catch {
            HapticFeedback.error.trigger()
            self.error = "Failed to update event"
        }

        isSubmitting = false
    }
}

#Preview {
    // Create a mock event for preview
    let mockEvent = EventWithDetails(
        id: "preview-1",
        creatorId: "user-1",
        mountainId: "baker",
        mountainName: "Mt. Baker",
        title: "Powder Day!",
        notes: "Let's hit the slopes",
        eventDate: "2025-03-15",
        departureTime: "06:30:00",
        departureLocation: "Seattle",
        skillLevel: .intermediate,
        carpoolAvailable: true,
        carpoolSeats: 4,
        maxAttendees: nil,
        status: .active,
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z",
        attendeeCount: 5,
        goingCount: 4,
        maybeCount: 1,
        waitlistCount: 0,
        commentCount: 0,
        photoCount: 0,
        creator: EventUser(id: "user-1", username: "test", displayName: "Test User", avatarUrl: nil, ridingStyle: nil),
        userRSVPStatus: nil,
        isCreator: true,
        attendees: [],
        conditions: nil,
        inviteToken: nil
    )

    EventEditView(event: mockEvent)
}
