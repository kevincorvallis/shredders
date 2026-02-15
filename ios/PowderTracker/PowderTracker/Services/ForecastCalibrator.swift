import Foundation

/// Learns per-mountain forecast bias by comparing past NOAA predictions to actual SNOTEL readings.
/// All computation is on-device using simple linear regression — no network calls, no API keys.
///
/// Usage:
///   1. Feed historical pairs via `recordObservation(mountainId:forecastSnowfall:actualSnowfall:)`.
///   2. Call `calibrate(mountainId:forecastSnowfall:)` to get a corrected estimate.
///   3. Observations persist across app sessions via UserDefaults.
@MainActor
@Observable
class ForecastCalibrator {
    static let shared = ForecastCalibrator()

    /// Per-mountain calibration model. Key = mountainId.
    private(set) var models: [String: CalibrationModel] = [:]

    private let storageKey = "ForecastCalibrator.observations"
    private let maxObservationsPerMountain = 90

    private init() {
        loadFromStorage()
    }

    // MARK: - Public API

    /// Record a forecast vs actual observation for a mountain.
    func recordObservation(mountainId: String, forecastSnowfall: Double, actualSnowfall: Double) {
        var model = models[mountainId] ?? CalibrationModel()
        model.observations.append(
            CalibrationObservation(forecast: forecastSnowfall, actual: actualSnowfall)
        )

        // Trim to keep bounded storage
        if model.observations.count > maxObservationsPerMountain {
            model.observations.removeFirst(model.observations.count - maxObservationsPerMountain)
        }

        model.recalculate()
        models[mountainId] = model
        saveToStorage()
    }

    /// Ingest a batch of history + forecast overlap. Compares dates where we have both
    /// a historical actual reading and a forecast prediction for the same day.
    func ingestHistoryVsForecast(
        mountainId: String,
        history: [HistoryDataPoint],
        forecast: [ForecastDay]
    ) {
        let historyByDate = Dictionary(uniqueKeysWithValues: history.map { ($0.date, $0) })

        var added = 0
        for day in forecast {
            guard let actual = historyByDate[day.date] else { continue }
            recordObservation(
                mountainId: mountainId,
                forecastSnowfall: day.snowfall,
                actualSnowfall: actual.snowfall
            )
            added += 1
        }

        #if DEBUG
        if added > 0 {
            print("ForecastCalibrator: ingested \(added) observations for \(mountainId)")
        }
        #endif
    }

    /// Return a corrected snowfall estimate for a given mountain and raw forecast value.
    /// Returns nil if there aren't enough observations to calibrate.
    func calibrate(mountainId: String, forecastSnowfall: Int) -> CalibratedForecast? {
        guard let model = models[mountainId],
              model.observations.count >= 5 else {
            return nil
        }

        let raw = Double(forecastSnowfall)
        let corrected = max(0, model.slope * raw + model.intercept)
        let rounded = Int(corrected.rounded())

        return CalibratedForecast(
            rawSnowfall: forecastSnowfall,
            correctedSnowfall: rounded,
            biasDirection: model.biasDirection,
            confidence: model.confidence,
            observationCount: model.observations.count
        )
    }

    /// Get a human-readable bias summary for a mountain.
    func biasSummary(for mountainId: String) -> String? {
        guard let model = models[mountainId],
              model.observations.count >= 5 else {
            return nil
        }

        switch model.biasDirection {
        case .overestimates:
            let pct = Int(abs(model.averageBias) / max(1, model.averageForecast) * 100)
            return "Forecast tends to overestimate by ~\(pct)%"
        case .underestimates:
            let pct = Int(abs(model.averageBias) / max(1, model.averageForecast) * 100)
            return "Forecast tends to underestimate by ~\(pct)%"
        case .accurate:
            return "Forecast is well-calibrated"
        }
    }

    /// Clear all data (e.g. on sign-out).
    func clearAll() {
        models.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Persistence

    private func saveToStorage() {
        let storable = models.mapValues { model in
            model.observations.map { ["f": $0.forecast, "a": $0.actual] }
        }
        UserDefaults.standard.set(storable, forKey: storageKey)
    }

    private func loadFromStorage() {
        guard let stored = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: [[String: Double]]] else {
            return
        }

        for (mountainId, pairs) in stored {
            var model = CalibrationModel()
            model.observations = pairs.compactMap { dict in
                guard let f = dict["f"], let a = dict["a"] else { return nil }
                return CalibrationObservation(forecast: f, actual: a)
            }
            model.recalculate()
            models[mountainId] = model
        }
    }
}

// MARK: - Models

struct CalibrationObservation: Equatable {
    let forecast: Double
    let actual: Double
}

struct CalibrationModel: Equatable {
    var observations: [CalibrationObservation] = []

    /// Linear regression: actual = slope * forecast + intercept
    private(set) var slope: Double = 1.0
    private(set) var intercept: Double = 0.0

    /// Average signed bias (actual - forecast). Negative = overestimates.
    private(set) var averageBias: Double = 0.0
    private(set) var averageForecast: Double = 0.0

    /// R² value — how well the model fits.
    private(set) var rSquared: Double = 0.0

    var biasDirection: BiasDirection {
        if averageBias < -0.5 { return .overestimates }
        if averageBias > 0.5 { return .underestimates }
        return .accurate
    }

    /// Confidence based on sample size and fit quality.
    var confidence: CalibrationConfidence {
        if observations.count < 10 { return .low }
        if observations.count < 30 && rSquared < 0.5 { return .low }
        if rSquared > 0.7 { return .high }
        return .medium
    }

    /// Recalculate the linear regression from observations.
    mutating func recalculate() {
        let n = Double(observations.count)
        guard n >= 2 else {
            slope = 1.0
            intercept = 0.0
            averageBias = 0.0
            averageForecast = 0.0
            rSquared = 0.0
            return
        }

        let xs = observations.map(\.forecast)
        let ys = observations.map(\.actual)

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)

        let denominator = n * sumX2 - sumX * sumX
        if abs(denominator) < 1e-10 {
            // All forecast values are the same — can't regress
            slope = 1.0
            intercept = (sumY - sumX) / n
        } else {
            slope = (n * sumXY - sumX * sumY) / denominator
            intercept = (sumY - slope * sumX) / n
        }

        averageForecast = sumX / n
        averageBias = (sumY - sumX) / n

        // R²
        let meanY = sumY / n
        let ssTotal = ys.map { ($0 - meanY) * ($0 - meanY) }.reduce(0, +)
        let ssResidual: Double = zip(xs, ys).map { x, y in
            let predicted = slope * x + intercept
            return (y - predicted) * (y - predicted)
        }.reduce(0.0, +)

        rSquared = ssTotal > 0 ? max(0, 1.0 - ssResidual / ssTotal) : 0
    }
}

enum BiasDirection: String, Equatable {
    case overestimates
    case underestimates
    case accurate
}

enum CalibrationConfidence: String, Equatable {
    case low
    case medium
    case high

    var displayName: String { rawValue.capitalized }
}

struct CalibratedForecast: Equatable {
    let rawSnowfall: Int
    let correctedSnowfall: Int
    let biasDirection: BiasDirection
    let confidence: CalibrationConfidence
    let observationCount: Int

    /// The difference between corrected and raw.
    var adjustment: Int { correctedSnowfall - rawSnowfall }

    /// Human-readable adjustment string (e.g. "+2"" or "-1"").
    var adjustmentLabel: String {
        if adjustment > 0 { return "+\(adjustment)\"" }
        if adjustment < 0 { return "\(adjustment)\"" }
        return "±0\""
    }
}
