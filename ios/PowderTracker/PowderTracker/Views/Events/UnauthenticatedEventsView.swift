//
//  UnauthenticatedEventsView.swift
//  PowderTracker
//
//  Events view for users who are not signed in, showing sample events.
//

import SwiftUI

struct UnauthenticatedEventsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(spacing: .spacingXL) {
                        heroSection
                        sampleEventsSection
                        ctaSection
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Ski Events")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "0F172A") ?? Color(.systemBackground),
                Color(hex: "1E293B") ?? Color(.secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: .spacingL) {
            // Feature card
            HStack(spacing: .spacingM) {
                featureIcon

                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Plan ski trips with friends")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Create events, coordinate carpools")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(.spacingL)
            .background(featureCardBackground)

            Text("Sign in to join upcoming trips or create your own")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // CTA Buttons
            ctaButtons
        }
        .padding(.horizontal)
        .padding(.top, .spacingS)
    }

    private var featureIcon: some View {
        Image(systemName: "person.3.fill")
            .font(.system(size: 24))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "0EA5E9")?.opacity(0.3) ?? .blue.opacity(0.3),
                        Color(hex: "A855F7")?.opacity(0.3) ?? .purple.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((Color(hex: "0EA5E9") ?? .blue).opacity(0.5), lineWidth: 1)
            )
    }

    private var featureCardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "0EA5E9")?.opacity(0.2) ?? .blue.opacity(0.2),
                    Color(hex: "A855F7")?.opacity(0.2) ?? .purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((Color(hex: "0EA5E9") ?? .blue).opacity(0.3), lineWidth: 1)
        )
    }

    private var ctaButtons: some View {
        VStack(spacing: .spacingM) {
            NavigationLink(destination: UnifiedAuthView()) {
                HStack {
                    Text("Sign in to join events")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .symbolRenderingMode(.hierarchical)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "0EA5E9") ?? .blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                HapticFeedback.light.trigger()
            })

            NavigationLink(destination: UnifiedAuthView()) {
                Text("Create an account")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "334155") ?? .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                HapticFeedback.light.trigger()
            })
        }
    }

    // MARK: - Sample Events Section

    private var sampleEventsSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack(spacing: .spacingS) {
                Text("Example Events")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.6))

                Text("Preview")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "1E293B") ?? .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()
            }
            .padding(.horizontal)

            ForEach(SampleEvent.samples) { event in
                SampleEventCard(event: event)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Bottom CTA

    private var ctaSection: some View {
        VStack(spacing: .spacingM) {
            Text("Ready to hit the slopes with friends?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))

            NavigationLink(destination: UnifiedAuthView()) {
                HStack {
                    Text("Get started free")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .symbolRenderingMode(.hierarchical)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacingL)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "0EA5E9") ?? .blue,
                            Color(hex: "0284C7") ?? .blue.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: (Color(hex: "0EA5E9") ?? .blue).opacity(0.3), radius: 12, y: 4)
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                HapticFeedback.medium.trigger()
            })
        }
        .padding(.horizontal)
        .padding(.vertical, .spacingXL)
    }
}

// MARK: - Sample Event Model

struct SampleEvent: Identifiable {
    let id: String
    let title: String
    let mountainName: String
    let eventDate: String
    let departureTime: String?
    let departureLocation: String?
    let goingCount: Int
    let maybeCount: Int
    let skillLevel: SkillLevel
    let carpoolAvailable: Bool
    let carpoolSeats: Int?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: eventDate) else { return eventDate }
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    var formattedTime: String? {
        guard let time = departureTime else { return nil }
        let components = time.split(separator: ":")
        guard components.count >= 2, let hour = Int(components[0]) else { return time }
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour >= 12 ? "PM" : "AM"
        return "\(h12):\(components[1]) \(ampm)"
    }

    static let samples: [SampleEvent] = [
        SampleEvent(
            id: "sample-1",
            title: "First Tracks Friday",
            mountainName: "Summit at Snoqualmie",
            eventDate: upcomingDate(2),
            departureTime: "06:00:00",
            departureLocation: "Seattle - Capitol Hill",
            goingCount: 8,
            maybeCount: 3,
            skillLevel: .beginner,
            carpoolAvailable: true,
            carpoolSeats: 4
        ),
        SampleEvent(
            id: "sample-2",
            title: "Powder Day at Baker!",
            mountainName: "Mt. Baker",
            eventDate: upcomingDate(3),
            departureTime: "05:30:00",
            departureLocation: "Bellingham",
            goingCount: 6,
            maybeCount: 2,
            skillLevel: .intermediate,
            carpoolAvailable: true,
            carpoolSeats: 3
        ),
        SampleEvent(
            id: "sample-3",
            title: "Backside Bowls Session",
            mountainName: "Stevens Pass",
            eventDate: upcomingDate(5),
            departureTime: "06:30:00",
            departureLocation: "Bellevue - Downtown",
            goingCount: 4,
            maybeCount: 1,
            skillLevel: .advanced,
            carpoolAvailable: true,
            carpoolSeats: 2
        ),
        SampleEvent(
            id: "sample-4",
            title: "Steep Chutes & Cliffs",
            mountainName: "Crystal Mountain",
            eventDate: upcomingDate(7),
            departureTime: "05:00:00",
            departureLocation: "Tacoma",
            goingCount: 3,
            maybeCount: 0,
            skillLevel: .expert,
            carpoolAvailable: false,
            carpoolSeats: nil
        ),
        SampleEvent(
            id: "sample-5",
            title: "Group Day - All Welcome!",
            mountainName: "Whistler Blackcomb",
            eventDate: upcomingDate(10),
            departureTime: "04:00:00",
            departureLocation: "Seattle - University District",
            goingCount: 12,
            maybeCount: 5,
            skillLevel: .all,
            carpoolAvailable: true,
            carpoolSeats: 6
        )
    ]

    private static func upcomingDate(_ daysFromNow: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Sample Event Card

struct SampleEventCard: View {
    let event: SampleEvent
    @State private var showSignInPrompt = false

    var body: some View {
        ZStack {
            cardContent

            if showSignInPrompt {
                signInOverlay
                    .transition(.opacity)
            }
        }
        .frame(height: 180)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.light.trigger()
            withAnimation(.bouncy) {
                showSignInPrompt = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.smooth) {
                    showSignInPrompt = false
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to sign in and view event details")
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Header
            HStack(alignment: .top, spacing: .spacingS) {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: .spacingS) {
                        Label(event.mountainName, systemImage: "mountain.2")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "0EA5E9") ?? .blue)

                        Text("•")
                            .foregroundStyle(.white.opacity(0.3))

                        Text(event.formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                SkillLevelBadge(level: event.skillLevel, size: .compact)
            }

            // Details
            VStack(alignment: .leading, spacing: .spacingXS) {
                if let time = event.formattedTime {
                    Label("Departing \(time)", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                if let location = event.departureLocation {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Footer
            HStack(spacing: .spacingL) {
                Label("\(event.goingCount) going", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                if event.maybeCount > 0 {
                    Text("+\(event.maybeCount) maybe")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                if event.carpoolAvailable, let seats = event.carpoolSeats {
                    Spacer()
                    CarpoolBadge(seats: seats, size: .compact)
                }
            }
        }
        .padding(.spacingL)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill((Color(hex: "1E293B") ?? .gray).opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((Color(hex: "334155") ?? .gray).opacity(0.5), lineWidth: 1)
        )
    }

    private var signInOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill((Color(hex: "0F172A") ?? .black).opacity(0.9))
            .overlay(
                VStack(spacing: .spacingS) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "0EA5E9") ?? .blue)

                    Text("Sign in to view & join")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            )
    }

    private var accessibilityLabel: String {
        var parts = [
            event.title,
            "at \(event.mountainName)",
            event.formattedDate
        ]
        if let time = event.formattedTime {
            parts.append("departing at \(time)")
        }
        parts.append("\(event.goingCount) people going")
        parts.append("Skill level: \(event.skillLevel.displayName)")
        if event.carpoolAvailable {
            parts.append("Carpool available")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("Unauthenticated Events") {
    UnauthenticatedEventsView()
}
