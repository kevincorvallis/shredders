import os

/// Lightweight performance logger using os_signpost for Instruments profiling.
/// Usage:
///   let span = PerformanceLogger.begin(.appLaunch)
///   // ... work ...
///   span.end()
enum PerformanceLogger {
    private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.shredders.powdertracker", category: "Performance")
    private static let signposter = OSSignposter(logHandle: log)

    enum Span: String {
        case appLaunch = "App Launch"
        case mountainsLoad = "Mountains Load"
        case favoritesLoad = "Favorites Load"
        case homeRefresh = "Home Refresh"
        case enhancedDataLoad = "Enhanced Data Load"
        case eventsFetch = "Events Fetch"
        case networkRequest = "Network Request"
    }

    struct IntervalHandle {
        fileprivate let state: OSSignpostIntervalState
        fileprivate let span: Span

        func end() {
            PerformanceLogger.signposter.endInterval(span.rawValue, state)
        }
    }

    static func begin(_ span: Span) -> IntervalHandle {
        let state = signposter.beginInterval(span.rawValue)
        return IntervalHandle(state: state, span: span)
    }

    /// One-shot event marker (no duration)
    static func event(_ name: StaticString) {
        signposter.emitEvent(name)
    }
}
