import Foundation

struct FavoriteMountain: Codable, Identifiable {
    let mountain: Mountain
    let conditions: MountainConditions?
    let forecast: [ForecastDay]
    let distance: Double? // miles from user

    var id: String { mountain.id }

    // Quick access to key metrics
    var snowfall24h: Int {
        conditions?.snowfall24h ?? 0
    }

    var next3DaySnow: Int {
        forecast.prefix(3).reduce(0) { $0 + $1.snowfall }
    }

    var hasData: Bool {
        conditions != nil || !forecast.isEmpty
    }
}
