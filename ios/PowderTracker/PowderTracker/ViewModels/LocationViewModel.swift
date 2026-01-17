import Foundation

@MainActor
class LocationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var locationData: MountainBatchedResponse?
    @Published var liftData: LiftGeoJSON?
    @Published var snowComparison: SnowComparisonResponse?

    let mountain: Mountain

    init(mountain: Mountain) {
        self.mountain = mountain
    }

    func fetchData() async {
        isLoading = true
        error = nil

        do {
            // Add a small delay to ensure view is stable before fetching
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            let data = try await APIClient.shared.fetchMountainData(for: mountain.id)

            // Check if task was cancelled
            guard !Task.isCancelled else {
                isLoading = false
                return
            }

            locationData = data
            isLoading = false

            // Fetch lift data and snow comparison (don't block on errors)
            await fetchLiftData()
            await fetchSnowComparison()
        } catch {
            // Ignore cancellation errors
            if (error as NSError).code == NSURLErrorCancelled {
                // Retry once after a delay
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if !Task.isCancelled {
                    await fetchData()
                }
                return
            }

            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func fetchLiftData() async {
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/mountains/\(mountain.id)/lifts") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let lifts = try JSONDecoder().decode(LiftGeoJSON.self, from: data)
            liftData = lifts
        } catch {
            // Lift data is optional, silently fail
        }
    }

    func fetchSnowComparison() async {
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/mountains/\(mountain.id)/snow-comparison") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let comparison = try JSONDecoder().decode(SnowComparisonResponse.self, from: data)
            snowComparison = comparison
        } catch {
            // Snow comparison is optional, silently fail
        }
    }

    // MARK: - Computed Properties

    var currentSnowDepth: Double? {
        guard let depth = locationData?.conditions.snowDepth else { return nil }
        return Double(depth)
    }

    var snowDepth24h: Double? {
        Double(locationData?.conditions.snowfall24h ?? 0)
    }

    var snowDepth48h: Double? {
        Double(locationData?.conditions.snowfall48h ?? 0)
    }

    var snowDepth72h: Double? {
        // Use snowfall7d as approximation for 72h
        Double(locationData?.conditions.snowfall7d ?? 0)
    }

    var temperature: Double? {
        guard let temp = locationData?.conditions.temperature else { return nil }
        return Double(temp)
    }

    var windSpeed: Double? {
        guard let speed = locationData?.conditions.wind?.speed else { return nil }
        return Double(speed)
    }

    var weatherDescription: String? {
        locationData?.conditions.conditions
    }

    var powderScore: Int? {
        Int(locationData?.powderScore.score ?? 0)
    }

    var lastUpdated: Date? {
        guard let dateString = locationData?.conditions.lastUpdated else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }

    var hasRoadData: Bool {
        guard let roads = locationData?.roads else { return false }
        return roads.supported && !roads.passes.isEmpty
    }

    var hasWebcams: Bool {
        guard let mountain = locationData?.mountain else { return false }
        let hasResortWebcams = !mountain.webcams.isEmpty
        let hasRoadWebcams = mountain.roadWebcams?.isEmpty == false
        return hasResortWebcams || hasRoadWebcams
    }

    // MARK: - Historical Data for Chart

    var historicalSnowData: [HistoricalDataPoint] {
        var dataPoints: [HistoricalDataPoint] = []

        // For now, create simple mock historical data based on current depth
        // TODO: Add actual historical data endpoint
        if let currentDepth = currentSnowDepth {
            // Create approximate historical data points
            dataPoints.append(HistoricalDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
                depth: currentDepth * 0.6,
                label: "30d"
            ))

            dataPoints.append(HistoricalDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                depth: currentDepth * 0.75,
                label: "14d"
            ))

            dataPoints.append(HistoricalDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                depth: currentDepth * 0.9,
                label: "7d"
            ))

            // Add current depth
            dataPoints.append(HistoricalDataPoint(
                date: Date(),
                depth: currentDepth,
                label: "Now"
            ))
        }

        return dataPoints.sorted { $0.date < $1.date }
    }
}

struct HistoricalDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let depth: Double
    let label: String
}
