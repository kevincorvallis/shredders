import Foundation
import CoreLocation

@MainActor
@Observable
class LocationViewModel {
    var isLoading = false
    var error: String?
    var locationData: MountainBatchedResponse?
    var liftData: LiftGeoJSON?
    var snowComparison: SnowComparisonResponse?
    var safetyData: SafetyData?
    var snowHistory: [SnowHistoryPoint] = []
    var snowHistoryLoading = false

    // WeatherKit integration
    var weatherKitData: WeatherKitService.WeatherData?
    var weatherKitLoading = false
    private let weatherKitService = WeatherKitService.shared

    let mountain: Mountain

    // MARK: - In-memory cache for satellite endpoints (10min TTL)

    private static var satelliteCache: [String: (data: SatelliteCacheEntry, timestamp: Date)] = [:]
    private static let cacheTTL: TimeInterval = 600 // 10 minutes

    private struct SatelliteCacheEntry {
        var liftData: LiftGeoJSON?
        var snowComparison: SnowComparisonResponse?
        var safetyData: SafetyData?
        var snowHistory: [SnowHistoryPoint]
    }

    init(mountain: Mountain) {
        self.mountain = mountain

        // Restore from cache if fresh
        if let cached = Self.satelliteCache[mountain.id],
           Date().timeIntervalSince(cached.timestamp) < Self.cacheTTL {
            liftData = cached.data.liftData
            snowComparison = cached.data.snowComparison
            safetyData = cached.data.safetyData
            snowHistory = cached.data.snowHistory
        }
    }

    private func saveSatelliteCache() {
        Self.satelliteCache[mountain.id] = (
            data: SatelliteCacheEntry(
                liftData: liftData,
                snowComparison: snowComparison,
                safetyData: safetyData,
                snowHistory: snowHistory
            ),
            timestamp: Date()
        )
    }

    func fetchData() async {
        isLoading = true
        error = nil

        do {
            let data = try await APIClient.shared.fetchMountainData(for: mountain.id)

            guard !Task.isCancelled else {
                isLoading = false
                return
            }

            locationData = data
            isLoading = false

            // Skip satellite fetches if cache is fresh
            let hasFreshCache = Self.satelliteCache[mountain.id].map {
                Date().timeIntervalSince($0.timestamp) < Self.cacheTTL
            } ?? false

            if !hasFreshCache {
                async let l: Void = fetchLiftData()
                async let sc: Void = fetchSnowComparison()
                async let s: Void = fetchSafetyData()
                async let sh: Void = fetchSnowHistory()
                async let w: Void = fetchWeatherKitData()
                _ = await (l, sc, s, sh, w)
                saveSatelliteCache()
            } else {
                // Still fetch WeatherKit (local, no network cost)
                await fetchWeatherKitData()
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
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

    func fetchSafetyData() async {
        do {
            let safety = try await APIClient.shared.fetchSafety(for: mountain.id)
            safetyData = safety
        } catch {
            // Safety data is optional, silently fail
        }
    }

    func fetchSnowHistory(days: Int = 30) async {
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/mountains/\(mountain.id)/history?days=\(days)") else { return }

        snowHistoryLoading = true
        defer { snowHistoryLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SnowHistoryResponse.self, from: data)
            snowHistory = response.history
        } catch {
            // Keep empty - charts will show fallback data
            #if DEBUG
            print("Failed to fetch snow history: \(error)")
            #endif
        }
    }
    
    func fetchWeatherKitData() async {
        // Create location from mountain coordinates
        let location = CLLocation(latitude: mountain.location.lat, longitude: mountain.location.lng)
        
        weatherKitLoading = true
        defer { weatherKitLoading = false }
        
        do {
            let weather = try await weatherKitService.fetchWeather(for: location)
            weatherKitData = weather
        } catch {
            // WeatherKit is optional - fall back to API data
            #if DEBUG
            print("Failed to fetch WeatherKit data: \(error)")
            #endif
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
        // Prefer WeatherKit data, fall back to API
        if let weatherKit = weatherKitData?.currentWeather.temperature {
            return weatherKitService.celsiusToFahrenheit(weatherKit)
        }
        guard let temp = locationData?.conditions.temperature else { return nil }
        return Double(temp)
    }

    var windSpeed: Double? {
        // Prefer WeatherKit data, fall back to API
        if let weatherKit = weatherKitData?.currentWeather.windSpeed {
            return weatherKitService.metersPerSecondToMph(weatherKit)
        }
        guard let speed = locationData?.conditions.wind?.speed else { return nil }
        return Double(speed)
    }

    var weatherDescription: String? {
        // Prefer WeatherKit data, fall back to API
        weatherKitData?.currentWeather.condition ?? locationData?.conditions.conditions
    }
    
    // Additional WeatherKit properties
    var humidity: Double? {
        weatherKitData?.currentWeather.humidity
    }
    
    var uvIndex: Int? {
        weatherKitData?.currentWeather.uvIndex
    }
    
    var visibility: Double? {
        guard let meters = weatherKitData?.currentWeather.visibility else { return nil }
        return meters * 0.000621371 // Convert meters to miles
    }
    
    var dewPoint: Double? {
        guard let celsius = weatherKitData?.currentWeather.dewPoint else { return nil }
        return weatherKitService.celsiusToFahrenheit(celsius)
    }
    
    var apparentTemperature: Double? {
        guard let celsius = weatherKitData?.currentWeather.apparentTemperature else { return nil }
        return weatherKitService.celsiusToFahrenheit(celsius)
    }
    
    var windGust: Double? {
        guard let mps = weatherKitData?.currentWeather.windGust else { return nil }
        return weatherKitService.metersPerSecondToMph(mps)
    }
    
    var windDirection: Int? {
        weatherKitData?.currentWeather.windDirection
    }
    
    var weatherSymbolName: String? {
        weatherKitData?.currentWeather.symbolName
    }
    
    var hasWeatherKitData: Bool {
        weatherKitData != nil
    }

    var powderScore: Double? {
        locationData?.powderScore.score
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
        let hasWebcamPageUrl = mountain.webcamPageUrl != nil
        return hasResortWebcams || hasRoadWebcams || hasWebcamPageUrl
    }

    // MARK: - Historical Data for Chart

    var historicalSnowData: [HistoricalDataPoint] {
        // Use real API data if available
        if !snowHistory.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            return snowHistory.compactMap { point -> HistoricalDataPoint? in
                guard let depth = point.snowDepth else { return nil }
                guard let date = formatter.date(from: point.date) else { return nil }

                // Create a short label from the date
                let labelFormatter = DateFormatter()
                labelFormatter.dateFormat = "M/d"
                let label = labelFormatter.string(from: date)

                return HistoricalDataPoint(date: date, depth: Double(depth), label: label)
            }.sorted { $0.date < $1.date }
        }

        // Fallback to generated data based on current depth
        var dataPoints: [HistoricalDataPoint] = []

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
