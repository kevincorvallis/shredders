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
    @State private var showingLocationPicker = false

    // Forecast preview
    @State private var forecastPreview: ForecastDay?
    @State private var allForecasts: [ForecastDay] = []
    @State private var isLoadingForecast = false
    @State private var bestPowderDay: ForecastDay?

    // All mountains from the app config (IDs must match backend)
    private let mountains: [(id: String, name: String)] = [
        ("baker", "Mt. Baker"),
        ("stevens", "Stevens Pass"),
        ("crystal", "Crystal Mountain"),
        ("snoqualmie", "Snoqualmie Pass"),
        ("whitepass", "White Pass"),
        ("missionridge", "Mission Ridge"),
        ("meadows", "Mt. Hood Meadows"),
        ("timberline", "Timberline"),
        ("bachelor", "Mt. Bachelor"),
        ("schweitzer", "Schweitzer"),
        ("lookout", "Lookout Pass"),
        ("fortynine", "49 Degrees North"),
        ("whistler", "Whistler Blackcomb"),
        ("brundage", "Brundage Mountain"),
        ("sunvalley", "Sun Valley"),
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
                    .accessibilityIdentifier("create_event_mountain_picker")
                    .onChange(of: selectedMountainId) { _, _ in
                        Task { await loadForecast() }
                    }
                }

                // Event details
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                        .textContentType(.none)
                        .accessibilityIdentifier("create_event_title_field")

                    DatePicker(
                        "Date",
                        selection: $eventDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .onChange(of: eventDate) { _, _ in
                        Task { await loadForecast() }
                    }
                }

                // Forecast Preview (when mountain + date selected)
                if !selectedMountainId.isEmpty {
                    Section {
                        forecastPreviewCard

                        // Best Powder Day Suggestion
                        if let bestDay = bestPowderDay, bestDay.date != forecastPreview?.date {
                            Button {
                                selectBestPowderDay(bestDay)
                            } label: {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                        .foregroundStyle(.cyan)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Best Powder Day")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                        Text("\(bestDay.dayOfWeek) - \(bestDay.snowfall)\" expected")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("Switch")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.cyan)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(.cyan.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        HStack {
                            Text("Forecast Preview")
                            Spacer()
                            if isLoadingForecast {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }
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
                    .accessibilityIdentifier("create_event_meeting_point_button")
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
                        .accessibilityIdentifier("create_event_carpool_toggle")

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
                    .accessibilityIdentifier("create_event_cancel_button")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createEvent() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSubmitting || !isFormValid)
                    .accessibilityIdentifier("create_event_submit_button")
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

    // MARK: - Forecast Preview Card

    @ViewBuilder
    private var forecastPreviewCard: some View {
        if let forecast = forecastPreview {
            VStack(spacing: 12) {
                // Date and conditions
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(forecast.dayOfWeek)
                            .font(.headline)
                        Text(forecast.conditions)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Weather icon
                    Text(forecast.iconEmoji ?? weatherIcon(for: forecast.conditions))
                        .font(.largeTitle)
                }

                Divider()

                // Weather details
                HStack(spacing: 0) {
                    // Temps
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(forecast.high)°")
                                .foregroundStyle(.orange)
                            Text("/")
                                .foregroundStyle(.secondary)
                            Text("\(forecast.low)°")
                                .foregroundStyle(.blue)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        Text("High / Low")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    // Snowfall
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            Text("\(forecast.snowfall)\"")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.cyan)
                            if forecast.snowfall >= 6 {
                                Image(systemName: "snowflake")
                                    .font(.caption2)
                                    .foregroundStyle(.cyan)
                            }
                        }
                        Text("Snow")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    // Precip probability
                    VStack(spacing: 2) {
                        Text("\(forecast.precipProbability)%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Precip")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Powder day indicator
                if forecast.snowfall >= 6 {
                    HStack {
                        Image(systemName: "snowflake.circle.fill")
                            .foregroundStyle(.cyan)
                        Text("Powder Day Alert!")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(10)
                    .background(.cyan.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        } else if isLoadingForecast {
            HStack {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            }
        } else {
            HStack {
                Image(systemName: "cloud.sun")
                    .foregroundStyle(.secondary)
                Text("Select a date to see the forecast")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private func weatherIcon(for conditions: String) -> String {
        let lowercased = conditions.lowercased()
        if lowercased.contains("snow") || lowercased.contains("blizzard") { return "❄️" }
        if lowercased.contains("rain") { return "🌧️" }
        if lowercased.contains("cloud") { return "☁️" }
        if lowercased.contains("sun") || lowercased.contains("clear") { return "☀️" }
        if lowercased.contains("wind") { return "💨" }
        if lowercased.contains("fog") { return "🌫️" }
        return "🌤️"
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !selectedMountainId.isEmpty &&
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        notes.count <= 2000
    }

    // MARK: - Data Loading

    private func loadForecast() async {
        guard !selectedMountainId.isEmpty else {
            forecastPreview = nil
            allForecasts = []
            bestPowderDay = nil
            return
        }

        isLoadingForecast = true

        do {
            // Fetch forecast for selected mountain
            let response = try await APIClient.shared.fetchForecast(for: selectedMountainId)
            let forecast = response.forecast
            allForecasts = forecast

            // Format event date to match forecast
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let eventDateStr = formatter.string(from: eventDate)

            // Find the forecast for the selected date
            forecastPreview = forecast.first { $0.date == eventDateStr }

            // If exact date not found, show closest future date
            if forecastPreview == nil {
                forecastPreview = forecast.first { day in
                    if let dayDate = formatter.date(from: day.date) {
                        return dayDate >= eventDate
                    }
                    return false
                }
            }

            // Find best powder day (most snowfall, >6" to qualify)
            bestPowderDay = forecast
                .filter { $0.snowfall >= 6 }
                .max(by: { $0.snowfall < $1.snowfall })

        } catch {
            // Silently fail - forecast is optional
            forecastPreview = nil
            allForecasts = []
            bestPowderDay = nil
        }

        isLoadingForecast = false
    }

    private func selectBestPowderDay(_ day: ForecastDay) {
        // Parse the date from forecast
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: day.date) {
            eventDate = date
            forecastPreview = day
            HapticFeedback.selection.trigger()
        }
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

            HapticFeedback.success.trigger()
            onEventCreated?(response.event)
            dismiss()
        } catch let err as EventServiceError {
            HapticFeedback.error.trigger()
            error = err.localizedDescription
        } catch {
            HapticFeedback.error.trigger()
            self.error = "Failed to create event"
        }

        isSubmitting = false
    }
}

#Preview {
    EventCreateView()
}
