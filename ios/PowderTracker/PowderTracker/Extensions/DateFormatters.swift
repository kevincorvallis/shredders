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

    /// "2 hours ago", "3 days ago" - Full relative time
    nonisolated(unsafe) static let relativeFull: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
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

    /// Format: "MMM d" - Short month and day (e.g., "Jan 15")
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Format: "EEEE, MMMM d, yyyy" - Full date with year
    static let fullDateWithYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    /// Format: "yyyy-MM-dd HH:mm" - Date and time parser
    static let dateTimeParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
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

    /// Parse an ISO8601 date string, trying fractional seconds first then simple
    static func parseISO8601(_ string: String) -> Date? {
        iso8601.date(from: string) ?? iso8601Simple.date(from: string)
    }

    /// Format a "HH:mm" or "HH:mm:ss" time string to "h:mm AM/PM"
    static func formatDepartureTime(_ time: String) -> String? {
        let components = time.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]) else { return time }
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour >= 12 ? "PM" : "AM"
        return "\(h12):\(components[1]) \(ampm)"
    }

    /// Human-friendly relative time (e.g., "Just now", "2h ago", "Yesterday", "3d ago", "Jan 15")
    static func relativeTimeString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else if interval < 172800 {
            return "Yesterday"
        } else {
            let days = Int(interval / 86400)
            if days < 7 {
                return "\(days)d ago"
            } else {
                return monthDay.string(from: date)
            }
        }
    }
}
