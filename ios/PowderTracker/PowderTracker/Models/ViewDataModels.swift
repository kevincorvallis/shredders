import Foundation
import SwiftUI

// MARK: - Snow Timeline Data

struct SnowDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let snowfall: Int
    let isForecast: Bool
    let isToday: Bool

    var dayOfWeek: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    var dayOfMonth: String {
        date.formatted(.dateTime.day())
    }

    var dateLabel: String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}

// MARK: - Road Condition Data

struct RoadCondition: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let conditions: String?
    let chainsRequired: Bool
}
