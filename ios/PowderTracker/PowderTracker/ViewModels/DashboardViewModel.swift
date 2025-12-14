import Foundation
import SwiftUI

@MainActor
@Observable
class DashboardViewModel {
    var conditions: Conditions?
    var powderScore: PowderScore?
    var forecast: [ForecastDay] = []
    var isLoading = false
    var error: String?

    private let apiClient = APIClient.shared

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let conditionsTask = apiClient.fetchConditions()
            async let powderScoreTask = apiClient.fetchPowderScore()
            async let forecastTask = apiClient.fetchForecast()

            let (conditions, powderScore, forecastResponse) = try await (conditionsTask, powderScoreTask, forecastTask)

            self.conditions = conditions
            self.powderScore = powderScore
            self.forecast = forecastResponse.forecast

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }
}
