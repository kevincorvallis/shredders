//
//  HostBadge.swift
//  PowderTracker
//
//  Badge indicating the user is the event host/organizer.
//

import SwiftUI

/// Displays a "HOST" badge for event organizers
struct HostBadge: View {
    var body: some View {
        Text("HOST")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(EventCardStyle.hostBadgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(EventCardStyle.hostBadgeColor.opacity(0.15))
            .clipShape(Capsule())
            .accessibilityLabel("You are the host of this event")
    }
}

#Preview {
    HostBadge()
        .padding()
}
