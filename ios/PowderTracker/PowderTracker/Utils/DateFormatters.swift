//
//  DateFormatters.swift
//  PowderTracker
//
//  Shared date formatters to avoid creating expensive formatter instances repeatedly.
//  Phase 6 & 10 optimization.
//

import Foundation

/// Shared date formatters for consistent formatting across the app.
/// DateFormatter and ISO8601DateFormatter are expensive to create,
/// so reusing them provides significant performance benefits.
enum DateFormatters {
    /// ISO 8601 date formatter with fractional seconds
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Standard date formatter for event dates (yyyy-MM-dd)
    static let eventDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Display date formatter for user-facing dates
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Display date/time formatter for user-facing dates with time
    static let displayDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Relative date formatter for "3 hours ago" style
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}
