//
//  View+Shimmer.swift
//  PowderTracker
//
//  Created by Claude Code
//

import SwiftUI
import Shimmer

extension View {
    /// Apply shimmer effect for loading skeleton states
    /// - Parameter active: Whether the shimmer animation is active
    /// - Returns: View with shimmer effect applied
    func loadingSkeleton(active: Bool = true) -> some View {
        self
            .shimmering(active: active)
            .opacity(active ? 0.7 : 1.0)
    }
}
