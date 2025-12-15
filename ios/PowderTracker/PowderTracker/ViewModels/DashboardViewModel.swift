import Foundation
import SwiftUI

@MainActor
@Observable
class DashboardViewModel {
    var conditions: MountainConditions?
    var powderScore: MountainPowderScore?
    var forecast: [ForecastDay] = []
    var isLoading = false
    var error: String?

    private let apiClient = APIClient.shared
    private(set) var currentMountainId: String = "baker"

    func loadData(for mountainId: String) async {
        currentMountainId = mountainId
        isLoading = true
        error = nil

        do {
            async let conditionsTask = apiClient.fetchConditions(for: mountainId)
            async let powderScoreTask = apiClient.fetchPowderScore(for: mountainId)
            async let forecastTask = apiClient.fetchForecast(for: mountainId)

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
        await loadData(for: currentMountainId)
    }
}
