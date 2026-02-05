//
//  FavoritesEmptyState.swift
//  PowderTracker
//
//  Brock-themed empty state for favorites.
//

import SwiftUI

struct FavoritesEmptyState: View {
    let onAddTapped: () -> Void

    var body: some View {
        BrockEmptyState(
            title: "No Favorite Mountains Yet",
            message: "Brock wants to help you track your favorite resorts! Add some mountains to compare conditions.",
            expression: .curious,
            actionTitle: "Sniff Out Mountains",
            action: onAddTapped
        )
    }
}

#Preview {
    FavoritesEmptyState {
        print("Add mountains tapped")
    }
}
