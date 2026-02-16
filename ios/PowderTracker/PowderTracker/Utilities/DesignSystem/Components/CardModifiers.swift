//
//  CardModifiers.swift
//  PowderTracker
//
//  Standard card modifiers, loading placeholders, sheet presentation, and navigation transitions
//

import SwiftUI

// MARK: - Standard Modifiers

extension View {
    /// Standard card styling
    func standardCard(padding: CGFloat = .spacingL) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
            .cardShadow()
    }

    /// Hero card styling with more prominent appearance
    func heroCard(padding: CGFloat = .spacingL) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusHero)
            .heroShadow()
    }

    /// Compact list item styling
    func listCard(padding: CGFloat = .spacingM) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
    }

    /// Status pill/badge styling with color background
    func statusPill(color: Color, padding: CGFloat = .spacingS) -> some View {
        self
            .padding(.horizontal, padding)
            .padding(.vertical, padding * 0.5)
            .background(color.opacity(.opacityMedium))
            .cornerRadius(.cornerRadiusMicro)
    }

    /// Focus border overlay for selected/highlighted states
    func focusBorder(color: Color = .blue, width: CGFloat = 2) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .stroke(color, lineWidth: width)
        )
    }

    /// Metric value styling for numeric displays
    func metricValue(size: Font.TextStyle = .subheadline) -> some View {
        self
            .font(.system(size, design: .rounded))
            .fontWeight(.semibold)
            .monospacedDigit()
    }
}

// MARK: - Loading Placeholder

extension View {
    /// Applies redacted placeholder effect for loading states
    /// Use this for simple loading placeholders instead of custom skeleton views
    func loadingPlaceholder(_ isLoading: Bool) -> some View {
        self.redacted(reason: isLoading ? .placeholder : [])
    }

    /// Applies shimmer effect to redacted placeholder
    func shimmerPlaceholder(_ isLoading: Bool) -> some View {
        self
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
    }
}

// MARK: - Modern Sheet Presentation

extension View {
    /// Applies modern sheet presentation styling with glass background and rounded corners
    /// Use this on content inside a .sheet() modifier
    func modernSheetStyle() -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(20)
    }

    /// Applies modern sheet presentation with background interaction enabled
    /// Allows user to interact with content behind the sheet
    func modernSheetStyleInteractive() -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(20)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }

    /// Applies modern sheet with custom detents
    func modernSheet(detents: Set<PresentationDetent> = [.medium, .large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(20)
    }
}

// MARK: - iOS 18+ Navigation Transitions

extension View {
    /// Applies zoom navigation transition on iOS 18+
    /// Falls back to default navigation on earlier versions
    @ViewBuilder
    func zoomNavigationTransition<ID: Hashable>(
        sourceID: ID,
        in namespace: Namespace.ID
    ) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
    }

    /// Marks view as matched transition source for iOS 18+ zoom transitions
    @ViewBuilder
    func matchedTransitionSourceIfAvailable<ID: Hashable>(
        id: ID,
        in namespace: Namespace.ID
    ) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}
