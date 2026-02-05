import Foundation
import NaturalLanguage

/// Analyzes sentiment of trip reports and check-in text using Apple's NaturalLanguage framework.
/// All processing is on-device — no network calls, no API keys.
@MainActor
@Observable
class SentimentAnalyzer {
    static let shared = SentimentAnalyzer()

    /// In-memory cache: checkIn.id → SentimentResult
    private var cache: [String: SentimentResult] = [:]

    private init() {}

    // MARK: - Public API

    /// Analyze sentiment of a single trip report.
    /// Returns nil if the text is too short to score meaningfully.
    nonisolated func analyze(_ text: String) -> SentimentResult? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 5 else { return nil }

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = trimmed

        let (tag, _) = tagger.tag(
            at: trimmed.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )

        guard let tag, let score = Double(tag.rawValue) else {
            return nil
        }

        return SentimentResult(score: score)
    }

    /// Analyze a check-in's trip report, returning a cached result when available.
    func analyzeCheckIn(_ checkIn: CheckIn) -> SentimentResult? {
        if let cached = cache[checkIn.id] {
            return cached
        }

        guard let tripReport = checkIn.tripReport else { return nil }

        let result = analyze(tripReport)
        if let result {
            cache[checkIn.id] = result
        }
        return result
    }

    /// Compute an aggregate "community vibe" score from multiple check-ins.
    /// Returns nil if there are no analyzable trip reports.
    func communityVibe(for checkIns: [CheckIn]) -> CommunityVibe? {
        let results = checkIns.compactMap { analyzeCheckIn($0) }
        guard !results.isEmpty else { return nil }

        let avgScore = results.map(\.score).reduce(0, +) / Double(results.count)
        let positiveCount = results.filter { $0.label == .positive }.count
        let negativeCount = results.filter { $0.label == .negative }.count

        return CommunityVibe(
            averageScore: avgScore,
            totalAnalyzed: results.count,
            positiveCount: positiveCount,
            negativeCount: negativeCount,
            neutralCount: results.count - positiveCount - negativeCount
        )
    }

    /// Clear the cache (e.g., on sign-out or memory warning).
    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Models

struct SentimentResult: Equatable {
    /// Raw score from NLTagger: -1.0 (very negative) to +1.0 (very positive)
    let score: Double

    var label: SentimentLabel {
        if score > 0.1 { return .positive }
        if score < -0.1 { return .negative }
        return .neutral
    }
}

enum SentimentLabel: String {
    case positive
    case neutral
    case negative

    var icon: String {
        switch self {
        case .positive: return "face.smiling"
        case .neutral: return "face.dashed"
        case .negative: return "cloud.rain"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

struct CommunityVibe: Equatable {
    let averageScore: Double
    let totalAnalyzed: Int
    let positiveCount: Int
    let negativeCount: Int
    let neutralCount: Int

    var label: SentimentLabel {
        if averageScore > 0.1 { return .positive }
        if averageScore < -0.1 { return .negative }
        return .neutral
    }

    var summary: String {
        let pct = totalAnalyzed > 0
            ? Int(Double(positiveCount) / Double(totalAnalyzed) * 100)
            : 0
        return "\(pct)% positive from \(totalAnalyzed) reports"
    }
}
