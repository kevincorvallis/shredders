import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL = AppConfig.apiBaseURL

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60  // Increased timeout
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    // MARK: - Mountains List

    func fetchMountains() async throws -> MountainsResponse {
        try await fetch(endpoint: "/mountains")
    }

    func fetchMountainDetail(mountainId: String) async throws -> MountainDetail {
        try await fetch(endpoint: "/mountains/\(mountainId)")
    }

    // MARK: - Per-Mountain Endpoints

    /// Fetch all mountain data in a single batched request for better performance
    func fetchMountainData(for mountainId: String) async throws -> MountainBatchedResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/all")
    }

    func fetchConditions(for mountainId: String) async throws -> MountainConditions {
        try await fetch(endpoint: "/mountains/\(mountainId)/conditions")
    }

    func fetchForecast(for mountainId: String) async throws -> MountainForecastResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/forecast")
    }

    func fetchPowderScore(for mountainId: String) async throws -> MountainPowderScore {
        try await fetch(endpoint: "/mountains/\(mountainId)/powder-score")
    }

    func fetchHistory(for mountainId: String, days: Int = 30) async throws -> MountainHistoryResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/history?days=\(days)")
    }

    func fetchRoads(for mountainId: String) async throws -> RoadsResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/roads")
    }

    func fetchTripAdvice(for mountainId: String) async throws -> TripAdviceResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/trip-advice")
    }

    func fetchPowderDayPlan(for mountainId: String) async throws -> PowderDayPlanResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/powder-day")
    }

    func fetchAlerts(for mountainId: String) async throws -> WeatherAlertsResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/alerts")
    }

    func fetchWeatherGovLinks(for mountainId: String) async throws -> WeatherGovLinksResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/weather-gov-links")
    }

    func fetchHourlyForecast(for mountainId: String, hours: Int = 48) async throws -> HourlyForecastResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/hourly?hours=\(hours)")
    }

    // MARK: - Legacy Endpoints (default to Baker for backwards compatibility)

    func fetchConditions() async throws -> Conditions {
        try await fetch(endpoint: "/conditions")
    }

    func fetchForecast() async throws -> ForecastResponse {
        try await fetch(endpoint: "/forecast")
    }

    func fetchPowderScore() async throws -> PowderScore {
        try await fetch(endpoint: "/powder-score")
    }

    func fetchHistory(days: Int = 30) async throws -> HistoryResponse {
        try await fetch(endpoint: "/history?days=\(days)")
    }

    // MARK: - Generic Fetch

    private func fetch<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(URLError(.badServerResponse))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
