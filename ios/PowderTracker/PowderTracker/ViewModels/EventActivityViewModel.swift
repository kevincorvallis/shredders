//
//  EventActivityViewModel.swift
//  PowderTracker
//
//  ViewModel for event activity timeline with RSVP gating support.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class EventActivityViewModel {

    // MARK: - State

    var activities: [EventActivity] = []
    var activityCount: Int = 0
    var isGated: Bool = true
    var gatedMessage: String?

    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String?
    var hasMore: Bool = false

    // MARK: - Private

    private let eventId: String
    private let eventService = EventService.shared
    private var currentOffset: Int = 0
    private let pageSize: Int = 20

    // MARK: - Initialization

    init(eventId: String) {
        self.eventId = eventId
    }

    // MARK: - Public Methods

    /// Load initial activity
    func loadActivity() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentOffset = 0

        do {
            let response = try await eventService.fetchActivity(
                eventId: eventId,
                limit: pageSize,
                offset: 0
            )
            activities = response.activities
            activityCount = response.activityCount
            isGated = response.gated
            gatedMessage = response.message
            hasMore = response.pagination?.hasMore ?? false
            currentOffset = pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load more activity (pagination)
    func loadMoreIfNeeded(currentItem: EventActivity) async {
        guard !isLoadingMore && hasMore else { return }

        // Check if we're near the end
        let thresholdIndex = activities.index(activities.endIndex, offsetBy: -3)
        guard let itemIndex = activities.firstIndex(where: { $0.id == currentItem.id }),
              itemIndex >= thresholdIndex else {
            return
        }

        await loadMore()
    }

    /// Load next page
    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }

        isLoadingMore = true

        do {
            let response = try await eventService.fetchActivity(
                eventId: eventId,
                limit: pageSize,
                offset: currentOffset
            )
            activities.append(contentsOf: response.activities)
            hasMore = response.pagination?.hasMore ?? false
            currentOffset += pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    /// Refresh activity
    func refresh() async {
        await loadActivity()
    }

    // MARK: - Static Formatters (avoid recreating on every call)

    private static let isoFormatterWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let dateGroupFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    // MARK: - Computed Properties

    var isEmpty: Bool {
        activities.isEmpty && !isLoading
    }

    /// Group activities by date for section headers
    var groupedActivities: [(String, [EventActivity])] {
        let grouped = Dictionary(grouping: activities) { activity -> String in
            guard let date = Self.isoFormatterWithFractional.date(from: activity.createdAt)
                    ?? Self.isoFormatterBasic.date(from: activity.createdAt) else {
                return "Unknown"
            }
            return self.dateGroupKey(for: date)
        }

        return grouped.sorted { $0.key > $1.key }
    }

    private func dateGroupKey(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return Self.dateGroupFormatter.string(from: date)
        }
    }
}
