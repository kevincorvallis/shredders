//
//  EventSkeletons.swift
//  PowderTracker
//
//  Skeleton loading states for event-related views.
//

import SwiftUI

// MARK: - Event Card Skeleton

/// Skeleton for event cards in the list view
struct EventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with date badge and mountain
            HStack(spacing: 12) {
                // Date badge
                VStack(spacing: 2) {
                    SkeletonText(width: 30, height: 12)
                    SkeletonText(width: 24, height: 20)
                }
                .frame(width: 50, height: 50)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)

                // Event info
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonText(width: 180, height: 18)
                    HStack(spacing: 8) {
                        SkeletonCircle(size: 16)
                        SkeletonText(width: 100, height: 14)
                    }
                }

                Spacer()

                // Attendee count
                VStack(spacing: 2) {
                    SkeletonCircle(size: 24)
                    SkeletonText(width: 20, height: 10)
                }
            }

            // Description line
            SkeletonText(width: 220, height: 14)

            // Tags row
            HStack(spacing: 8) {
                SkeletonRoundedRect(cornerRadius: 12, height: 24)
                    .frame(width: 70)
                SkeletonRoundedRect(cornerRadius: 12, height: 24)
                    .frame(width: 60)
                SkeletonRoundedRect(cornerRadius: 12, height: 24)
                    .frame(width: 80)
            }

            // Footer with creator and time
            HStack {
                HStack(spacing: 8) {
                    SkeletonCircle(size: 24)
                    SkeletonText(width: 80, height: 12)
                }
                Spacer()
                SkeletonText(width: 60, height: 12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

/// List of event card skeletons
struct EventListSkeleton: View {
    var itemCount: Int = 5

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<itemCount, id: \.self) { index in
                EventCardSkeleton()
                    .opacity(1.0 - Double(index) * 0.12)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Last Minute Event Skeleton

/// Skeleton for last-minute event cards (horizontal scroll)
struct LastMinuteEventSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Time badge
            SkeletonRoundedRect(cornerRadius: 8, height: 24)
                .frame(width: 80)

            // Title
            SkeletonText(width: 140, height: 16)

            // Mountain
            HStack(spacing: 6) {
                SkeletonCircle(size: 20)
                SkeletonText(width: 80, height: 14)
            }

            Spacer()

            // Attendees
            HStack(spacing: -8) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCircle(size: 28)
                }
            }
        }
        .padding()
        .frame(width: 180, height: 160)
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

/// Horizontal row of last minute event skeletons
struct LastMinuteEventRowSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    LastMinuteEventSkeleton()
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Event Detail Skeleton

/// Skeleton for event detail view
struct EventDetailSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                VStack(spacing: 16) {
                    // Event type badge
                    SkeletonRoundedRect(cornerRadius: 16, height: 28)
                        .frame(width: 100)

                    // Title
                    SkeletonText(width: 250, height: 28)

                    // Date and time
                    HStack(spacing: 16) {
                        HStack(spacing: 8) {
                            SkeletonCircle(size: 20)
                            SkeletonText(width: 100, height: 16)
                        }
                        HStack(spacing: 8) {
                            SkeletonCircle(size: 20)
                            SkeletonText(width: 60, height: 16)
                        }
                    }

                    // Mountain info
                    HStack(spacing: 12) {
                        SkeletonCircle(size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonText(width: 120, height: 18)
                            SkeletonText(width: 80, height: 14)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(.cornerRadiusHero)

                // Description card
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonText(width: 100, height: 18)
                    SkeletonText(width: .infinity, height: 14)
                    SkeletonText(width: 280, height: 14)
                    SkeletonText(width: 200, height: 14)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(.cornerRadiusHero)

                // Attendees card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SkeletonText(width: 100, height: 18)
                        Spacer()
                        SkeletonText(width: 40, height: 14)
                    }

                    HStack(spacing: -8) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonCircle(size: 40)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(.cornerRadiusHero)

                // Action buttons
                HStack(spacing: 12) {
                    SkeletonRoundedRect(cornerRadius: 12, height: 50)
                    SkeletonRoundedRect(cornerRadius: 12, height: 50)
                        .frame(width: 50)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Full Events Tab Skeleton

/// Complete skeleton for the EventsView loading state
struct EventsTabSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonRoundedRect(cornerRadius: 16, height: 32)
                                .frame(width: 80)
                        }
                    }
                    .padding(.horizontal)
                }

                // Last minute section header
                HStack {
                    SkeletonText(width: 140, height: 18)
                    Spacer()
                    SkeletonText(width: 60, height: 14)
                }
                .padding(.horizontal)

                // Last minute cards
                LastMinuteEventRowSkeleton()

                // Events section header
                HStack {
                    SkeletonText(width: 120, height: 18)
                    Spacer()
                }
                .padding(.horizontal)

                // Event list
                EventListSkeleton(itemCount: 4)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Previews

#Preview("Event Card Skeleton") {
    EventCardSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Event List Skeleton") {
    ScrollView {
        EventListSkeleton()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Last Minute Event Skeleton") {
    LastMinuteEventSkeleton()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Event Detail Skeleton") {
    NavigationStack {
        EventDetailSkeleton()
            .navigationTitle("Event")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Full Events Tab Skeleton") {
    NavigationStack {
        EventsTabSkeleton()
            .navigationTitle("Events")
    }
}
