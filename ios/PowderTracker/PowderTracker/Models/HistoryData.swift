import Foundation

struct HistoryResponse: Codable {
    let location: HistoryLocation
    let period: HistoryPeriod
    let summary: HistorySummary
    let history: [HistoryDataPoint]
}

struct HistoryLocation: Codable {
    let name: String
    let snotelStation: String
}

struct HistoryPeriod: Codable {
    let days: Int
    let start: String
    let end: String
}

struct HistorySummary: Codable {
    let currentDepth: Int
    let maxDepth: Int
    let minDepth: Int
    let totalSnowfall: Int
    let avgDailySnowfall: String
}

struct HistoryDataPoint: Codable, Identifiable {
    var id: String { date }

    let date: String
    let snowDepth: Int
    let snowfall: Int
    let temperature: Int

    var formattedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

// MARK: - Mock Data
extension HistoryDataPoint {
    static func mockHistory(days: Int = 30) -> [HistoryDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var history: [HistoryDataPoint] = []
        var currentDepth = 142

        for i in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            let snowfall = Int.random(in: 0...12)
            let melt = Int.random(in: 0...2)
            currentDepth = max(80, currentDepth - snowfall + melt)

            history.append(HistoryDataPoint(
                date: formatter.string(from: date),
                snowDepth: currentDepth + snowfall,
                snowfall: snowfall,
                temperature: Int.random(in: 20...40)
            ))

            currentDepth += snowfall - melt
        }

        return history
    }
}
