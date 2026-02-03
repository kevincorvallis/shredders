//
//  EventsMapView.swift
//  PowderTracker
//
//  Map view showing ski events at their mountain locations.
//  Allows users to discover events geographically and get directions.
//

import SwiftUI
import MapKit

struct EventsMapView: View {
    let events: [Event]
    let mountains: [Mountain]
    let onEventSelected: (Event) -> Void

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.5, longitude: -121.5), // PNW default
            span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3)
        )
    )
    @State private var selectedEvent: Event?

    // Group events by mountain for clustering
    private var eventsByMountain: [String: [Event]] {
        Dictionary(grouping: events, by: { $0.mountainId })
    }

    // Get unique mountains that have events
    private var mountainsWithEvents: [Mountain] {
        let eventMountainIds = Set(events.map { $0.mountainId })
        return mountains.filter { eventMountainIds.contains($0.id) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                // Show markers for mountains with events
                ForEach(mountainsWithEvents) { mountain in
                    let mountainEvents = eventsByMountain[mountain.id] ?? []
                    let firstEvent = mountainEvents.first

                    Annotation(
                        mountain.name,
                        coordinate: mountain.location.coordinate,
                        anchor: .bottom
                    ) {
                        EventMapMarker(
                            eventCount: mountainEvents.count,
                            isToday: mountainEvents.contains { $0.isToday },
                            isTomorrow: mountainEvents.contains { $0.isTomorrow },
                            isSelected: selectedEvent?.mountainId == mountain.id
                        )
                        .onTapGesture {
                            if let event = firstEvent {
                                selectEvent(event, at: mountain)
                            }
                        }
                    }
                }

                // User location
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            // Selected event card
            if let event = selectedEvent {
                EventMapCard(
                    event: event,
                    allEventsAtMountain: eventsByMountain[event.mountainId] ?? [],
                    onTap: {
                        onEventSelected(event)
                    },
                    onDirections: {
                        openDirections(for: event)
                    },
                    onDismiss: {
                        withAnimation {
                            selectedEvent = nil
                        }
                    },
                    onSelectEvent: { newEvent in
                        selectedEvent = newEvent
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding()
            }
        }
        .onChange(of: selectedEvent?.id) { _, newId in
            if newId != nil {
                HapticFeedback.selection.trigger()
            }
        }
    }

    // MARK: - Helpers

    private func selectEvent(_ event: Event, at mountain: Mountain) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedEvent = event
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: mountain.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            )
        }
    }

    private func openDirections(for event: Event) {
        guard let mountain = mountains.first(where: { $0.id == event.mountainId }) else { return }

        let destination = MKMapItem(placemark: MKPlacemark(coordinate: mountain.location.coordinate))
        destination.name = mountain.name

        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Event Map Marker

struct EventMapMarker: View {
    let eventCount: Int
    let isToday: Bool
    let isTomorrow: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Marker bubble
            ZStack {
                // Background
                Circle()
                    .fill(markerColor)
                    .frame(width: isSelected ? 48 : 40, height: isSelected ? 48 : 40)
                    .shadow(color: markerColor.opacity(0.4), radius: isSelected ? 8 : 4, y: 2)

                // Icon or count
                if eventCount > 1 {
                    Text("\(eventCount)")
                        .font(.system(size: isSelected ? 18 : 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "figure.skiing.downhill")
                        .font(.system(size: isSelected ? 20 : 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            // Pointer triangle
            EventMarkerTriangle()
                .fill(markerColor)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    private var markerColor: Color {
        if isToday {
            return .orange
        } else if isTomorrow {
            return .green
        } else {
            return .blue
        }
    }
}

// MARK: - Event Map Card

struct EventMapCard: View {
    let event: Event
    let allEventsAtMountain: [Event]
    let onTap: () -> Void
    let onDirections: () -> Void
    let onDismiss: () -> Void
    let onSelectEvent: (Event) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.tertiaryLabel))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            // Multiple events selector (if more than one event at this mountain)
            if allEventsAtMountain.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allEventsAtMountain) { e in
                            Button {
                                onSelectEvent(e)
                            } label: {
                                Text(e.title)
                                    .font(.caption)
                                    .fontWeight(e.id == event.id ? .semibold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(e.id == event.id ? Color.blue : Color(.tertiarySystemFill))
                                    .foregroundStyle(e.id == event.id ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }

            HStack(alignment: .top, spacing: 12) {
                // Event info
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "mountain.2.fill")
                            .font(.caption)
                        Text(event.mountainName ?? "Mountain")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        // Date
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(event.formattedDate)
                                .font(.caption)
                        }
                        .foregroundStyle(event.isToday ? .orange : .secondary)

                        // Attendees
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                            Text("\(event.goingCount)")
                                .font(.caption)
                        }
                        .foregroundStyle(.green)

                        // Carpool
                        if event.carpoolAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "car.fill")
                                    .font(.caption)
                                if let seats = event.carpoolSeats {
                                    Text("\(seats)")
                                        .font(.caption)
                                }
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                }

                Spacer()

                // Action buttons
                VStack(spacing: 8) {
                    Button {
                        onDirections()
                    } label: {
                        Image(systemName: "car.fill")
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.blue)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Get directions")

                    Button {
                        onTap()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("View event details")
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 50 {
                        onDismiss()
                    }
                }
        )
    }
}

// MARK: - Triangle Shape

struct EventMarkerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    EventsMapView(
        events: [],
        mountains: [],
        onEventSelected: { _ in }
    )
}
