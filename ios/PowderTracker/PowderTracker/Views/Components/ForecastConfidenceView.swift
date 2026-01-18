import SwiftUI

/// Displays forecast confidence level with progress bar and model agreement
struct ForecastConfidenceView: View {
    let confidence: Double  // 0.0 - 1.0
    let modelAgreement: ModelAgreement?
    var showDetails: Bool = true

    private var confidenceLevel: ConfidenceLevel {
        ConfidenceLevel(from: confidence)
    }

    private var confidenceColor: Color {
        switch confidenceLevel {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Header
            HStack {
                Text("Confidence: \(confidenceLevel.rawValue)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(confidenceLevel.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(Int(confidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(confidenceColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * confidence, height: 8)
                }
            }
            .frame(height: 8)

            // Model agreement details
            if showDetails, let agreement = modelAgreement {
                HStack(spacing: .spacingM) {
                    if let gfs = agreement.gfs {
                        modelBadge(model: gfs)
                    }
                    if let ecmwf = agreement.ecmwf {
                        modelBadge(model: ecmwf)
                    }
                    if let nam = agreement.nam {
                        modelBadge(model: nam)
                    }
                }
                .padding(.top, .spacingXS)

                // Consensus
                if !agreement.consensus.isEmpty {
                    HStack {
                        Text("Consensus:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(agreement.consensus)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            // Low confidence warning
            if confidenceLevel == .low {
                Text("Models disagree significantly - check back tomorrow")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func modelBadge(model: ModelForecast) -> some View {
        HStack(spacing: 4) {
            Image(systemName: model.agrees ? "checkmark" : "exclamationmark")
                .font(.caption2)
                .foregroundColor(model.agrees ? .green : .orange)

            Text("\(model.name): \(Int(model.snowfallInches))\"")
                .font(.caption)
                .foregroundColor(model.agrees ? .primary : .orange)
        }
    }
}

/// Compact inline confidence indicator
struct CompactForecastConfidence: View {
    let confidence: Double

    private var confidenceLevel: ConfidenceLevel {
        ConfidenceLevel(from: confidence)
    }

    private var color: Color {
        switch confidenceLevel {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(Int(confidence * 100))% confidence")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Mini confidence badge (just the percentage)
struct ConfidenceBadge: View {
    let confidence: Double

    private var color: Color {
        let level = ConfidenceLevel(from: confidence)
        switch level {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        }
    }

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ForecastConfidenceView(
                confidence: 0.85,
                modelAgreement: ModelAgreement(
                    gfs: ModelForecast(name: "GFS", snowfallInches: 10, agrees: true),
                    ecmwf: ModelForecast(name: "ECMWF", snowfallInches: 12, agrees: true),
                    nam: ModelForecast(name: "NAM", snowfallInches: 11, agrees: true),
                    spread: "Low",
                    consensus: "11\" (±1\")"
                )
            )

            ForecastConfidenceView(
                confidence: 0.65,
                modelAgreement: ModelAgreement(
                    gfs: ModelForecast(name: "GFS", snowfallInches: 10, agrees: true),
                    ecmwf: ModelForecast(name: "ECMWF", snowfallInches: 14, agrees: false),
                    nam: ModelForecast(name: "NAM", snowfallInches: 11, agrees: true),
                    spread: "Medium",
                    consensus: "12\" (±2\")"
                )
            )

            ForecastConfidenceView(
                confidence: 0.35,
                modelAgreement: ModelAgreement(
                    gfs: ModelForecast(name: "GFS", snowfallInches: 6, agrees: false),
                    ecmwf: ModelForecast(name: "ECMWF", snowfallInches: 18, agrees: false),
                    nam: ModelForecast(name: "NAM", snowfallInches: 10, agrees: false),
                    spread: "High",
                    consensus: "11\" (±6\")"
                )
            )

            HStack(spacing: 20) {
                CompactForecastConfidence(confidence: 0.85)
                CompactForecastConfidence(confidence: 0.65)
                CompactForecastConfidence(confidence: 0.35)
            }

            HStack(spacing: 10) {
                ConfidenceBadge(confidence: 0.85)
                ConfidenceBadge(confidence: 0.65)
                ConfidenceBadge(confidence: 0.35)
            }
        }
        .padding()
    }
}
