import Foundation

// MARK: - Forecast Narrative

/// AI-generated or forecaster-written narrative for a region or mountain
struct ForecastNarrative: Codable, Identifiable {
    let id: String
    let regionId: String?           // nil = specific mountain
    let mountainId: String?         // nil = regional
    let title: String               // "Today's Outlook" or "Baker Outlook"
    let date: Date
    let body: String                // The narrative text
    let confidence: Double          // 0.0 - 1.0
    let confidenceLabel: String     // "HIGH", "MEDIUM", "LOW"
    let modelAgreement: ModelAgreement?
    let whatWouldChange: String?    // Optional "what would change" text
    let author: String?             // "AI Generated" or forecaster name
    let lastUpdated: Date
    let source: String
}

// MARK: - Model Agreement

struct ModelAgreement: Codable {
    let gfs: ModelForecast?
    let ecmwf: ModelForecast?
    let nam: ModelForecast?
    let spread: String              // "Low", "Medium", "High"
    let consensus: String           // "10" (±1.5")"
}

struct ModelForecast: Codable {
    let name: String
    let snowfallInches: Double
    let agrees: Bool
}

// MARK: - Confidence Level

enum ConfidenceLevel: String, CaseIterable {
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"

    init(from value: Double) {
        if value >= 0.8 {
            self = .high
        } else if value >= 0.5 {
            self = .medium
        } else {
            self = .low
        }
    }

    var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "yellow"
        case .low: return "red"
        }
    }

    var description: String {
        switch self {
        case .high: return "Models agree"
        case .medium: return "Some spread"
        case .low: return "High spread"
        }
    }
}

// MARK: - Mock Data

extension ForecastNarrative {
    static let mock = ForecastNarrative(
        id: "narrative-1",
        regionId: "washington",
        mountainId: nil,
        title: "Pacific Northwest Outlook",
        date: Date(),
        body: "A strong atmospheric river will bring significant snowfall to the Cascades over the next 48 hours. Expect 12-18 inches at pass level with higher amounts above 5000 feet. Winds will be gusty from the southwest, potentially impacting lift operations.",
        confidence: 0.85,
        confidenceLabel: "HIGH",
        modelAgreement: ModelAgreement(
            gfs: ModelForecast(name: "GFS", snowfallInches: 14, agrees: true),
            ecmwf: ModelForecast(name: "ECMWF", snowfallInches: 16, agrees: true),
            nam: ModelForecast(name: "NAM", snowfallInches: 12, agrees: true),
            spread: "Low",
            consensus: "14\" (±2\")"
        ),
        whatWouldChange: "If the storm tracks further north, southern Washington resorts may see reduced totals.",
        author: "AI Generated",
        lastUpdated: Date(),
        source: "NWS Seattle"
    )
}
