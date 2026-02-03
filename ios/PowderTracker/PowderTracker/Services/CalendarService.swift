//
//  CalendarService.swift
//  PowderTracker
//
//  Calendar integration service for adding ski events to the user's calendar.
//

import EventKit
import Foundation

@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var isAuthorized = false

    private init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    func updateAuthorizationStatus() {
        if #available(iOS 17.0, *) {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            isAuthorized = authorizationStatus == .fullAccess
        } else {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            isAuthorized = authorizationStatus == .authorized
        }
    }

    func requestAccess() async -> Bool {
        do {
            var granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            updateAuthorizationStatus()
            return granted
        } catch {
            print("[CalendarService] Failed to request access: \(error)")
            return false
        }
    }

    // MARK: - Event Operations

    /// Add an event to the calendar
    /// - Returns: The EKEvent identifier if successful, nil otherwise
    func addEventToCalendar(
        title: String,
        startDate: Date,
        endDate: Date? = nil,
        location: String? = nil,
        notes: String? = nil,
        mountainName: String? = nil
    ) async throws -> String {
        // Request access if not authorized
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else {
                throw CalendarServiceError.accessDenied
            }
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Build title with mountain name if available
        if let mountain = mountainName {
            event.title = "\(title) - \(mountain)"
        } else {
            event.title = title
        }

        event.startDate = startDate
        event.endDate = endDate ?? Calendar.current.date(byAdding: .hour, value: 8, to: startDate) ?? startDate
        event.location = location
        event.notes = notes

        // Add an alarm for morning of event
        let morningAlarm = EKAlarm(absoluteDate: Calendar.current.startOfDay(for: startDate))
        event.addAlarm(morningAlarm)

        // Add a 1-hour before alarm
        let oneHourBefore = EKAlarm(relativeOffset: -3600) // -1 hour
        event.addAlarm(oneHourBefore)

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarServiceError.saveFailed(error)
        }
    }

    /// Update an existing calendar event
    func updateCalendarEvent(
        eventIdentifier: String,
        title: String,
        startDate: Date,
        endDate: Date? = nil,
        location: String? = nil,
        notes: String? = nil
    ) throws {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            throw CalendarServiceError.eventNotFound
        }

        event.title = title
        event.startDate = startDate
        event.endDate = endDate ?? Calendar.current.date(byAdding: .hour, value: 8, to: startDate) ?? startDate
        event.location = location
        event.notes = notes

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarServiceError.saveFailed(error)
        }
    }

    /// Remove an event from the calendar
    func removeCalendarEvent(eventIdentifier: String) throws {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            // Event already removed or doesn't exist - not an error
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            throw CalendarServiceError.removeFailed(error)
        }
    }

    /// Check if an event exists in the calendar
    func eventExists(eventIdentifier: String) -> Bool {
        return eventStore.event(withIdentifier: eventIdentifier) != nil
    }
}

// MARK: - Errors

enum CalendarServiceError: LocalizedError {
    case accessDenied
    case saveFailed(Error)
    case removeFailed(Error)
    case eventNotFound

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was denied. Please enable calendar access in Settings."
        case .saveFailed(let error):
            return "Failed to save event to calendar: \(error.localizedDescription)"
        case .removeFailed(let error):
            return "Failed to remove event from calendar: \(error.localizedDescription)"
        case .eventNotFound:
            return "Calendar event not found."
        }
    }
}

// MARK: - Helper Extension for Events

extension EventWithDetails {
    /// Convert event date string to Date object
    var eventStartDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: eventDate) else { return nil }

        // If departure time is set, parse and combine
        if let timeString = departureTime {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            if let time = timeFormatter.date(from: timeString) {
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                return calendar.date(bySettingHour: timeComponents.hour ?? 8,
                                     minute: timeComponents.minute ?? 0,
                                     second: 0,
                                     of: date)
            }
        }

        // Default to 8 AM if no time specified
        return Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: date)
    }

    /// Generate calendar notes from event details
    var calendarNotes: String {
        var parts: [String] = []

        if let notes = self.notes, !notes.isEmpty {
            parts.append(notes)
        }

        parts.append("---")
        parts.append("Organized by: \(creator.displayNameOrUsername)")
        parts.append("RSVP: \(goingCount) going, \(maybeCount) maybe")

        if carpoolAvailable, let seats = carpoolSeats {
            parts.append("Carpool: \(seats) seats available")
        }

        parts.append("")
        parts.append("View event in PowderTracker app")

        return parts.joined(separator: "\n")
    }
}
