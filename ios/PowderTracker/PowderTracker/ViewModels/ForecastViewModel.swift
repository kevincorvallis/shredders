import Foundation
import SwiftUI

@MainActor
@Observable
class ForecastViewModel {
    var forecast: [ForecastDay] = []
    var isLoading = false
    var error: String?

    private let apiClient = APIClient.shared

    func loadForecast() async {
        isLoading = true
        error = nil

        do {
            let response = try await apiClient.fetchForecast()
            self.forecast = response.forecast
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
