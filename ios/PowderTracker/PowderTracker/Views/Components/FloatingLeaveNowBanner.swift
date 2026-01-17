//
//  FloatingLeaveNowBanner.swift
//  PowderTracker
//
//  Floating bottom banner for urgent "Leave Now" alerts
//

import SwiftUI

/// Floating banner that appears at the bottom when user should leave soon
struct FloatingLeaveNowBanner: View {
    let mountain: Mountain
    let arrivalTime: ArrivalTimeRecommendation
    let onDismiss: () -> Void
    let onNavigate: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: .spacingM) {
            // Animated clock icon
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .symbolEffect(.pulse)

            VStack(alignment: .leading, spacing: .spacingXS / 2) {
                Text("Leave now for \(mountain.shortName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("Arrive by \(arrivalTime.arrivalWindow.optimal)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            // Navigate button
            Button(action: onNavigate) {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingM)
        .background(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(.cornerRadiusHero)
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: -4)
        .padding(.horizontal, .spacingL)
        .padding(.bottom, .spacingS)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 100)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

/// Container that overlays the floating banner on content
struct FloatingLeaveNowContainer<Content: View>: View {
    let leaveNowMountain: (mountain: Mountain, arrivalTime: ArrivalTimeRecommendation)?
    @ViewBuilder let content: Content

    @State private var isDismissed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            content

            if let item = leaveNowMountain, !isDismissed {
                FloatingLeaveNowBanner(
                    mountain: item.mountain,
                    arrivalTime: item.arrivalTime,
                    onDismiss: {
                        withAnimation(.spring(response: 0.3)) {
                            isDismissed = true
                        }
                    },
                    onNavigate: {
                        openMapsDirections(to: item.mountain)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func openMapsDirections(to mountain: Mountain) {
        let lat = mountain.location.lat
        let lng = mountain.location.lng
        if let url = URL(string: "maps://?daddr=\(lat),\(lng)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack {
        Text("Content goes here")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
    .overlay(alignment: .bottom) {
        FloatingLeaveNowBanner(
            mountain: Mountain(
                id: "baker",
                name: "Mt. Baker",
                shortName: "Baker",
                location: MountainLocation(lat: 48.8563, lng: -121.6644),
                elevation: MountainElevation(base: 3500, summit: 5089),
                region: "WA",
                color: "#4A90E2",
                website: "https://www.mtbaker.us",
                hasSnotel: true,
                webcamCount: 3,
                logo: "/logos/baker.svg",
                status: nil,
                passType: .ikon
            ),
            arrivalTime: .mock,
            onDismiss: {},
            onNavigate: {}
        )
    }
}
#endif
