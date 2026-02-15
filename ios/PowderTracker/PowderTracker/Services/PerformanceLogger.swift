import Foundation
import os

/// Lightweight performance logger using os_signpost for Instruments profiling.
/// Open Instruments → choose the "os_signpost" instrument → filter by "Performance" category.
///
/// Usage:
///   let span = PerformanceLogger.beginAppLaunch()
///   // ... work ...
///   span.end()
enum PerformanceLogger {
    static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.shredders.powdertracker", category: "Performance")

    struct IntervalHandle {
        fileprivate let id: OSSignpostID
        fileprivate let name: StaticString

        func end() {
            os_signpost(.end, log: PerformanceLogger.log, name: name, signpostID: id)
        }
    }

    private static func begin(_ name: StaticString) -> IntervalHandle {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        return IntervalHandle(id: id, name: name)
    }

    static func beginAppLaunch() -> IntervalHandle { begin("App Launch") }
    static func beginMountainsLoad() -> IntervalHandle { begin("Mountains Load") }
    static func beginFavoritesLoad() -> IntervalHandle { begin("Favorites Load") }
    static func beginHomeRefresh() -> IntervalHandle { begin("Home Refresh") }
    static func beginEnhancedDataLoad() -> IntervalHandle { begin("Enhanced Data Load") }
    static func beginEventsFetch() -> IntervalHandle { begin("Events Fetch") }
    static func beginNetworkRequest() -> IntervalHandle { begin("Network Request") }

    /// One-shot event marker (no duration)
    static func event(_ name: StaticString) {
        os_signpost(.event, log: log, name: name)
    }
}
