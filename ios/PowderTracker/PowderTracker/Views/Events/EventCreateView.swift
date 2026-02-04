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
    @State private var hasMaxAttendees = false
    @State private var maxAttendees = 20

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
                    
                    // Auto-fill best powder day button
                    if !selectedMountainId.isEmpty {
                        autoFillBestDayButton
                    }
                }

                // Forecast Preview (when mountain + date selected)
                if !selectedMountainId.isEmpty {
                    Section {
                        forecastPreviewCard
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

                // Skill level and capacity
                Section("Group Info") {
                    Picker("Skill Level", selection: $skillLevel) {
                        Text("All levels welcome").tag(nil as SkillLevel?)
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as SkillLevel?)
                        }
                    }

                    Toggle("Limit group size", isOn: $hasMaxAttendees)
                        .accessibilityIdentifier("create_event_max_attendees_toggle")

                    if hasMaxAttendees {
                        Stepper("Max attendees: \(maxAttendees)", value: $maxAttendees, in: 2...100)
                            .accessibilityIdentifier("create_event_max_attendees_stepper")

                        if maxAttendees <= 6 {
                            Text("Small intimate group")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if maxAttendees <= 15 {
                            Text("Medium-sized crew")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Large group event")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                    Text(forecast.iconEmoji)
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

    // MARK: - Auto-fill Best Day Button
    
    @ViewBuilder
    private var autoFillBestDayButton: some View {
        if isLoadingForecast {
            HStack(spacing: .spacingS) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Finding best powder day...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if let best = bestPowderDay {
            Button {
                HapticFeedback.medium.trigger()
                selectBestPowderDay(best)
            } label: {
                HStack(spacing: .spacingS) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.cyan)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best Powder Day: \(best.dayOfWeek)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 10))
                            Text("\(best.snowfall)\" expected")
                                .font(.caption)
                        }
                        .foregroundStyle(.cyan)
                    }
                    
                    Spacer()
                    
                    Text("Apply")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("auto_fill_best_day_button")
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
            let todayStr = formatter.string(from: Date())

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

            // Find best powder day from FUTURE dates only (fix for past dates bug)
            // Lower threshold to 3" for more frequent suggestions
            // Also consider days with good snow conditions (fresh snow + cold temps)
            let futureDays = forecast.filter { day in
                day.date >= todayStr && day.date != eventDateStr
            }

            // Primary: Find day with most snowfall (3"+ threshold)
            if let snowDay = futureDays.filter({ $0.snowfall >= 3 }).max(by: { $0.snowfall < $1.snowfall }) {
                bestPowderDay = snowDay
            } else {
                // Secondary: Find best conditions day (cold temps, any snow expected)
                bestPowderDay = futureDays
                    .filter { $0.snowfall > 0 || $0.precipProbability >= 60 }
                    .sorted { day1, day2 in
                        // Score: snowfall + precip probability bonus + cold temp bonus
                        let score1 = day1.snowfall * 10 + (day1.precipProbability > 70 ? 5 : 0) + (day1.high < 32 ? 3 : 0)
                        let score2 = day2.snowfall * 10 + (day2.precipProbability > 70 ? 5 : 0) + (day2.high < 32 ? 3 : 0)
                        return score1 > score2
                    }
                    .first
            }

        } catch {
            // Silently fail - forecast is optional
            forecastPreview = nil
            allForecasts = []
            bestPowderDay = nil
        }

        isLoadingForecast = false
    }

    /// Score a forecast day for comparison (higher = better skiing conditions)
    private func scoreForecast(_ day: ForecastDay) -> Int {
        var score = 0

        // Snowfall is most important (10 points per inch)
        score += day.snowfall * 10

        // Fresh snow bonus
        if day.snowfall >= 6 { score += 20 }
        if day.snowfall >= 12 { score += 30 }

        // Cold temps preserve snow quality
        if day.high < 32 { score += 10 }
        if day.high < 28 { score += 5 }

        // High precip probability when expecting snow
        if day.precipProbability >= 70 && day.precipType == "snow" {
            score += 15
        }

        // Penalize high winds (safety concern)
        if day.wind.gust > 40 { score -= 10 }
        if day.wind.gust > 50 { score -= 15 }

        return score
    }

    private func selectBestPowderDay(_ day: ForecastDay) {
        // Parse the date from forecast
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: day.date) {
            eventDate = date
            forecastPreview = day
            HapticFeedback.selection.trigger()

            // Clear best powder day since we just selected it
            bestPowderDay = nil
        }
    }

    /// Generate a description for the powder day suggestion
    private func powderDayDescription(_ day: ForecastDay) -> String {
        var parts: [String] = []

        parts.append(day.dayOfWeek)

        if day.snowfall >= 6 {
            parts.append("\(day.snowfall)\" expected")
        } else if day.snowfall > 0 {
            parts.append("\(day.snowfall)\" snow")
        }

        if day.precipProbability >= 70 && day.snowfall == 0 {
            parts.append("\(day.precipProbability)% chance of snow")
        }

        if day.high < 28 {
            parts.append("great snow quality")
        }

        return parts.joined(separator: " - ")
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
                carpoolSeats: carpoolAvailable ? carpoolSeats : nil,
                maxAttendees: hasMaxAttendees ? maxAttendees : nil
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

#Preview("Create Event") {
    EventCreateView()
}

#Preview("Auto-fill Button") {
    List {
        Section("Event Details") {
            Text("Event Title")
            Text("Date: Feb 4, 2026")
            
            // Simulated auto-fill button
            Button {
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.cyan)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best Powder Day: Friday")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 10))
                            Text("12\" expected")
                                .font(.caption)
                        }
                        .foregroundStyle(.cyan)
                    }
                    
                    Spacer()
                    
                    Text("Apply")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }
}
