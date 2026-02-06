import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unauthorized
    case rateLimited(retryAfter: Int)
    case tokenRefreshFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to connect. Please try again."
        case .networkError(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "No internet connection. Please check your network settings."
                case .timedOut:
                    return "Request timed out. Please try again."
                case .cannotFindHost, .cannotConnectToHost:
                    return "Unable to reach server. Please try again later."
                default:
                    return "Connection failed. Please check your internet and try again."
                }
            }
            return "Connection failed. Please check your internet and try again."
        case .decodingError:
            return "We're having trouble loading this data. Please try again."
        case .serverError(let code):
            if code >= 500 {
                return "Our servers are experiencing issues. Please try again in a moment."
            }
            return "Something went wrong. Please try again."
        case .unauthorized:
            return "Please sign in to continue."
        case .rateLimited(let retryAfter):
            return "Too many requests. Please wait \(retryAfter) seconds and try again."
        case .tokenRefreshFailed:
            return "Your session has expired. Please sign in again."
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
        // Use protocol cache policy to respect server cache headers (10-min TTL)
        // instead of returnCacheDataElseLoad which can return stale data indefinitely
        config.requestCachePolicy = .useProtocolCachePolicy
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

    /// Fetch all data for multiple mountains in a single batch request
    func fetchBatchMountainData(for mountainIds: [String]) async throws -> BatchMountainAllResponse {
        let ids = mountainIds.joined(separator: ",")
        return try await fetch(endpoint: "/mountains/batch/all?ids=\(ids)")
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

    func fetchArrivalTime(for mountainId: String) async throws -> ArrivalTimeRecommendation {
        try await fetch(endpoint: "/mountains/\(mountainId)/arrival-time")
    }

    func fetchParkingPrediction(for mountainId: String) async throws -> ParkingPredictionResponse {
        try await fetch(endpoint: "/mountains/\(mountainId)/parking")
    }

    func fetchSafety(for mountainId: String) async throws -> SafetyData {
        try await fetch(endpoint: "/mountains/\(mountainId)/safety")
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

    private func fetch<T: Decodable>(endpoint: String, requiresAuth: Bool = false) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        // Build request with optional auth header
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if requiresAuth {
            try await addAuthHeader(to: &request)
        }

        return try await performRequest(request, requiresAuth: requiresAuth)
    }

    /// Perform authenticated POST request
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U, requiresAuth: Bool = false) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        if requiresAuth {
            try await addAuthHeader(to: &request)
        }

        return try await performRequest(request, requiresAuth: requiresAuth)
    }

    /// Perform request with automatic token refresh on 401
    private func performRequest<T: Decodable>(_ request: URLRequest, requiresAuth: Bool, isRetry: Bool = false) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(URLError(.badServerResponse))
            }

            // Handle 401 Unauthorized - attempt token refresh
            if httpResponse.statusCode == 401 && requiresAuth && !isRetry {
                do {
                    try await refreshTokens()
                    // Retry with new token
                    var retryRequest = request
                    try await addAuthHeader(to: &retryRequest)
                    return try await performRequest(retryRequest, requiresAuth: requiresAuth, isRetry: true)
                } catch {
                    // Token refresh failed - clear tokens and throw
                    KeychainHelper.clearTokens()
                    throw APIError.tokenRefreshFailed
                }
            }

            // Handle 429 Rate Limited
            if httpResponse.statusCode == 429 {
                let retryAfter = Int(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
                throw APIError.rateLimited(retryAfter: retryAfter)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                #if DEBUG
                // Debug: Print raw JSON for mountains endpoint to verify passType is present
                if request.url?.path.contains("/mountains") == true && !request.url!.path.contains("/mountains/") {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        let preview = String(jsonString.prefix(500))
                        print("🌐 [APIClient] Mountains raw response (first 500 chars): \(preview)")
                    }
                }
                #endif
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("🌐 [APIClient] Decoding error: \(error)")
                #endif
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Auth Header Management

    private func addAuthHeader(to request: inout URLRequest) async throws {
        // Check if we need to refresh first
        if KeychainHelper.isAccessTokenExpired() {
            try await refreshTokens()
        }

        guard let accessToken = KeychainHelper.getAccessToken() else {
            throw APIError.unauthorized
        }

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    /// Refresh tokens using the backend refresh endpoint
    private func refreshTokens() async throws {
        guard let refreshToken = KeychainHelper.getRefreshToken() else {
            throw APIError.tokenRefreshFailed
        }

        guard let url = URL(string: baseURL + "/auth/refresh") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct RefreshRequest: Encodable {
            let refreshToken: String
        }

        struct RefreshResponse: Decodable {
            let accessToken: String
            let refreshToken: String
        }

        request.httpBody = try JSONEncoder().encode(RefreshRequest(refreshToken: refreshToken))

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.tokenRefreshFailed
        }

        let tokens = try decoder.decode(RefreshResponse.self, from: data)

        // Save new tokens (access token expires in 15 minutes by default)
        try KeychainHelper.saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresIn: 15 * 60
        )
    }
}

