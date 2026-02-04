import SwiftUI

struct EventCreateView: View {
    @Environment(\.dismiss) private var dismiss

    // Optional suggestion from smart suggestions
    var suggestion: EventSuggestionType?
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

    // Mountain suggestions (multiple for leaderboard)
    @State private var mountainComparisons: [(id: String, name: String, forecast: ForecastDay)] = []
    @State private var bestMountain: (id: String, name: String, forecast: ForecastDay)?
    @State private var isLoadingMountainSuggestion = false
    
    // Track if we've applied the suggestion
    @State private var suggestionApplied = false

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

                    // Enhanced Powder Day Suggestions
                    if !allForecasts.isEmpty {
                        Section {
                            PowderDaySuggestionCard(
                                forecasts: allForecasts,
                                selectedDate: eventDate,
                                selectedMountainId: selectedMountainId,
                                mountainName: mountains.first { $0.id == selectedMountainId }?.name ?? "",
                                onSelectDate: { day in
                                    selectBestPowderDay(day)
                                },
                                onSelectMountain: { mountain in
                                    selectBestMountain(mountain)
                                },
                                mountainComparisons: mountainComparisons,
                                isLoadingComparisons: isLoadingMountainSuggestion
                            )
                        } header: {
                            HStack {
                                Text("Powder Day Finder")
                                Spacer()
                                if isLoadingMountainSuggestion {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
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
            .onAppear {
                applySuggestionIfNeeded()
            }
        }
    }
    
    // MARK: - Apply Suggestion
    
    private func applySuggestionIfNeeded() {
        guard let suggestion = suggestion, !suggestionApplied else { return }
        suggestionApplied = true
        
        switch suggestion {
        case .powderDay(let mountain, let forecast):
            selectedMountainId = mountain.id
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: forecast.date) {
                eventDate = date
            }
            title = "Powder Day at \(mountain.name)"
            notes = "Expected snowfall: \(forecast.snowfall)\"\nConditions: \(forecast.conditions)"
            
        case .weekendTrip(let mountain, let date, let snowfall):
            selectedMountainId = mountain.id
            eventDate = date
            title = "Weekend at \(mountain.name)"
            if snowfall > 0 {
                notes = "Expected fresh snow: \(snowfall)\""
            }
            
        case .bestConditions(let mountain, let score):
            selectedMountainId = mountain.id
            eventDate = Date()
            title = "\(mountain.name) - Great Conditions"
            notes = "Current powder score: \(String(format: "%.1f", score))/10"
            
        case .groupTrip(let mountains, let date):
            if let firstMountain = mountains.first {
                selectedMountainId = firstMountain.id
            }
            eventDate = date
            title = "Group Ski Trip"
            let mountainNames = mountains.map { $0.name }.joined(separator: ", ")
            notes = "Considering: \(mountainNames)"
        }
        
        // Load forecast for the selected mountain
        Task { await loadForecast() }
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

        // Also check for better mountains (in background)
        await loadBestMountainSuggestion()
    }

    /// Check other mountains for better conditions on the selected date
    /// Populates mountainComparisons for the leaderboard
    private func loadBestMountainSuggestion() async {
        isLoadingMountainSuggestion = true
        mountainComparisons = []
        bestMountain = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let eventDateStr = formatter.string(from: eventDate)
        let todayStr = formatter.string(from: Date())

        // Only suggest if the date is today or in the future
        guard eventDateStr >= todayStr else {
            isLoadingMountainSuggestion = false
            return
        }

        // Check a subset of popular mountains (to avoid too many API calls)
        let mountainsToCheck = mountains.filter { $0.id != selectedMountainId }.prefix(6)

        var allComparisons: [(id: String, name: String, forecast: ForecastDay, score: Int)] = []

        // Score the currently selected mountain's forecast
        var currentScore = 0
        if let currentForecast = forecastPreview {
            currentScore = scoreForecast(currentForecast)
        }

        // Fetch forecasts for other mountains concurrently
        // Note: Using a local scoring function to avoid actor isolation issues
        let scoreFn: @Sendable (ForecastDay) -> Int = { day in
            var score = 0
            score += day.snowfall * 10
            if day.snowfall >= 6 { score += 20 }
            if day.snowfall >= 12 { score += 30 }
            if day.high < 32 { score += 10 }
            if day.high < 28 { score += 5 }
            if day.precipProbability >= 70 && day.precipType == "snow" { score += 15 }
            if day.wind.gust > 40 { score -= 10 }
            if day.wind.gust > 50 { score -= 15 }
            return score
        }

        await withTaskGroup(of: (String, String, ForecastDay, Int)?.self) { group in
            for mountain in mountainsToCheck {
                // Capture values explicitly for Sendable closure
                let mountainId = mountain.id
                let mountainName = mountain.name
                let dateStr = eventDateStr

                group.addTask { [scoreFn] in
                    do {
                        let response = try await APIClient.shared.fetchForecast(for: mountainId)

                        // Find forecast for the selected date
                        if let dayForecast = response.forecast.first(where: { $0.date == dateStr }) {
                            let score = scoreFn(dayForecast)
                            return (mountainId, mountainName, dayForecast, score)
                        }
                    } catch {
                        // Skip this mountain on error
                    }
                    return nil
                }
            }

            for await result in group {
                if let result = result {
                    allComparisons.append((id: result.0, name: result.1, forecast: result.2, score: result.3))
                }
            }
        }

        // Sort by score descending and take top 3 that are better than current
        let betterMountains = allComparisons
            .filter { $0.score > currentScore }
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { (id: $0.id, name: $0.name, forecast: $0.forecast) }

        mountainComparisons = Array(betterMountains)

        // Set best mountain (first one if any)
        bestMountain = mountainComparisons.first

        isLoadingMountainSuggestion = false
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

            // Re-check for mountain suggestion with new date
            Task { await loadBestMountainSuggestion() }
        }
    }

    private func selectBestMountain(_ mountain: (id: String, name: String, forecast: ForecastDay)) {
        selectedMountainId = mountain.id
        forecastPreview = mountain.forecast
        bestMountain = nil
        HapticFeedback.selection.trigger()

        // Reload forecast for new mountain
        Task { await loadForecast() }
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
