import SwiftUI

struct PatrolView: View {
    var mountainId: String? = nil  // Optional parameter from parent
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"
    @State private var safetyData: SafetyResponse?
    @State private var isLoading = true
    @State private var error: String?

    // Use passed mountainId if available, otherwise fall back to AppStorage
    private var effectiveMountainId: String {
        mountainId ?? selectedMountainId
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading safety data...")
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else if let error = error {
                        ErrorCard(message: error) {
                            Task { await loadData() }
                        }
                    } else if let data = safetyData {
                        // Safety Assessment
                        SafetyAssessmentCard(data: data)

                        // Extended Weather
                        ExtendedWeatherCard(data: data)

                        // Visibility
                        VisibilityCard(data: data)

                        // Wind Assessment
                        WindAssessmentCard(data: data)

                        // Hazard Matrix
                        if let hazards = data.hazards {
                            HazardMatrixCard(hazards: hazards)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Patrol Dashboard")
            .refreshable {
                await loadData()
            }
            .task(id: effectiveMountainId) {
                await loadData()
            }
        }
    }

    private func loadData() async {
        isLoading = true
        error = nil

        do {
            guard let url = URL(string: "\(AppConfig.apiBaseURL)/mountains/\(effectiveMountainId)/safety") else {
                self.error = "Unable to load safety data. Please try again."
                isLoading = false
                return
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            safetyData = try JSONDecoder().decode(SafetyResponse.self, from: data)
        } catch {
            self.error = "Unable to load safety data. Please check your connection."
        }

        isLoading = false
    }
}

// MARK: - Safety Response Model
struct SafetyResponse: Codable {
    let mountain: MountainInfo
    let assessment: Assessment
    let weather: ExtendedWeather
    let hazards: Hazards?

    struct Assessment: Codable {
        let level: String
        let description: String
        let recommendations: [String]
    }

    struct ExtendedWeather: Codable {
        let temperature: Int?
        let feelsLike: Int?
        let humidity: Int?
        let visibility: Double?
        let pressure: Double?
        let uvIndex: Int?
        let wind: WindData?
    }

    struct WindData: Codable {
        let speed: Int
        let gust: Int?
        let direction: String
    }

    struct Hazards: Codable {
        let avalanche: HazardLevel?
        let treeWells: HazardLevel?
        let icy: HazardLevel?
        let crowded: HazardLevel?

        struct HazardLevel: Codable {
            let level: String
            let description: String?
        }
    }
}

// MARK: - Safety Assessment Card
struct SafetyAssessmentCard: View {
    let data: SafetyResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Safety Assessment")
                    .font(.headline)
                Spacer()
                Text(data.assessment.level.uppercased())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(levelColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(levelColor.opacity(0.2))
                    .cornerRadius(8)
            }

            Text(data.assessment.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !data.assessment.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    ForEach(data.assessment.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(rec)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var levelColor: Color {
        switch data.assessment.level.lowercased() {
        case "low": return .green
        case "moderate": return .yellow
        case "considerable", "high": return .orange
        case "extreme": return .red
        default: return .gray
        }
    }
}

// MARK: - Extended Weather Card
struct ExtendedWeatherCard: View {
    let data: SafetyResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Details")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let temp = data.weather.temperature {
                    WeatherMetric(icon: "thermometer", label: "Temperature", value: "\(temp)°F")
                }
                if let feelsLike = data.weather.feelsLike {
                    WeatherMetric(icon: "thermometer.sun", label: "Feels Like", value: "\(feelsLike)°F")
                }
                if let humidity = data.weather.humidity {
                    WeatherMetric(icon: "humidity", label: "Humidity", value: "\(humidity)%")
                }
                if let pressure = data.weather.pressure {
                    WeatherMetric(icon: "barometer", label: "Pressure", value: "\(Int(pressure)) mb")
                }
                if let uv = data.weather.uvIndex {
                    WeatherMetric(icon: "sun.max", label: "UV Index", value: "\(uv)")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct WeatherMetric: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Visibility Card
struct VisibilityCard: View {
    let data: SafetyResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visibility")
                .font(.headline)

            if let visibility = data.weather.visibility {
                HStack {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                    Text("\(Int(visibility)) miles")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(visibilityDescription(visibility))
                        .font(.subheadline)
                        .foregroundColor(visibilityColor(visibility))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(visibilityColor(visibility).opacity(0.2))
                        .cornerRadius(8)
                }
            } else {
                Text("Visibility data unavailable")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func visibilityDescription(_ miles: Double) -> String {
        if miles >= 10 { return "Excellent" }
        if miles >= 5 { return "Good" }
        if miles >= 2 { return "Moderate" }
        return "Poor"
    }

    private func visibilityColor(_ miles: Double) -> Color {
        if miles >= 10 { return .green }
        if miles >= 5 { return .blue }
        if miles >= 2 { return .yellow }
        return .red
    }
}

// MARK: - Wind Assessment Card
struct WindAssessmentCard: View {
    let data: SafetyResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wind Conditions")
                .font(.headline)

            if let wind = data.weather.wind {
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "wind")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("\(wind.speed)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("mph")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let gust = wind.gust {
                        VStack {
                            Image(systemName: "wind.circle")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("\(gust)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("gusts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack {
                        Image(systemName: "location.north.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(directionAngle(wind.direction)))
                        Text(wind.direction)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("direction")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                Text(windDescription(wind.speed))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Wind data unavailable")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func directionAngle(_ direction: String) -> Double {
        let directions = ["N": 0, "NE": 45, "E": 90, "SE": 135, "S": 180, "SW": 225, "W": 270, "NW": 315]
        return Double(directions[direction] ?? 0)
    }

    private func windDescription(_ speed: Int) -> String {
        if speed < 10 { return "Light winds - ideal conditions" }
        if speed < 20 { return "Moderate winds - good skiing" }
        if speed < 30 { return "Strong winds - exposed terrain affected" }
        return "High winds - lifts may be affected"
    }
}

// MARK: - Hazard Matrix Card
struct HazardMatrixCard: View {
    let hazards: SafetyResponse.Hazards

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hazard Assessment")
                .font(.headline)

            VStack(spacing: 8) {
                if let avalanche = hazards.avalanche {
                    HazardRow(name: "Avalanche", level: avalanche.level, description: avalanche.description)
                }
                if let treeWells = hazards.treeWells {
                    HazardRow(name: "Tree Wells", level: treeWells.level, description: treeWells.description)
                }
                if let icy = hazards.icy {
                    HazardRow(name: "Icy Conditions", level: icy.level, description: icy.description)
                }
                if let crowded = hazards.crowded {
                    HazardRow(name: "Crowding", level: crowded.level, description: crowded.description)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct HazardRow: View {
    let name: String
    let level: String
    let description: String?

    var body: some View {
        HStack {
            Circle()
                .fill(levelColor)
                .frame(width: 12, height: 12)

            Text(name)
                .font(.subheadline)

            Spacer()

            Text(level.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(levelColor)
        }
        .padding(.vertical, 4)
    }

    private var levelColor: Color {
        switch level.lowercased() {
        case "low": return .green
        case "moderate": return .yellow
        case "considerable", "high": return .orange
        case "extreme": return .red
        default: return .gray
        }
    }
}

// MARK: - Error Card
struct ErrorCard: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Failed to load data")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    PatrolView()
}
