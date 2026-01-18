import SwiftUI

/// Time scrubber for time-based overlays (snowfall, radar)
struct MapTimeScrubber: View {
    @ObservedObject var overlayState: MapOverlayState
    @State private var animationTimer: Timer? = nil

    private var timeIntervals: [TimeInterval] {
        overlayState.activeOverlay?.timeIntervals ?? []
    }

    private var currentIndex: Int {
        timeIntervals.firstIndex(of: overlayState.selectedTimeOffset) ?? 0
    }

    var body: some View {
        VStack(spacing: .spacingS) {
            // Scrubber
            HStack(spacing: .spacingS) {
                // Back button
                Button(action: stepBackward) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(currentIndex > 0 ? .primary : .secondary)
                }
                .disabled(currentIndex == 0)

                // Slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 4)
                            .cornerRadius(2)

                        // Progress
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: progressWidth(in: geometry), height: 4)
                            .cornerRadius(2)

                        // Thumb
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                            .offset(x: thumbOffset(in: geometry))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        updateFromDrag(value: value.location.x, in: geometry)
                                    }
                            )
                    }
                }
                .frame(height: 16)

                // Forward button
                Button(action: stepForward) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(currentIndex < timeIntervals.count - 1 ? .primary : .secondary)
                }
                .disabled(currentIndex >= timeIntervals.count - 1)
            }
            .padding(.horizontal, .spacingM)

            // Time labels
            HStack {
                ForEach(timeLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if label != timeLabels.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, .spacingM)

            // Current time and play button
            HStack {
                Text("Currently showing: \(currentTimeLabel)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: toggleAnimation) {
                    HStack(spacing: 4) {
                        Image(systemName: overlayState.isAnimating ? "pause.fill" : "play.fill")
                            .font(.caption)
                        Text(overlayState.isAnimating ? "Pause" : "Play animation")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, .spacingM)
        }
        .padding(.vertical, .spacingS)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
        .onDisappear {
            stopAnimation()
        }
    }

    // MARK: - Time Labels

    private var timeLabels: [String] {
        guard let overlay = overlayState.activeOverlay else { return [] }

        switch overlay {
        case .snowfall:
            return ["Now", "+6h", "+12h", "+24h", "+48h", "+72h"]
        case .radar:
            return ["Now", "+1h", "+2h", "+3h", "+4h", "+5h", "+6h"]
        default:
            return []
        }
    }

    private var currentTimeLabel: String {
        let hours = Int(overlayState.selectedTimeOffset / 3600)
        if hours == 0 {
            return "Now"
        }

        let date = Date().addingTimeInterval(overlayState.selectedTimeOffset)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE h a"
        return "+\(hours)h (\(formatter.string(from: date)))"
    }

    // MARK: - Geometry Calculations

    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        guard !timeIntervals.isEmpty else { return 0 }
        let progress = CGFloat(currentIndex) / CGFloat(timeIntervals.count - 1)
        return geometry.size.width * progress
    }

    private func thumbOffset(in geometry: GeometryProxy) -> CGFloat {
        guard !timeIntervals.isEmpty else { return 0 }
        let progress = CGFloat(currentIndex) / CGFloat(timeIntervals.count - 1)
        return (geometry.size.width - 16) * progress
    }

    private func updateFromDrag(value: CGFloat, in geometry: GeometryProxy) {
        guard !timeIntervals.isEmpty else { return }
        let progress = max(0, min(1, value / geometry.size.width))
        let index = Int(round(progress * CGFloat(timeIntervals.count - 1)))
        overlayState.selectedTimeOffset = timeIntervals[index]
    }

    // MARK: - Navigation

    private func stepBackward() {
        guard currentIndex > 0 else { return }
        overlayState.selectedTimeOffset = timeIntervals[currentIndex - 1]
    }

    private func stepForward() {
        guard currentIndex < timeIntervals.count - 1 else { return }
        overlayState.selectedTimeOffset = timeIntervals[currentIndex + 1]
    }

    // MARK: - Animation

    private func toggleAnimation() {
        if overlayState.isAnimating {
            stopAnimation()
        } else {
            startAnimation()
        }
    }

    private func startAnimation() {
        overlayState.isAnimating = true
        overlayState.selectedTimeOffset = timeIntervals.first ?? 0

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak overlayState] _ in
            Task { @MainActor in
                guard let overlayState = overlayState else { return }
                let intervals = overlayState.activeOverlay?.timeIntervals ?? []
                let currentIdx = intervals.firstIndex(of: overlayState.selectedTimeOffset) ?? 0
                if currentIdx < intervals.count - 1 {
                    overlayState.selectedTimeOffset = intervals[currentIdx + 1]
                } else {
                    overlayState.selectedTimeOffset = intervals.first ?? 0
                }
            }
        }
    }

    private func stopAnimation() {
        overlayState.isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - Compact Time Picker

struct CompactTimePicker: View {
    @ObservedObject var overlayState: MapOverlayState

    private var timeIntervals: [TimeInterval] {
        overlayState.activeOverlay?.timeIntervals ?? []
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                ForEach(Array(timeIntervals.enumerated()), id: \.offset) { index, interval in
                    let isSelected = overlayState.selectedTimeOffset == interval
                    Button(action: {
                        overlayState.selectedTimeOffset = interval
                    }) {
                        Text(labelFor(interval))
                            .font(.caption)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundColor(isSelected ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .spacingM)
        }
    }

    private func labelFor(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        return hours == 0 ? "Now" : "+\(hours)h"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        let state = MapOverlayState()

        MapTimeScrubber(overlayState: state)
            .onAppear {
                state.activeOverlay = .snowfall
            }

        CompactTimePicker(overlayState: state)
    }
    .padding()
}
