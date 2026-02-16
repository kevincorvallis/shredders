//
//  ShareableCards.swift
//  PowderTracker
//
//  Shareable conditions card and share analytics tracking
//

import SwiftUI
import UIKit
import Foundation

// MARK: - Shareable Cards

/// Instagram Story-optimized share card for mountain conditions
struct ShareableConditionsCard: View {
    let mountainName: String
    let snowfall24h: Int
    let snowDepth: Int
    let powderScore: Int
    let date: Date

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient.powderBlue
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App branding
                HStack {
                    Image(systemName: "snowflake")
                        .font(.title2)
                    Text("PowderTracker")
                        .font(.title2.bold())
                }
                .foregroundColor(.white.opacity(0.9))

                Spacer()

                // Mountain name
                Text(mountainName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Conditions
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(snowfall24h)\"")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Fresh Snow")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(snowDepth)\"")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Base Depth")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Powder score badge
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 80, height: 80)

                    VStack(spacing: 2) {
                        Text("\(powderScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("SCORE")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Date
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(40)
        }
        .frame(width: 390, height: 844) // iPhone 14 Pro dimensions for Stories
    }

    /// Renders the card as a UIImage for sharing
    @MainActor
    func renderAsImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// MARK: - Share Analytics Tracking

/// Tracks share events for engagement analytics
@MainActor
final class ShareAnalyticsTracker {
    static let shared = ShareAnalyticsTracker()

    private let defaults = UserDefaults.standard
    private let shareCountKey = "share_analytics_count"
    private let shareHistoryKey = "share_analytics_history"

    private init() {}

    /// Total number of shares
    var totalShares: Int {
        defaults.integer(forKey: shareCountKey)
    }

    /// Track a share event
    /// - Parameters:
    ///   - type: Type of content shared (mountain, conditions, event, etc.)
    ///   - itemId: ID of the shared item
    ///   - platform: Optional platform identifier (messages, instagram, etc.)
    func trackShare(type: ShareType, itemId: String, platform: String? = nil) {
        // Increment total count
        let newCount = totalShares + 1
        defaults.set(newCount, forKey: shareCountKey)

        // Add to history
        var history = shareHistory
        let event = ShareEvent(
            id: UUID().uuidString,
            type: type,
            itemId: itemId,
            platform: platform,
            timestamp: Date()
        )
        history.append(event)

        // Keep only last 100 events
        if history.count > 100 {
            history = Array(history.suffix(100))
        }

        if let encoded = try? JSONEncoder().encode(history) {
            defaults.set(encoded, forKey: shareHistoryKey)
        }

    }

    /// Get share history
    var shareHistory: [ShareEvent] {
        guard let data = defaults.data(forKey: shareHistoryKey),
              let history = try? JSONDecoder().decode([ShareEvent].self, from: data) else {
            return []
        }
        return history
    }

    /// Get shares by type
    func shareCount(for type: ShareType) -> Int {
        shareHistory.filter { $0.type == type }.count
    }

    /// Get shares in last N days
    func sharesInLastDays(_ days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return shareHistory.filter { $0.timestamp > cutoff }.count
    }

    enum ShareType: String, Codable {
        case mountain
        case conditions
        case forecast
        case event
        case achievement
        case general
    }

    struct ShareEvent: Codable, Identifiable {
        let id: String
        let type: ShareType
        let itemId: String
        let platform: String?
        let timestamp: Date
    }
}

/// View modifier to track shares
struct ShareTrackingModifier: ViewModifier {
    let type: ShareAnalyticsTracker.ShareType
    let itemId: String

    func body(content: Content) -> some View {
        content.onAppear {
            // Track when share sheet is presented
            ShareAnalyticsTracker.shared.trackShare(type: type, itemId: itemId)
        }
    }
}

extension View {
    /// Track this view being shared
    func trackShare(type: ShareAnalyticsTracker.ShareType, itemId: String) -> some View {
        modifier(ShareTrackingModifier(type: type, itemId: itemId))
    }
}
