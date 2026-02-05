import Foundation

@MainActor
@Observable
class TripPlanningViewModel {
    var roads: RoadsResponse?
    var tripAdvice: TripAdviceResponse?
    var powderDayPlan: PowderDayPlanResponse?
    var isLoading = false
    var error: Error?

    private let apiClient = APIClient.shared

    func fetchAll(for mountainId: String) async {
        isLoading = true
        error = nil

        // Fetch all three in parallel, handling failures gracefully
        async let roadsTask: RoadsResponse? = fetchRoadsSafe(for: mountainId)
        async let tripAdviceTask: TripAdviceResponse? = fetchTripAdviceSafe(for: mountainId)
        async let powderDayTask: PowderDayPlanResponse? = fetchPowderDayPlanSafe(for: mountainId)

        let (roadsResult, tripAdviceResult, powderDayResult) = await (roadsTask, tripAdviceTask, powderDayTask)

        roads = roadsResult
        tripAdvice = tripAdviceResult
        powderDayPlan = powderDayResult
        isLoading = false
    }

    private func fetchRoadsSafe(for mountainId: String) async -> RoadsResponse? {
        do {
            return try await apiClient.fetchRoads(for: mountainId)
        } catch {
            return nil
        }
    }

    private func fetchTripAdviceSafe(for mountainId: String) async -> TripAdviceResponse? {
        do {
            return try await apiClient.fetchTripAdvice(for: mountainId)
        } catch {
            return nil
        }
    }

    private func fetchPowderDayPlanSafe(for mountainId: String) async -> PowderDayPlanResponse? {
        do {
            return try await apiClient.fetchPowderDayPlan(for: mountainId)
        } catch {
            return nil
        }
    }

    func refresh(for mountainId: String) async {
        await fetchAll(for: mountainId)
    }
}
