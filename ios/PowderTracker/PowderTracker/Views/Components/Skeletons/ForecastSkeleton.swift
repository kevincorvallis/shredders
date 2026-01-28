import SwiftUI

/// Forecast view skeleton
struct ForecastViewSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<7, id: \.self) { _ in
                    ForecastDayCardSkeleton()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// Full forecast day card skeleton
struct ForecastDayCardSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonText(width: 100, height: 18)
                    SkeletonText(width: 80, height: 14)
                }

                Spacer()

                SkeletonCircle(size: 48)
            }

            Divider()

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonCircle(size: 24)
                        SkeletonText(width: 60, height: 12)
                        SkeletonText(width: 40, height: 14)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
        .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        ForecastViewSkeleton()
            .navigationTitle("7-Day Forecast")
    }
}
