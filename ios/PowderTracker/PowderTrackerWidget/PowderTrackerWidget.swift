import WidgetKit
import SwiftUI

private let apiBaseURL = "https://shredders-bay.vercel.app/api"

struct PowderEntry: TimelineEntry {
    let date: Date
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

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PowderEntry {
        PowderEntry(
            date: Date(),
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

    func getSnapshot(in context: Context, completion: @escaping @Sendable (PowderEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<PowderEntry>) -> Void) {
        // Capture context before async boundary to avoid sending issues
        let placeholderEntry = placeholder(in: context)

        Task { @MainActor in
            do {
                // Fetch real data from API
                let conditions = try await fetchConditions()
                let powderScore = try await fetchPowderScore()
                let forecastResponse = try await fetchForecast()

                let forecast = forecastResponse.forecast.prefix(3).map { day in
                    WidgetForecastDay(dayOfWeek: day.dayOfWeek, snowfall: day.snowfall, icon: day.iconEmoji)
                }

                let entry = PowderEntry(
                    date: Date(),
                    snowDepth: conditions.snowDepth,
                    snowfall24h: conditions.snowfall24h,
                    powderScore: powderScore.score,
                    scoreLabel: powderScore.label,
                    forecast: Array(forecast)
                )

                // Refresh every 30 minutes
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)

            } catch {
                // Use placeholder on error (captured before async boundary)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
                let timeline = Timeline(entries: [placeholderEntry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }

    // MARK: - API Calls

    private func fetchConditions() async throws -> Conditions {
        guard let url = URL(string: "\(apiBaseURL)/conditions") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Conditions.self, from: data)
    }

    private func fetchPowderScore() async throws -> PowderScore {
        guard let url = URL(string: "\(apiBaseURL)/powder-score") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PowderScore.self, from: data)
    }

    private func fetchForecast() async throws -> ForecastResponse {
        guard let url = URL(string: "\(apiBaseURL)/forecast") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ForecastResponse.self, from: data)
    }
}

struct PowderTrackerWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct PowderTrackerWidget: Widget {
    let kind: String = "PowderTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PowderTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Powder Tracker")
        .description("Current snow conditions at Mt. Baker")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    PowderTrackerWidget()
} timeline: {
    PowderEntry(
        date: Date(),
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
