//
//  SkeletonView.swift
//  PowderTracker
//
//  Modern skeleton loading states using SwiftUI-Shimmer
//

import SwiftUI
import Shimmer

/// Rounded skeleton shape (for cards, buttons, etc.)
struct SkeletonRoundedRect: View {
    var cornerRadius: CGFloat = 8
    var height: CGFloat? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(height: height)
            .shimmering()
    }
}

/// Circle skeleton (for icons, avatars)
struct SkeletonCircle: View {
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: size, height: size)
            .shimmering()
    }
}

/// Text skeleton with automatic sizing
struct SkeletonText: View {
    var width: CGFloat = 100
    var height: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .shimmering()
    }
}

#Preview("Skeleton Shapes") {
    VStack(spacing: 20) {
        SkeletonRoundedRect(height: 60)

        HStack {
            SkeletonCircle(size: 40)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonText(width: 150, height: 16)
                SkeletonText(width: 100, height: 12)
            }
        }

        SkeletonText(width: 200)
    }
    .padding()
}
