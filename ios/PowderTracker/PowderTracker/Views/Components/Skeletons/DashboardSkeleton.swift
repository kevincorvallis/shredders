import SwiftUI

/// Full dashboard loading skeleton
struct DashboardSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header skeleton
                VStack(spacing: 4) {
                    SkeletonText(width: 180, height: 28)
                    SkeletonText(width: 120, height: 14)
                }
                .padding(.vertical)

                // Powder Score skeleton
                PowderScoreSkeleton()

                // Conditions Card skeleton
                ConditionsCardSkeleton()

                // Roads Card skeleton
                CardSkeleton(height: 120)

                // Trip Advice skeleton
                CardSkeleton(height: 150)

                // Powder Day Card skeleton
                CardSkeleton(height: 180)

                // Forecast Preview skeleton
                ForecastPreviewSkeleton()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// Powder score gauge skeleton
struct PowderScoreSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Circular gauge
            SkeletonCircle(size: 140)

            // Verdict text
            SkeletonText(width: 200, height: 16)
                .padding(.horizontal)

            // Factors
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        SkeletonCircle(size: 8)
                        SkeletonText(width: 100, height: 14)
                        Spacer()
                        SkeletonText(width: 80, height: 14)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

/// Conditions card skeleton (2x4 grid)
struct ConditionsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SkeletonText(width: 150, height: 18)
                Spacer()
                SkeletonText(width: 80, height: 12)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(0..<8, id: \.self) { _ in
                    ConditionItemSkeleton()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

/// Single condition item skeleton
struct ConditionItemSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 28)

            VStack(alignment: .leading, spacing: 4) {
                SkeletonText(width: 60, height: 10)
                SkeletonText(width: 40, height: 14)
            }

            Spacer()
        }
    }
}

/// Generic card skeleton
struct CardSkeleton: View {
    var height: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonText(width: 120, height: 18)

            SkeletonRoundedRect(height: height - 50)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

/// Forecast preview skeleton
struct ForecastPreviewSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonText(width: 120, height: 18)
                Spacer()
                SkeletonText(width: 50, height: 14)
            }

            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    ForecastRowSkeleton()
                    if index < 2 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

/// Single forecast row skeleton
struct ForecastRowSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                SkeletonText(width: 80, height: 14)
                SkeletonText(width: 60, height: 12)
            }

            Spacer()

            SkeletonCircle(size: 32)

            VStack(alignment: .trailing, spacing: 4) {
                SkeletonText(width: 40, height: 14)
                SkeletonText(width: 50, height: 12)
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview("Dashboard Skeleton") {
    NavigationStack {
        DashboardSkeleton()
            .navigationTitle("PowderTracker")
    }
}

#Preview("Powder Score Skeleton") {
    PowderScoreSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Conditions Card Skeleton") {
    ConditionsCardSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}
