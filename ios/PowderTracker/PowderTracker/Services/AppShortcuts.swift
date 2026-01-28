import AppIntents
import SwiftUI

// MARK: - Check Conditions Intent

/// Intent for checking mountain conditions via Siri
struct CheckConditionsIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Mountain Conditions"
    static let description = IntentDescription("Get current snow conditions for a ski resort")

    @Parameter(title: "Mountain")
    var mountain: AppMountainEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Check conditions at \(\.$mountain)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let mountainToCheck = mountain ?? AppMountainEntity.defaultMountain

        // Fetch conditions from API
        let conditions = try await fetchConditions(for: mountainToCheck.id)

        let dialog = IntentDialog("""
            \(mountainToCheck.name) has \(conditions.snowfall24h) inches of fresh snow in the last 24 hours. \
            Base depth is \(conditions.snowDepth) inches.
            """)

        return .result(dialog: dialog) {
            ConditionsSnippetView(
                mountainName: mountainToCheck.name,
                snowfall24h: conditions.snowfall24h,
                snowDepth: conditions.snowDepth
            )
        }
    }

    private func fetchConditions(for mountainId: String) async throws -> SimpleConditions {
        guard let url = URL(string: "https://shredders-bay.vercel.app/api/mountains/\(mountainId)/conditions") else {
            throw IntentError.invalidMountain
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        struct APIResponse: Codable {
            let snowfall24h: Int?
            let snowDepth: Int?

            enum CodingKeys: String, CodingKey {
                case snowfall24h = "snowfall_24h"
                case snowDepth = "snow_depth"
            }
        }

        let response = try JSONDecoder().decode(APIResponse.self, from: data)
        return SimpleConditions(
            snowfall24h: response.snowfall24h ?? 0,
            snowDepth: response.snowDepth ?? 0
        )
    }
}

// MARK: - Check Powder Score Intent

/// Intent for checking powder score via Siri
struct CheckPowderScoreIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Powder Score"
    static let description = IntentDescription("Get the current powder score for a ski resort")

    @Parameter(title: "Mountain")
    var mountain: AppMountainEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Check powder score at \(\.$mountain)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let mountainToCheck = mountain ?? AppMountainEntity.defaultMountain

        // Fetch powder score from API
        let score = try await fetchPowderScore(for: mountainToCheck.id)

        let verdict = scoreVerdict(score)

        return .result(dialog: IntentDialog("""
            \(mountainToCheck.name) has a powder score of \(score) out of 10. \
            \(verdict)
            """))
    }

    private func fetchPowderScore(for mountainId: String) async throws -> Int {
        guard let url = URL(string: "https://shredders-bay.vercel.app/api/mountains/\(mountainId)/powder-score") else {
            throw IntentError.invalidMountain
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        struct APIResponse: Codable {
            let score: Double?
        }

        let response = try JSONDecoder().decode(APIResponse.self, from: data)
        return Int(response.score ?? 5)
    }

    private func scoreVerdict(_ score: Int) -> String {
        switch score {
        case 9...10: return "It's an epic powder day!"
        case 7...8: return "Great conditions for skiing today."
        case 5...6: return "Decent conditions."
        case 3...4: return "Conditions are fair."
        default: return "Consider waiting for better conditions."
        }
    }
}

// MARK: - Open Mountain Intent

/// Intent for opening a mountain's details in the app
struct OpenMountainIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Mountain"
    static let description = IntentDescription("Open a ski resort in PowderTracker")
    static let openAppWhenRun = true

    @Parameter(title: "Mountain")
    var mountain: AppMountainEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$mountain) in PowderTracker")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // The app will handle the deep link
        return .result()
    }
}

// MARK: - Mountain Entity

/// Entity representing a mountain for App Intents
struct AppMountainEntity: AppEntity {
    let id: String
    let name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Mountain"
    static let defaultQuery = AppMountainQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultMountain: AppMountainEntity {
        AppMountainEntity(id: "crystal-mountain", name: "Crystal Mountain")
    }
}

/// Query for finding mountains
struct AppMountainQuery: EntityQuery {
    func entities(for identifiers: [AppMountainEntity.ID]) async throws -> [AppMountainEntity] {
        allMountains.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [AppMountainEntity] {
        allMountains
    }

    func defaultResult() async -> AppMountainEntity? {
        AppMountainEntity.defaultMountain
    }

    private var allMountains: [AppMountainEntity] {
        [
            // Washington
            AppMountainEntity(id: "crystal-mountain", name: "Crystal Mountain"),
            AppMountainEntity(id: "stevens-pass", name: "Stevens Pass"),
            AppMountainEntity(id: "snoqualmie", name: "Snoqualmie"),
            AppMountainEntity(id: "mt-baker", name: "Mt. Baker"),

            // Oregon
            AppMountainEntity(id: "mt-hood-meadows", name: "Mt. Hood Meadows"),
            AppMountainEntity(id: "mt-bachelor", name: "Mt. Bachelor"),

            // Idaho
            AppMountainEntity(id: "schweitzer", name: "Schweitzer"),
            AppMountainEntity(id: "sun-valley", name: "Sun Valley"),

            // Canada
            AppMountainEntity(id: "whistler-blackcomb", name: "Whistler Blackcomb"),
            AppMountainEntity(id: "revelstoke", name: "Revelstoke"),
            AppMountainEntity(id: "cypress-mountain", name: "Cypress Mountain"),
            AppMountainEntity(id: "sun-peaks", name: "Sun Peaks")
        ]
    }
}

// MARK: - App Shortcuts

/// Shortcuts provider for the app
struct PowderTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckConditionsIntent(),
            phrases: [
                "Check conditions at \(\.$mountain) in \(.applicationName)",
                "What are the conditions at \(\.$mountain) in \(.applicationName)",
                "Snow report for \(\.$mountain) in \(.applicationName)",
                "How much snow at \(\.$mountain) with \(.applicationName)"
            ],
            shortTitle: "Check Conditions",
            systemImageName: "snowflake"
        )

        AppShortcut(
            intent: CheckPowderScoreIntent(),
            phrases: [
                "Check powder score at \(\.$mountain) in \(.applicationName)",
                "What's the powder score at \(\.$mountain) in \(.applicationName)",
                "Is it a powder day at \(\.$mountain) in \(.applicationName)"
            ],
            shortTitle: "Powder Score",
            systemImageName: "star.fill"
        )

        AppShortcut(
            intent: OpenMountainIntent(),
            phrases: [
                "Open \(\.$mountain) in \(.applicationName)",
                "Show me \(\.$mountain) in \(.applicationName)"
            ],
            shortTitle: "Open Mountain",
            systemImageName: "mountain.2.fill"
        )
    }
}

// MARK: - Helper Types

struct SimpleConditions {
    let snowfall24h: Int
    let snowDepth: Int
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidMountain
    case networkError

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidMountain:
            return "Could not find that mountain."
        case .networkError:
            return "Unable to fetch conditions. Please try again."
        }
    }
}

// MARK: - Snippet View

/// View shown in Siri results
struct ConditionsSnippetView: View {
    let mountainName: String
    let snowfall24h: Int
    let snowDepth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mountainName)
                .font(.headline)

            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "snowflake")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("\(snowfall24h)\"")
                        .font(.title3.bold())
                    Text("24hr")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Image(systemName: "mountain.2.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("\(snowDepth)\"")
                        .font(.title3.bold())
                    Text("Base")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}
