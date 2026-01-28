import WidgetKit
import SwiftUI
import ActivityKit

@main
struct PowderTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PowderTrackerWidget()
        if #available(iOS 16.2, *) {
            SkiDayLiveActivity()
        }
    }
}

// MARK: - Live Activity Attributes (Shared)

/// Attributes for the ski day Live Activity
struct SkiDayAttributes: ActivityAttributes {
    /// Content state that can be updated
    public struct ContentState: Codable, Hashable {
        var snowfall24h: Int
        var powderScore: Int
        var liftsOpen: Int
        var liftsTotal: Int
        var lastUpdated: Date
        var alertMessage: String?
    }

    /// Static attributes set when activity starts
    var mountainId: String
    var mountainName: String
    var mountainColor: String
}

// MARK: - Live Activity Widget

@available(iOS 16.2, *)
struct SkiDayLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SkiDayAttributes.self) { context in
            // Lock Screen view
            SkiDayLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "mountain.2.fill")
                            .foregroundColor(.blue)
                        Text(context.attributes.mountainName)
                            .font(.headline)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.powderScore)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(context.state.powderScore >= 7 ? .green : .yellow)
                }

                DynamicIslandExpandedRegion(.center) {}

                DynamicIslandExpandedRegion(.bottom) {
                    SkiDayExpandedBottomView(context: context)
                }
            } compactLeading: {
                Image(systemName: "snowflake")
                    .foregroundColor(.cyan)
            } compactTrailing: {
                Text("\(context.state.powderScore)")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(context.state.powderScore >= 7 ? .green : .yellow)
            } minimal: {
                Image(systemName: "snowflake")
                    .foregroundColor(.cyan)
            }
        }
    }
}

// MARK: - Live Activity Views

@available(iOS 16.2, *)
struct SkiDayLockScreenView: View {
    let context: ActivityViewContext<SkiDayAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.mountainName)
                    .font(.headline)
                    .fontWeight(.bold)

                if let alert = context.state.alertMessage {
                    Text(alert)
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Ski Day Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Image(systemName: "snowflake")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text("\(context.state.snowfall24h)\"")
                        .font(.system(.body, design: .rounded, weight: .bold))
                    Text("24hr")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(scoreColor(context.state.powderScore))
                    Text("\(context.state.powderScore)")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundColor(scoreColor(context.state.powderScore))
                    Text("Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(context.state.liftsOpen)/\(context.state.liftsTotal)")
                        .font(.system(.body, design: .rounded, weight: .bold))
                    Text("Lifts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 8 { return .green }
        if score >= 6 { return .yellow }
        if score >= 4 { return .orange }
        return .red
    }
}

@available(iOS 16.2, *)
struct SkiDayExpandedBottomView: View {
    let context: ActivityViewContext<SkiDayAttributes>

    var body: some View {
        VStack(spacing: 8) {
            if let alert = context.state.alertMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(alert)
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
            }

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Image(systemName: "snowflake")
                        .font(.title3)
                        .foregroundColor(.cyan)
                    Text("\(context.state.snowfall24h)\"")
                        .font(.headline)
                    Text("Fresh Snow")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(scoreColor(context.state.powderScore))
                    Text("\(context.state.powderScore)/10")
                        .font(.headline)
                    Text("Powder Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.title3)
                        .foregroundColor(.green)
                    Text("\(context.state.liftsOpen)/\(context.state.liftsTotal)")
                        .font(.headline)
                    Text("Lifts Open")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Text("Updated \(context.state.lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 8 { return .green }
        if score >= 6 { return .yellow }
        if score >= 4 { return .orange }
        return .red
    }
}
