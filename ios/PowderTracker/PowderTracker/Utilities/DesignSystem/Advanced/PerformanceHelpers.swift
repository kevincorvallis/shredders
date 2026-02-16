//
//  PerformanceHelpers.swift
//  PowderTracker
//
//  View performance optimizations and iPad adaptive layout components
//

import SwiftUI

// MARK: - View Performance Optimizations

extension View {
    /// Prevents unnecessary animations when a value hasn't actually changed
    /// Useful for views with animations that shouldn't re-trigger on parent redraws
    func animateOnlyWhenChanged<Value: Equatable>(_ value: Value, animation: Animation? = .default) -> some View {
        self.animation(animation, value: value)
    }

    /// Conditionally draws based on a visibility flag
    /// More efficient than using if statements in view body
    @ViewBuilder
    func drawIf(_ condition: Bool) -> some View {
        if condition {
            self
        }
    }

    /// Adds a drawing group for views with complex layering
    /// Use for views with many overlapping layers to improve render performance
    func optimizedDrawing() -> some View {
        self.drawingGroup()
    }
}

/// Helper struct for building efficient lists
struct EfficientList<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {
    let data: Data
    @ViewBuilder let content: (Data.Element) -> Content

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(data) { item in
                content(item)
            }
        }
    }
}

/// A wrapper that delays view rendering until on-screen
/// Useful for expensive views in long lists
struct LazyRenderView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var shouldRender = false

    var body: some View {
        Group {
            if shouldRender {
                content()
            } else {
                Color.clear
            }
        }
        .onAppear {
            if !shouldRender {
                shouldRender = true
            }
        }
    }
}

/// View modifier for reducing animation calculations
struct ReduceAnimationComplexityModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .transaction { transaction in
                if reduceMotion {
                    transaction.animation = nil
                }
            }
    }
}

extension View {
    /// Automatically disables animations when Reduce Motion is enabled
    func respectsReduceMotion() -> some View {
        modifier(ReduceAnimationComplexityModifier())
    }

    /// Wraps in a lazy render view for deferred loading
    func lazyRender() -> some View {
        LazyRenderView { self }
    }
}

/// Performance monitoring helper for debug builds
#if DEBUG
struct PerformanceMonitor: View {
    let label: String
    @State private var renderCount = 0

    var body: some View {
        Color.clear
            .onAppear {
                renderCount += 1
                print("[\(label)] Render count: \(renderCount)")
            }
    }
}

extension View {
    /// Adds a performance monitor overlay in debug builds
    func monitorPerformance(_ label: String) -> some View {
        self.background(PerformanceMonitor(label: label))
    }
}
#endif

// MARK: - iPad Adaptive Layout Components

/// Container that constrains content width on iPad for better readability
/// On iPhone, content uses full width. On iPad, content is centered with max-width.
struct AdaptiveContentView<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let maxWidth: CGFloat
    let alignment: HorizontalAlignment
    @ViewBuilder let content: () -> Content

    init(
        maxWidth: CGFloat = .maxContentWidthRegular,
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack {
                if alignment == .center || alignment == .trailing {
                    Spacer(minLength: 0)
                }
                content()
                    .frame(maxWidth: maxWidth)
                if alignment == .center || alignment == .leading {
                    Spacer(minLength: 0)
                }
            }
        } else {
            content()
        }
    }
}

/// Adaptive grid that shows more columns on iPad
/// iPhone: 1-2 columns, iPad: 2-4 columns depending on available width
struct AdaptiveGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let minColumnWidth: CGFloat
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        minColumnWidth: CGFloat = .gridColumnIdealWidth,
        spacing: CGFloat = .spacingL,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minColumnWidth = minColumnWidth
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minColumnWidth), spacing: spacing)],
            spacing: spacing
        ) {
            content()
        }
    }
}

/// View modifier that constrains card width on iPad to prevent stretched appearance
struct CardMaxWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let maxWidth: CGFloat

    init(maxWidth: CGFloat = .maxContentWidthCompact) {
        self.maxWidth = maxWidth
    }

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
        } else {
            content
        }
    }
}

extension View {
    /// Constrains view width on iPad to prevent stretched appearance
    func cardMaxWidth(_ maxWidth: CGFloat = .maxContentWidthCompact) -> some View {
        modifier(CardMaxWidthModifier(maxWidth: maxWidth))
    }

    /// Wraps content in an adaptive container that centers and constrains width on iPad
    func adaptiveContent(maxWidth: CGFloat = .maxContentWidthRegular) -> some View {
        AdaptiveContentView(maxWidth: maxWidth) { self }
    }
}

/// Navigation section enum for iPad sidebar
enum NavigationSection: String, CaseIterable, Identifiable {
    case today
    case mountains
    case events
    case map
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .mountains: return "Mountains"
        case .events: return "Events"
        case .map: return "Map"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .mountains: return "mountain.2.fill"
        case .events: return "calendar"
        case .map: return "map.fill"
        case .profile: return "person.fill"
        }
    }
}
