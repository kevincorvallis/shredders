import WidgetKit
import SwiftUI
import AppIntents

private let apiBaseURL = "https://shredders-bay.vercel.app/api"

struct PowderEntry: TimelineEntry {
    let date: Date
    let mountainId: String
    let mountainName: String
    let snowDepth: Int
    let snowfall24h: Int
    let powderScore: Int
    let scoreLabel: String
    let forecast: [WidgetForecastDay]
}

struct WidgetForecastDay: Identifiable {
    let id = UUID()
    let dayOfWeek: String
    let snowfall: Int
    let icon: String
}

struct ConfigurableProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PowderEntry {
        PowderEntry(
            date: Date(),
            mountainId: WidgetMountainOption.crystalMountain.apiId,
            mountainName: WidgetMountainOption.crystalMountain.displayName,
            snowDepth: 142,
            snowfall24h: 8,
            powderScore: 8,
            scoreLabel: "Great",
            forecast: [
                WidgetForecastDay(dayOfWeek: "Sat", snowfall: 6, icon: "❄️"),
                WidgetForecastDay(dayOfWeek: "Sun", snowfall: 10, icon: "❄️"),
                WidgetForecastDay(dayOfWeek: "Mon", snowfall: 4, icon: "❄️")
            ]
        )
    }

    func snapshot(for configuration: SelectMountainIntent, in context: Context) async -> PowderEntry {
        let mountain = configuration.mountain
        return PowderEntry(
            date: Date(),
            mountainId: mountain.apiId,
            mountainName: mountain.displayName,
            snowDepth: 142,
            snowfall24h: 8,
            powderScore: 8,
            scoreLabel: "Great",
            forecast: [
                WidgetForecastDay(dayOfWeek: "Sat", snowfall: 6, icon: "❄️"),
                WidgetForecastDay(dayOfWeek: "Sun", snowfall: 10, icon: "❄️"),
                WidgetForecastDay(dayOfWeek: "Mon", snowfall: 4, icon: "❄️")
            ]
        )
    }

    func timeline(for configuration: SelectMountainIntent, in context: Context) async -> Timeline<PowderEntry> {
        let mountain = configuration.mountain
        let placeholderEntry = placeholder(in: context)

        do {
            // Fetch real data from API for selected mountain
            let conditions = try await fetchConditions(for: mountain.apiId)
            let powderScore = try await fetchPowderScore(for: mountain.apiId)
            let forecastResponse = try await fetchForecast(for: mountain.apiId)

            let forecast = forecastResponse.forecast.prefix(3).map { day in
                WidgetForecastDay(dayOfWeek: day.dayOfWeek, snowfall: day.snowfall, icon: day.iconEmoji)
            }

            let entry = PowderEntry(
                date: Date(),
                mountainId: mountain.apiId,
                mountainName: mountain.displayName,
                snowDepth: conditions.snowDepth,
                snowfall24h: conditions.snowfall24h,
                powderScore: powderScore.score,
                scoreLabel: powderScore.label,
                forecast: Array(forecast)
            )

            // Refresh every 30 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            return Timeline(entries: [entry], policy: .after(nextUpdate))

        } catch {
            // Use placeholder on error
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
            return Timeline(entries: [placeholderEntry], policy: .after(nextUpdate))
        }
    }

    // MARK: - API Calls

    private func fetchConditions(for mountainId: String) async throws -> WidgetConditions {
        guard let url = URL(string: "\(apiBaseURL)/mountains/\(mountainId)/conditions") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WidgetConditions.self, from: data)
    }

    private func fetchPowderScore(for mountainId: String) async throws -> WidgetPowderScore {
        guard let url = URL(string: "\(apiBaseURL)/mountains/\(mountainId)/powder-score") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WidgetPowderScore.self, from: data)
    }

    private func fetchForecast(for mountainId: String) async throws -> WidgetForecastResponse {
        guard let url = URL(string: "\(apiBaseURL)/mountains/\(mountainId)/forecast") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WidgetForecastResponse.self, from: data)
    }
}

// MARK: - Widget Data Models

struct WidgetConditions: Codable {
    let snowDepth: Int
    let snowfall24h: Int

    enum CodingKeys: String, CodingKey {
        case snowDepth = "snow_depth"
        case snowfall24h = "snowfall_24h"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        snowDepth = (try? container.decode(Int.self, forKey: .snowDepth)) ?? 0
        snowfall24h = (try? container.decode(Int.self, forKey: .snowfall24h)) ?? 0
    }
}

struct WidgetPowderScore: Codable {
    let score: Int
    let label: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = (try? container.decode(Int.self, forKey: .score)) ?? 5
        label = (try? container.decode(String.self, forKey: .label)) ?? "Good"
    }

    enum CodingKeys: String, CodingKey {
        case score, label
    }
}

struct WidgetForecastResponse: Codable {
    let forecast: [WidgetForecastDayData]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        forecast = (try? container.decode([WidgetForecastDayData].self, forKey: .forecast)) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case forecast
    }
}

struct WidgetForecastDayData: Codable {
    let dayOfWeek: String
    let snowfall: Int
    let iconEmoji: String

    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case snowfall
        case iconEmoji = "icon_emoji"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dayOfWeek = (try? container.decode(String.self, forKey: .dayOfWeek)) ?? "?"
        snowfall = (try? container.decode(Int.self, forKey: .snowfall)) ?? 0
        iconEmoji = (try? container.decode(String.self, forKey: .iconEmoji)) ?? "❄️"
    }
}

struct PowderTrackerWidgetEntryView: View {
    var entry: ConfigurableProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct PowderTrackerWidget: Widget {
    let kind: String = "PowderTrackerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectMountainIntent.self,
            provider: ConfigurableProvider()
        ) { entry in
            PowderTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Powder Tracker")
        .description("Current snow conditions for your favorite mountain")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    PowderTrackerWidget()
} timeline: {
    PowderEntry(
        date: Date(),
        mountainId: "crystal-mountain",
        mountainName: "Crystal Mountain",
        snowDepth: 142,
        snowfall24h: 8,
        powderScore: 8,
        scoreLabel: "Great",
        forecast: [
            WidgetForecastDay(dayOfWeek: "Sat", snowfall: 6, icon: "❄️"),
            WidgetForecastDay(dayOfWeek: "Sun", snowfall: 10, icon: "❄️"),
            WidgetForecastDay(dayOfWeek: "Mon", snowfall: 4, icon: "❄️")
        ]
    )
}

#Preview(as: .systemMedium) {
    PowderTrackerWidget()
} timeline: {
    PowderEntry(
        date: Date(),
        mountainId: "crystal-mountain",
        mountainName: "Crystal Mountain",
        snowDepth: 142,
        snowfall24h: 8,
        powderScore: 8,
        scoreLabel: "Great",
        forecast: [
            WidgetForecastDay(dayOfWeek: "Sat", snowfall: 6, icon: "❄️"),
            WidgetForecastDay(dayOfWeek: "Sun", snowfall: 10, icon: "❄️"),
            WidgetForecastDay(dayOfWeek: "Mon", snowfall: 4, icon: "❄️")
        ]
    )
}
