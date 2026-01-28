import WidgetKit
import AppIntents

/// App intent for selecting a mountain in widget configuration
struct SelectMountainIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Mountain"
    static let description = IntentDescription("Choose which mountain to display in the widget")

    @Parameter(title: "Mountain", default: .crystalMountain)
    var mountain: WidgetMountainOption
}

/// Available mountains for widget selection
enum WidgetMountainOption: String, AppEnum, CaseIterable {
    // Washington
    case crystalMountain = "crystal-mountain"
    case stevenPass = "stevens-pass"
    case snoqualmie = "snoqualmie"
    case mtBaker = "mt-baker"

    // Oregon
    case mtHood = "mt-hood-meadows"
    case mtBachelor = "mt-bachelor"

    // Idaho
    case schweitzer = "schweitzer"
    case sunValley = "sun-valley"

    // Canada
    case whistler = "whistler-blackcomb"
    case revelstoke = "revelstoke"
    case cypressMountain = "cypress-mountain"
    case sunPeaks = "sun-peaks"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Mountain"

    static var caseDisplayRepresentations: [WidgetMountainOption: DisplayRepresentation] {
        [
            // Washington
            .crystalMountain: "Crystal Mountain",
            .stevenPass: "Stevens Pass",
            .snoqualmie: "Snoqualmie",
            .mtBaker: "Mt. Baker",

            // Oregon
            .mtHood: "Mt. Hood Meadows",
            .mtBachelor: "Mt. Bachelor",

            // Idaho
            .schweitzer: "Schweitzer",
            .sunValley: "Sun Valley",

            // Canada
            .whistler: "Whistler Blackcomb",
            .revelstoke: "Revelstoke",
            .cypressMountain: "Cypress Mountain",
            .sunPeaks: "Sun Peaks"
        ]
    }

    var displayName: String {
        switch self {
        case .crystalMountain: return "Crystal Mountain"
        case .stevenPass: return "Stevens Pass"
        case .snoqualmie: return "Snoqualmie"
        case .mtBaker: return "Mt. Baker"
        case .mtHood: return "Mt. Hood Meadows"
        case .mtBachelor: return "Mt. Bachelor"
        case .schweitzer: return "Schweitzer"
        case .sunValley: return "Sun Valley"
        case .whistler: return "Whistler Blackcomb"
        case .revelstoke: return "Revelstoke"
        case .cypressMountain: return "Cypress Mountain"
        case .sunPeaks: return "Sun Peaks"
        }
    }

    var apiId: String {
        rawValue
    }
}
