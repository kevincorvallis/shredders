//
//  PowderDayEventSheet.swift
//  PowderTracker
//
//  Quick event creation sheet with powder day defaults
//

import SwiftUI

struct PowderDayEventSheet: View {
    @Environment(\.dismiss) private var dismiss

    let mountain: Mountain
    let snowfall24h: Int

    // Pre-filled defaults
    @State private var title: String = ""
    @State private var eventDate: Date = Date()
    @State private var departureTime: Date = Date()
    @State private var departureLocation: String = ""
    @State private var carpoolSeats: Int = 4
    @State private var showAdvanced = false

    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var error: String?

    var onEventCreated: ((Event) -> Void)?

    init(mountain: Mountain, snowfall24h: Int = 0, onEventCreated: ((Event) -> Void)? = nil) {
        self.mountain = mountain
        self.snowfall24h = snowfall24h
        self.onEventCreated = onEventCreated

        // Set smart defaults
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        _eventDate = State(initialValue: tomorrow)

        // Default to 6:30 AM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 6
        components.minute = 30
        _departureTime = State(initialValue: Calendar.current.date(from: components) ?? tomorrow)

        _title = State(initialValue: "Powder Day at \(mountain.shortName)!")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with snow info
                    powderHeader

                    // Main form
                    VStack(spacing: 16) {
                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Event Title")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("Powder Day!", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Date & Time
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Date")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                DatePicker("", selection: $eventDate, in: Date()..., displayedComponents: .date)
                                    .labelsHidden()
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Departure")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                DatePicker("", selection: $departureTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }

                        // Carpool seats
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Carpool Seats Available")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Stepper("\(carpoolSeats) seats", value: $carpoolSeats, in: 1...8)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }

                        // Advanced options toggle
                        DisclosureGroup("More Options", isExpanded: $showAdvanced) {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Meeting Point")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    TextField("Optional", text: $departureLocation)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .tint(.blue)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Error message
                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Create button
                    Button(action: createEvent) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "snowflake")
                                Text("Create Powder Day Event")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.powderBlue)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting || title.isEmpty)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Powder Day!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
    }

    private var powderHeader: some View {
        HStack(spacing: 16) {
            // Snow icon with amount
            ZStack {
                Circle()
                    .fill(LinearGradient.powderBlue.opacity(0.2))
                    .frame(width: 60, height: 60)

                VStack(spacing: 2) {
                    Image(systemName: "snowflake")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    if snowfall24h > 0 {
                        Text("\(snowfall24h)\"")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.name)
                    .font(.headline)

                if snowfall24h > 0 {
                    Text("\(snowfall24h) inches of fresh snow!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Great conditions for a powder day!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("Event Created!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Share with your crew")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
        .transition(.opacity)
    }

    private func createEvent() {
        guard !title.isEmpty else { return }

        isSubmitting = true
        error = nil

        // Format departure time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let departureTimeStr = timeFormatter.string(from: departureTime)

        Task {
            do {
                let response = try await EventService.shared.createEvent(
                    mountainId: mountain.id,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    notes: "Fresh powder alert! Join us for first tracks.",
                    eventDate: eventDate,
                    departureTime: departureTimeStr,
                    departureLocation: departureLocation.isEmpty ? nil : departureLocation,
                    skillLevel: .all,
                    carpoolAvailable: true,
                    carpoolSeats: carpoolSeats
                )

                HapticFeedback.success.trigger()

                // Show success
                withAnimation {
                    showSuccess = true
                }

                // Dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onEventCreated?(response.event)
                    dismiss()
                }

            } catch let err as EventServiceError {
                error = err.localizedDescription
                isSubmitting = false
            } catch {
                self.error = "Failed to create event"
                isSubmitting = false
            }
        }
    }
}

#Preview {
    PowderDayEventSheet(
        mountain: Mountain(
            id: "stevens",
            name: "Stevens Pass",
            shortName: "Stevens",
            location: MountainLocation(lat: 47.74, lng: -121.09),
            elevation: MountainElevation(base: 4061, summit: 5845),
            region: "Washington",
            color: "#2563EB",
            website: "https://stevenspass.com",
            hasSnotel: true,
            webcamCount: 3,
            logo: nil,
            status: nil,
            passType: .epic
        ),
        snowfall24h: 12
    )
}
