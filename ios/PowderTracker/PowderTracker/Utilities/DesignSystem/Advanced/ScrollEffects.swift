//
//  ScrollEffects.swift
//  PowderTracker
//
//  Sticky section headers, custom refresh indicator, and scroll velocity tracking
//

import SwiftUI

// MARK: - Sticky Section Headers

/// A sticky section header that pins to the top of the scroll view
struct StickySectionHeader<Content: View>: View {
    let title: String
    let count: Int?
    let isSticky: Bool
    let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        count: Int? = nil,
        isSticky: Bool = false,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.count = count
        self.isSticky = isSticky
        self.content = content
    }

    var body: some View {
        HStack(spacing: .spacingM) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if let count = count {
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue))
            }

            Spacer()

            content()
        }
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingM)
        .background {
            if isSticky {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            } else {
                Rectangle()
                    .fill(Color(.systemGroupedBackground))
            }
        }
        .animation(.easeOut(duration: 0.2), value: isSticky)
    }
}

/// A region header specifically for mountain lists
struct RegionSectionHeader: View {
    let region: String
    let mountainCount: Int
    let isSticky: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: .spacingM) {
            // Region icon
            Image(systemName: regionIcon)
                .font(.subheadline)
                .foregroundColor(regionColor)
                .frame(width: 24, height: 24)
                .background(Circle().fill(regionColor.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(region)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(mountainCount) resort\(mountainCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Collapse indicator when sticky
            if isSticky {
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingM)
        .background {
            Group {
                if isSticky {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, y: 2)
                        .blur(radius: 0)
                } else {
                    Rectangle()
                        .fill(Color(.systemGroupedBackground))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSticky)
    }

    private var regionIcon: String {
        switch region.lowercased() {
        case let r where r.contains("washington"):
            return "cloud.rain"
        case let r where r.contains("oregon"):
            return "tree"
        case let r where r.contains("california"):
            return "sun.max"
        case let r where r.contains("colorado"):
            return "snowflake"
        case let r where r.contains("utah"):
            return "sparkles"
        case let r where r.contains("idaho"):
            return "mountain.2"
        case let r where r.contains("montana"):
            return "wind"
        case let r where r.contains("canada"), let r where r.contains("british columbia"):
            return "maple.leaf"
        default:
            return "mountain.2"
        }
    }

    private var regionColor: Color {
        switch region.lowercased() {
        case let r where r.contains("washington"):
            return .blue
        case let r where r.contains("oregon"):
            return .green
        case let r where r.contains("california"):
            return .orange
        case let r where r.contains("colorado"):
            return .purple
        case let r where r.contains("utah"):
            return .cyan
        case let r where r.contains("idaho"):
            return .indigo
        case let r where r.contains("montana"):
            return .teal
        case let r where r.contains("canada"), let r where r.contains("british columbia"):
            return .red
        default:
            return .blue
        }
    }
}

/// Preference key to track sticky header state
struct StickyHeaderPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

/// A grouped list with sticky section headers
struct GroupedListWithStickyHeaders<T: Identifiable, Header: View, Content: View>: View {
    let groups: [(key: String, items: [T])]
    let headerBuilder: (String, Int, Bool) -> Header
    let contentBuilder: (T) -> Content

    @State private var stickyHeaders: Set<String> = []

    init(
        groups: [(key: String, items: [T])],
        @ViewBuilder header: @escaping (String, Int, Bool) -> Header,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.groups = groups
        self.headerBuilder = header
        self.contentBuilder = content
    }

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach(groups, id: \.key) { group in
                Section {
                    ForEach(group.items) { item in
                        contentBuilder(item)
                    }
                } header: {
                    headerBuilder(group.key, group.items.count, stickyHeaders.contains(group.key))
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: StickyHeaderPreferenceKey.self,
                                        value: [group.key: geo.frame(in: .global).minY]
                                    )
                            }
                        )
                }
            }
        }
        .onPreferenceChange(StickyHeaderPreferenceKey.self) { values in
            // Headers are "sticky" when they're at the top of the view
            let newSticky = Set(values.filter { $0.value <= 100 }.keys)
            if newSticky != stickyHeaders {
                withAnimation(.easeOut(duration: 0.15)) {
                    stickyHeaders = newSticky
                }
            }
        }
    }
}

// MARK: - Custom Refresh Indicator

/// A custom pull-to-refresh indicator with animated icon
struct AnimatedRefreshIndicator: View {
    let isRefreshing: Bool
    let progress: CGFloat

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 2)

            // Progress arc
            Circle()
                .trim(from: 0, to: isRefreshing ? 1 : progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(isRefreshing ? rotation : 0))

            // Snow icon
            Image(systemName: "snowflake")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(isRefreshing ? -rotation : 0))
        }
        .frame(width: 32, height: 32)
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                rotation = 0
            }
        }
    }
}

/// Pull-to-refresh container with custom indicator
struct PullToRefreshView<Content: View>: View {
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    @State private var isRefreshing = false
    @State private var pullProgress: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let offset = geo.frame(in: .global).minY
                    let progress = min(max(offset / 80, 0), 1)

                    Color.clear
                        .preference(key: RefreshProgressKey.self, value: progress)
                        .onChange(of: offset) { _, newValue in
                            if newValue > 80 && !isRefreshing {
                                triggerRefresh()
                            }
                        }
                }
                .frame(height: 0)

                // Refresh indicator
                if pullProgress > 0 || isRefreshing {
                    AnimatedRefreshIndicator(isRefreshing: isRefreshing, progress: pullProgress)
                        .padding(.vertical, .spacingM)
                        .transition(.opacity.combined(with: .scale))
                }

                content()
            }
        }
        .onPreferenceChange(RefreshProgressKey.self) { value in
            pullProgress = value
        }
    }

    private func triggerRefresh() {
        guard !isRefreshing else { return }

        HapticFeedback.medium.trigger()
        isRefreshing = true

        Task {
            await onRefresh()
            await MainActor.run {
                withAnimation {
                    isRefreshing = false
                }
            }
        }
    }
}

private struct RefreshProgressKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Velocity Tracking

/// Tracks scroll offset for velocity calculations
struct ScrollOffsetTracker: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: ScrollVelocityPreferenceKey.self,
                    value: geo.frame(in: .named("scroll")).minY
                )
        }
        .frame(height: 0)
    }
}

/// Preference key for scroll velocity tracking
struct ScrollVelocityPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Observable class to track scroll velocity over time
@MainActor
@Observable
final class ScrollVelocityTracker {
    private var lastOffset: CGFloat = 0
    private var lastUpdateTime: Date = Date()
    private(set) var velocity: CGFloat = 0
    private(set) var blurAmount: CGFloat = 0

    /// Maximum blur radius when scrolling fast
    var maxBlurRadius: CGFloat = 6
    /// Velocity threshold to start applying blur (points per second)
    var blurThreshold: CGFloat = 1500
    /// Velocity at which maximum blur is applied
    var maxVelocityForBlur: CGFloat = 4000

    func updateOffset(_ offset: CGFloat) {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastUpdateTime)

        guard timeDelta > 0.001 else { return } // Avoid division by zero

        let offsetDelta = abs(offset - lastOffset)
        let newVelocity = offsetDelta / CGFloat(timeDelta)

        // Smooth the velocity using exponential moving average
        velocity = velocity * 0.7 + newVelocity * 0.3

        // Calculate blur based on velocity
        if velocity > blurThreshold {
            let normalizedVelocity = min((velocity - blurThreshold) / (maxVelocityForBlur - blurThreshold), 1)
            blurAmount = normalizedVelocity * maxBlurRadius
        } else {
            blurAmount = 0
        }

        lastOffset = offset
        lastUpdateTime = now
    }

    func resetVelocity() {
        velocity = 0
        blurAmount = 0
    }
}

/// View modifier that applies velocity-based blur during fast scrolling
struct VelocityBlurModifier: ViewModifier {
    let velocity: CGFloat
    let threshold: CGFloat
    let maxBlur: CGFloat

    private var blurAmount: CGFloat {
        guard velocity > threshold else { return 0 }
        let normalizedVelocity = min((velocity - threshold) / (4000 - threshold), 1)
        return normalizedVelocity * maxBlur
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: blurAmount)
            .animation(.easeOut(duration: 0.15), value: blurAmount)
    }
}

extension View {
    /// Applies blur effect based on scroll velocity
    /// - Parameters:
    ///   - velocity: Current scroll velocity (points per second)
    ///   - threshold: Velocity threshold to start blur (default: 1500)
    ///   - maxBlur: Maximum blur radius (default: 6)
    func velocityBlur(velocity: CGFloat, threshold: CGFloat = 1500, maxBlur: CGFloat = 6) -> some View {
        modifier(VelocityBlurModifier(velocity: velocity, threshold: threshold, maxBlur: maxBlur))
    }
}

/// A scroll view that tracks velocity and applies blur during fast scrolling
struct VelocityBlurScrollView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var velocityTracker = ScrollVelocityTracker()
    @State private var lastOffset: CGFloat = 0
    @State private var scrollStopTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScrollOffsetTracker()

                content()
                    .blur(radius: velocityTracker.blurAmount)
                    .animation(.easeOut(duration: 0.15), value: velocityTracker.blurAmount)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollVelocityPreferenceKey.self) { offset in
            velocityTracker.updateOffset(offset)
            lastOffset = offset

            // Cancel existing timer
            scrollStopTimer?.invalidate()

            // Start new timer to detect scroll stop
            scrollStopTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                Task { @MainActor in
                    withAnimation(.easeOut(duration: 0.3)) {
                        velocityTracker.resetVelocity()
                    }
                }
            }
        }
        .modifier(ScrollPhaseChangeModifier(onIdle: {
            withAnimation(.easeOut(duration: 0.3)) {
                velocityTracker.resetVelocity()
            }
        }))
    }
}

/// Modifier to handle scroll phase changes on iOS 18+
struct ScrollPhaseChangeModifier: ViewModifier {
    let onIdle: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollPhaseChange { _, newPhase in
                    if case .idle = newPhase {
                        onIdle()
                    }
                }
        } else {
            content
        }
    }
}
