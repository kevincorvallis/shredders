import ActivityKit
import SwiftUI

// MARK: - Activity Attributes (must match widget extension)

/// Attributes for the ski day Live Activity
/// Note: This must be identical to the definition in the widget extension
struct SkiDayAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var snowfall24h: Int
        var powderScore: Int
        var liftsOpen: Int
        var liftsTotal: Int
        var lastUpdated: Date
        var alertMessage: String?
    }

    var mountainId: String
    var mountainName: String
    var mountainColor: String
}

// MARK: - Activity Manager

/// Manages Live Activities for ski days
@available(iOS 16.2, *)
@MainActor
class SkiDayActivityService: ObservableObject {
    static let shared = SkiDayActivityService()

    @Published private(set) var currentActivity: Activity<SkiDayAttributes>?

    private init() {
        // Check for any existing activities on app launch
        if let existing = Activity<SkiDayAttributes>.activities.first {
            currentActivity = existing
        }
    }

    /// Start a new ski day activity
    func startActivity(
        mountainId: String,
        mountainName: String,
        mountainColor: String,
        snowfall24h: Int,
        powderScore: Int,
        liftsOpen: Int,
        liftsTotal: Int
    ) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw SkiDayActivityError.notSupported
        }

        // End any existing activity first
        await endActivity()

        let attributes = SkiDayAttributes(
            mountainId: mountainId,
            mountainName: mountainName,
            mountainColor: mountainColor
        )

        let initialState = SkiDayAttributes.ContentState(
            snowfall24h: snowfall24h,
            powderScore: powderScore,
            liftsOpen: liftsOpen,
            liftsTotal: liftsTotal,
            lastUpdated: Date(),
            alertMessage: nil
        )

        let content = ActivityContent(
            state: initialState,
            staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            HapticFeedback.success.trigger()
        } catch {
            throw SkiDayActivityError.failedToStart(error)
        }
    }

    /// Update the current activity with new conditions
    func updateActivity(
        snowfall24h: Int,
        powderScore: Int,
        liftsOpen: Int,
        liftsTotal: Int
    ) async {
        guard let activity = currentActivity else { return }

        let newState = SkiDayAttributes.ContentState(
            snowfall24h: snowfall24h,
            powderScore: powderScore,
            liftsOpen: liftsOpen,
            liftsTotal: liftsTotal,
            lastUpdated: Date(),
            alertMessage: nil
        )

        let content = ActivityContent(
            state: newState,
            staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
        )

        await activity.update(content)
    }

    /// Update with an alert message (shows notification)
    func sendAlert(_ message: String) async {
        guard let activity = currentActivity else { return }

        var state = activity.content.state
        state.alertMessage = message
        state.lastUpdated = Date()

        let content = ActivityContent(
            state: state,
            staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
        )

        let alertConfig = AlertConfiguration(
            title: LocalizedStringResource("Conditions Update"),
            body: LocalizedStringResource(stringLiteral: message),
            sound: .default
        )

        await activity.update(content, alertConfiguration: alertConfig)
        HapticFeedback.warning.trigger()
    }

    /// End the current activity
    func endActivity() async {
        guard let activity = currentActivity else { return }

        let finalState = activity.content.state
        let content = ActivityContent(
            state: finalState,
            staleDate: nil
        )

        await activity.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
    }

    /// Check if Live Activities are available
    static var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Check if an activity is currently running
    var isActivityRunning: Bool {
        currentActivity != nil
    }
}

// MARK: - Errors

enum SkiDayActivityError: LocalizedError {
    case notSupported
    case failedToStart(Error)

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Live Activities are not enabled. Enable them in Settings > PowderTracker."
        case .failedToStart(let error):
            return "Failed to start Live Activity: \(error.localizedDescription)"
        }
    }
}

// MARK: - Convenience Extension

@available(iOS 16.2, *)
extension SkiDayActivityService {
    /// Start activity with mountain and conditions data
    func startActivity(
        for mountain: Mountain,
        conditions: MountainConditions?,
        score: Double?
    ) async throws {
        try await startActivity(
            mountainId: mountain.id,
            mountainName: mountain.name,
            mountainColor: mountain.color,
            snowfall24h: conditions?.snowfall24h ?? 0,
            powderScore: Int(score ?? 5),
            liftsOpen: conditions?.liftStatus?.liftsOpen ?? 0,
            liftsTotal: conditions?.liftStatus?.liftsTotal ?? 0
        )
    }

    /// Update activity with conditions data
    func updateActivity(with conditions: MountainConditions?, score: Double?) async {
        await updateActivity(
            snowfall24h: conditions?.snowfall24h ?? 0,
            powderScore: Int(score ?? 5),
            liftsOpen: conditions?.liftStatus?.liftsOpen ?? 0,
            liftsTotal: conditions?.liftStatus?.liftsTotal ?? 0
        )
    }
}
