import UIKit
import Vision
import CoreImage

/// Classifies ski-slope photos to suggest snow quality using Apple Vision + color analysis.
///
/// Uses two complementary signals:
/// 1. **Vision scene classification** (`VNClassifyImageRequest`) for broad scene labels
///    (snow, ice, rain, etc.) mapped to `SnowQuality` via a weighted lookup table.
/// 2. **Color histogram analysis** — the ratio of whites, blues, and grays helps
///    distinguish powder (bright white) from icy (blue-gray) or slushy (dark/wet).
///
/// All processing runs on-device with no network calls.
///
/// Usage:
/// ```swift
/// let result = await SnowConditionClassifier.shared.classify(someUIImage)
/// if let result, result.confidence > 0.5 {
///     print("Suggested: \(result.quality.displayName) (\(result.confidence))")
/// }
/// ```
final class SnowConditionClassifier: Sendable {
    static let shared = SnowConditionClassifier()

    /// Minimum confidence to return a result.
    private let minimumConfidence: Double = 0.5

    private init() {}

    // MARK: - Public API

    /// Classify a photo to suggest snow quality. Runs on a background thread.
    /// Returns `nil` if confidence is below threshold or the image can't be analyzed.
    nonisolated func classify(_ image: UIImage) async -> SnowClassification? {
        guard let cgImage = image.cgImage else { return nil }

        // Run both analyses concurrently
        async let visionScores = visionClassify(cgImage)
        async let colorScores = colorHistogramClassify(cgImage)

        let v = await visionScores
        let c = await colorScores

        // Blend: 60% vision, 40% color histogram
        let blended = blendScores(vision: v, color: c, visionWeight: 0.6)

        // Pick the top-scoring quality
        guard let best = blended.max(by: { $0.value < $1.value }) else { return nil }

        let confidence = best.value
        guard confidence >= minimumConfidence else { return nil }

        return SnowClassification(
            quality: best.key,
            confidence: confidence,
            allScores: blended
        )
    }

    // MARK: - Vision Classification

    /// Use VNClassifyImageRequest to get scene-level labels, then map them to SnowQuality scores.
    private nonisolated func visionClassify(_ cgImage: CGImage) async -> [SnowQuality: Double] {
        await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: Self.uniformScores())
                    return
                }

                let scores = Self.mapVisionToSnowQuality(observations)
                continuation.resume(returning: scores)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: Self.uniformScores())
            }
        }
    }

    /// Map Vision classification labels to SnowQuality scores.
    ///
    /// Vision returns labels like "snow", "ice", "rain", "water", "outdoor", "sky", etc.
    /// We use a weighted lookup to accumulate evidence for each SnowQuality.
    private static func mapVisionToSnowQuality(
        _ observations: [VNClassificationObservation]
    ) -> [SnowQuality: Double] {
        // Lookup table: Vision label → [(SnowQuality, weight)]
        let labelMap: [String: [(SnowQuality, Double)]] = [
            // Strong snow signals
            "snow":         [(.powder, 0.5), (.packedPowder, 0.3), (.groomed, 0.1)],
            "snowfall":     [(.powder, 0.7), (.packedPowder, 0.2)],
            "blizzard":     [(.powder, 0.8), (.variable, 0.1)],
            "frost":        [(.powder, 0.3), (.hardPack, 0.3), (.icy, 0.2)],
            "winter":       [(.powder, 0.3), (.packedPowder, 0.3), (.groomed, 0.2)],

            // Ice/hard signals
            "ice":          [(.icy, 0.7), (.hardPack, 0.2)],
            "glacier":      [(.icy, 0.5), (.hardPack, 0.3)],
            "frozen":       [(.icy, 0.5), (.hardPack, 0.3)],

            // Wet/warm signals
            "rain":         [(.slushy, 0.6), (.variable, 0.2)],
            "water":        [(.slushy, 0.4), (.variable, 0.2)],
            "sleet":        [(.slushy, 0.5), (.icy, 0.2), (.variable, 0.2)],
            "puddle":       [(.slushy, 0.7)],

            // Mixed signals
            "cloud":        [(.variable, 0.3), (.groomed, 0.2)],
            "fog":          [(.variable, 0.3), (.groomed, 0.1)],
            "overcast":     [(.variable, 0.3), (.groomed, 0.2)],
            "sun":          [(.groomed, 0.3), (.slushy, 0.2)],

            // Groomed/prepared surface signals
            "track":        [(.groomed, 0.5), (.packedPowder, 0.3)],
            "trail":        [(.groomed, 0.4), (.packedPowder, 0.3)],
            "slope":        [(.groomed, 0.3), (.packedPowder, 0.2), (.powder, 0.2)],
            "skiing":       [(.groomed, 0.3), (.powder, 0.3), (.packedPowder, 0.2)],
            "snowboard":    [(.groomed, 0.3), (.powder, 0.3), (.packedPowder, 0.2)],

            // Outdoor/mountain context (weak signals)
            "mountain":     [(.powder, 0.15), (.groomed, 0.15), (.variable, 0.1)],
            "outdoor":      [(.variable, 0.1)],
            "landscape":    [(.variable, 0.1)],
        ]

        var scores = uniformScores(value: 0)

        for observation in observations {
            let label = observation.identifier.lowercased()
            let confidence = Double(observation.confidence)

            // Check each keyword in the label
            for (keyword, mappings) in labelMap {
                if label.contains(keyword) {
                    for (quality, weight) in mappings {
                        scores[quality, default: 0] += confidence * weight
                    }
                }
            }
        }

        // Normalize so max is 1.0
        let maxScore = scores.values.max() ?? 1.0
        if maxScore > 0 {
            for key in scores.keys {
                scores[key] = (scores[key] ?? 0) / maxScore
            }
        }

        return scores
    }

    // MARK: - Color Histogram Analysis

    /// Analyze the color distribution of the image to infer snow quality.
    ///
    /// Rationale:
    /// - **Bright white** dominant → fresh powder or well-groomed surface
    /// - **Blue-gray** dominant → icy/hard pack conditions
    /// - **Dark/wet** tones → slushy or variable
    /// - **Mixed bright** → packed powder
    private nonisolated func colorHistogramClassify(_ cgImage: CGImage) async -> [SnowQuality: Double] {
        let histogram = computeHistogram(cgImage)
        return mapHistogramToSnowQuality(histogram)
    }

    /// Pixel color categories for histogram analysis.
    struct ColorHistogram: Equatable {
        /// Fraction of pixels that are bright white (high R, G, B, low saturation)
        var brightWhiteRatio: Double = 0
        /// Fraction that are blue-gray (cool tones, medium brightness)
        var blueGrayRatio: Double = 0
        /// Fraction that are dark/wet (low brightness)
        var darkWetRatio: Double = 0
        /// Fraction that are bright non-white (sunny, colorful)
        var brightColorRatio: Double = 0
        /// Average brightness (0-1)
        var averageBrightness: Double = 0
    }

    /// Compute a simplified color histogram by sampling pixels.
    nonisolated func computeHistogram(_ cgImage: CGImage) -> ColorHistogram {
        let width = cgImage.width
        let height = cgImage.height

        guard width > 0, height > 0,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return ColorHistogram()
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        // Sample every Nth pixel for performance (target ~10K samples)
        let totalPixels = width * height
        let step = max(1, Int(sqrt(Double(totalPixels) / 10000.0)))

        var brightWhiteCount = 0
        var blueGrayCount = 0
        var darkWetCount = 0
        var brightColorCount = 0
        var totalBrightness: Double = 0
        var sampleCount = 0

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                guard offset + 2 < CFDataGetLength(data) else { continue }

                let r = Double(bytes[offset]) / 255.0
                let g = Double(bytes[offset + 1]) / 255.0
                let b = Double(bytes[offset + 2]) / 255.0

                let brightness = (r + g + b) / 3.0
                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let saturation = maxC > 0 ? (maxC - minC) / maxC : 0

                totalBrightness += brightness
                sampleCount += 1

                if brightness > 0.75 && saturation < 0.15 {
                    // Bright, low saturation → snow/white
                    brightWhiteCount += 1
                } else if brightness > 0.3 && brightness < 0.7 && b > r && saturation < 0.3 {
                    // Medium brightness, cool tones → blue-gray (icy)
                    blueGrayCount += 1
                } else if brightness < 0.3 {
                    // Dark → wet/slushy
                    darkWetCount += 1
                } else if brightness > 0.5 && saturation > 0.2 {
                    // Bright with color → sunny/variable
                    brightColorCount += 1
                }
            }
        }

        guard sampleCount > 0 else { return ColorHistogram() }

        let n = Double(sampleCount)
        return ColorHistogram(
            brightWhiteRatio: Double(brightWhiteCount) / n,
            blueGrayRatio: Double(blueGrayCount) / n,
            darkWetRatio: Double(darkWetCount) / n,
            brightColorRatio: Double(brightColorCount) / n,
            averageBrightness: totalBrightness / n
        )
    }

    /// Map histogram ratios to SnowQuality scores.
    nonisolated func mapHistogramToSnowQuality(_ histogram: ColorHistogram) -> [SnowQuality: Double] {
        var scores: [SnowQuality: Double] = [:]

        // Bright white → powder or groomed
        scores[.powder] = histogram.brightWhiteRatio * 0.8 +
                          histogram.averageBrightness * 0.2
        scores[.groomed] = histogram.brightWhiteRatio * 0.5 +
                           (1.0 - histogram.blueGrayRatio) * 0.2
        scores[.packedPowder] = histogram.brightWhiteRatio * 0.4 +
                                histogram.averageBrightness * 0.3

        // Blue-gray → icy / hard pack
        scores[.icy] = histogram.blueGrayRatio * 0.8 +
                        (1.0 - histogram.brightWhiteRatio) * 0.15
        scores[.hardPack] = histogram.blueGrayRatio * 0.5 +
                            histogram.averageBrightness * 0.2

        // Dark/wet → slushy
        scores[.slushy] = histogram.darkWetRatio * 0.7 +
                          (1.0 - histogram.averageBrightness) * 0.2

        // Mixed signals → variable
        scores[.variable] = histogram.brightColorRatio * 0.4 +
                            (1.0 - histogram.brightWhiteRatio) * 0.15 +
                            (1.0 - histogram.blueGrayRatio) * 0.1

        // Normalize so max is 1.0
        let maxScore = scores.values.max() ?? 1.0
        if maxScore > 0 {
            for key in scores.keys {
                scores[key] = (scores[key] ?? 0) / maxScore
            }
        }

        return scores
    }

    // MARK: - Score Blending

    /// Blend vision and color scores with the given weight.
    private nonisolated func blendScores(
        vision: [SnowQuality: Double],
        color: [SnowQuality: Double],
        visionWeight: Double
    ) -> [SnowQuality: Double] {
        let colorWeight = 1.0 - visionWeight
        var blended: [SnowQuality: Double] = [:]

        for quality in SnowQuality.allCases {
            let v = vision[quality] ?? 0
            let c = color[quality] ?? 0
            blended[quality] = v * visionWeight + c * colorWeight
        }

        return blended
    }

    // MARK: - Helpers

    private static func uniformScores(value: Double = 1.0 / Double(SnowQuality.allCases.count)) -> [SnowQuality: Double] {
        Dictionary(uniqueKeysWithValues: SnowQuality.allCases.map { ($0, value) })
    }
}

// MARK: - Models

struct SnowClassification: Equatable {
    /// The most likely snow quality.
    let quality: SnowQuality

    /// Confidence of the classification (0-1). Values below 0.5 are filtered out.
    let confidence: Double

    /// Scores for all snow quality categories.
    let allScores: [SnowQuality: Double]
}
