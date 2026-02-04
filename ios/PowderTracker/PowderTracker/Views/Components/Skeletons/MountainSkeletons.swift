//
//  MountainSkeletons.swift
//  PowderTracker
//
//  Skeleton loading states for mountain-related views.
//  Based on UX research: skeletons are perceived as faster than spinners
//  and should match the actual layout for best results.
//

import SwiftUI

// MARK: - Mountain Card Skeleton

/// Skeleton for ConditionMountainCard - matches the actual card layout
struct MountainCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Logo placeholder
            SkeletonCircle(size: 56)

            // Info section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    SkeletonText(width: 120, height: 18)
                    SkeletonRoundedRect(cornerRadius: 4, height: 16)
                        .frame(width: 50)
                }

                HStack(spacing: 12) {
                    SkeletonText(width: 40, height: 14)
                    SkeletonText(width: 50, height: 14)
                    SkeletonText(width: 45, height: 14)
                }
            }

            Spacer()

            // Score placeholder
            VStack(spacing: 2) {
                SkeletonText(width: 35, height: 24)
                SkeletonText(width: 30, height: 12)
            }

            // Favorite star
            SkeletonCircle(size: 24)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

/// List of mountain card skeletons
struct MountainListSkeleton: View {
    var itemCount: Int = 6

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(0..<itemCount, id: \.self) { index in
                MountainCardSkeleton()
                    .opacity(1.0 - Double(index) * 0.1) // Fade out effect
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Mountain Detail Skeleton

/// Skeleton for TabbedLocationView / MountainDetailView
struct MountainDetailSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                SkeletonText(width: 180, height: 24)
                SkeletonText(width: 140, height: 14)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // Tab picker skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonRoundedRect(cornerRadius: 20, height: 36)
                            .frame(width: 80)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            Divider()

            // Content skeleton
            ScrollView {
                VStack(spacing: 20) {
                    // Overview cards
                    OverviewTabSkeleton()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

/// Skeleton for the overview tab content
struct OverviewTabSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Quick stats row
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    QuickStatSkeleton()
                }
            }

            // Conditions card
            ConditionsCardSkeleton()

            // Forecast preview
            ForecastPreviewSkeleton()

            // Webcam preview
            CardSkeleton(height: 180)
        }
    }
}

/// Quick stat pill skeleton
struct QuickStatSkeleton: View {
    var body: some View {
        VStack(spacing: 4) {
            SkeletonText(width: 40, height: 20)
            SkeletonText(width: 50, height: 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Planner Card Skeleton

/// Skeleton for horizontal planner cards
struct PlannerCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            SkeletonRoundedRect(cornerRadius: 12, height: 100)

            // Mountain name
            SkeletonText(width: 100, height: 16)

            // Stats row
            HStack(spacing: 8) {
                SkeletonText(width: 40, height: 14)
                SkeletonText(width: 50, height: 14)
            }

            // Score badge
            HStack {
                Spacer()
                SkeletonRoundedRect(cornerRadius: 8, height: 28)
                    .frame(width: 60)
            }
        }
        .padding()
        .frame(width: 180)
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
    }
}

/// Horizontal scroll of planner card skeletons
struct PlannerRowSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    PlannerCardSkeleton()
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Status Header Skeleton

/// Skeleton for the status header with pills
struct StatusHeaderSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 2) {
                    SkeletonText(width: 30, height: 20)
                    SkeletonText(width: 50, height: 12)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Full Mountains Tab Skeleton

/// Complete skeleton for the MountainsTabView loading state
struct MountainsTabSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // Mode picker skeleton
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: 4) {
                        SkeletonCircle(size: 18)
                        SkeletonText(width: 40, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
            .padding(4)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            .padding(.top, .spacingS)

            ScrollView {
                LazyVStack(spacing: 16) {
                    // Status header
                    StatusHeaderSkeleton()
                        .padding(.horizontal)
                        .padding(.top)

                    // Sort picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                SkeletonRoundedRect(cornerRadius: 16, height: 32)
                                    .frame(width: 100)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { _ in
                                SkeletonRoundedRect(cornerRadius: 16, height: 32)
                                    .frame(width: 80)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Mountain cards
                    MountainListSkeleton(itemCount: 6)

                    Spacer(minLength: 50)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Previews

#Preview("Mountain Card Skeleton") {
    MountainCardSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Mountain List Skeleton") {
    ScrollView {
        MountainListSkeleton()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Mountain Detail Skeleton") {
    NavigationStack {
        MountainDetailSkeleton()
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Planner Card Skeleton") {
    PlannerCardSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Full Mountains Tab Skeleton") {
    NavigationStack {
        MountainsTabSkeleton()
            .navigationTitle("Mountains")
            .navigationBarTitleDisplayMode(.large)
    }
}
