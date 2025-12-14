import Foundation
import SwiftUI

@MainActor
@Observable
class HistoryViewModel {
    var history: [HistoryDataPoint] = []
    var summary: HistorySummary?
    var isLoading = false
    var error: String?
    var selectedDays: Int = 30

    private let apiClient = APIClient.shared

    func loadHistory() async {
        isLoading = true
        error = nil

        do {
            let response = try await apiClient.fetchHistory(days: selectedDays)
            self.history = response.history
            self.summary = response.summary
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func changePeriod(to days: Int) async {
        selectedDays = days
        await loadHistory()
    }
}
