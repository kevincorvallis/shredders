//
//  ChartAnnotation.swift
//  PowderTracker
//
//  Protocol and types for chart annotations (story elements)
//

import SwiftUI
import Charts

// MARK: - Chart Annotation Protocol

/// Protocol for chart annotations that tell a story with data
protocol ChartAnnotation: Identifiable {
    associatedtype XValue: Plottable
    associatedtype ContentView: View

    var id: String { get }
    var xValue: XValue { get }
    var type: ChartAnnotationType { get }
    var label: String { get }

    /// The view to display for this annotation
    @ViewBuilder func annotationView() -> ContentView
}

/// Types of chart annotations
enum ChartAnnotationType {
    case powderDay       // 6"+ snowfall
    case epicPowderDay   // 12"+ snowfall
    case bestDay         // Season best/record
    case milestone       // Season milestone (50", 100", etc.)
    case stormStart      // Start of a storm event
    case stormEnd        // End of a storm event
    case custom(String)  // Custom annotation with icon name
}

// MARK: - Powder Day Annotation

/// Annotation for powder days (6"+ snowfall)
struct PowderDayAnnotation: ChartAnnotation {
    let id: String
    let date: Date
    let snowfall: Double

    var xValue: Date { date }

    var type: ChartAnnotationType {
        if snowfall >= 12 {
            return .epicPowderDay
        }
        return .powderDay
    }

    var label: String {
        if snowfall >= 12 {
            return "EPIC!"
        }
        return "Powder!"
    }

    init(date: Date, snowfall: Double) {
        self.id = "powder-\(date.timeIntervalSince1970)"
        self.date = date
        self.snowfall = snowfall
    }

    @ViewBuilder
    func annotationView() -> some View {
        VStack(spacing: 2) {
            if snowfall >= 12 {
                // Epic powder day badge
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
            }
            Text("\(Int(snowfall))\"")
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(snowfall >= 12 ? Color.cyan : Color.blue)
        )
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Best Day Annotation

/// Annotation for the best/record day in the dataset
struct BestDayAnnotation: ChartAnnotation {
    let id: String
    let date: Date
    let value: Double
    let metric: String // "snowfall", "depth", etc.

    var xValue: Date { date }
    var type: ChartAnnotationType { .bestDay }
    var label: String { "Best \(metric.capitalized)" }

    init(date: Date, value: Double, metric: String = "snowfall") {
        self.id = "best-\(metric)-\(date.timeIntervalSince1970)"
        self.date = date
        self.value = value
        self.metric = metric
    }

    @ViewBuilder
    func annotationView() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 10))
                .foregroundStyle(.yellow)
            Text("\(Int(value))\"")
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .orange.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Milestone Annotation

/// Annotation for season milestones (e.g., 50", 100", 200" cumulative)
struct MilestoneAnnotation: ChartAnnotation {
    let id: String
    let date: Date
    let milestone: Int // The milestone value reached

    var xValue: Date { date }
    var type: ChartAnnotationType { .milestone }
    var label: String { "\(milestone)\" Total" }

    init(date: Date, milestone: Int) {
        self.id = "milestone-\(milestone)-\(date.timeIntervalSince1970)"
        self.date = date
        self.milestone = milestone
    }

    @ViewBuilder
    func annotationView() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "flag.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white)
            Text("\(milestone)\"")
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.indigo)
        )
        .shadow(color: .indigo.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Storm Event Annotation

/// Annotation for storm events
struct StormAnnotation: ChartAnnotation {
    let id: String
    let startDate: Date
    let endDate: Date
    let totalSnowfall: Int
    let stormName: String?

    var xValue: Date { startDate }
    var type: ChartAnnotationType { .stormStart }
    var label: String { stormName ?? "Storm" }

    init(startDate: Date, endDate: Date, totalSnowfall: Int, name: String? = nil) {
        self.id = "storm-\(startDate.timeIntervalSince1970)"
        self.startDate = startDate
        self.endDate = endDate
        self.totalSnowfall = totalSnowfall
        self.stormName = name
    }

    @ViewBuilder
    func annotationView() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "cloud.snow.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 0) {
                if let name = stormName {
                    Text(name)
                        .font(.system(size: 8).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Text("\(totalSnowfall)\"")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: .purple.opacity(0.3), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Annotation Detector

/// Utility to detect annotations from data
struct AnnotationDetector {
    /// Minimum snowfall to qualify as a powder day (inches)
    static let powderDayThreshold = 6

    /// Minimum snowfall to qualify as an epic powder day (inches)
    static let epicPowderDayThreshold = 12

    /// Milestones to track (cumulative inches)
    static let milestoneLevels = [50, 100, 150, 200, 250, 300, 400, 500]

    /// Detect powder day annotations from history data
    static func detectPowderDays(from history: [HistoryDataPoint]) -> [PowderDayAnnotation] {
        history.compactMap { point in
            guard point.snowfall >= powderDayThreshold,
                  let date = point.formattedDate else {
                return nil
            }
            return PowderDayAnnotation(date: date, snowfall: point.snowfall)
        }
    }

    /// Find the best day in the dataset
    static func findBestDay(from history: [HistoryDataPoint], metric: String = "snowfall") -> BestDayAnnotation? {
        let best = history.max { $0.snowfall < $1.snowfall }
        guard let best = best,
              best.snowfall > 0,
              let date = best.formattedDate else {
            return nil
        }
        return BestDayAnnotation(date: date, value: best.snowfall, metric: metric)
    }

    /// Detect milestone annotations from cumulative data
    static func detectMilestones(from history: [HistoryDataPoint]) -> [MilestoneAnnotation] {
        var annotations: [MilestoneAnnotation] = []
        var cumulative: Double = 0
        var hitMilestones: Set<Int> = []

        for point in history.sorted(by: { ($0.formattedDate ?? .distantPast) < ($1.formattedDate ?? .distantPast) }) {
            cumulative += point.snowfall

            for milestone in milestoneLevels {
                if cumulative >= milestone && !hitMilestones.contains(milestone) {
                    hitMilestones.insert(milestone)
                    if let date = point.formattedDate {
                        annotations.append(MilestoneAnnotation(date: date, milestone: milestone))
                    }
                }
            }
        }

        return annotations
    }

    /// Detect all relevant annotations from history data
    static func detectAllAnnotations(from history: [HistoryDataPoint]) -> AnnotationSet {
        let powderDays = detectPowderDays(from: history)
        let bestDay = findBestDay(from: history)
        let milestones = detectMilestones(from: history)

        return AnnotationSet(
            powderDays: powderDays,
            bestDay: bestDay,
            milestones: milestones
        )
    }
}

// MARK: - Annotation Set

/// Collection of all annotations for a chart
struct AnnotationSet {
    let powderDays: [PowderDayAnnotation]
    let bestDay: BestDayAnnotation?
    let milestones: [MilestoneAnnotation]

    /// All powder day dates for quick lookup
    var powderDayDates: Set<Date> {
        Set(powderDays.map { Calendar.current.startOfDay(for: $0.date) })
    }

    /// Check if a date is a powder day
    func isPowderDay(_ date: Date) -> Bool {
        let dayStart = Calendar.current.startOfDay(for: date)
        return powderDayDates.contains(dayStart)
    }

    /// Check if a date is an epic powder day (12"+)
    func isEpicPowderDay(_ date: Date) -> Bool {
        let dayStart = Calendar.current.startOfDay(for: date)
        return powderDays.first {
            Calendar.current.startOfDay(for: $0.date) == dayStart && $0.snowfall >= 12
        } != nil
    }

    /// Get snowfall for a powder day
    func snowfallForPowderDay(_ date: Date) -> Int? {
        let dayStart = Calendar.current.startOfDay(for: date)
        return powderDays.first {
            Calendar.current.startOfDay(for: $0.date) == dayStart
        }?.snowfall
    }
}

// MARK: - Powder Day Badge View

/// Standalone badge for marking powder days on charts
struct PowderDayBadge: View {
    let snowfall: Int
    let isCompact: Bool

    init(snowfall: Int, compact: Bool = false) {
        self.snowfall = snowfall
        self.isCompact = compact
    }

    private var isEpic: Bool { snowfall >= 12 }

    var body: some View {
        Group {
            if isCompact {
                // Compact mode - just an icon
                Image(systemName: isEpic ? "star.fill" : "snowflake")
                    .font(.system(size: isEpic ? 10 : 8))
                    .foregroundStyle(isEpic ? Color.yellow : Color.cyan)
            } else {
                // Full badge
                HStack(spacing: 2) {
                    if isEpic {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                    }
                    Text(isEpic ? "EPIC" : "POW")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isEpic ? Color.orange : Color.cyan)
                )
            }
        }
    }
}

// MARK: - Animated Powder Day Badge

/// Animated badge for powder days with subtle pulse effect
struct AnimatedPowderDayBadge: View {
    let snowfall: Int
    let isEpic: Bool

    @State private var isPulsing = false

    init(snowfall: Int, isEpic: Bool = false) {
        self.snowfall = snowfall
        self.isEpic = isEpic || snowfall >= 12
    }

    var body: some View {
        HStack(spacing: 2) {
            if isEpic {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5), value: isPulsing)
            } else {
                Image(systemName: "snowflake")
                    .font(.system(size: 8))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(isEpic ? Color.orange : Color.cyan)
                .shadow(color: (isEpic ? Color.orange : Color.cyan).opacity(0.6), radius: isPulsing ? 4 : 2)
        )
        .scaleEffect(isPulsing && isEpic ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Preview

#Preview("Powder Day Badge") {
    VStack(spacing: 20) {
        PowderDayBadge(snowfall: 6)
        PowderDayBadge(snowfall: 8)
        PowderDayBadge(snowfall: 12)
        PowderDayBadge(snowfall: 15)

        Divider()

        HStack(spacing: 20) {
            PowderDayBadge(snowfall: 6, compact: true)
            PowderDayBadge(snowfall: 12, compact: true)
        }
    }
    .padding()
}

#Preview("Annotations") {
    VStack(spacing: 20) {
        PowderDayAnnotation(date: Date(), snowfall: 8).annotationView()
        PowderDayAnnotation(date: Date(), snowfall: 14).annotationView()
        BestDayAnnotation(date: Date(), value: 18).annotationView()
        MilestoneAnnotation(date: Date(), milestone: 100).annotationView()
        StormAnnotation(startDate: Date(), endDate: Date(), totalSnowfall: 24, name: "Winter Storm Elsa").annotationView()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
