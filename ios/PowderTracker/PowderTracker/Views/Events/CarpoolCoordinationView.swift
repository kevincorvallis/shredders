//
//  CarpoolCoordinationView.swift
//  PowderTracker
//
//  Carpool coordination UI for matching drivers with riders.
//

import SwiftUI

struct CarpoolCoordinationView: View {
    let attendees: [EventAttendee]
    let carpoolSeats: Int?
    var isCurrentUserHost: Bool = false
    var currentUserIsDriver: Bool = false
    var currentUserNeedsRide: Bool = false
    let onOfferRide: () -> Void
    let onNeedRide: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "car.2.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Carpool Coordination")
                    .font(.headline)
                Spacer()

                // Show host's carpool status
                if isCurrentUserHost {
                    Text("You organized this")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
            }

            // Your carpool status (for host or current user)
            if isCurrentUserHost || currentUserIsDriver || currentUserNeedsRide {
                yourCarpoolStatus
            }

            Divider()

            // Drivers Section
            driversSection

            // Riders Section
            ridersSection

            // Stats
            carpoolStats
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Your Carpool Status

    private var yourCarpoolStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: currentUserIsDriver ? "car.fill" : (currentUserNeedsRide ? "figure.wave" : "person.fill"))
                .font(.title3)
                .foregroundStyle(currentUserIsDriver ? .green : (currentUserNeedsRide ? .purple : .blue))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if currentUserIsDriver {
                    Text("Offering rides")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                } else if currentUserNeedsRide {
                    Text("Looking for a ride")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.purple)
                } else if isCurrentUserHost {
                    Text("Not set - tap to update")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isCurrentUserHost && !currentUserIsDriver && !currentUserNeedsRide {
                Button("Update") {
                    onOfferRide()
                }
                .font(.caption)
                .fontWeight(.medium)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(currentUserIsDriver ? Color.green.opacity(0.3) : (currentUserNeedsRide ? Color.purple.opacity(0.3) : Color.clear), lineWidth: 1)
                )
        )
    }

    // MARK: - Drivers Section

    private var driversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.fill.badge.plus")
                    .foregroundStyle(.green)
                Text("Drivers")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(drivers.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if drivers.isEmpty {
                HStack {
                    Text("No drivers yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Offer a ride") {
                        onOfferRide()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            } else {
                ForEach(drivers) { driver in
                    driverRow(driver)
                }
            }
        }
    }

    private func driverRow(_ attendee: EventAttendee) -> some View {
        HStack(spacing: 8) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(attendee.user.displayNameOrUsername.prefix(1)).uppercased())
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(attendee.user.displayNameOrUsername)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let location = attendee.pickupLocation, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Driver badge
            HStack(spacing: 4) {
                Image(systemName: "car.fill")
                    .font(.caption)
                Text("Driver")
                    .font(.caption)
            }
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.green.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Riders Section

    private var ridersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.purple)
                Text("Looking for a Ride")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(riders.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if riders.isEmpty {
                HStack {
                    Text("No one needs a ride yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("I need a ride") {
                        onNeedRide()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                .padding(8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            } else {
                ForEach(riders) { rider in
                    riderRow(rider)
                }
            }
        }
    }

    private func riderRow(_ attendee: EventAttendee) -> some View {
        HStack(spacing: 8) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(attendee.user.displayNameOrUsername.prefix(1)).uppercased())
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(attendee.user.displayNameOrUsername)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let location = attendee.pickupLocation, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Needs ride badge
            HStack(spacing: 4) {
                Image(systemName: "hand.raised.fill")
                    .font(.caption)
                Text("Needs ride")
                    .font(.caption)
            }
            .foregroundStyle(.purple)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.purple.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Stats

    private var carpoolStats: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("\(drivers.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                Text("Drivers")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 30)

            VStack(spacing: 2) {
                Text("\(riders.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)
                Text("Need Rides")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            if let seats = carpoolSeats, seats > 0 {
                Divider()
                    .frame(height: 30)

                VStack(spacing: 2) {
                    Text("\(seats)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text("Total Seats")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    private var drivers: [EventAttendee] {
        attendees.filter { $0.isDriver && ($0.status == .going || $0.status == .maybe) }
    }

    private var riders: [EventAttendee] {
        attendees.filter { $0.needsRide && ($0.status == .going || $0.status == .maybe) }
    }
}

// MARK: - RSVP with Carpool Sheet

struct RSVPCarpoolSheet: View {
    let eventId: String
    let eventDate: String
    let currentStatus: RSVPStatus?
    /// Callback with the new RSVP status after successful update
    let onComplete: (RSVPStatus) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStatus: RSVPStatus = .going
    @State private var isDriver = false
    @State private var needsRide = false
    @State private var pickupLocation = ""
    @State private var isSubmitting = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                // RSVP Status
                Section("Are you going?") {
                    Picker("Status", selection: $selectedStatus) {
                        Text("I'm In!").tag(RSVPStatus.going)
                        Text("Maybe").tag(RSVPStatus.maybe)
                        Text("Can't make it").tag(RSVPStatus.declined)
                    }
                    .pickerStyle(.segmented)
                }

                // Carpool Options (only show if going or maybe)
                if selectedStatus != .declined {
                    Section("Carpool") {
                        Toggle(isOn: $isDriver) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("I can drive")
                                    Text("Offer seats to others")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .onChange(of: isDriver) { _, newValue in
                            if newValue { needsRide = false }
                        }

                        Toggle(isOn: $needsRide) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("I need a ride")
                                    Text("Looking for a carpool")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "figure.walk")
                                    .foregroundStyle(.purple)
                            }
                        }
                        .onChange(of: needsRide) { _, newValue in
                            if newValue { isDriver = false }
                        }
                    }

                    // Pickup Location (if driver or needs ride)
                    if isDriver || needsRide {
                        Section {
                            TextField("Pickup location (optional)", text: $pickupLocation)
                        } header: {
                            Text("Pickup Location")
                        } footer: {
                            Text(isDriver
                                ? "Where can you pick people up?"
                                : "Where would you like to be picked up?")
                        }
                    }
                }

                // Error display
                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("RSVP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        Task { await submitRSVP() }
                    }
                    .disabled(isSubmitting)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let currentStatus = currentStatus {
                    selectedStatus = currentStatus
                }
            }
        }
    }

    private func submitRSVP() async {
        isSubmitting = true
        error = nil

        do {
            let response = try await EventService.shared.rsvp(
                eventId: eventId,
                eventDate: eventDate,
                status: selectedStatus,
                isDriver: isDriver,
                needsRide: needsRide,
                pickupLocation: pickupLocation.isEmpty ? nil : pickupLocation
            )

            HapticFeedback.success.trigger()
            // Pass the new status from the response to update UI immediately
            onComplete(response.attendee.status)
            dismiss()
        } catch let err as EventServiceError {
            error = err.localizedDescription
            HapticFeedback.error.trigger()
        } catch {
            self.error = "Failed to update RSVP"
            HapticFeedback.error.trigger()
        }

        isSubmitting = false
    }
}

#Preview("Carpool Coordination") {
    VStack(spacing: 20) {
        // As host who is a driver
        CarpoolCoordinationView(
            attendees: [
                EventAttendee(
                    id: "1",
                    userId: "u1",
                    status: .going,
                    isDriver: true,
                    needsRide: false,
                    pickupLocation: "Seattle - Capitol Hill",
                    waitlistPosition: nil,
                    respondedAt: nil,
                    user: EventUser(id: "u1", username: "sarah_k", displayName: "Sarah K.", avatarUrl: nil, ridingStyle: "skier")
                ),
                EventAttendee(
                    id: "2",
                    userId: "u2",
                    status: .going,
                    isDriver: false,
                    needsRide: true,
                    pickupLocation: "Bellevue",
                    waitlistPosition: nil,
                    respondedAt: nil,
                    user: EventUser(id: "u2", username: "mike_t", displayName: "Mike T.", avatarUrl: nil, ridingStyle: "snowboarder")
                )
            ],
            carpoolSeats: 4,
            isCurrentUserHost: true,
            currentUserIsDriver: true,
            currentUserNeedsRide: false,
            onOfferRide: {},
            onNeedRide: {}
        )

        // As host who hasn't set status
        CarpoolCoordinationView(
            attendees: [],
            carpoolSeats: 4,
            isCurrentUserHost: true,
            currentUserIsDriver: false,
            currentUserNeedsRide: false,
            onOfferRide: {},
            onNeedRide: {}
        )
    }
    .padding()
}

#Preview("RSVP Sheet") {
    RSVPCarpoolSheet(
        eventId: "test",
        eventDate: "2026-03-15",
        currentStatus: nil,
        onComplete: { _ in }
    )
}
