//
//  DateFormatters.swift
//  PowderTracker
//
//  Shared static DateFormatter instances to avoid expensive instantiation.
//  Creating DateFormatter() costs ~1ms per instance - using shared statics
//  eliminates this overhead in view bodies, computed properties, and loops.
//

import Foundation

/// Shared DateFormatter instances for consistent, performant date formatting.
/// All formatters are lazily initialized and cached as static constants.
enum DateFormatters {

    // MARK: - Event Formatters

    /// Format: "Sat, Jan 15" - Used for event date display
    static let eventDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    /// Format: "9:30 AM" - Used for event time display
    static let eventTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// Format: "Saturday, January 15" - Full date for detail views
    static let eventDateFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    /// Format: "Jan 15, 2025" - Medium date format
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Short Formatters

    /// Format: "1/15/25" - Short date for compact display
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Format: "9:30 AM" - Time only
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Format: "1/15/25, 9:30 AM" - Short date and time
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Relative Formatters

    /// "2 hours ago", "in 3 days" - Relative time formatting
    nonisolated(unsafe) static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// "2 hr ago", "3 days ago" - Short relative time
    nonisolated(unsafe) static let relativeShort: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    // MARK: - ISO8601 Formatters

    /// Standard ISO8601 format for API communication
    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// ISO8601 without fractional seconds
    nonisolated(unsafe) static let iso8601Simple: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - Specialized Formatters

    /// Format: "Monday" - Day of week only
    static let dayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    /// Format: "Mon" - Short day of week
    static let dayOfWeekShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    /// Format: "January" - Month name only
    static let monthName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    /// Format: "Jan" - Short month name
    static let monthNameShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    /// Format: "15" - Day number only
    static let dayNumber: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    /// Format: "yyyy-MM-dd" - Date parser for API dates
    static let dateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Format: "h:mm a" - Time parser
    static let timeParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - Convenience Methods

    /// Format a date using the appropriate formatter for event display
    static func formatEventDate(_ date: Date) -> String {
        eventDate.string(from: date)
    }

    /// Format a date using the appropriate formatter for event time display
    static func formatEventTime(_ date: Date) -> String {
        eventTime.string(from: date)
    }

    /// Format a date as relative time (e.g., "2 hours ago")
    static func formatRelative(_ date: Date) -> String {
        relative.localizedString(for: date, relativeTo: Date())
    }
}
