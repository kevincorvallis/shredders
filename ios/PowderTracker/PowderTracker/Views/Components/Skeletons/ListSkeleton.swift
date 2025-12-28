import SwiftUI

/// Generic list skeleton for various list views
struct ListSkeleton: View {
    var itemCount: Int = 5
    var itemHeight: CGFloat = 80

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<itemCount, id: \.self) { _ in
                ListItemSkeleton(height: itemHeight)
            }
        }
    }
}

/// Single list item skeleton
struct ListItemSkeleton: View {
    var height: CGFloat = 80

    var body: some View {
        HStack(spacing: 16) {
            SkeletonCircle(size: 40)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonText(width: 180, height: 16)
                SkeletonText(width: 120, height: 14)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SkeletonText(width: 60, height: 14)
                SkeletonText(width: 40, height: 12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// Mountain picker skeleton
struct MountainPickerSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { index in
                HStack(spacing: 16) {
                    SkeletonCircle(size: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonText(width: 150, height: 16)
                        SkeletonText(width: 100, height: 12)
                    }

                    Spacer()
                }
                .padding()

                if index < 9 {
                    Divider()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// History chart skeleton
struct HistoryChartSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Title and period selector
            HStack {
                SkeletonText(width: 120, height: 18)
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRoundedRect(cornerRadius: 16, height: 32)
                            .frame(width: 60)
                    }
                }
            }

            // Chart area
            SkeletonRoundedRect(cornerRadius: 12, height: 250)

            // Legend
            HStack(spacing: 24) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 8) {
                        SkeletonCircle(size: 12)
                        SkeletonText(width: 80, height: 12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

/// Patrol/Safety view skeleton
struct PatrolViewSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    SkeletonText(width: 200, height: 24)
                    SkeletonText(width: 150, height: 14)
                }
                .padding()

                // Avalanche risk
                VStack(spacing: 16) {
                    SkeletonText(width: 140, height: 18)
                    SkeletonCircle(size: 100)
                    SkeletonText(width: 180, height: 16)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)

                // Safety info cards
                ForEach(0..<3, id: \.self) { _ in
                    CardSkeleton(height: 120)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// Webcams view skeleton
struct WebcamsViewSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 12) {
                        SkeletonText(width: 120, height: 16)
                        SkeletonRoundedRect(cornerRadius: 12, height: 200)
                        HStack {
                            SkeletonText(width: 100, height: 12)
                            Spacer()
                            SkeletonCircle(size: 32)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview("List Skeleton") {
    ListSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Mountain Picker Skeleton") {
    NavigationStack {
        MountainPickerSkeleton()
            .navigationTitle("Select Mountain")
    }
}

#Preview("History Chart Skeleton") {
    HistoryChartSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Patrol View Skeleton") {
    NavigationStack {
        PatrolViewSkeleton()
            .navigationTitle("Safety & Patrol")
    }
}

#Preview("Webcams Skeleton") {
    NavigationStack {
        WebcamsViewSkeleton()
            .navigationTitle("Webcams")
    }
}
