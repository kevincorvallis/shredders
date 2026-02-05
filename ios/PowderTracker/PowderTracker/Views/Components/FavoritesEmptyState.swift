//
//  FavoritesEmptyState.swift
//  PowderTracker
//
//  Modern empty state for favorites with illustrated design.
//

import SwiftUI

struct FavoritesEmptyState: View {
    let onAddTapped: () -> Void

    var body: some View {
        ModernEmptyStateView(
            style: .noFavorites,
            title: "No Favorite Mountains Yet",
            message: "Track your favorite resorts to quickly compare conditions and snowfall forecasts."
        ) {
            ModernEmptyStateButton(
                title: "Add Mountains",
                icon: "plus.circle.fill",
                action: onAddTapped
            )
        }
    }
}

#Preview {
    FavoritesEmptyState {
        print("Add mountains tapped")
    }
}
